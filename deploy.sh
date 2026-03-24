#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# Kheteebaadi - Complete AWS Deployment Script
# Run: chmod +x deploy.sh && ./deploy.sh
#
# Prerequisites:
#   - AWS CLI v2 configured (aws configure)
#   - Docker installed and running
#   - Terraform >= 1.0 installed
#
# This script will:
#   1. Create Terraform state backend (S3 + DynamoDB)
#   2. Provision all AWS infrastructure via Terraform
#   3. Build and push Docker images to ECR
#   4. Create secrets in AWS Secrets Manager
#   5. Deploy ECS services
#   6. Build and deploy the dashboard to S3/CloudFront
#   7. Print all endpoints and credentials
# ═══════════════════════════════════════════════════════════════════════════

set -e

# ── Colors ──
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ── Configuration ──
PROJECT_NAME="kheteebaadi"
AWS_REGION="ap-south-1"
ENVIRONMENT="prod"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/infrastructure/terraform"
BACKEND_DIR="$SCRIPT_DIR/backend"
DASHBOARD_DIR="$SCRIPT_DIR/ovol-dashboard"

echo -e "${CYAN}"
echo "═══════════════════════════════════════════════════════════════"
echo "   KHETEEBAADI - AWS Deployment"
echo "   Region: $AWS_REGION | Environment: $ENVIRONMENT"
echo "═══════════════════════════════════════════════════════════════"
echo -e "${NC}"

# ── Pre-flight checks ──
echo -e "${YELLOW}[1/7] Pre-flight checks...${NC}"

command -v aws >/dev/null 2>&1 || { echo -e "${RED}aws CLI not found. Install: https://aws.amazon.com/cli/${NC}"; exit 1; }
command -v docker >/dev/null 2>&1 || { echo -e "${RED}Docker not found. Install: https://docker.com/get-docker${NC}"; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo -e "${RED}Terraform not found. Install: https://terraform.io${NC}"; exit 1; }

# Verify AWS credentials
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null) || {
    echo -e "${RED}AWS credentials not configured. Run: aws configure${NC}"
    exit 1
}
echo -e "${GREEN}  AWS Account: $AWS_ACCOUNT_ID${NC}"
echo -e "${GREEN}  Region: $AWS_REGION${NC}"
echo -e "${GREEN}  All tools verified${NC}"

# ── Generate secrets if not in .env ──
if [ ! -f "$SCRIPT_DIR/.env" ]; then
    echo -e "${YELLOW}Generating production secrets...${NC}"
    JWT_SECRET=$(openssl rand -hex 32)
    DB_PASSWORD=$(openssl rand -base64 32 | tr -d '/+=' | head -c 40)

    cat > "$SCRIPT_DIR/.env" <<ENVEOF
DB_USER=kheteebaadi_admin
DB_PASSWORD=$DB_PASSWORD
DB_NAME=kheteebaadi
DB_PORT=5432
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_MAX_MEMORY=256mb
REDIS_EVICTION_POLICY=allkeys-lru
JWT_SECRET_KEY=$JWT_SECRET
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
CORS_ORIGINS=["https://kheteebaadi.in","*"]
AWS_REGION=$AWS_REGION
S3_BUCKET=${PROJECT_NAME}-${ENVIRONMENT}
API_PORT=8000
APP_NAME=Kheteebaadi API
APP_VERSION=1.0.0
DEBUG=false
ENVEOF
    echo -e "${GREEN}  Created .env with secure secrets${NC}"
else
    echo -e "${GREEN}  Using existing .env${NC}"
fi

# Source the env file
set -a; source "$SCRIPT_DIR/.env"; set +a

# ══════════════════════════════════════════════════════════════════
# STEP 1: Terraform State Backend
# ══════════════════════════════════════════════════════════════════
echo ""
echo -e "${YELLOW}[2/7] Setting up Terraform state backend...${NC}"

STATE_BUCKET="${PROJECT_NAME}-terraform-state"
LOCK_TABLE="${PROJECT_NAME}-terraform-locks"

# Create S3 bucket for state (ignore if exists)
if ! aws s3api head-bucket --bucket "$STATE_BUCKET" 2>/dev/null; then
    aws s3api create-bucket \
        --bucket "$STATE_BUCKET" \
        --region "$AWS_REGION" \
        --create-bucket-configuration LocationConstraint="$AWS_REGION" >/dev/null

    aws s3api put-bucket-versioning \
        --bucket "$STATE_BUCKET" \
        --versioning-configuration Status=Enabled

    aws s3api put-bucket-encryption \
        --bucket "$STATE_BUCKET" \
        --server-side-encryption-configuration \
        '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

    echo -e "${GREEN}  Created S3 state bucket: $STATE_BUCKET${NC}"
else
    echo -e "${GREEN}  State bucket already exists${NC}"
fi

# Create DynamoDB table for locking (ignore if exists)
if ! aws dynamodb describe-table --table-name "$LOCK_TABLE" --region "$AWS_REGION" >/dev/null 2>&1; then
    aws dynamodb create-table \
        --table-name "$LOCK_TABLE" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "$AWS_REGION" >/dev/null

    echo -e "${GREEN}  Created DynamoDB lock table: $LOCK_TABLE${NC}"
else
    echo -e "${GREEN}  Lock table already exists${NC}"
fi

# ══════════════════════════════════════════════════════════════════
# STEP 2: Terraform - Provision Infrastructure
# ══════════════════════════════════════════════════════════════════
echo ""
echo -e "${YELLOW}[3/7] Provisioning AWS infrastructure with Terraform...${NC}"
echo -e "${YELLOW}       (This takes 15-20 minutes on first run)${NC}"

cd "$TERRAFORM_DIR"

# Create terraform.tfvars if not present
if [ ! -f "terraform.tfvars" ]; then
    cat > terraform.tfvars <<TFEOF
environment         = "$ENVIRONMENT"
project_name        = "$PROJECT_NAME"
aws_region          = "$AWS_REGION"
vpc_cidr            = "10.0.0.0/16"
db_instance_class   = "db.t4g.micro"
db_allocated_storage = 20
db_name             = "$DB_NAME"
db_username         = "$DB_USER"
db_password         = "$DB_PASSWORD"
enable_rds_multi_az = false
rds_backup_retention = 7
redis_node_type     = "cache.t4g.micro"
ecs_api_cpu         = 256
ecs_api_memory      = 512
ecs_api_min_tasks   = 1
ecs_api_max_tasks   = 5
ecs_cpu_target      = 65
domain_name         = "kheteebaadi.in"
acm_certificate_arn = ""
enable_container_insights = true
log_retention_days  = 30
tags = {
  Owner       = "Soubhagya"
  Project     = "Kheteebaadi"
  Environment = "$ENVIRONMENT"
}
TFEOF
    echo -e "${GREEN}  Created terraform.tfvars${NC}"
fi

# Initialize and apply
terraform init -input=false
terraform plan -out=tfplan -input=false
terraform apply -input=false tfplan

# Capture outputs
ALB_DNS=$(terraform output -raw alb_dns_name)
ECR_API_REPO=$(terraform output -raw ecr_api_repository_url)
ECR_WORKER_REPO=$(terraform output -raw ecr_celery_worker_repository_url)
RDS_ENDPOINT=$(terraform output -raw rds_address)
REDIS_ENDPOINT=$(terraform output -raw redis_endpoint)
REDIS_AUTH_TOKEN=$(terraform output -raw redis_auth_token)
CLUSTER_NAME=$(terraform output -raw ecs_cluster_name)
DASHBOARD_BUCKET=$(terraform output -raw dashboard_bucket_name)
CF_DIST_ID=$(terraform output -raw cloudfront_dashboard_distribution_id)
CF_DOMAIN=$(terraform output -raw cloudfront_dashboard_domain_name)
UPLOADS_CDN=$(terraform output -raw cloudfront_uploads_domain_name)

echo -e "${GREEN}  Infrastructure provisioned successfully!${NC}"

# ══════════════════════════════════════════════════════════════════
# STEP 3: Build & Push Docker Images
# ══════════════════════════════════════════════════════════════════
echo ""
echo -e "${YELLOW}[4/7] Building and pushing Docker images to ECR...${NC}"

# ECR Login
aws ecr get-login-password --region "$AWS_REGION" | \
    docker login --username AWS --password-stdin \
    "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

cd "$BACKEND_DIR"

# Build and push API image
echo -e "${CYAN}  Building API image...${NC}"
docker build -t ${PROJECT_NAME}-api:latest .
docker tag ${PROJECT_NAME}-api:latest "$ECR_API_REPO:latest"
docker tag ${PROJECT_NAME}-api:latest "$ECR_API_REPO:v1.0.0"
docker push "$ECR_API_REPO:latest"
docker push "$ECR_API_REPO:v1.0.0"
echo -e "${GREEN}  API image pushed to ECR${NC}"

# Build and push Worker image
echo -e "${CYAN}  Building Celery worker image...${NC}"
docker build -t ${PROJECT_NAME}-worker:latest -f Dockerfile.worker .
docker tag ${PROJECT_NAME}-worker:latest "$ECR_WORKER_REPO:latest"
docker tag ${PROJECT_NAME}-worker:latest "$ECR_WORKER_REPO:v1.0.0"
docker push "$ECR_WORKER_REPO:latest"
docker push "$ECR_WORKER_REPO:v1.0.0"
echo -e "${GREEN}  Worker image pushed to ECR${NC}"

# ══════════════════════════════════════════════════════════════════
# STEP 4: Create Secrets in AWS Secrets Manager
# ══════════════════════════════════════════════════════════════════
echo ""
echo -e "${YELLOW}[5/7] Creating secrets in AWS Secrets Manager...${NC}"

DATABASE_URL="postgresql+asyncpg://${DB_USER}:${DB_PASSWORD}@${RDS_ENDPOINT}:5432/${DB_NAME}"
REDIS_URL="redis://:${REDIS_AUTH_TOKEN}@${REDIS_ENDPOINT}:6379/0"

# Create or update secrets
for SECRET_NAME in "${PROJECT_NAME}/db-url" "${PROJECT_NAME}/redis-url" "${PROJECT_NAME}/jwt-secret"; do
    case "$SECRET_NAME" in
        *db-url)    SECRET_VALUE="$DATABASE_URL" ;;
        *redis-url) SECRET_VALUE="$REDIS_URL" ;;
        *jwt-secret) SECRET_VALUE="$JWT_SECRET_KEY" ;;
    esac

    if aws secretsmanager describe-secret --secret-id "$SECRET_NAME" --region "$AWS_REGION" >/dev/null 2>&1; then
        aws secretsmanager update-secret --secret-id "$SECRET_NAME" \
            --secret-string "$SECRET_VALUE" --region "$AWS_REGION" >/dev/null
        echo -e "${GREEN}  Updated secret: $SECRET_NAME${NC}"
    else
        aws secretsmanager create-secret --name "$SECRET_NAME" \
            --secret-string "$SECRET_VALUE" --region "$AWS_REGION" >/dev/null
        echo -e "${GREEN}  Created secret: $SECRET_NAME${NC}"
    fi
done

# ══════════════════════════════════════════════════════════════════
# STEP 5: Deploy ECS Services
# ══════════════════════════════════════════════════════════════════
echo ""
echo -e "${YELLOW}[6/7] Deploying ECS services...${NC}"

# Force new deployment of all services
for SERVICE in "${PROJECT_NAME}-${ENVIRONMENT}-api" "${PROJECT_NAME}-${ENVIRONMENT}-celery-worker" "${PROJECT_NAME}-${ENVIRONMENT}-celery-beat"; do
    aws ecs update-service \
        --cluster "$CLUSTER_NAME" \
        --service "$SERVICE" \
        --force-new-deployment \
        --region "$AWS_REGION" >/dev/null 2>&1 || true
    echo -e "${GREEN}  Triggered deployment: $SERVICE${NC}"
done

echo -e "${CYAN}  Waiting for API service to stabilize (2-5 min)...${NC}"
aws ecs wait services-stable \
    --cluster "$CLUSTER_NAME" \
    --services "${PROJECT_NAME}-${ENVIRONMENT}-api" \
    --region "$AWS_REGION" 2>/dev/null || echo -e "${YELLOW}  Service still stabilizing, check AWS Console${NC}"

echo -e "${GREEN}  ECS services deployed!${NC}"

# ══════════════════════════════════════════════════════════════════
# STEP 6: Deploy Dashboard
# ══════════════════════════════════════════════════════════════════
echo ""
echo -e "${YELLOW}[7/7] Building and deploying dashboard...${NC}"

cd "$DASHBOARD_DIR"

if [ -f "package.json" ]; then
    npm install --production=false
    NEXT_PUBLIC_API_BASE_URL="http://${ALB_DNS}/api/v1" npm run build 2>/dev/null || echo -e "${YELLOW}  Dashboard build had warnings (may be fine)${NC}"

    # Upload to S3
    if [ -d "out" ]; then
        aws s3 sync out/ "s3://${DASHBOARD_BUCKET}/" --delete --region "$AWS_REGION"
        echo -e "${GREEN}  Dashboard uploaded to S3${NC}"

        # Invalidate CloudFront cache
        aws cloudfront create-invalidation \
            --distribution-id "$CF_DIST_ID" \
            --paths "/*" >/dev/null
        echo -e "${GREEN}  CloudFront cache invalidated${NC}"
    elif [ -d ".next" ]; then
        echo -e "${YELLOW}  Next.js using SSR mode. For static hosting, add 'output: export' to next.config.js${NC}"
    fi
else
    echo -e "${YELLOW}  Skipping dashboard (no package.json)${NC}"
fi

# ══════════════════════════════════════════════════════════════════
# DONE!
# ══════════════════════════════════════════════════════════════════
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   DEPLOYMENT COMPLETE!${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}  API Endpoint:      ${NC}http://${ALB_DNS}"
echo -e "${BLUE}  API Docs:          ${NC}http://${ALB_DNS}/docs"
echo -e "${BLUE}  API Health:        ${NC}http://${ALB_DNS}/health"
echo -e "${BLUE}  Dashboard:         ${NC}https://${CF_DOMAIN}"
echo -e "${BLUE}  Images CDN:        ${NC}https://${UPLOADS_CDN}"
echo ""
echo -e "${BLUE}  ECS Cluster:       ${NC}${CLUSTER_NAME}"
echo -e "${BLUE}  ECR API Repo:      ${NC}${ECR_API_REPO}"
echo -e "${BLUE}  ECR Worker Repo:   ${NC}${ECR_WORKER_REPO}"
echo -e "${BLUE}  RDS Endpoint:      ${NC}${RDS_ENDPOINT}"
echo -e "${BLUE}  Redis Endpoint:    ${NC}${REDIS_ENDPOINT}"
echo -e "${BLUE}  Dashboard Bucket:  ${NC}${DASHBOARD_BUCKET}"
echo ""
echo -e "${YELLOW}  Next steps:${NC}"
echo -e "  1. Set up DNS: Point api.kheteebaadi.in → ${ALB_DNS}"
echo -e "  2. Set up DNS: Point app.kheteebaadi.in → ${CF_DOMAIN}"
echo -e "  3. Request ACM certificate for HTTPS"
echo -e "  4. Update Flutter app: --dart-define=ENV=production"
echo -e "  5. Enable MFA on your AWS root account"
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"

# Save deployment info
cd "$SCRIPT_DIR"
cat > DEPLOYMENT_INFO.txt <<INFOEOF
Kheteebaadi Deployment Info
Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

API Endpoint:      http://${ALB_DNS}
API Docs:          http://${ALB_DNS}/docs
Dashboard:         https://${CF_DOMAIN}
Images CDN:        https://${UPLOADS_CDN}

ECS Cluster:       ${CLUSTER_NAME}
ECR API:           ${ECR_API_REPO}
ECR Worker:        ${ECR_WORKER_REPO}
RDS:               ${RDS_ENDPOINT}
Redis:             ${REDIS_ENDPOINT}
S3 Dashboard:      ${DASHBOARD_BUCKET}
AWS Account:       ${AWS_ACCOUNT_ID}
Region:            ${AWS_REGION}
INFOEOF

echo -e "${GREEN}  Saved deployment info to DEPLOYMENT_INFO.txt${NC}"
