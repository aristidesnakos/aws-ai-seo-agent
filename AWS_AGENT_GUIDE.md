# AWS Agent Implementation Guide

## Overview

This document provides detailed guidance on implementing the AWS AI SEO Agent using AWS services, following AWS best practices for AI agent architecture and deployment.

---

## Agent Architecture Pattern

### Core Components

The AWS AI SEO Agent follows the **Agent with Tools** pattern, which consists of:

1. **Foundation Model (FM)** - AWS Bedrock (Claude Haiku 4.5)
2. **Orchestration Layer** - AWS Lambda functions
3. **Action Groups (Tools)** - Specialized functions for specific tasks
4. **Knowledge Bases** - Optional RAG for SEO best practices
5. **Guardrails** - Input/output validation and safety controls

### Agent Workflow

```
User Request (URL)
    ↓
Input Validation & Guardrails
    ↓
Orchestrator (Input Handler Lambda)
    ↓
┌─────────────────────────────────────┐
│   Agent Reasoning Loop              │
│   (AWS Bedrock Agent)               │
│                                     │
│   1. Analyze request                │
│   2. Plan action sequence           │
│   3. Select appropriate tools       │
│   4. Execute tools                  │
│   5. Synthesize results             │
│   6. Generate recommendations       │
└─────────────────────────────────────┘
    ↓
Action Groups (Tools):
├─→ PageSpeed Analysis Tool
├─→ Content Crawling Tool
├─→ SEO Analysis Tool
└─→ Report Generation Tool
    ↓
Output Guardrails & Formatting
    ↓
Final Report (JSON/Markdown)
```

---

## Detailed Component Architecture

### 1. Foundation Model Configuration

**Service**: AWS Bedrock  
**Model**: anthropic.claude-haiku-4.5-20250514-v1:0

**Configuration**:
```json
{
  "modelId": "anthropic.claude-haiku-4.5-20250514-v1:0",
  "inferenceConfig": {
    "maxTokens": 4096,
    "temperature": 0.7,
    "topP": 0.9,
    "stopSequences": []
  }
}
```

**Key Features**:
- **Context Window**: 200K tokens (sufficient for large web pages)
- **Speed**: 3x faster than Claude 3 Sonnet with lower latency
- **Cost**: 80% lower cost per token compared to Claude 3 Sonnet
- **Reasoning Capabilities**: Multi-step analysis and planning
- **Tool Use**: Native support for function calling
- **Structured Output**: JSON mode for consistent formatting

### 2. Agent Orchestration

**Primary Orchestrator**: Input Handler Lambda

**Responsibilities**:
- Request routing and validation
- Tool invocation coordination
- State management across tool calls
- Error handling and retry logic
- Response aggregation

**Implementation Pattern**:
```python
class AgentOrchestrator:
    def __init__(self):
        self.bedrock_client = boto3.client('bedrock-runtime')
        self.tools = self._register_tools()
        
    def process_request(self, url: str, options: dict):
        # Step 1: Initialize conversation
        messages = self._build_initial_prompt(url, options)
        
        # Step 2: Agent reasoning loop
        max_iterations = 5
        for iteration in range(max_iterations):
            # Invoke foundation model
            response = self._invoke_model(messages)
            
            # Check if tool use is required
            if self._requires_tool_use(response):
                # Execute tools
                tool_results = self._execute_tools(response['tool_use'])
                
                # Add results to conversation
                messages.append({
                    'role': 'user',
                    'content': tool_results
                })
            else:
                # Agent has completed reasoning
                return self._format_final_response(response)
        
        # Max iterations reached
        return self._handle_timeout()
    
    def _invoke_model(self, messages):
        return self.bedrock_client.invoke_model(
            modelId=self.model_id,
            body=json.dumps({
                'anthropic_version': 'bedrock-2023-05-31',
                'messages': messages,
                'max_tokens': 4096,
                'temperature': 0.7,
                'tools': self.tools
            })
        )
```

### 3. Action Groups (Tools)

Action groups are the executable functions that the agent can invoke to perform specific tasks.

#### Tool 1: PageSpeed Analysis

**Purpose**: Fetch and analyze PageSpeed Insights data

**Lambda Function**: `pagespeed-collector`

**Tool Schema**:
```json
{
  "toolSpec": {
    "name": "analyze_pagespeed",
    "description": "Fetch PageSpeed Insights data for a URL including Core Web Vitals, performance scores, and optimization opportunities",
    "inputSchema": {
      "json": {
        "type": "object",
        "properties": {
          "url": {
            "type": "string",
            "description": "The URL to analyze"
          },
          "strategy": {
            "type": "string",
            "enum": ["mobile", "desktop"],
            "description": "Device strategy for analysis"
          }
        },
        "required": ["url"]
      }
    }
  }
}
```

**Implementation**:
```python
def analyze_pagespeed(url: str, strategy: str = "mobile") -> dict:
    """
    Tool for analyzing PageSpeed metrics.
    Returns Core Web Vitals and performance data.
    """
    api_key = get_secret('pagespeed_api_key')
    
    response = requests.get(
        'https://www.googleapis.com/pagespeedinsights/v5/runPagespeed',
        params={
            'url': url,
            'key': api_key,
            'strategy': strategy,
            'category': ['performance', 'seo', 'accessibility']
        }
    )
    
    data = response.json()
    return {
        'coreWebVitals': extract_core_web_vitals(data),
        'performanceScore': extract_performance_score(data),
        'opportunities': extract_opportunities(data),
        'diagnostics': extract_diagnostics(data)
    }
```

#### Tool 2: Content Crawling

**Purpose**: Fetch and parse HTML content

**Lambda Function**: `content-crawler`

**Tool Schema**:
```json
{
  "toolSpec": {
    "name": "crawl_webpage",
    "description": "Fetch and parse HTML content from a webpage to extract SEO elements like meta tags, headings, images, and structured data",
    "inputSchema": {
      "json": {
        "type": "object",
        "properties": {
          "url": {
            "type": "string",
            "description": "The URL to crawl"
          },
          "extract_links": {
            "type": "boolean",
            "description": "Whether to extract and analyze links"
          }
        },
        "required": ["url"]
      }
    }
  }
}
```

**Implementation**:
```python
def crawl_webpage(url: str, extract_links: bool = True) -> dict:
    """
    Tool for crawling and parsing webpage content.
    Returns structured SEO elements.
    """
    response = requests.get(url, timeout=30)
    soup = BeautifulSoup(response.text, 'lxml')
    
    return {
        'metadata': {
            'title': get_title(soup),
            'description': get_meta_description(soup),
            'canonical': get_canonical(soup),
            'robots': get_meta_robots(soup)
        },
        'content': {
            'headings': extract_headings(soup),
            'images': extract_images(soup),
            'wordCount': count_words(soup)
        },
        'structuredData': extract_json_ld(soup),
        'links': extract_links(soup, url) if extract_links else None
    }
```

#### Tool 3: SEO Analysis

**Purpose**: Analyze combined data and identify issues

**Lambda Function**: Inline or separate function

**Tool Schema**:
```json
{
  "toolSpec": {
    "name": "analyze_seo_issues",
    "description": "Analyze PageSpeed and content data to identify specific SEO issues and categorize them by severity",
    "inputSchema": {
      "json": {
        "type": "object",
        "properties": {
          "pagespeed_data": {
            "type": "object",
            "description": "PageSpeed analysis results"
          },
          "content_data": {
            "type": "object",
            "description": "Crawled content data"
          }
        },
        "required": ["pagespeed_data", "content_data"]
      }
    }
  }
}
```

#### Tool 4: Report Generation

**Purpose**: Format and structure final recommendations

**Lambda Function**: `report-generator`

**Tool Schema**:
```json
{
  "toolSpec": {
    "name": "generate_report",
    "description": "Generate a structured SEO report with recommendations, prioritization, and action items",
    "inputSchema": {
      "json": {
        "type": "object",
        "properties": {
          "recommendations": {
            "type": "array",
            "description": "List of SEO recommendations"
          },
          "format": {
            "type": "string",
            "enum": ["json", "markdown"],
            "description": "Output format"
          }
        },
        "required": ["recommendations"]
      }
    }
  }
}
```

### 4. Guardrails

AWS Bedrock Guardrails provide content filtering and safety controls.

**Configuration**:
```json
{
  "guardrailIdentifier": "seo-agent-guardrail",
  "guardrailVersion": "1",
  "contentPolicy": {
    "filtersConfig": [
      {
        "type": "HATE",
        "inputStrength": "HIGH",
        "outputStrength": "HIGH"
      },
      {
        "type": "VIOLENCE",
        "inputStrength": "HIGH",
        "outputStrength": "HIGH"
      },
      {
        "type": "SEXUAL",
        "inputStrength": "HIGH",
        "outputStrength": "HIGH"
      }
    ]
  },
  "topicPolicy": {
    "topicsConfig": [
      {
        "name": "SEO Analysis",
        "definition": "Content must be related to SEO, web performance, or website optimization",
        "type": "DENY"
      }
    ]
  },
  "wordPolicy": {
    "wordsConfig": [],
    "managedWordListsConfig": []
  }
}
```

**Input Validation**:
```python
def validate_input(url: str) -> bool:
    """Validate URL before processing"""
    # URL format validation
    if not re.match(r'^https?://', url):
        raise ValueError("URL must start with http:// or https://")
    
    # Domain validation (prevent internal AWS resources)
    parsed = urlparse(url)
    if parsed.netloc in ['169.254.169.254', 'localhost', '127.0.0.1']:
        raise ValueError("Invalid URL: cannot access internal resources")
    
    # Length validation
    if len(url) > 2048:
        raise ValueError("URL too long")
    
    return True
```

**Output Validation**:
```python
def validate_output(recommendations: list) -> bool:
    """Validate recommendations before returning"""
    # Ensure recommendations are properly formatted
    for rec in recommendations:
        required_fields = ['id', 'title', 'severity', 'category']
        if not all(field in rec for field in required_fields):
            raise ValueError("Invalid recommendation format")
    
    # Check for PII or sensitive data
    output_text = json.dumps(recommendations)
    if contains_pii(output_text):
        raise ValueError("Output contains potential PII")
    
    return True
```

### 5. Knowledge Base (Optional)

**Service**: Amazon Bedrock Knowledge Bases with RAG

**Purpose**: Provide the agent with access to:
- SEO best practices documentation
- Google's official SEO guidelines
- Core Web Vitals documentation
- Historical analysis patterns

**Configuration**:
```json
{
  "knowledgeBaseId": "seo-kb-12345",
  "dataSource": {
    "type": "S3",
    "s3Configuration": {
      "bucketArn": "arn:aws:s3:::seo-knowledge-base",
      "inclusionPrefixes": ["seo-docs/", "guidelines/"]
    }
  },
  "embeddingModel": "amazon.titan-embed-text-v1",
  "vectorStore": {
    "type": "OPENSEARCH_SERVERLESS",
    "configuration": {
      "collectionArn": "arn:aws:aoss:region:account:collection/seo-vectors"
    }
  }
}
```

**Usage in Agent**:
```python
def query_knowledge_base(question: str) -> list:
    """Query knowledge base for relevant context"""
    kb_client = boto3.client('bedrock-agent-runtime')
    
    response = kb_client.retrieve(
        knowledgeBaseId='seo-kb-12345',
        retrievalQuery={
            'text': question
        },
        retrievalConfiguration={
            'vectorSearchConfiguration': {
                'numberOfResults': 5
            }
        }
    )
    
    return response['retrievalResults']
```

---

## Agent Prompt Engineering

### System Prompt

```
You are an expert SEO consultant and web performance analyst. Your role is to analyze websites and provide actionable, prioritized recommendations to improve search engine optimization.

You have access to the following tools:
1. analyze_pagespeed - Fetch PageSpeed Insights data
2. crawl_webpage - Extract HTML content and SEO elements
3. analyze_seo_issues - Identify specific SEO problems
4. generate_report - Create structured recommendations

When analyzing a website:
1. First, use analyze_pagespeed to get performance metrics for both mobile and desktop
2. Then, use crawl_webpage to extract on-page SEO elements
3. Analyze the combined data to identify issues across these categories:
   - Technical SEO (HTTPS, robots.txt, sitemaps, structured data)
   - On-Page SEO (title, meta, headings, content)
   - Performance (Core Web Vitals, page speed)
   - Content Quality (readability, depth)
   - Mobile Optimization

4. Categorize each issue by:
   - Severity: Critical, High, Medium, Low
   - Impact: High, Medium, Low
   - Effort: Easy (< 1 hour), Medium (1-8 hours), Hard (> 8 hours)

5. Generate a final report with:
   - Executive summary
   - Quick wins (high impact, low effort)
   - Prioritized recommendations with specific action steps
   - Expected improvements

Be specific, actionable, and focus on recommendations that will have measurable impact on SEO performance.
```

### User Prompt Template

```python
def build_user_prompt(url: str, options: dict) -> str:
    """Build user prompt for agent"""
    prompt = f"""Analyze the following URL for SEO improvements: {url}

Analysis Options:
- Include Mobile Analysis: {options.get('includeMobile', True)}
- Include Desktop Analysis: {options.get('includeDesktop', True)}
- Detail Level: {options.get('detailLevel', 'standard')}

Please:
1. Fetch PageSpeed data for the specified strategies
2. Crawl and analyze the webpage content
3. Identify SEO issues and opportunities
4. Generate a comprehensive report with prioritized recommendations

Focus on actionable items that can be implemented to improve:
- Search engine rankings
- Core Web Vitals scores
- User experience
- Technical SEO compliance
"""
    return prompt
```

---

## Conversation Flow Example

**Turn 1 - User Input**:
```
Analyze https://example.com for SEO improvements
```

**Turn 2 - Agent Reasoning**:
```
I need to analyze this website. Let me start by gathering data.
Tool Use: analyze_pagespeed
{
  "url": "https://example.com",
  "strategy": "mobile"
}
```

**Turn 3 - Tool Result**:
```json
{
  "coreWebVitals": {
    "LCP": 2.8,
    "FID": 95,
    "CLS": 0.15
  },
  "performanceScore": 55,
  "opportunities": [...]
}
```

**Turn 4 - Agent Reasoning**:
```
The mobile performance score is 55, which is below optimal. LCP and CLS need improvement.
Let me also check desktop and analyze the content.
Tool Use: analyze_pagespeed
{
  "url": "https://example.com",
  "strategy": "desktop"
}
```

**Turn 5 - Tool Result** (desktop data)

**Turn 6 - Agent Reasoning**:
```
Now let me examine the on-page elements.
Tool Use: crawl_webpage
{
  "url": "https://example.com",
  "extract_links": true
}
```

**Turn 7 - Tool Result** (content data)

**Turn 8 - Agent Analysis**:
```
Based on the data, I've identified several issues. Let me generate the report.
Tool Use: generate_report
{
  "recommendations": [...],
  "format": "json"
}
```

**Turn 9 - Final Response**:
```json
{
  "url": "https://example.com",
  "overallScore": 65,
  "recommendations": [...]
}
```

---

## AWS Infrastructure Requirements

### Required AWS Services

1. **AWS Bedrock**
   - Model: Claude Haiku 4.5
   - Region: us-east-1 (or region with Bedrock access)
   - Permissions: `bedrock:InvokeModel`, `bedrock:InvokeModelWithResponseStream`

2. **AWS Lambda**
   - Runtime: Python 3.11
   - Memory: 512MB - 2048MB (depending on function)
   - Timeout: 30-120 seconds
   - VPC: Not required (public internet access needed)

3. **Amazon S3**
   - Temp data bucket (lifecycle: 1 day)
   - Reports bucket (lifecycle: 90 days)
   - Knowledge base bucket (if using RAG)

4. **Amazon API Gateway**
   - Type: REST API
   - Authentication: API Key
   - Rate limiting: 100 req/min

5. **AWS Secrets Manager**
   - Store: PageSpeed Insights API key
   - Encryption: Default AWS KMS

6. **Amazon CloudWatch**
   - Logs: All Lambda function logs
   - Metrics: Custom application metrics
   - Alarms: Error rate, latency

### IAM Permissions

**Lambda Execution Role**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream"
      ],
      "Resource": "arn:aws:bedrock:*::foundation-model/anthropic.claude-haiku-4.5-*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::seo-agent-temp-data/*",
        "arn:aws:s3:::seo-agent-reports/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": "arn:aws:secretsmanager:*:*:secret:pagespeed-api-key-*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "lambda:InvokeFunction"
      ],
      "Resource": "arn:aws:lambda:*:*:function:seo-agent-*"
    }
  ]
}
```

### Environment Variables

**Input Handler Lambda**:
```bash
BEDROCK_MODEL_ID=anthropic.claude-haiku-4.5-20250514-v1:0
BEDROCK_REGION=us-east-1
PAGESPEED_LAMBDA_ARN=arn:aws:lambda:region:account:function:pagespeed-collector
CRAWLER_LAMBDA_ARN=arn:aws:lambda:region:account:function:content-crawler
S3_TEMP_BUCKET=seo-agent-temp-data
S3_REPORTS_BUCKET=seo-agent-reports
MAX_ITERATIONS=5
TIMEOUT_SECONDS=120
```

---

## Deployment Architecture

### CloudFormation Template Structure

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'AWS AI SEO Agent Infrastructure'

Parameters:
  PageSpeedAPIKey:
    Type: String
    NoEcho: true
    Description: Google PageSpeed Insights API Key

Resources:
  # S3 Buckets
  TempDataBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Sub '${AWS::StackName}-temp-data'
      LifecycleConfiguration:
        Rules:
          - Id: DeleteAfter1Day
            Status: Enabled
            ExpirationInDays: 1

  ReportsBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Sub '${AWS::StackName}-reports'
      LifecycleConfiguration:
        Rules:
          - Id: DeleteAfter90Days
            Status: Enabled
            ExpirationInDays: 90

  # Secrets Manager
  PageSpeedSecret:
    Type: AWS::SecretsManager::Secret
    Properties:
      Name: !Sub '${AWS::StackName}-pagespeed-api-key'
      SecretString: !Ref PageSpeedAPIKey

  # IAM Role
  LambdaExecutionRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: lambda.amazonaws.com
            Action: sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
      Policies:
        - PolicyName: BedrockAccess
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - bedrock:InvokeModel
                Resource: '*'
        - PolicyName: S3Access
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - s3:GetObject
                  - s3:PutObject
                Resource:
                  - !Sub '${TempDataBucket.Arn}/*'
                  - !Sub '${ReportsBucket.Arn}/*'

  # Lambda Functions
  InputHandlerFunction:
    Type: AWS::Lambda::Function
    Properties:
      FunctionName: !Sub '${AWS::StackName}-input-handler'
      Runtime: python3.11
      Handler: handler.lambda_handler
      Role: !GetAtt LambdaExecutionRole.Arn
      Timeout: 120
      MemorySize: 512
      Environment:
        Variables:
          BEDROCK_MODEL_ID: anthropic.claude-haiku-4.5-20250514-v1:0
          S3_TEMP_BUCKET: !Ref TempDataBucket
          S3_REPORTS_BUCKET: !Ref ReportsBucket

  PageSpeedCollectorFunction:
    Type: AWS::Lambda::Function
    Properties:
      FunctionName: !Sub '${AWS::StackName}-pagespeed-collector'
      Runtime: python3.11
      Handler: handler.lambda_handler
      Role: !GetAtt LambdaExecutionRole.Arn
      Timeout: 45
      MemorySize: 512

  ContentCrawlerFunction:
    Type: AWS::Lambda::Function
    Properties:
      FunctionName: !Sub '${AWS::StackName}-content-crawler'
      Runtime: python3.11
      Handler: handler.lambda_handler
      Role: !GetAtt LambdaExecutionRole.Arn
      Timeout: 30
      MemorySize: 1024

  # API Gateway
  RestAPI:
    Type: AWS::ApiGateway::RestApi
    Properties:
      Name: !Sub '${AWS::StackName}-api'
      Description: SEO Agent API

  APIResource:
    Type: AWS::ApiGateway::Resource
    Properties:
      ParentId: !GetAtt RestAPI.RootResourceId
      PathPart: analyze
      RestApiId: !Ref RestAPI

  APIMethod:
    Type: AWS::ApiGateway::Method
    Properties:
      HttpMethod: POST
      ResourceId: !Ref APIResource
      RestApiId: !Ref RestAPI
      AuthorizationType: API_KEY
      Integration:
        Type: AWS_PROXY
        IntegrationHttpMethod: POST
        Uri: !Sub 'arn:aws:apigateway:${AWS::Region}:lambda:path/2015-03-31/functions/${InputHandlerFunction.Arn}/invocations'

Outputs:
  APIEndpoint:
    Description: API Gateway endpoint URL
    Value: !Sub 'https://${RestAPI}.execute-api.${AWS::Region}.amazonaws.com/prod/analyze'
```

---

## Monitoring and Observability

### CloudWatch Metrics

**Custom Metrics**:
```python
cloudwatch = boto3.client('cloudwatch')

def publish_metrics(metric_name: str, value: float, unit: str = 'Count'):
    """Publish custom metrics to CloudWatch"""
    cloudwatch.put_metric_data(
        Namespace='SEOAgent',
        MetricData=[
            {
                'MetricName': metric_name,
                'Value': value,
                'Unit': unit,
                'Timestamp': datetime.utcnow()
            }
        ]
    )

# Example usage
publish_metrics('AnalysisSuccess', 1, 'Count')
publish_metrics('AnalysisDuration', 24.5, 'Seconds')
publish_metrics('RecommendationCount', 15, 'Count')
```

**Key Metrics to Track**:
- Analysis success/failure rate
- Average processing time
- Bedrock API latency
- Tool execution time
- Cost per analysis
- Error rates by category

### CloudWatch Alarms

```python
# High error rate alarm
{
  'AlarmName': 'SEOAgent-HighErrorRate',
  'MetricName': 'Errors',
  'Namespace': 'AWS/Lambda',
  'Statistic': 'Sum',
  'Period': 300,
  'EvaluationPeriods': 2,
  'Threshold': 10,
  'ComparisonOperator': 'GreaterThanThreshold'
}

# High latency alarm
{
  'AlarmName': 'SEOAgent-HighLatency',
  'MetricName': 'Duration',
  'Namespace': 'AWS/Lambda',
  'Statistic': 'Average',
  'Period': 300,
  'EvaluationPeriods': 2,
  'Threshold': 30000,  # 30 seconds
  'ComparisonOperator': 'GreaterThanThreshold'
}
```

### Structured Logging

```python
import json
import logging
from datetime import datetime

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def log_structured(event_type: str, details: dict):
    """Log structured JSON for better querying"""
    log_entry = {
        'timestamp': datetime.utcnow().isoformat(),
        'event_type': event_type,
        'details': details
    }
    logger.info(json.dumps(log_entry))

# Example usage
log_structured('analysis_started', {
    'url': 'https://example.com',
    'request_id': context.aws_request_id
})

log_structured('tool_executed', {
    'tool': 'analyze_pagespeed',
    'duration_ms': 1250,
    'success': True
})
```

---

## Cost Optimization

### Estimated Costs

**Per Analysis**:
- Lambda invocations (5 functions): $0.0001
- Lambda compute (avg 25 seconds): $0.0050
- Bedrock API call (4K tokens): $0.0060
- S3 storage/operations: $0.0001
- API Gateway: $0.0001
- **Total**: ~$0.0113 per analysis

**Monthly (1,000 analyses)**:
- Total: ~$11.30
- Breakdown:
  - Bedrock: $6.00 (53%)
  - Lambda: $5.10 (45%)
  - Other: $0.20 (2%)

### Optimization Strategies

1. **Bedrock Token Usage**:
   - Use concise system prompts
   - Implement caching for repeated context
   - Optimize tool schemas to reduce token count

2. **Lambda Optimization**:
   - Use Lambda layers for shared dependencies
   - Implement provisioned concurrency for predictable traffic
   - Right-size memory allocation

3. **Caching**:
   - Cache PageSpeed results (TTL: 1 hour)
   - Cache crawled content (TTL: 1 hour)
   - Use ElastiCache for high-traffic scenarios

4. **Batching**:
   - Process multiple URLs in single session
   - Batch S3 writes
   - Aggregate CloudWatch metrics

---

## Security Best Practices

### 1. Input Validation

```python
def validate_and_sanitize_url(url: str) -> str:
    """Validate and sanitize URL input"""
    # Remove whitespace
    url = url.strip()
    
    # Validate format
    if not re.match(r'^https?://', url):
        raise ValueError("Invalid URL protocol")
    
    # Parse and validate components
    parsed = urlparse(url)
    
    # Prevent SSRF attacks
    if parsed.hostname in BLOCKED_HOSTS:
        raise ValueError("Access to this host is not allowed")
    
    # Prevent access to internal resources
    if is_internal_ip(parsed.hostname):
        raise ValueError("Cannot access internal resources")
    
    return url
```

### 2. Secret Management

```python
def get_secret(secret_name: str) -> str:
    """Retrieve secret from AWS Secrets Manager"""
    client = boto3.client('secretsmanager')
    
    try:
        response = client.get_secret_value(SecretId=secret_name)
        return response['SecretString']
    except Exception as e:
        logger.error(f"Failed to retrieve secret: {str(e)}")
        raise
```

### 3. Output Sanitization

```python
def sanitize_output(data: dict) -> dict:
    """Remove sensitive data from output"""
    # Remove potential PII
    sensitive_patterns = [
        r'\b\d{3}-\d{2}-\d{4}\b',  # SSN
        r'\b\d{16}\b',  # Credit card
        r'\b[\w\.-]+@[\w\.-]+\.\w+\b'  # Email (if needed)
    ]
    
    data_str = json.dumps(data)
    for pattern in sensitive_patterns:
        data_str = re.sub(pattern, '[REDACTED]', data_str)
    
    return json.loads(data_str)
```

### 4. Network Security

- Use VPC endpoints for AWS services (optional)
- Implement WAF rules on API Gateway
- Enable AWS Shield for DDoS protection
- Use TLS 1.2+ for all communications

---

## Testing Strategy

### Unit Tests

```python
import pytest
from moto import mock_bedrock, mock_s3

@mock_bedrock
def test_agent_orchestration():
    """Test agent orchestration logic"""
    orchestrator = AgentOrchestrator()
    
    result = orchestrator.process_request(
        url='https://example.com',
        options={'includeMobile': True}
    )
    
    assert 'recommendations' in result
    assert len(result['recommendations']) > 0

@mock_s3
def test_report_storage():
    """Test report storage to S3"""
    # Create mock bucket
    s3 = boto3.client('s3')
    s3.create_bucket(Bucket='test-reports')
    
    # Store report
    report = {'test': 'data'}
    store_report(report, 'test-123')
    
    # Verify
    obj = s3.get_object(Bucket='test-reports', Key='test-123.json')
    assert json.loads(obj['Body'].read()) == report
```

### Integration Tests

```python
def test_end_to_end_analysis():
    """Test complete analysis flow"""
    # Invoke API Gateway endpoint
    response = requests.post(
        'https://api.example.com/analyze',
        json={'url': 'https://example.com'},
        headers={'X-API-Key': 'test-key'}
    )
    
    assert response.status_code == 200
    data = response.json()
    
    assert 'recommendations' in data
    assert data['overallScore'] > 0
    assert len(data['recommendations']) >= 10
```

### Load Testing

```bash
# Using Apache Bench
ab -n 100 -c 10 -p request.json -T application/json \
   https://api.example.com/analyze

# Using Locust
locust -f load_test.py --host=https://api.example.com
```

---

## Troubleshooting Guide

### Common Issues

**Issue 1: Bedrock Throttling**
- **Symptom**: `ThrottlingException` errors
- **Solution**: Implement exponential backoff, request quota increase

**Issue 2: Lambda Timeout**
- **Symptom**: Function times out before completion
- **Solution**: Increase timeout, optimize tool execution, implement async processing

**Issue 3: High Costs**
- **Symptom**: Bedrock costs higher than expected
- **Solution**: Optimize prompts, implement caching, review token usage

**Issue 4: Inconsistent Results**
- **Symptom**: Agent produces different results for same input
- **Solution**: Lower temperature, add deterministic seed, improve prompt specificity

---

## Appendix

### A. Tool Schema Best Practices

1. **Clear Descriptions**: Tool and parameter descriptions should be specific
2. **Type Constraints**: Use enums and validation where appropriate
3. **Required vs Optional**: Clearly mark required parameters
4. **Examples**: Include examples in descriptions when helpful

### B. Prompt Engineering Tips

1. **Be Specific**: Clear instructions yield better results
2. **Use Examples**: Few-shot examples improve consistency
3. **Structure Output**: Request JSON format for structured data
4. **Chain of Thought**: Ask agent to explain reasoning
5. **Iterative Refinement**: Test and refine prompts based on results

### C. References

- [AWS Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [AWS Bedrock Agents](https://docs.aws.amazon.com/bedrock/latest/userguide/agents.html)
- [Claude Haiku 4.5 Model Card](https://www.anthropic.com/claude)
- [Bedrock Guardrails](https://docs.aws.amazon.com/bedrock/latest/userguide/guardrails.html)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

---

**Document Version**: 1.0  
**Last Updated**: 2025-10-18  
**Author**: AWS AI SEO Agent Team
