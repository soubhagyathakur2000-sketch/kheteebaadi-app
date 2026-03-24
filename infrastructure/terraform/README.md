# Kheteebaadi AgTech Platform - Terraform Infrastructure

Production-grade Infrastructure-as-Code for Kheteebaadi AgTech platform on AWS ap-south-1 (Mumbai region).

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         Internet (0.0.0.0/0)                    │
└────────────────────────────────────┬────────────────────────────┘
                                     │
                    ┌────────────────┴────────────────┐
                    │    Application Load Balancer    │
                    │  (HTTPS: 443, HTTP: 80→443)    │
                    └────────────────┬────────────────┘
                                     │
        ┌────────────────────────────┴────────────────────────────┐
        │                         VPC (10.0.0.0/16)               │
        │                                                          │
        │  ┌──────────────────┐      ┌──────────────────┐        │
        │  │ Public Subnet 1a │      │ Public Subnet 1b │        │
        │  │  (10.0.1.0/24)   │      │  (10.0.2.0/24)   │        │
        │  │   NAT Gateway    │      │                  │        │
        │  └──────────────────┘      └──────────────────┘        │
        │           │                                             │
        │  ┌────────┴──────────────────────────────┐             │
        │  │         Private Route Table            │             │
        │  │      (Routes via NAT Gateway)          │             │
        │  └────────┬──────────────────────────────┘             │
        │           │                                             │
        │  ┌────────┴──────────────────────────────┐             │
        │  │    ECS Fargate Tasks (App Subnet)     │             │
        │  │   API Service (256 CPU, 512 MB)       │             │
        │  │   Celery Worker (Fargate SPOT)        │             │
        │  │   Celery Beat (Scheduled Tasks)       │             │
        │  │  (10.0.10.0/24, 10.0.20.0/24)         │             │
        │  └────────┬──────────────────────────────┘             │
        │           │                                             │
        │  ┌────────┴──────────────────────────────┐             │
        │  │  Data Tier (Data Subnets)             │             │
        │  │  ┌─────────────────────────────────┐  │             │
        │  │  │ RDS PostgreSQL 15 (db.t4g.micro)│  │             │
        │  │  │ - Encrypted, Multi-AZ capable   │  │             │
        │  │  │ - Automated backups (7 days)    │  │             │
        │  │  │ (10.0.100.0/24, 10.0.200.0/24) │  │             │
        │  │  └─────────────────────────────────┘  │             │
        │  │  ┌─────────────────────────────────┐  │             │
        │  │  │ ElastiCache Redis 7 (t4g.micro) │  │             │
        │  │  │ - Encrypted at-rest & in-transit│  │             │
        │  │  │ - Single node (cost optimized)  │  │             │
        │  │  │ - CloudWatch logs & alarms      │  │             │
        │  │  └─────────────────────────────────┘  │             │
        │  └────────────────────────────────────────┘             │
        │                                                          │
        │  ┌──────────────────────────────────────┐             │
        │  │  S3 + CloudFront CDN                 │             │
        │  │  - Dashboard (Static Website)        │             │
        │  │  - Uploads (Crop Images)             │             │
        │  │  - KMS Encryption                    │             │
        │  └──────────────────────────────────────┘             │
        │                                                          │
        └──────────────────────────────────────────────────────────┘
```

## Directory Structure

```
infrastructure/terraform/
├── main.tf                  # Provider config, backend, data sources
├── variables.tf             # Variable definitions with validations
├── vpc.tf                   # VPC, subnets, NAT Gateway, flow logs
├── security_groups.tf       # 4 security groups (ALB, ECS, RDS, Redis)
├── ecs.tf                   # ECS cluster, services, task definitions, auto-scaling
├── alb.tf                   # Application Load Balancer, target groups, listeners
├── rds.tf                   # RDS PostgreSQL, subnet group, parameter group
├── redis.tf                 # ElastiCache Redis, parameter group, alarms
├── s3_cdn.tf                # S3 buckets, CloudFront distributions, OAI
├── outputs.tf               # All outputs for integration
├── terraform.tfvars.example # Example variables file
└── README.md                # This file
```

## Prerequisites

### Required Tools
- Terraform >= 1.0
- AWS CLI v2
- AWS account with appropriate permissions

### AWS Resources (Pre-requisites)
1. **S3 Backend Bucket**: `kheteebaadi-terraform-state`
2. **DynamoDB Table**: `kheteebaadi-terraform-locks`
3. **ACM Certificate** (optional): Pre-created in ap-south-1
4. **VPC**: Will be created by Terraform

### Creating Backend Infrastructure

```bash
# Create S3 bucket for Terraform state
aws s3api create-bucket \
  --bucket kheteebaadi-terraform-state \
  --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket kheteebaadi-terraform-state \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket kheteebaadi-terraform-state \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name kheteebaadi-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-south-1
```

## Configuration

### Step 1: Set AWS Credentials

```bash
export AWS_REGION=ap-south-1
export AWS_PROFILE=your-profile  # or AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
```

### Step 2: Create terraform.tfvars

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

**Critical Variables to Set:**
- `db_password`: Use a strong, randomly generated password (consider AWS Secrets Manager)
- `acm_certificate_arn`: Pre-created ACM certificate ARN (leave empty for self-signed)
- `domain_name`: Your domain (e.g., kheteebaadi.in)

### Step 3: Initialize Terraform

```bash
terraform init
```

This initializes the working directory and downloads AWS provider.

## Deployment

### Plan the Infrastructure

```bash
terraform plan -out=tfplan
# Review the plan carefully
```

### Apply the Configuration

```bash
terraform apply tfplan
```

This will create:
- VPC with public and private subnets
- NAT Gateway for outbound internet access
- 4 Security Groups (ALB, ECS, RDS, Redis)
- Application Load Balancer with HTTPS
- ECS Fargate cluster with services for API, Celery Worker, and Celery Beat
- RDS PostgreSQL database with automated backups
- ElastiCache Redis with encryption and monitoring
- 2 S3 buckets (dashboard + uploads) with CloudFront CDN
- CloudWatch log groups and alarms
- KMS keys for encryption at-rest

### Important Outputs

After deployment, save these outputs:

```bash
terraform output -json > outputs.json

# Get specific outputs
terraform output alb_dns_name
terraform output rds_endpoint
terraform output redis_endpoint
terraform output ecr_api_repository_url
terraform output cloudfront_dashboard_domain_name
```

## Environment Variables & Secrets

### Using AWS Secrets Manager (Recommended for Production)

1. Create secrets in AWS Secrets Manager:

```bash
aws secretsmanager create-secret \
  --name kheteebaadi/db-url \
  --secret-string "postgresql://user:password@host:5432/kheteebaadi" \
  --region ap-south-1

aws secretsmanager create-secret \
  --name kheteebaadi/redis-url \
  --secret-string "rediss://:password@host:6379/0" \
  --region ap-south-1

aws secretsmanager create-secret \
  --name kheteebaadi/jwt-secret \
  --secret-string "your-jwt-secret-key" \
  --region ap-south-1
```

2. ECS task definitions reference these secrets automatically

### Using Terraform Secrets (Development Only)

```bash
terraform apply -var="db_password=mypassword"
```

## Auto-Scaling Configuration

### API Service Auto-Scaling

The API service auto-scales based on:
- **CPU Utilization**: Target 65% (scales out on high CPU)
- **Memory Utilization**: Target 80% (scales out on high memory)
- **Min Tasks**: 2
- **Max Tasks**: 10

Scaling parameters in `variables.tf`:
```hcl
ecs_api_min_tasks = 2
ecs_api_max_tasks = 10
ecs_cpu_target = 65
```

### Celery Worker (Cost Optimization)

- Uses **Fargate Spot** instances for 80% cost savings
- Single instance (no auto-scaling)
- If Spot instance terminates, ECS automatically restarts it

## Database Configuration

### PostgreSQL 15

- **Instance**: db.t4g.micro (Graviton2 processors - cost efficient)
- **Storage**: 20 GB gp3 (auto-scales up to 100 GB)
- **Encryption**: AES-256 with KMS
- **Backups**: 7-day retention, automated daily (02:00 UTC)
- **Parameters**:
  - `force_ssl=1` (enforces SSL connections)
  - `pg_stat_statements` and `pgaudit` extensions

### CloudWatch Alarms

Three alarms monitor database health:
1. **CPU Utilization** > 80%
2. **Free Storage** < 1 GB
3. **Database Connections** > 80

## Redis Configuration

### ElastiCache Redis 7

- **Node Type**: cache.t4g.micro (single node for cost optimization)
- **Encryption**: At-rest with KMS, in-transit with AUTH token
- **Memory Policy**: `allkeys-lru` (evicts least-recently-used keys when full)
- **Snapshots**: Daily at 02:00 UTC, retention 5 days
- **CloudWatch Logs**: Engine and slow-query logs

### CloudWatch Alarms

Three alarms monitor Redis health:
1. **CPU Utilization** > 75%
2. **Memory Usage** > 90%
3. **Evictions** > 0 (eviction rate)

## Storage & CDN

### S3 Buckets

1. **Dashboard Bucket** (`kheteebaadi-dashboard-*`)
   - Static website hosting files
   - CloudFront distribution with OAI
   - Error handling for SPA routing (404 → index.html)

2. **Uploads Bucket** (`kheteebaadi-uploads-*`)
   - Crop images and file uploads
   - Lifecycle policy: Delete after 90 days
   - Tiered storage: Standard → IA → Glacier
   - CORS enabled for API requests
   - CloudFront distribution for fast delivery

### CloudFront CDN

**Dashboard Distribution:**
- Static asset caching (1 year TTL)
- HTML caching (1 hour TTL)
- Compression enabled
- Custom error pages for SPA

**Uploads Distribution:**
- Image caching (1 day TTL)
- HTTPS only
- No query string forwarding

## Security Best Practices Implemented

1. **Network Isolation**
   - Private subnets for RDS and Redis (no direct internet access)
   - Private subnets for ECS tasks (egress via NAT Gateway only)
   - Security groups restrict traffic to minimum needed

2. **Data Encryption**
   - RDS: AES-256 with KMS
   - Redis: At-rest with KMS, in-transit with AUTH
   - S3: AES-256 with KMS
   - ELB: HTTPS only (HTTP redirects to HTTPS)

3. **Access Control**
   - IAM roles with least-privilege policies
   - ECS task execution role for pulling images and secrets
   - ECS task role for application-level permissions
   - CloudFront Origin Access Identity (OAI) for S3 access

4. **Monitoring & Logging**
   - CloudWatch Logs for all services
   - CloudWatch Alarms for critical metrics
   - VPC Flow Logs for network debugging
   - Container Insights for ECS monitoring

5. **Backup & Disaster Recovery**
   - RDS automated backups with 7-day retention
   - S3 versioning enabled
   - Redis snapshots daily

## Cost Optimization

1. **NAT Gateway**: Single NAT Gateway (instead of per-AZ) saves ~$32/month
2. **RDS**: db.t4g.micro with Graviton2 processors (30% cheaper)
3. **ElastiCache**: cache.t4g.micro with Graviton2 processors
4. **Celery Worker**: Fargate Spot instances (80% cost savings)
5. **S3 Tiering**: Automatic transition to cheaper storage classes
6. **ECS**: Rolling deployment with circuit breaker (no redundant tasks)

**Estimated Monthly Cost** (production, ap-south-1):
- ALB: ~$16
- ECS Fargate (2-10 tasks): ~$80-400
- RDS db.t4g.micro: ~$25
- ElastiCache cache.t4g.micro: ~$18
- S3: ~$5-20 (varies by usage)
- NAT Gateway: ~$32
- **Total**: ~$176-511/month (before data transfer)

## Maintenance & Updates

### Terraform State Management

```bash
# Backup state before major changes
aws s3 cp s3://kheteebaadi-terraform-state/prod/terraform.tfstate ./backup/

# List all resources
terraform state list

# View resource details
terraform state show aws_db_instance.postgres
```

### Updating Infrastructure

```bash
# Always plan first
terraform plan -out=tfplan

# Review changes carefully
terraform show tfplan

# Apply only after review
terraform apply tfplan
```

### Destroying Infrastructure

```bash
# WARNING: This deletes all resources
terraform destroy

# Selective destruction (example: ALB only)
terraform destroy -target=aws_lb.main
```

## Troubleshooting

### Common Issues

1. **RDS Creation Timeout**
   - RDS creation can take 10-15 minutes
   - Check AWS CloudFormation events for details
   - Wait for completion before destroying

2. **ECS Task Fails to Start**
   - Check ECS task definition security group
   - Verify ECR repository exists with image
   - Check CloudWatch logs: `/ecs/kheteebaadi-api-prod`

3. **Database Connection Issues**
   - Verify security group allows port 5432 from ECS
   - Check `force_ssl=1` parameter (use `sslmode=require` in connection string)
   - Verify RDS endpoint format: `hostname:5432`

4. **Redis AUTH Issues**
   - Check Redis auth token in Secrets Manager
   - Verify security group allows port 6379 from ECS
   - Use correct Redis URL format: `rediss://:password@host:6379`

### Debug Commands

```bash
# Check Terraform state
terraform state list
terraform state show aws_db_instance.postgres

# View CloudWatch logs
aws logs tail /ecs/kheteebaadi-api-prod --follow

# Check ECS service status
aws ecs describe-services \
  --cluster kheteebaadi-cluster-prod \
  --services kheteebaadi-api \
  --region ap-south-1

# Get RDS endpoint
aws rds describe-db-instances \
  --db-instance-identifier kheteebaadi-db-prod \
  --query 'DBInstances[0].Endpoint' \
  --region ap-south-1
```

## File Descriptions

| File | Purpose |
|------|---------|
| `main.tf` | Terraform configuration, AWS provider, S3 backend setup |
| `variables.tf` | Input variables with defaults, descriptions, validations |
| `vpc.tf` | VPC, subnets, NAT Gateway, routing, Flow Logs |
| `security_groups.tf` | Network security - 4 security groups |
| `ecs.tf` | ECS cluster, services, task definitions, auto-scaling |
| `alb.tf` | Load balancer, target groups, HTTPS listeners |
| `rds.tf` | PostgreSQL database, encryption, backups, alarms |
| `redis.tf` | ElastiCache Redis cluster, encryption, monitoring |
| `s3_cdn.tf` | S3 buckets, CloudFront distributions, CDN setup |
| `outputs.tf` | All outputs for external integration |
| `terraform.tfvars.example` | Example variables file (copy to terraform.tfvars) |

## Next Steps

1. **Create terraform.tfvars** with your values
2. **Run `terraform plan`** and review
3. **Run `terraform apply`** to create infrastructure
4. **Update DNS** to point to ALB and CloudFront
5. **Deploy application** to ECR and ECS
6. **Configure CI/CD** for automated deployments

## Support & Documentation

- Terraform AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- AWS Architecture Best Practices: https://aws.amazon.com/architecture/well-architected/
- Kheteebaadi Project Docs: See parent README.md

## License

This Terraform code is part of the Kheteebaadi AgTech platform. All rights reserved.
