# ALB Outputs
output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.main.arn
}

output "alb_zone_id" {
  description = "Zone ID of the load balancer"
  value       = aws_lb.main.zone_id
}

# RDS Outputs
output "rds_endpoint" {
  description = "RDS database endpoint"
  value       = aws_db_instance.postgres.endpoint
  sensitive   = false
}

output "rds_address" {
  description = "RDS database address only (hostname)"
  value       = aws_db_instance.postgres.address
}

output "rds_port" {
  description = "RDS database port"
  value       = aws_db_instance.postgres.port
}

output "rds_database_name" {
  description = "RDS database name"
  value       = aws_db_instance.postgres.db_name
}

output "rds_resource_id" {
  description = "RDS database resource ID"
  value       = aws_db_instance.postgres.resource_id
}

# Redis Outputs
output "redis_endpoint" {
  description = "Redis cluster endpoint address"
  value       = aws_elasticache_cluster.main.cache_nodes[0].address
}

output "redis_port" {
  description = "Redis cluster port"
  value       = aws_elasticache_cluster.main.port
}

output "redis_engine_version" {
  description = "Redis engine version"
  value       = aws_elasticache_cluster.main.engine_version
}

output "redis_configuration_endpoint" {
  description = "Redis configuration endpoint"
  value       = aws_elasticache_cluster.main.configuration_endpoint_address
}

output "redis_auth_token" {
  description = "Redis auth token"
  value       = random_password.redis_auth_token.result
  sensitive   = true
}

# ECR Outputs
output "ecr_api_repository_url" {
  description = "ECR repository URL for API service"
  value       = aws_ecr_repository.api.repository_url
}

output "ecr_celery_worker_repository_url" {
  description = "ECR repository URL for Celery worker"
  value       = aws_ecr_repository.celery_worker.repository_url
}

output "ecr_registry_id" {
  description = "ECR registry ID"
  value       = aws_ecr_repository.api.registry_id
}

# ECS Outputs
output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.main.arn
}

output "ecs_api_service_name" {
  description = "ECS API service name"
  value       = aws_ecs_service.api.name
}

output "ecs_celery_worker_service_name" {
  description = "ECS Celery worker service name"
  value       = aws_ecs_service.celery_worker.name
}

output "ecs_celery_beat_service_name" {
  description = "ECS Celery Beat service name"
  value       = aws_ecs_service.celery_beat.name
}

# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

output "private_app_subnet_ids" {
  description = "IDs of private app subnets"
  value       = [aws_subnet.private_app_1.id, aws_subnet.private_app_2.id]
}

output "private_data_subnet_ids" {
  description = "IDs of private data subnets"
  value       = [aws_subnet.private_data_1.id, aws_subnet.private_data_2.id]
}

output "nat_gateway_ip" {
  description = "Elastic IP address of NAT Gateway"
  value       = aws_eip.nat.public_ip
}

# Security Group Outputs
output "alb_security_group_id" {
  description = "Security group ID for ALB"
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "Security group ID for ECS"
  value       = aws_security_group.ecs.id
}

output "rds_security_group_id" {
  description = "Security group ID for RDS"
  value       = aws_security_group.rds.id
}

output "redis_security_group_id" {
  description = "Security group ID for Redis"
  value       = aws_security_group.redis.id
}

# S3 Outputs
output "dashboard_bucket_name" {
  description = "S3 bucket name for dashboard"
  value       = aws_s3_bucket.dashboard.id
}

output "uploads_bucket_name" {
  description = "S3 bucket name for uploads"
  value       = aws_s3_bucket.uploads.id
}

output "uploads_bucket_arn" {
  description = "S3 bucket ARN for uploads"
  value       = aws_s3_bucket.uploads.arn
}

# CloudFront Outputs
output "cloudfront_dashboard_domain_name" {
  description = "CloudFront distribution domain name for dashboard"
  value       = aws_cloudfront_distribution.dashboard.domain_name
}

output "cloudfront_dashboard_distribution_id" {
  description = "CloudFront distribution ID for dashboard"
  value       = aws_cloudfront_distribution.dashboard.id
}

output "cloudfront_uploads_domain_name" {
  description = "CloudFront distribution domain name for uploads"
  value       = aws_cloudfront_distribution.uploads.domain_name
}

output "cloudfront_uploads_distribution_id" {
  description = "CloudFront distribution ID for uploads"
  value       = aws_cloudfront_distribution.uploads.id
}

# KMS Outputs
output "rds_kms_key_id" {
  description = "KMS key ID for RDS encryption"
  value       = aws_kms_key.rds.key_id
}

output "s3_kms_key_id" {
  description = "KMS key ID for S3 encryption"
  value       = aws_kms_key.s3.key_id
}

# CloudWatch Outputs
output "api_log_group_name" {
  description = "CloudWatch log group name for API service"
  value       = aws_cloudwatch_log_group.api.name
}

output "celery_worker_log_group_name" {
  description = "CloudWatch log group name for Celery worker"
  value       = aws_cloudwatch_log_group.celery_worker.name
}

output "celery_beat_log_group_name" {
  description = "CloudWatch log group name for Celery Beat"
  value       = aws_cloudwatch_log_group.celery_beat.name
}

# Summary Outputs
output "application_url" {
  description = "Application URL (via ALB)"
  value       = "https://${var.domain_name}"
}

output "dashboard_url" {
  description = "Dashboard URL (via CloudFront)"
  value       = "https://${aws_cloudfront_distribution.dashboard.domain_name}"
}

output "images_cdn_url" {
  description = "Images CDN URL (via CloudFront)"
  value       = "https://${aws_cloudfront_distribution.uploads.domain_name}"
}

output "deployment_summary" {
  description = "Deployment summary"
  value = {
    environment              = var.environment
    region                   = var.aws_region
    project_name             = var.project_name
    alb_endpoint             = aws_lb.main.dns_name
    api_service_name         = aws_ecs_service.api.name
    database_endpoint        = aws_db_instance.postgres.address
    redis_endpoint           = aws_elasticache_cluster.main.cache_nodes[0].address
    ecr_api_repo             = aws_ecr_repository.api.repository_url
    dashboard_bucket         = aws_s3_bucket.dashboard.id
    uploads_bucket           = aws_s3_bucket.uploads.id
  }
}
