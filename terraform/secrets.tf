# AWS Secrets Manager for API Keys

resource "aws_secretsmanager_secret" "pagespeed_api_key" {
  name        = "${var.project_name}-${var.environment}-pagespeed-api-key"
  description = "Google PageSpeed Insights API Key"
  
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "pagespeed_api_key_value" {
  secret_id     = aws_secretsmanager_secret.pagespeed_api_key.id
  secret_string = var.pagespeed_api_key
}
