# Variables for AWS AI SEO Agent Infrastructure

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "seo-agent"
}

variable "pagespeed_api_key" {
  description = "Google PageSpeed Insights API Key"
  type        = string
  sensitive   = true
}

variable "bedrock_model_id" {
  description = "AWS Bedrock model ID"
  type        = string
  default     = "anthropic.claude-haiku-4.5-20250514-v1:0"
}

variable "lambda_runtime" {
  description = "Lambda runtime version"
  type        = string
  default     = "python3.11"
}

variable "api_rate_limit" {
  description = "API Gateway rate limit (requests per minute)"
  type        = number
  default     = 100
}

variable "temp_data_retention_days" {
  description = "S3 temp data retention in days"
  type        = number
  default     = 1
}

variable "reports_retention_days" {
  description = "S3 reports retention in days"
  type        = number
  default     = 90
}
