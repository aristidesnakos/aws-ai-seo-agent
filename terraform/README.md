# Terraform Infrastructure for AWS AI SEO Agent

This directory contains Terraform configuration for automatically provisioning the AWS AI SEO Agent infrastructure.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- AWS CLI configured with appropriate credentials
- Google PageSpeed Insights API key

## Infrastructure Components

The Terraform configuration provisions the following AWS resources:

### Compute & Orchestration
- **3 Lambda Functions**:
  - Input Handler (orchestrator)
  - PageSpeed Collector
  - Content Crawler
- **IAM Role** with policies for Lambda execution

### Storage
- **2 S3 Buckets**:
  - Temporary data (1-day lifecycle)
  - Analysis reports (90-day lifecycle)

### API & Networking
- **API Gateway** (REST API)
  - `/analyze` endpoint
  - API key authentication
  - Rate limiting (100 req/min)

### Security
- **Secrets Manager** for PageSpeed API key
- **IAM Policies** with least privilege access

### Monitoring
- **CloudWatch Log Groups** for all Lambda functions
- **CloudWatch Alarms**:
  - Lambda errors and duration
  - API Gateway 4XX/5XX errors

## Quick Start

### 1. Configure Variables

Copy the example variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
aws_region        = "us-east-1"
environment       = "dev"
pagespeed_api_key = "YOUR_ACTUAL_API_KEY"
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Review the Plan

```bash
terraform plan
```

### 4. Apply Configuration

```bash
terraform apply
```

Type `yes` when prompted to confirm.

### 5. Get Outputs

After successful deployment:

```bash
terraform output
```

This will display:
- API Gateway URL
- API Key for authentication
- S3 bucket names
- Lambda function names

## Lambda Deployment

**Important**: The Terraform configuration creates Lambda functions with a placeholder zip file. You need to deploy actual Lambda code separately.

### Option 1: Manual Deployment

Package and deploy Lambda code for each function:

```bash
# Package Lambda function
cd ../src/lambda/input_handler
zip -r input_handler.zip .

# Update Lambda function
aws lambda update-function-code \
  --function-name seo-agent-dev-input-handler \
  --zip-file fileb://input_handler.zip
```

### Option 2: CI/CD Pipeline

Set up automated deployment using GitHub Actions or AWS CodePipeline (see `IMPLEMENTATION.md` for details).

## Configuration Reference

### Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `aws_region` | AWS region | us-east-1 | No |
| `environment` | Environment name | dev | No |
| `project_name` | Project identifier | seo-agent | No |
| `pagespeed_api_key` | PageSpeed API key | - | Yes |
| `bedrock_model_id` | Bedrock model | anthropic.claude-haiku-4.5-* | No |
| `api_rate_limit` | API rate limit (req/min) | 100 | No |
| `temp_data_retention_days` | Temp data retention | 1 | No |
| `reports_retention_days` | Reports retention | 90 | No |

### Outputs

| Output | Description |
|--------|-------------|
| `api_gateway_url` | API endpoint URL |
| `api_key_value` | API key (sensitive) |
| `temp_data_bucket` | Temp S3 bucket |
| `reports_bucket` | Reports S3 bucket |
| `input_handler_function_name` | Input handler function |
| `pagespeed_collector_function_name` | PageSpeed collector function |
| `content_crawler_function_name` | Content crawler function |

## Cost Estimation

Using default configuration (dev environment):

**Monthly Costs** (assuming 1,000 analyses):
- Lambda: ~$5
- Bedrock (Claude Haiku 4.5): ~$6
- S3: ~$0.20
- API Gateway: ~$0.10
- **Total**: ~$11.30/month

**Per Analysis**: ~$0.011

## Environment Management

Deploy multiple environments by using different tfvars files:

```bash
# Development
terraform apply -var-file="dev.tfvars"

# Staging
terraform apply -var-file="staging.tfvars"

# Production
terraform apply -var-file="prod.tfvars"
```

Or use Terraform workspaces:

```bash
terraform workspace new prod
terraform workspace select prod
terraform apply
```

## Security Best Practices

1. **Never commit** `terraform.tfvars` with real secrets
2. **Use** AWS Secrets Manager for sensitive data
3. **Enable** CloudTrail for audit logging
4. **Implement** least privilege IAM policies
5. **Encrypt** S3 buckets (enabled by default)
6. **Review** security groups and API access

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will delete all resources including S3 buckets and their contents.

## Troubleshooting

### Issue: Lambda placeholder zip not found

**Solution**: Create a placeholder zip file:

```bash
cd terraform
echo 'def lambda_handler(event, context): return {"statusCode": 200}' > handler.py
zip lambda_placeholder.zip handler.py
rm handler.py
```

### Issue: Bedrock access denied

**Solution**: Ensure your AWS account has Bedrock access enabled in your region. Request access through AWS Console if needed.

### Issue: API Gateway 403 errors

**Solution**: Verify API key is included in request headers:

```bash
curl -X POST https://your-api-url/analyze \
  -H "X-API-Key: your-api-key" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com"}'
```

## Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Lambda Terraform Guide](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function)
- [AWS Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)

## Support

For issues with Terraform configuration, please open a GitHub issue.
