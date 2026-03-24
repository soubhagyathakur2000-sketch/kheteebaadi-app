# Kheteebaadi Terraform - Complete Index

Complete production-grade Terraform infrastructure-as-code for deploying Kheteebaadi AgTech platform on AWS ap-south-1.

## Quick Navigation

| Goal | Start Here |
|------|-----------|
| Get started in 10 minutes | [QUICKSTART.md](./QUICKSTART.md) |
| Full step-by-step deployment | [DEPLOYMENT_CHECKLIST.md](./DEPLOYMENT_CHECKLIST.md) |
| Architecture & deep dive | [README.md](./README.md) |
| All available outputs | [outputs.tf](./outputs.tf) |

## Files Overview

### Documentation (Read These First)

| File | Purpose | Read Time |
|------|---------|-----------|
| **QUICKSTART.md** | Fast 10-minute setup guide | 5 min |
| **DEPLOYMENT_CHECKLIST.md** | Complete deployment checklist | 15 min |
| **README.md** | Full documentation & architecture | 30 min |
| **INDEX.md** | This file - navigation guide | 2 min |

### Terraform Files (10 modules)

#### Core Configuration

| File | Purpose | Resources | Lines |
|------|---------|-----------|-------|
| **main.tf** | Provider, backend, data sources | 3 | 25 |
| **variables.tf** | Input variables with validation | 18 | 175 |
| **outputs.tf** | All output values | 50+ | 250 |

#### Infrastructure

| File | Purpose | Resources | Lines |
|------|---------|-----------|-------|
| **vpc.tf** | VPC, subnets, NAT, route tables | 18 | 190 |
| **security_groups.tf** | Network security - 4 groups | 4 | 90 |
| **alb.tf** | Load balancer, TLS, routing | 10 | 150 |
| **ecs.tf** | ECS cluster, services, scaling | 20+ | 400 |
| **rds.tf** | PostgreSQL database, backups | 12 | 160 |
| **redis.tf** | ElastiCache Redis cluster | 15 | 180 |
| **s3_cdn.tf** | S3 buckets, CloudFront CDN | 20 | 280 |

### Configuration Templates

| File | Purpose |
|------|---------|
| **terraform.tfvars.example** | Example variables - copy to terraform.tfvars |

## Architecture

```
Internet
   ↓
ALB (HTTPS: 443, HTTP: 80→443)
   ↓
ECS Fargate Tasks (Private Subnets)
   ├── API Service (256 CPU, 512 MB) [Min 2, Max 10 tasks]
   ├── Celery Worker (Fargate Spot - 80% cheaper)
   └── Celery Beat (Scheduled tasks)
   ↓
Data Tier (Private Data Subnets)
   ├── RDS PostgreSQL 15 (db.t4g.micro)
   │   └── Encrypted, Auto-backups (7 days)
   └── ElastiCache Redis 7 (cache.t4g.micro)
       └── Encrypted, Auth token, CloudWatch logs
   ↓
S3 + CloudFront CDN
   ├── Dashboard (Static website)
   └── Uploads (Crop images)
```

## Resource Summary

### Total Resources: ~50-60

**Networking:**
- 1 VPC (10.0.0.0/16)
- 6 Subnets (2 public, 2 app, 2 data)
- 1 Internet Gateway
- 1 NAT Gateway (single for cost optimization)
- 2 Route Tables
- VPC Flow Logs
- 1 Network ACL

**Security:**
- 4 Security Groups (ALB, ECS, RDS, Redis)
- 2 KMS Keys (RDS, S3)
- 3 IAM Roles with policies
- 2 Origin Access Identities (CloudFront)

**Compute:**
- 1 ECS Cluster
- 2 ECR Repositories (API, Celery)
- 3 ECS Services (API, Worker, Beat)
- 3 Task Definitions
- 1 ALB with target group

**Database & Cache:**
- 1 RDS PostgreSQL instance
- 1 RDS subnet group
- 1 RDS parameter group
- 1 ElastiCache Redis cluster
- 1 ElastiCache subnet group
- 1 ElastiCache parameter group

**Storage & CDN:**
- 2 S3 Buckets (Dashboard, Uploads)
- 2 CloudFront distributions
- 2 CloudFront OAI (Origin Access Identities)

**Monitoring:**
- 3 CloudWatch log groups (API, Celery Worker, Celery Beat)
- 2 Additional log groups (Redis logs)
- 1 Log group for VPC Flow Logs
- 6+ CloudWatch Alarms (RDS, Redis, S3)

**Scaling & Auto-Management:**
- 1 App Auto Scaling target
- 2 Auto Scaling policies (CPU, Memory)
- 1 SNS topic (ElastiCache notifications)
- ECR lifecycle policies

## Key Features

### High Availability
- Multi-AZ capable for RDS
- Load balancing across multiple ECS tasks
- NAT Gateway for redundant egress

### Security
- All traffic encrypted (TLS 1.2+)
- Private subnets for databases and app servers
- Encryption at-rest: RDS, Redis, S3 (all with KMS)
- Encryption in-transit: HTTPS, Redis AUTH token
- Least-privilege IAM roles
- CloudFront Origin Access Identity for S3

### Cost Optimization
- Single NAT Gateway (~$32/month savings)
- Fargate Spot for Celery workers (80% cheaper)
- Graviton2 processors (30% cheaper)
- S3 tiered storage (Standard → IA → Glacier)
- Auto-scaling down to minimum tasks
- Estimated: $200-500/month

### Monitoring & Observability
- CloudWatch Container Insights (ECS)
- CloudWatch Logs for all services
- VPC Flow Logs for network debugging
- Performance Insights for RDS
- CloudWatch Alarms for critical metrics
- SNS notifications for events

### Disaster Recovery
- Automated RDS backups (7-day retention)
- S3 versioning enabled
- Redis snapshots (daily, 5-day retention)
- State locking with DynamoDB
- Terraform state in S3

## Deployment Options

### Option 1: Quick Start (10 min)
See [QUICKSTART.md](./QUICKSTART.md)
```bash
terraform init && terraform plan && terraform apply
```

### Option 2: Full Deployment (30-60 min)
See [DEPLOYMENT_CHECKLIST.md](./DEPLOYMENT_CHECKLIST.md)
Includes pre-checks, post-deployment config, verification

### Option 3: Manual Step-by-Step
Follow instructions in [README.md](./README.md)

## Prerequisites Checklist

- [ ] AWS Account in ap-south-1
- [ ] Terraform 1.0+ installed
- [ ] AWS CLI v2 configured
- [ ] S3 bucket: `kheteebaadi-terraform-state`
- [ ] DynamoDB table: `kheteebaadi-terraform-locks`
- [ ] ACM certificate (optional - can use self-signed)
- [ ] Strong database password generated

## Common Tasks

### View Everything
```bash
terraform state list          # All resources
terraform state show resource # View specific resource
terraform output              # All outputs
terraform output -json        # JSON format
```

### Check Status
```bash
# ECS service status
aws ecs describe-services --cluster kheteebaadi-cluster-prod --services kheteebaadi-api --region ap-south-1

# RDS status
aws rds describe-db-instances --db-instance-identifier kheteebaadi-db-prod --region ap-south-1

# Redis status
aws elasticache describe-cache-clusters --cache-cluster-id kheteebaadi-redis-prod --region ap-south-1
```

### View Logs
```bash
# API logs (real-time)
aws logs tail /ecs/kheteebaadi-api-prod --follow

# Last 100 lines
aws logs tail /ecs/kheteebaadi-api-prod --max-items 100
```

### Update Resources
```bash
# Edit .tf files
# Then:
terraform plan -out=tfplan
terraform show tfplan
terraform apply tfplan
```

### Destroy Everything
```bash
# WARNING: This deletes all resources!
terraform destroy

# Destroy specific resource only:
terraform destroy -target=aws_lb.main
```

## Maintenance

### Weekly
- [ ] Check CloudWatch dashboards
- [ ] Review alarms
- [ ] Monitor costs in AWS Billing

### Monthly
- [ ] Verify backups are working
- [ ] Check Terraform drift: `terraform plan`
- [ ] Review IAM permissions
- [ ] Rotate secrets if needed

### Quarterly
- [ ] Update Terraform providers
- [ ] Review security best practices
- [ ] Test disaster recovery
- [ ] Plan capacity improvements

## File Sizes

```
README.md (18 KB)              - Full documentation
main.tf (1 KB)                 - Provider config
variables.tf (4.5 KB)          - Variable definitions
vpc.tf (6 KB)                  - VPC & networking
security_groups.tf (3 KB)      - Security groups
ecs.tf (15 KB)                 - ECS & containers
alb.tf (5 KB)                  - Load balancer
rds.tf (4.5 KB)                - Database
redis.tf (5.5 KB)              - Cache
s3_cdn.tf (8.5 KB)             - Storage & CDN
outputs.tf (7 KB)              - Outputs
terraform.tfvars.example (1 KB) - Example vars
DEPLOYMENT_CHECKLIST.md (15 KB) - Deployment guide
QUICKSTART.md (6 KB)           - Quick start
INDEX.md (This file)           - Navigation

Total: ~108 KB, ~2,840 lines of code
```

## Next Steps

1. **Start Here**: Read [QUICKSTART.md](./QUICKSTART.md) (5 min)
2. **Prepare**: Copy `terraform.tfvars.example` → `terraform.tfvars` and fill values
3. **Initialize**: Run `terraform init`
4. **Plan**: Run `terraform plan -out=tfplan`
5. **Review**: Examine the plan carefully
6. **Deploy**: Run `terraform apply tfplan`
7. **Verify**: Test infrastructure and deploy application
8. **Monitor**: Set up CloudWatch dashboards

## Support & Debugging

**Check this first:**
1. [README.md](./README.md) - Comprehensive documentation
2. [DEPLOYMENT_CHECKLIST.md](./DEPLOYMENT_CHECKLIST.md) - Troubleshooting section
3. AWS Console - CloudFormation, ECS, RDS, ElastiCache status

**Common issues:**
- Terraform state issues → Check S3 bucket and DynamoDB table
- RDS connection fails → Verify security group and force_ssl parameter
- ECS task won't start → Check ECR repository and CloudWatch logs
- Database too slow → Monitor RDS CPU and connections in CloudWatch

## Cost Estimation

| Service | Size | Monthly Cost |
|---------|------|-------------|
| ALB | 1 | $16 |
| ECS (min 2 tasks) | 2 × 256 CPU, 512 MB | $50 |
| ECS (max 10 tasks) | 10 × 256 CPU, 512 MB | $250 |
| RDS | db.t4g.micro | $25 |
| ElastiCache | cache.t4g.micro | $18 |
| S3 | ~10 GB | $5-10 |
| NAT Gateway | 1 | $32 |
| CloudFront | Varies | $10-50 |
| **Total (min)** | | **$156-176** |
| **Total (max)** | | **$401-456** |

See [README.md](./README.md) for detailed cost breakdown.

## Architecture Diagram

See [README.md](./README.md#architecture-overview) for full ASCII diagram.

## License

Part of Kheteebaadi AgTech platform. All rights reserved.

---

**Ready?** Start with [QUICKSTART.md](./QUICKSTART.md) or [DEPLOYMENT_CHECKLIST.md](./DEPLOYMENT_CHECKLIST.md)!

Last updated: 2026-03-23
