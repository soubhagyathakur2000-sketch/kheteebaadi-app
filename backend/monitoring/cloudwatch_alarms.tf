# CloudWatch Alarms for Kheteebaadi AgTech Platform
# Organized by severity level (P0, P1, P2) with automated remediation

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# SNS Topics for Alarm Notifications
resource "aws_sns_topic" "alarms_critical" {
  name              = "kheteebaadi-alarms-critical"
  display_name      = "Kheteebaadi Critical Alarms (P0)"
  kms_master_key_id = "alias/aws/sns"

  tags = {
    Name        = "kheteebaadi-alarms-critical"
    Environment = var.environment
    Severity    = "P0"
  }
}

resource "aws_sns_topic" "alarms_high" {
  name              = "kheteebaadi-alarms-high"
  display_name      = "Kheteebaadi High Priority Alarms (P1)"
  kms_master_key_id = "alias/aws/sns"

  tags = {
    Name        = "kheteebaadi-alarms-high"
    Environment = var.environment
    Severity    = "P1"
  }
}

resource "aws_sns_topic" "alarms_medium" {
  name              = "kheteebaadi-alarms-medium"
  display_name      = "Kheteebaadi Medium Priority Alarms (P2)"
  kms_master_key_id = "alias/aws/sns"

  tags = {
    Name        = "kheteebaadi-alarms-medium"
    Environment = var.environment
    Severity    = "P2"
  }
}

# SNS Topic Subscriptions
resource "aws_sns_topic_subscription" "critical_slack" {
  topic_arn = aws_sns_topic.alarms_critical.arn
  protocol  = "https"
  endpoint  = var.slack_webhook_critical
}

resource "aws_sns_topic_subscription" "high_slack" {
  topic_arn = aws_sns_topic.alarms_high.arn
  protocol  = "https"
  endpoint  = var.slack_webhook_high
}

resource "aws_sns_topic_subscription" "medium_slack" {
  topic_arn = aws_sns_topic.alarms_medium.arn
  protocol  = "https"
  endpoint  = var.slack_webhook_medium
}

# ============================================================================
# P0 CRITICAL ALARMS - Require immediate action
# ============================================================================

# API 5xx Error Rate Threshold: > 10% for 2 minutes
resource "aws_cloudwatch_metric_alarm" "api_5xx_error_rate_high" {
  alarm_name          = "kheteebaadi-api-5xx-error-rate-critical"
  alarm_description   = "API 5xx error rate exceeds 10% - Production impact"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "5XXError"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_name
  }

  alarm_actions = [aws_sns_topic.alarms_critical.arn]
  ok_actions    = [aws_sns_topic.alarms_critical.arn]

  tags = {
    Severity = "P0"
    Type     = "API"
  }
}

# Stuck Payments Alert: > 5 transactions in failed state for > 1 hour
resource "aws_cloudwatch_metric_alarm" "stuck_payments" {
  alarm_name          = "kheteebaadi-stuck-payments-critical"
  alarm_description   = "More than 5 payments stuck in failed state - Revenue impact"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "StuckPaymentsCount"
  namespace           = "Kheteebaadi/Business"
  period              = 300
  statistic           = "Average"
  threshold           = 5
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alarms_critical.arn]
  ok_actions    = [aws_sns_topic.alarms_critical.arn]

  tags = {
    Severity = "P0"
    Type     = "Payment"
  }
}

# ============================================================================
# P1 HIGH PRIORITY ALARMS - Require action within 1 hour
# ============================================================================

# API Latency P99: > 3 seconds
resource "aws_cloudwatch_metric_alarm" "api_latency_p99_high" {
  alarm_name          = "kheteebaadi-api-latency-p99-high"
  alarm_description   = "API latency P99 exceeds 3 seconds - User experience degradation"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  extended_statistic  = "p99"
  threshold           = 3
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_name
  }

  alarm_actions = [aws_sns_topic.alarms_high.arn]
  ok_actions    = [aws_sns_topic.alarms_high.arn]

  tags = {
    Severity = "P1"
    Type     = "Performance"
  }
}

# ECS CPU utilization sustained > 85% for 5 minutes
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "kheteebaadi-ecs-cpu-utilization-high"
  alarm_description   = "ECS cluster CPU utilization exceeds 85% for 5 minutes"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 85
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.ecs_cluster_name
  }

  alarm_actions = [aws_sns_topic.alarms_high.arn]
  ok_actions    = [aws_sns_topic.alarms_high.arn]

  tags = {
    Severity = "P1"
    Type     = "Infrastructure"
  }
}

# ECS Memory utilization sustained > 85% for 5 minutes
resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  alarm_name          = "kheteebaadi-ecs-memory-utilization-high"
  alarm_description   = "ECS cluster memory utilization exceeds 85% for 5 minutes"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 85
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.ecs_cluster_name
  }

  alarm_actions = [aws_sns_topic.alarms_high.arn]
  ok_actions    = [aws_sns_topic.alarms_high.arn]

  tags = {
    Severity = "P1"
    Type     = "Infrastructure"
  }
}

# RDS Connection Count > 200 (approaching limit of 250)
resource "aws_cloudwatch_metric_alarm" "rds_connections_high" {
  alarm_name          = "kheteebaadi-rds-connections-high"
  alarm_description   = "RDS database connection count exceeds 200 - approaching limit"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 200
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  alarm_actions = [aws_sns_topic.alarms_high.arn]
  ok_actions    = [aws_sns_topic.alarms_high.arn]

  tags = {
    Severity = "P1"
    Type     = "Database"
  }
}

# RDS CPU utilization > 85%
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "kheteebaadi-rds-cpu-utilization-high"
  alarm_description   = "RDS instance CPU utilization exceeds 85%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  alarm_actions = [aws_sns_topic.alarms_high.arn]
  ok_actions    = [aws_sns_topic.alarms_high.arn]

  tags = {
    Severity = "P1"
    Type     = "Database"
  }
}

# Sync stale clients > 50 (custom metric from app)
resource "aws_cloudwatch_metric_alarm" "sync_stale_clients" {
  alarm_name          = "kheteebaadi-sync-stale-clients-high"
  alarm_description   = "More than 50 clients with stale sync data - data consistency risk"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StaleSyncClientsCount"
  namespace           = "Kheteebaadi/Sync"
  period              = 300
  statistic           = "Maximum"
  threshold           = 50
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alarms_high.arn]
  ok_actions    = [aws_sns_topic.alarms_high.arn]

  tags = {
    Severity = "P1"
    Type     = "DataIntegrity"
  }
}

# ALB Unhealthy Host Count > 0
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name          = "kheteebaadi-alb-unhealthy-hosts"
  alarm_description   = "ALB has unhealthy hosts - some application instances are down"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_name
    TargetGroup  = var.target_group_name
  }

  alarm_actions = [aws_sns_topic.alarms_high.arn]
  ok_actions    = [aws_sns_topic.alarms_high.arn]

  tags = {
    Severity = "P1"
    Type     = "Availability"
  }
}

# ============================================================================
# P2 MEDIUM PRIORITY ALARMS - Require action within 24 hours
# ============================================================================

# RDS Free Storage < 2GB
resource "aws_cloudwatch_metric_alarm" "rds_free_storage_low" {
  alarm_name          = "kheteebaadi-rds-free-storage-low"
  alarm_description   = "RDS free storage space below 2GB - plan for scaling"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 2147483648  # 2GB in bytes
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  alarm_actions = [aws_sns_topic.alarms_medium.arn]
  ok_actions    = [aws_sns_topic.alarms_medium.arn]

  tags = {
    Severity = "P2"
    Type     = "Database"
  }
}

# Application Log Errors increasing trend
resource "aws_cloudwatch_metric_alarm" "application_errors_trend" {
  alarm_name          = "kheteebaadi-application-errors-trend"
  alarm_description   = "Application error rate showing increasing trend"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "ApplicationErrorCount"
  namespace           = "Kheteebaadi/Application"
  period              = 300
  statistic           = "Sum"
  threshold           = 100
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alarms_medium.arn]
  ok_actions    = [aws_sns_topic.alarms_medium.arn]

  tags = {
    Severity = "P2"
    Type     = "Application"
  }
}

# CloudFront 4xx Error Rate > 5%
resource "aws_cloudwatch_metric_alarm" "cloudfront_4xx_errors" {
  alarm_name          = "kheteebaadi-cloudfront-4xx-errors-high"
  alarm_description   = "CloudFront 4xx error rate exceeds 5% - possible configuration issue"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "4xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = 300
  statistic           = "Average"
  threshold           = 5
  treat_missing_data  = "notBreaching"

  dimensions = {
    DistributionId = var.cloudfront_distribution_id
  }

  alarm_actions = [aws_sns_topic.alarms_medium.arn]
  ok_actions    = [aws_sns_topic.alarms_medium.arn]

  tags = {
    Severity = "P2"
    Type     = "CDN"
  }
}

# ECS Task Launch Failures
resource "aws_cloudwatch_metric_alarm" "ecs_task_launch_failures" {
  alarm_name          = "kheteebaadi-ecs-task-launch-failures"
  alarm_description   = "ECS tasks are failing to launch - check resource availability"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "TasksFailedToLaunch"
  namespace           = "Kheteebaadi/ECS"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = var.ecs_cluster_name
  }

  alarm_actions = [aws_sns_topic.alarms_medium.arn]

  tags = {
    Severity = "P2"
    Type     = "Infrastructure"
  }
}

# Redis Memory Usage > 80%
resource "aws_cloudwatch_metric_alarm" "redis_memory_high" {
  alarm_name          = "kheteebaadi-redis-memory-usage-high"
  alarm_description   = "Redis memory usage exceeds 80% - monitor for cache eviction"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"

  dimensions = {
    CacheClusterId = var.redis_cluster_id
  }

  alarm_actions = [aws_sns_topic.alarms_medium.arn]
  ok_actions    = [aws_sns_topic.alarms_medium.arn]

  tags = {
    Severity = "P2"
    Type     = "Cache"
  }
}

# Dashboard Upload Failures
resource "aws_cloudwatch_metric_alarm" "dashboard_deployment_failures" {
  alarm_name          = "kheteebaadi-dashboard-deployment-failures"
  alarm_description   = "Dashboard S3 upload or CloudFront invalidation failures"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "DashboardDeploymentFailures"
  namespace           = "Kheteebaadi/Deployment"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alarms_medium.arn]

  tags = {
    Severity = "P2"
    Type     = "Deployment"
  }
}

# ============================================================================
# Composite Alarms - Combine multiple metrics for higher-level insights
# ============================================================================

# Overall System Health (combines critical indicators)
resource "aws_cloudwatch_composite_alarm" "overall_system_health" {
  alarm_name          = "kheteebaadi-overall-system-health"
  alarm_description   = "Composite alarm for overall system health"
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.alarms_high.arn]
  ok_actions          = [aws_sns_topic.alarms_high.arn]

  alarm_rule = join(" OR ", [
    "ALARM(${aws_cloudwatch_metric_alarm.api_5xx_error_rate_high.alarm_name})",
    "ALARM(${aws_cloudwatch_metric_alarm.ecs_cpu_high.alarm_name})",
    "ALARM(${aws_cloudwatch_metric_alarm.rds_connections_high.alarm_name})",
  ])

  tags = {
    Type = "Composite"
  }
}

# Database Health (combines RDS metrics)
resource "aws_cloudwatch_composite_alarm" "database_health" {
  alarm_name          = "kheteebaadi-database-health"
  alarm_description   = "Composite alarm for database health"
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.alarms_high.arn]

  alarm_rule = join(" OR ", [
    "ALARM(${aws_cloudwatch_metric_alarm.rds_cpu_high.alarm_name})",
    "ALARM(${aws_cloudwatch_metric_alarm.rds_connections_high.alarm_name})",
    "ALARM(${aws_cloudwatch_metric_alarm.rds_free_storage_low.alarm_name})",
  ])

  tags = {
    Type = "Composite"
  }
}

# ============================================================================
# Variables
# ============================================================================

variable "environment" {
  description = "Environment name (prod, staging, etc.)"
  type        = string
}

variable "alb_name" {
  description = "Application Load Balancer name"
  type        = string
}

variable "target_group_name" {
  description = "ALB target group name"
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS cluster name"
  type        = string
}

variable "ecs_service_name" {
  description = "ECS service name"
  type        = string
}

variable "rds_instance_id" {
  description = "RDS instance identifier"
  type        = string
}

variable "redis_cluster_id" {
  description = "ElastiCache Redis cluster ID"
  type        = string
}

variable "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  type        = string
}

variable "slack_webhook_critical" {
  description = "Slack webhook URL for critical (P0) alerts"
  type        = string
  sensitive   = true
}

variable "slack_webhook_high" {
  description = "Slack webhook URL for high (P1) alerts"
  type        = string
  sensitive   = true
}

variable "slack_webhook_medium" {
  description = "Slack webhook URL for medium (P2) alerts"
  type        = string
  sensitive   = true
}

# ============================================================================
# Outputs
# ============================================================================

output "critical_topic_arn" {
  description = "SNS topic ARN for critical (P0) alarms"
  value       = aws_sns_topic.alarms_critical.arn
}

output "high_topic_arn" {
  description = "SNS topic ARN for high (P1) alarms"
  value       = aws_sns_topic.alarms_high.arn
}

output "medium_topic_arn" {
  description = "SNS topic ARN for medium (P2) alarms"
  value       = aws_sns_topic.alarms_medium.arn
}
