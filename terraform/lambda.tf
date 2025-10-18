# Lambda Functions for AWS AI SEO Agent

# Create Lambda deployment package placeholder
# Note: Actual Lambda code should be packaged separately

# Input Handler Lambda
resource "aws_lambda_function" "input_handler" {
  function_name = "${var.project_name}-${var.environment}-input-handler"
  role          = aws_iam_role.lambda_execution.arn
  runtime       = var.lambda_runtime
  handler       = "handler.lambda_handler"
  timeout       = 120
  memory_size   = 512

  filename         = "lambda_placeholder.zip"
  source_code_hash = filebase64sha256("lambda_placeholder.zip")

  environment {
    variables = {
      BEDROCK_MODEL_ID        = var.bedrock_model_id
      BEDROCK_REGION          = var.aws_region
      S3_TEMP_BUCKET          = aws_s3_bucket.temp_data.id
      S3_REPORTS_BUCKET       = aws_s3_bucket.reports.id
      PAGESPEED_LAMBDA_ARN    = aws_lambda_function.pagespeed_collector.arn
      CRAWLER_LAMBDA_ARN      = aws_lambda_function.content_crawler.arn
      MAX_ITERATIONS          = "5"
      TIMEOUT_SECONDS         = "120"
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_cloudwatch_log_group.input_handler
  ]
}

# PageSpeed Collector Lambda
resource "aws_lambda_function" "pagespeed_collector" {
  function_name = "${var.project_name}-${var.environment}-pagespeed-collector"
  role          = aws_iam_role.lambda_execution.arn
  runtime       = var.lambda_runtime
  handler       = "handler.lambda_handler"
  timeout       = 45
  memory_size   = 512

  filename         = "lambda_placeholder.zip"
  source_code_hash = filebase64sha256("lambda_placeholder.zip")

  environment {
    variables = {
      PAGESPEED_API_SECRET_ARN = aws_secretsmanager_secret.pagespeed_api_key.arn
      PAGESPEED_API_URL        = "https://www.googleapis.com/pagespeedinsights/v5/runPagespeed"
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_cloudwatch_log_group.pagespeed_collector
  ]
}

# Content Crawler Lambda
resource "aws_lambda_function" "content_crawler" {
  function_name = "${var.project_name}-${var.environment}-content-crawler"
  role          = aws_iam_role.lambda_execution.arn
  runtime       = var.lambda_runtime
  handler       = "handler.lambda_handler"
  timeout       = 30
  memory_size   = 1024

  filename         = "lambda_placeholder.zip"
  source_code_hash = filebase64sha256("lambda_placeholder.zip")

  environment {
    variables = {
      USER_AGENT       = "Mozilla/5.0 (compatible; SEO-Agent/1.0)"
      REQUEST_TIMEOUT  = "30"
      MAX_CONTENT_SIZE = "10485760"
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_cloudwatch_log_group.content_crawler
  ]
}

# CloudWatch Log Groups for Lambda functions
resource "aws_cloudwatch_log_group" "input_handler" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-input-handler"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "pagespeed_collector" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-pagespeed-collector"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "content_crawler" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-content-crawler"
  retention_in_days = 7
}
