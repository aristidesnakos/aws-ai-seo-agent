# CloudWatch Alarms and Monitoring

# Lambda Error Alarm - Input Handler
resource "aws_cloudwatch_metric_alarm" "input_handler_errors" {
  alarm_name          = "${var.project_name}-${var.environment}-input-handler-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Alert when Input Handler Lambda errors exceed threshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.input_handler.function_name
  }
}

# Lambda Duration Alarm - Input Handler
resource "aws_cloudwatch_metric_alarm" "input_handler_duration" {
  alarm_name          = "${var.project_name}-${var.environment}-input-handler-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Average"
  threshold           = 100000
  alarm_description   = "Alert when Input Handler Lambda duration exceeds 100 seconds"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.input_handler.function_name
  }
}

# API Gateway 4XX Errors
resource "aws_cloudwatch_metric_alarm" "api_4xx_errors" {
  alarm_name          = "${var.project_name}-${var.environment}-api-4xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "4XXError"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = 20
  alarm_description   = "Alert when API Gateway 4XX errors exceed threshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiName = aws_api_gateway_rest_api.seo_agent_api.name
    Stage   = aws_api_gateway_stage.prod.stage_name
  }
}

# API Gateway 5XX Errors
resource "aws_cloudwatch_metric_alarm" "api_5xx_errors" {
  alarm_name          = "${var.project_name}-${var.environment}-api-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Alert when API Gateway 5XX errors exceed threshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiName = aws_api_gateway_rest_api.seo_agent_api.name
    Stage   = aws_api_gateway_stage.prod.stage_name
  }
}
