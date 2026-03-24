variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "kheteebaadi"
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "ap-south-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid CIDR block."
  }
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20

  validation {
    condition     = var.db_allocated_storage >= 20
    error_message = "DB allocated storage must be at least 20 GB."
  }
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "kheteebaadi"
}

variable "db_username" {
  description = "RDS master username"
  type        = string
  default     = "kheteebaadi_admin"
}

variable "db_password" {
  description = "RDS master password (store in Secrets Manager or tfvars)"
  type        = string
  sensitive   = true
}

variable "redis_node_type" {
  description = "ElastiCache Redis node type"
  type        = string
  default     = "cache.t4g.micro"
}

variable "ecs_api_cpu" {
  description = "ECS API task CPU units (256, 512, 1024, etc.)"
  type        = number
  default     = 256

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.ecs_api_cpu)
    error_message = "ECS CPU must be 256, 512, 1024, 2048, or 4096."
  }
}

variable "ecs_api_memory" {
  description = "ECS API task memory in MB"
  type        = number
  default     = 512

  validation {
    condition     = contains([512, 1024, 2048, 3072, 4096, 5120, 6144, 7168, 8192], var.ecs_api_memory)
    error_message = "ECS memory must be a valid Fargate size."
  }
}

variable "ecs_api_min_tasks" {
  description = "Minimum number of API tasks"
  type        = number
  default     = 2

  validation {
    condition     = var.ecs_api_min_tasks >= 1
    error_message = "Minimum tasks must be at least 1."
  }
}

variable "ecs_api_max_tasks" {
  description = "Maximum number of API tasks"
  type        = number
  default     = 10

  validation {
    condition     = var.ecs_api_max_tasks >= var.ecs_api_min_tasks
    error_message = "Maximum tasks must be >= minimum tasks."
  }
}

variable "ecs_cpu_target" {
  description = "Target CPU utilization for auto-scaling (%)"
  type        = number
  default     = 65

  validation {
    condition     = var.ecs_cpu_target > 0 && var.ecs_cpu_target <= 100
    error_message = "CPU target must be between 1 and 100."
  }
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "kheteebaadi.in"
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for HTTPS (must be pre-created)"
  type        = string
  default     = ""
}

variable "enable_container_insights" {
  description = "Enable ECS Container Insights"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch value."
  }
}

variable "enable_rds_multi_az" {
  description = "Enable RDS Multi-AZ deployment"
  type        = bool
  default     = false
}

variable "rds_backup_retention" {
  description = "RDS backup retention period in days"
  type        = number
  default     = 7

  validation {
    condition     = var.rds_backup_retention >= 1 && var.rds_backup_retention <= 35
    error_message = "RDS backup retention must be between 1 and 35 days."
  }
}

variable "rds_backup_window" {
  description = "RDS backup window (HH:MM-HH:MM UTC)"
  type        = string
  default     = "02:00-03:00"
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
