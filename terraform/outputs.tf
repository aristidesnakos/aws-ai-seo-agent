# Outputs for AWS AI SEO Agent Infrastructure

output "api_gateway_url" {
  description = "API Gateway endpoint URL"
  value       = "${aws_api_gateway_stage.prod.invoke_url}/analyze"
}

output "api_key_id" {
  description = "API Gateway API Key ID"
  value       = aws_api_gateway_api_key.default.id
}

output "api_key_value" {
  description = "API Gateway API Key Value"
  value       = aws_api_gateway_api_key.default.value
  sensitive   = true
}

output "temp_data_bucket" {
  description = "S3 bucket for temporary data"
  value       = aws_s3_bucket.temp_data.id
}

output "reports_bucket" {
  description = "S3 bucket for analysis reports"
  value       = aws_s3_bucket.reports.id
}

output "input_handler_function_name" {
  description = "Input Handler Lambda function name"
  value       = aws_lambda_function.input_handler.function_name
}

output "pagespeed_collector_function_name" {
  description = "PageSpeed Collector Lambda function name"
  value       = aws_lambda_function.pagespeed_collector.function_name
}

output "content_crawler_function_name" {
  description = "Content Crawler Lambda function name"
  value       = aws_lambda_function.content_crawler.function_name
}

output "lambda_execution_role_arn" {
  description = "Lambda execution role ARN"
  value       = aws_iam_role.lambda_execution.arn
}
