# Kheteebaadi Terraform - Quick Start Guide

Get up and running in 10 minutes!

## Prerequisites

- AWS Account with permissions in ap-south-1
- Terraform 1.0+ installed
- AWS CLI v2 configured with credentials
- Backend infrastructure created (see README.md)

## Step 1: Prepare Configuration (2 min)

```bash
# Navigate to terraform directory
cd infrastructure/terraform

# Create terraform.tfvars from example
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
vim terraform.tfvars
```

**Key values to set:**
```hcl
environment = "prod"
aws_region = "ap-south-1"
db_password = "YourStrongPassword123!@#$%"  # Change this!
domain_name = "kheteebaadi.in"
acm_certificate_arn = "arn:aws:acm:ap-south-1:YOUR_ACCOUNT:certificate/YOUR_CERT_ID"
```

## Step 2: Initialize (2 min)

```bash
# Set AWS region
export AWS_REGION=ap-south-1

# Initialize Terraform
terraform init

# Validate configuration
terraform validate
```

**Expected output:**
```
Success! The configuration is valid.
```

## Step 3: Review Plan (3 min)

```bash
# Plan infrastructure
terraform plan -out=tfplan

# Review the plan carefully
# Resources to be created:
# - VPC with 6 subnets
# - ALB, ECS, RDS, Redis, S3, CloudFront
# - IAM roles, KMS keys, CloudWatch resources
```

## Step 4: Deploy (10-30 min)

```bash
# Apply the plan
terraform apply tfplan

# Watch deployment progress in terminal
# Check AWS CloudFormation console for details
```

**Expected output:**
```
Apply complete! Resources: 50 added, 0 changed, 0 destroyed.

Outputs:
alb_dns_name = "kheteebaadi-alb-prod-123456789.ap-south-1.elb.amazonaws.com"
rds_endpoint = "kheteebaadi-db-prod.c1234567890.ap-south-1.rds.amazonaws.com:5432"
redis_endpoint = "kheteebaadi-redis-prod.ab1234cd.cache.amazonaws.com"
...
```

## Step 5: Create Secrets (2 min)

```bash
# Get values from Terraform
RDS_ENDPOINT=$(terraform output -raw rds_address)
RDS_PASSWORD=$(grep "db_password" terraform.tfvars | cut -d'"' -f2)
REDIS_ENDPOINT=$(terraform output -raw redis_endpoint)
REDIS_AUTH=$(terraform output -raw redis_auth_token)

# Create RDS URL secret
aws secretsmanager create-secret \
  --name kheteebaadi/db-url \
  --secret-string "postgresql://kheteebaadi_admin:${RDS_PASSWORD}@${RDS_ENDPOINT}:5432/kheteebaadi" \
  --region ap-south-1

# Create Redis URL secret
aws secretsmanager create-secret \
  --name kheteebaadi/redis-url \
  --secret-string "rediss://:${REDIS_AUTH}@${REDIS_ENDPOINT}:6379/0" \
  --region ap-south-1

# Create JWT secret
aws secretsmanager create-secret \
  --name kheteebaadi/jwt-secret \
  --secret-string "$(openssl rand -hex 32)" \
  --region ap-south-1
```

## Step 6: Verify Deployment

```bash
# Check all outputs
terraform output

# Test RDS connection
psql -h $(terraform output -raw rds_address) \
  -U kheteebaadi_admin \
  -d kheteebaadi \
  -c "SELECT 1;"

# Test Redis connection
redis-cli -h $(terraform output -raw redis_endpoint) ping

# Test ALB
curl -I https://$(terraform output -raw alb_dns_name)
```

## Step 7: Deploy Application

```bash
# Get ECR repository
ECR_REPO=$(terraform output -raw ecr_api_repository_url)

# Login to ECR
aws ecr get-login-password --region ap-south-1 | \
  docker login --username AWS --password-stdin $(echo $ECR_REPO | cut -d'/' -f1)

# Build and push API image
docker build -t ${ECR_REPO}:latest -f Dockerfile .
docker push ${ECR_REPO}:latest

# ECS will automatically pull and run the new image
```

## Common Commands

### View Infrastructure Status
```bash
# List all resources
terraform state list

# View specific resource details
terraform state show aws_db_instance.postgres

# Check outputs
terraform output
```

### Update Infrastructure
```bash
# Make changes to .tf files

# Review changes
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan
```

### Check Logs
```bash
# API service logs
aws logs tail /ecs/kheteebaadi-api-prod --follow

# RDS logs
aws logs tail /aws/rds/instance/kheteebaadi-db-prod/postgresql --follow

# Redis logs
aws logs tail /aws/elasticache/kheteebaadi-redis-prod-slow-log-prod --follow
```

### Monitor Auto-Scaling
```bash
# Watch ECS service metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=kheteebaadi-api \
              Name=ClusterName,Value=kheteebaadi-cluster-prod \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average \
  --region ap-south-1
```

## Troubleshooting

### Issue: "terraform init" fails
```bash
# Verify backend bucket exists
aws s3 ls s3://kheteebaadi-terraform-state

# Verify DynamoDB table exists
aws dynamodb list-tables --region ap-south-1 | grep kheteebaadi-terraform-locks
```

### Issue: RDS creation takes too long
```bash
# This is normal - RDS takes 10-15 minutes to create
# Monitor progress in AWS CloudFormation console
aws cloudformation describe-stacks \
  --query 'Stacks[?StackName==`terraform-*`].{Name:StackName,Status:StackStatus}' \
  --region ap-south-1
```

### Issue: ECS task won't start
```bash
# Check task logs
aws logs tail /ecs/kheteebaadi-api-prod --follow

# Check ECS service events
aws ecs describe-services \
  --cluster kheteebaadi-cluster-prod \
  --services kheteebaadi-api \
  --region ap-south-1 \
  --query 'services[0].events[:5]'
```

### Issue: Can't connect to RDS
```bash
# Verify security group allows ECS
aws ec2 describe-security-groups \
  --group-ids sg-xxxxx \
  --region ap-south-1

# Verify RDS endpoint
terraform output rds_endpoint

# Check if database is up
aws rds describe-db-instances \
  --db-instance-identifier kheteebaadi-db-prod \
  --query 'DBInstances[0].{Endpoint:Endpoint,Status:DBInstanceStatus}' \
  --region ap-south-1
```

## Next Steps

1. **Deploy Application**: Push Docker images to ECR
2. **Create DNS Records**: Point domain to ALB
3. **Run Migrations**: Execute database migrations
4. **Monitor**: Set up CloudWatch dashboards and alarms
5. **Backup**: Verify automated backups are working

## Full Documentation

See [README.md](./README.md) for complete documentation including:
- Architecture overview
- Security best practices
- Cost optimization
- Auto-scaling configuration
- Maintenance procedures
- Troubleshooting guide

## Important Notes

- **State File**: Never commit `terraform.tfstate` or `terraform.tfvars` to git
- **Passwords**: Store `db_password` in AWS Secrets Manager, not in code
- **Cost**: Infrastructure costs ~$200-500/month (see README.md for breakdown)
- **Region**: Always deploy to ap-south-1 (Mumbai) for lowest latency in India
- **Backups**: RDS backups enabled automatically (7-day retention)

## Support

Questions? Check:
1. [README.md](./README.md) - Comprehensive documentation
2. [DEPLOYMENT_CHECKLIST.md](./DEPLOYMENT_CHECKLIST.md) - Step-by-step deployment
3. AWS Console - CloudFormation/ECS/RDS status
4. CloudWatch Logs - Application logs

---

**Ready to deploy?** Run `terraform init && terraform plan`!
