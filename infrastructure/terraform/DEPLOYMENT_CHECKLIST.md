# Kheteebaadi Terraform Deployment Checklist

## Pre-Deployment (One-time Setup)

- [ ] **AWS Account Setup**
  - [ ] AWS Account created in ap-south-1 region
  - [ ] Appropriate IAM permissions configured
  - [ ] AWS CLI v2 installed and configured with credentials

- [ ] **Backend Infrastructure**
  - [ ] S3 bucket `kheteebaadi-terraform-state` created with versioning & encryption
  - [ ] DynamoDB table `kheteebaadi-terraform-locks` created for state locking
  - [ ] Verify S3 bucket is accessible and encrypted

- [ ] **SSL/TLS Certificate**
  - [ ] ACM certificate created in ap-south-1 (or use self-signed for dev)
  - [ ] Certificate ARN noted for terraform.tfvars

- [ ] **Tools Installed**
  - [ ] Terraform >= 1.0 (`terraform version`)
  - [ ] AWS CLI v2 (`aws --version`)
  - [ ] jq for JSON parsing (optional)

## Configuration

- [ ] **Create terraform.tfvars**
  ```bash
  cp terraform.tfvars.example terraform.tfvars
  ```

- [ ] **Set Critical Variables in terraform.tfvars**
  - [ ] `environment`: Set to "prod", "staging", or "dev"
  - [ ] `project_name`: "kheteebaadi"
  - [ ] `aws_region`: "ap-south-1"
  - [ ] `db_password`: Strong random password (32+ chars)
  - [ ] `domain_name`: Your domain (e.g., "kheteebaadi.in")
  - [ ] `acm_certificate_arn`: Your ACM certificate ARN (leave empty for self-signed)
  - [ ] Optional: `enable_rds_multi_az`, `ecs_api_min_tasks`, `ecs_api_max_tasks`

- [ ] **Secure terraform.tfvars**
  ```bash
  chmod 600 terraform.tfvars
  # Add to .gitignore
  echo "terraform.tfvars" >> .gitignore
  echo "terraform.tfvars.prod" >> .gitignore
  echo "terraform.tfvars.staging" >> .gitignore
  ```

- [ ] **Set AWS Credentials**
  ```bash
  export AWS_REGION=ap-south-1
  export AWS_PROFILE=your-profile  # or AWS_ACCESS_KEY_ID + AWS_SECRET_ACCESS_KEY
  ```

## Initialization

- [ ] **Initialize Terraform**
  ```bash
  terraform init
  ```
  - [ ] Verify "Terraform has been successfully configured!"
  - [ ] Check `.terraform/versions.lock.hcl` created

- [ ] **Validate Configuration**
  ```bash
  terraform fmt -check
  terraform validate
  ```
  - [ ] All files properly formatted
  - [ ] No validation errors

## Pre-Deployment Review

- [ ] **Run Terraform Plan**
  ```bash
  terraform plan -out=tfplan
  ```
  - [ ] Review planned resources
  - [ ] Check for unexpected changes
  - [ ] Verify resource counts:
    - [ ] 1 VPC with 6 subnets
    - [ ] 4 Security Groups
    - [ ] 1 ALB with target group
    - [ ] 1 ECS Cluster with 3 services
    - [ ] 1 RDS PostgreSQL instance
    - [ ] 1 ElastiCache Redis cluster
    - [ ] 2 S3 buckets with CloudFront distributions
    - [ ] Multiple KMS keys, IAM roles, CloudWatch resources

- [ ] **Cost Estimation**
  ```bash
  terraform plan -out=tfplan | grep -i "Resources planned:"
  ```
  - [ ] Estimate matches expected costs (~$200-500/month)

## Deployment

- [ ] **Create Infrastructure**
  ```bash
  terraform apply tfplan
  ```
  - [ ] Wait for completion (15-30 minutes)
  - [ ] Verify all resources created successfully
  - [ ] Check CloudFormation events in AWS Console

- [ ] **Capture Outputs**
  ```bash
  terraform output -json > outputs.json
  terraform output alb_dns_name
  terraform output rds_endpoint
  terraform output redis_endpoint
  terraform output ecr_api_repository_url
  terraform output cloudfront_dashboard_domain_name
  ```
  - [ ] Save outputs.json for reference
  - [ ] Note important endpoints

## Post-Deployment Configuration

- [ ] **Create Database Secrets**
  ```bash
  # Get RDS endpoint
  RDS_ENDPOINT=$(terraform output -raw rds_address)
  RDS_PASSWORD=$(terraform output -raw db_password 2>/dev/null || echo "check tfvars")

  # Create database connection string secret
  aws secretsmanager create-secret \
    --name kheteebaadi/db-url \
    --secret-string "postgresql://kheteebaadi_admin:${RDS_PASSWORD}@${RDS_ENDPOINT}:5432/kheteebaadi" \
    --region ap-south-1
  ```
  - [ ] Verify secret created in AWS Secrets Manager

- [ ] **Create Redis AUTH Secret**
  ```bash
  # Get Redis endpoint and auth token
  REDIS_ENDPOINT=$(terraform output -raw redis_endpoint)
  REDIS_AUTH=$(terraform output -raw redis_auth_token)

  # Create Redis URL secret
  aws secretsmanager create-secret \
    --name kheteebaadi/redis-url \
    --secret-string "rediss://:${REDIS_AUTH}@${REDIS_ENDPOINT}:6379/0" \
    --region ap-south-1
  ```
  - [ ] Verify secret created

- [ ] **Create JWT Secret**
  ```bash
  # Generate a strong JWT secret
  JWT_SECRET=$(openssl rand -hex 32)

  aws secretsmanager create-secret \
    --name kheteebaadi/jwt-secret \
    --secret-string "${JWT_SECRET}" \
    --region ap-south-1
  ```
  - [ ] Verify secret created
  - [ ] Save JWT_SECRET securely

- [ ] **Upload Dashboard Files to S3**
  ```bash
  DASHBOARD_BUCKET=$(terraform output -raw dashboard_bucket_name)

  # Build dashboard (from ovol-dashboard/)
  npm run build

  # Upload to S3
  aws s3 sync dist/ s3://${DASHBOARD_BUCKET}/ --delete
  ```
  - [ ] Verify files uploaded
  - [ ] Check CloudFront cache invalidation if needed

## Application Deployment

- [ ] **Build & Push Docker Images**
  ```bash
  # Get ECR repository URL
  ECR_REPO=$(terraform output -raw ecr_api_repository_url)
  AWS_ACCOUNT=$(echo $ECR_REPO | cut -d'.' -f1)

  # Login to ECR
  aws ecr get-login-password --region ap-south-1 | \
    docker login --username AWS --password-stdin ${AWS_ACCOUNT}.dkr.ecr.ap-south-1.amazonaws.com

  # Build and push API image
  docker build -t ${ECR_REPO}:latest ./backend
  docker push ${ECR_REPO}:latest
  ```
  - [ ] API image pushed to ECR
  - [ ] Celery worker image pushed to ECR

- [ ] **Update ECS Services**
  ```bash
  # Force new deployment of API service
  aws ecs update-service \
    --cluster kheteebaadi-cluster-prod \
    --service kheteebaadi-api \
    --force-new-deployment \
    --region ap-south-1
  ```
  - [ ] Monitor deployment in ECS console
  - [ ] Check CloudWatch logs for errors

- [ ] **Run Database Migrations**
  ```bash
  # Option 1: Use ECS one-off task
  aws ecs run-task \
    --cluster kheteebaadi-cluster-prod \
    --task-definition kheteebaadi-api:latest \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx]}" \
    --overrides 'containerOverrides=[{name=api,command=[python,manage.py,migrate]}]' \
    --region ap-south-1
  ```
  - [ ] Verify migrations completed successfully

## Health Checks

- [ ] **Verify Infrastructure**
  ```bash
  # Check RDS connectivity
  psql -h $(terraform output -raw rds_address) -U kheteebaadi_admin -d kheteebaadi -c "SELECT 1;"

  # Check Redis connectivity
  redis-cli -h $(terraform output -raw redis_endpoint) -p 6379 ping

  # Check ALB health
  aws elbv2 describe-target-health \
    --target-group-arn $(terraform output -raw alb_target_group_arn) \
    --region ap-south-1
  ```
  - [ ] RDS accessible and responding
  - [ ] Redis accessible and responding
  - [ ] ALB targets healthy

- [ ] **Check CloudWatch Logs**
  ```bash
  aws logs tail /ecs/kheteebaadi-api-prod --follow
  aws logs tail /ecs/kheteebaadi-celery-worker-prod --follow
  ```
  - [ ] No critical errors in logs
  - [ ] Services starting successfully

- [ ] **Test Application**
  - [ ] Access ALB endpoint: `https://$(terraform output -raw alb_dns_name)`
  - [ ] Verify API health check endpoint: `/health`
  - [ ] Access dashboard: `https://$(terraform output -raw cloudfront_dashboard_domain_name)`
  - [ ] Test image upload to S3
  - [ ] Verify files served via CloudFront

- [ ] **DNS Configuration** (for production)
  ```bash
  # Update DNS records
  # ALB Record:
  # kheteebaadi.in ALIAS/CNAME $(terraform output -raw alb_dns_name)

  # CloudFront Records (optional):
  # dashboard.kheteebaadi.in ALIAS/CNAME $(terraform output -raw cloudfront_dashboard_domain_name)
  # images.kheteebaadi.in ALIAS/CNAME $(terraform output -raw cloudfront_uploads_domain_name)
  ```
  - [ ] DNS records created in Route53 or domain registrar
  - [ ] DNS propagation verified

## Monitoring Setup

- [ ] **CloudWatch Dashboards**
  - [ ] Create custom dashboard for monitoring
  - [ ] Add widgets for:
    - [ ] ECS CPU/Memory utilization
    - [ ] RDS CPU/Storage/Connections
    - [ ] Redis CPU/Memory/Evictions
    - [ ] ALB request count and latency

- [ ] **Alarms**
  - [ ] Verify RDS alarms created and SNS topic configured
  - [ ] Verify Redis alarms created
  - [ ] Add SNS subscriptions for notifications
  - [ ] Test alarm notifications

- [ ] **Auto-Scaling**
  - [ ] Verify ECS service auto-scaling policies active
  - [ ] Monitor scaling metrics in CloudWatch

## Backup & Recovery

- [ ] **Backup Configuration**
  - [ ] RDS automated backups enabled (7-day retention)
  - [ ] S3 versioning enabled on both buckets
  - [ ] Redis snapshots configured (daily at 02:00 UTC)

- [ ] **Test Recovery Process**
  - [ ] Create test RDS snapshot
  - [ ] Verify snapshot appears in RDS console
  - [ ] Document recovery procedure

- [ ] **Terraform State Backup**
  ```bash
  # Backup before major changes
  aws s3 cp s3://kheteebaadi-terraform-state/prod/terraform.tfstate ./backups/terraform.tfstate.$(date +%Y%m%d)
  ```

## Security Verification

- [ ] **Network Security**
  - [ ] Verify RDS in private subnet (no public IP)
  - [ ] Verify Redis in private subnet
  - [ ] Verify ECS tasks only accessible via ALB
  - [ ] Verify VPC Flow Logs enabled

- [ ] **Encryption**
  - [ ] RDS encrypted with KMS
  - [ ] S3 buckets encrypted with KMS
  - [ ] Redis encrypted at-rest and in-transit
  - [ ] All KMS keys have rotation enabled

- [ ] **Access Control**
  - [ ] IAM roles follow least-privilege principle
  - [ ] ECS task execution role has minimal permissions
  - [ ] S3 buckets have public access blocked
  - [ ] Database passwords stored in Secrets Manager

- [ ] **SSL/TLS**
  - [ ] ALB listening on HTTPS (443)
  - [ ] HTTP (80) redirects to HTTPS
  - [ ] CloudFront distributions use HTTPS
  - [ ] ACM certificate valid and not expiring soon

## Documentation

- [ ] **Update Project Documentation**
  - [ ] Record all endpoint URLs
  - [ ] Document scaling policies
  - [ ] Document backup procedures
  - [ ] Document disaster recovery plan

- [ ] **Team Knowledge Sharing**
  - [ ] Walk through Terraform code with team
  - [ ] Document manual processes
  - [ ] Create runbooks for common tasks
  - [ ] Share AWS console access with team members

## Ongoing Maintenance

- [ ] **Weekly Checks**
  - [ ] Monitor CloudWatch dashboards
  - [ ] Check for Terraform drift: `terraform plan`
  - [ ] Review CloudWatch alarms
  - [ ] Check AWS service health

- [ ] **Monthly Maintenance**
  - [ ] Review and rotate database password
  - [ ] Review IAM permissions
  - [ ] Check RDS backup integrity
  - [ ] Review cost analysis in AWS Billing

- [ ] **Quarterly Tasks**
  - [ ] Update Terraform provider versions
  - [ ] Review security best practices
  - [ ] Test disaster recovery procedures
  - [ ] Plan capacity improvements

## Troubleshooting Reference

| Issue | Solution |
|-------|----------|
| Terraform init fails | Check AWS credentials and backend bucket exists |
| RDS creation timeout | Wait 15+ minutes, check CloudFormation events |
| ECS task won't start | Check security groups, ECR repo, CloudWatch logs |
| Database connection fails | Verify security group rules and force_ssl parameter |
| Redis connection fails | Check auth token format and security group |
| CloudFront returns 403 | Verify Origin Access Identity and S3 bucket policy |

## Rollback Procedure

If deployment fails:

```bash
# Option 1: Destroy specific resource
terraform destroy -target=resource.name

# Option 2: Rollback to previous state (backup required)
aws s3 cp ./backups/terraform.tfstate.YYYYMMDD s3://kheteebaadi-terraform-state/prod/terraform.tfstate

# Option 3: Refresh state and redeploy
terraform refresh
terraform apply
```

---

**Deployment Date**: _______________
**Deployed By**: _______________
**Environment**: _______________
**Notes**: _________________________________________________________________

