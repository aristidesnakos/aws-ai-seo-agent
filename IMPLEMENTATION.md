# Implementation Guide - AWS AI SEO Agent

This guide provides step-by-step instructions for implementing the AWS AI SEO Agent MVP.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Environment Setup](#environment-setup)
3. [Project Structure](#project-structure)
4. [Implementation Steps](#implementation-steps)
5. [Testing](#testing)
6. [Deployment](#deployment)
7. [Monitoring](#monitoring)

---

## Prerequisites

### Required Accounts & Access
- AWS Account with appropriate permissions
- AWS Bedrock access (request if needed)
- Google Cloud Platform account for PageSpeed Insights API
- GitHub account for version control

### Required Tools
- Python 3.11 or higher
- AWS CLI configured
- Docker (for local testing)
- Git

### Required Skills
- Python programming
- AWS Lambda basics
- REST API concepts
- Basic SEO knowledge

---

## Environment Setup

### 1. Install Dependencies

```bash
# Clone the repository
git clone https://github.com/aristidesnakos/aws-ai-seo-agent.git
cd aws-ai-seo-agent

# Create virtual environment
python3.11 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install Python dependencies
pip install -r requirements.txt

# Install development dependencies
pip install -r requirements-dev.txt
```

### 2. Configure AWS CLI

```bash
# Configure AWS credentials
aws configure

# Verify Bedrock access
aws bedrock list-foundation-models --region us-east-1
```

### 3. Set Up Environment Variables

Create a `.env` file:

```bash
# AWS Configuration
AWS_REGION=us-east-1
AWS_ACCOUNT_ID=123456789012

# PageSpeed Insights API
PAGESPEED_API_KEY=your_api_key_here

# Bedrock Configuration
BEDROCK_MODEL_ID=anthropic.claude-3-sonnet-20240229-v1:0
BEDROCK_REGION=us-east-1

# S3 Buckets
S3_TEMP_BUCKET=seo-agent-temp-data
S3_REPORTS_BUCKET=seo-agent-reports

# Lambda Configuration
LAMBDA_TIMEOUT=30
LAMBDA_MEMORY=512

# API Configuration
API_RATE_LIMIT=100
```

---

## Project Structure

```
aws-ai-seo-agent/
├── src/
│   ├── lambda/
│   │   ├── input_handler/
│   │   │   ├── handler.py
│   │   │   ├── validator.py
│   │   │   └── requirements.txt
│   │   ├── pagespeed_collector/
│   │   │   ├── handler.py
│   │   │   ├── api_client.py
│   │   │   └── requirements.txt
│   │   ├── content_crawler/
│   │   │   ├── handler.py
│   │   │   ├── parser.py
│   │   │   └── requirements.txt
│   │   ├── ai_engine/
│   │   │   ├── handler.py
│   │   │   ├── prompt_builder.py
│   │   │   └── requirements.txt
│   │   └── report_generator/
│   │       ├── handler.py
│   │       ├── formatter.py
│   │       └── requirements.txt
│   ├── shared/
│   │   ├── models.py
│   │   ├── utils.py
│   │   └── constants.py
│   └── cli/
│       └── seo_agent.py
├── infrastructure/
│   ├── cloudformation/
│   │   ├── template.yaml
│   │   └── parameters.json
│   └── terraform/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── tests/
│   ├── unit/
│   ├── integration/
│   └── fixtures/
├── docs/
│   ├── PRD.md
│   ├── ARCHITECTURE.md
│   ├── API.md
│   └── IMPLEMENTATION.md
├── .env.example
├── .gitignore
├── requirements.txt
├── requirements-dev.txt
├── README.md
└── LICENSE
```

---

## Implementation Steps

### Phase 1: Core Lambda Functions

#### Step 1: Input Handler Lambda

**File**: `src/lambda/input_handler/handler.py`

```python
import json
import boto3
import os
from validator import validate_url
from typing import Dict, Any

lambda_client = boto3.client('lambda')

def lambda_handler(event: Dict[str, Any], context) -> Dict[str, Any]:
    """
    Main entry point for SEO analysis.
    Orchestrates the entire analysis workflow.
    """
    try:
        # Parse request
        body = json.loads(event.get('body', '{}'))
        url = body.get('url')
        options = body.get('options', {})
        
        # Validate URL
        validation_result = validate_url(url)
        if not validation_result['valid']:
            return error_response(400, 'INVALID_URL', validation_result['message'])
        
        # Invoke collectors in parallel
        pagespeed_future = invoke_lambda_async(
            os.environ['PAGESPEED_LAMBDA_ARN'],
            {'url': url, 'options': options}
        )
        
        crawler_future = invoke_lambda_async(
            os.environ['CRAWLER_LAMBDA_ARN'],
            {'url': url, 'options': options}
        )
        
        # Wait for results
        pagespeed_data = get_lambda_result(pagespeed_future)
        crawler_data = get_lambda_result(crawler_future)
        
        # Invoke AI engine
        ai_result = invoke_lambda_sync(
            os.environ['AI_LAMBDA_ARN'],
            {
                'url': url,
                'pagespeed': pagespeed_data,
                'content': crawler_data
            }
        )
        
        # Generate report
        report = invoke_lambda_sync(
            os.environ['REPORT_LAMBDA_ARN'],
            ai_result
        )
        
        return success_response(report)
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return error_response(500, 'INTERNAL_ERROR', str(e))

def invoke_lambda_async(function_arn: str, payload: Dict) -> str:
    """Invoke Lambda function asynchronously"""
    response = lambda_client.invoke(
        FunctionName=function_arn,
        InvocationType='RequestResponse',
        Payload=json.dumps(payload)
    )
    return response

def invoke_lambda_sync(function_arn: str, payload: Dict) -> Dict:
    """Invoke Lambda function synchronously"""
    response = lambda_client.invoke(
        FunctionName=function_arn,
        InvocationType='RequestResponse',
        Payload=json.dumps(payload)
    )
    return json.loads(response['Payload'].read())

def success_response(data: Dict) -> Dict:
    """Format success response"""
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'status': 'success',
            'data': data
        })
    }

def error_response(status_code: int, code: str, message: str) -> Dict:
    """Format error response"""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'status': 'error',
            'code': code,
            'message': message
        })
    }
```

**File**: `src/lambda/input_handler/validator.py`

```python
import re
from urllib.parse import urlparse
import requests

def validate_url(url: str) -> dict:
    """
    Validate URL format and accessibility.
    """
    if not url:
        return {'valid': False, 'message': 'URL is required'}
    
    # Check format
    url_pattern = re.compile(
        r'^https?://'  # http:// or https://
        r'(?:(?:[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?\.)+[A-Z]{2,6}\.?|'  # domain
        r'localhost|'  # localhost
        r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})'  # or IP
        r'(?::\d+)?'  # optional port
        r'(?:/?|[/?]\S+)$', re.IGNORECASE)
    
    if not url_pattern.match(url):
        return {'valid': False, 'message': 'Invalid URL format'}
    
    # Parse URL
    try:
        parsed = urlparse(url)
        if not all([parsed.scheme, parsed.netloc]):
            return {'valid': False, 'message': 'URL must include scheme and domain'}
    except Exception as e:
        return {'valid': False, 'message': f'URL parsing error: {str(e)}'}
    
    # Check accessibility (HEAD request)
    try:
        response = requests.head(url, timeout=5, allow_redirects=True)
        if response.status_code >= 400:
            return {'valid': False, 'message': f'URL not accessible (HTTP {response.status_code})'}
    except requests.RequestException as e:
        return {'valid': False, 'message': f'URL not accessible: {str(e)}'}
    
    return {'valid': True, 'message': 'URL is valid'}
```

#### Step 2: PageSpeed Collector Lambda

**File**: `src/lambda/pagespeed_collector/handler.py`

```python
import json
import os
from api_client import PageSpeedClient

def lambda_handler(event, context):
    """
    Fetch and parse PageSpeed Insights data.
    """
    try:
        url = event.get('url')
        options = event.get('options', {})
        
        client = PageSpeedClient(os.environ['PAGESPEED_API_KEY'])
        
        results = {}
        
        # Fetch mobile metrics
        if options.get('includeMobile', True):
            results['mobile'] = client.analyze(url, 'mobile')
        
        # Fetch desktop metrics
        if options.get('includeDesktop', True):
            results['desktop'] = client.analyze(url, 'desktop')
        
        return {
            'statusCode': 200,
            'body': results
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': {'error': str(e)}
        }
```

**File**: `src/lambda/pagespeed_collector/api_client.py`

```python
import requests
from typing import Dict, Any

class PageSpeedClient:
    """Client for Google PageSpeed Insights API"""
    
    BASE_URL = "https://www.googleapis.com/pagespeedinsights/v5/runPagespeed"
    
    def __init__(self, api_key: str):
        self.api_key = api_key
    
    def analyze(self, url: str, strategy: str = 'mobile') -> Dict[str, Any]:
        """
        Analyze URL using PageSpeed Insights API.
        
        Args:
            url: Target URL
            strategy: 'mobile' or 'desktop'
        
        Returns:
            Parsed PageSpeed data
        """
        params = {
            'url': url,
            'key': self.api_key,
            'category': ['performance', 'seo', 'accessibility'],
            'strategy': strategy
        }
        
        response = requests.get(self.BASE_URL, params=params, timeout=30)
        response.raise_for_status()
        
        data = response.json()
        return self._parse_response(data)
    
    def _parse_response(self, data: Dict) -> Dict:
        """Parse PageSpeed API response"""
        lighthouse = data.get('lighthouseResult', {})
        
        return {
            'performanceScore': lighthouse.get('categories', {}).get('performance', {}).get('score', 0) * 100,
            'seoScore': lighthouse.get('categories', {}).get('seo', {}).get('score', 0) * 100,
            'accessibilityScore': lighthouse.get('categories', {}).get('accessibility', {}).get('score', 0) * 100,
            'coreWebVitals': self._extract_core_web_vitals(lighthouse),
            'metrics': self._extract_metrics(lighthouse),
            'opportunities': self._extract_opportunities(lighthouse),
            'diagnostics': self._extract_diagnostics(lighthouse)
        }
    
    def _extract_core_web_vitals(self, lighthouse: Dict) -> Dict:
        """Extract Core Web Vitals"""
        audits = lighthouse.get('audits', {})
        
        return {
            'LCP': {
                'value': audits.get('largest-contentful-paint', {}).get('numericValue', 0) / 1000,
                'unit': 's',
                'displayValue': audits.get('largest-contentful-paint', {}).get('displayValue', '')
            },
            'FID': {
                'value': audits.get('max-potential-fid', {}).get('numericValue', 0),
                'unit': 'ms',
                'displayValue': audits.get('max-potential-fid', {}).get('displayValue', '')
            },
            'CLS': {
                'value': audits.get('cumulative-layout-shift', {}).get('numericValue', 0),
                'unit': 'score',
                'displayValue': audits.get('cumulative-layout-shift', {}).get('displayValue', '')
            }
        }
    
    def _extract_metrics(self, lighthouse: Dict) -> Dict:
        """Extract performance metrics"""
        audits = lighthouse.get('audits', {})
        
        return {
            'firstContentfulPaint': audits.get('first-contentful-paint', {}).get('numericValue', 0),
            'speedIndex': audits.get('speed-index', {}).get('numericValue', 0),
            'timeToInteractive': audits.get('interactive', {}).get('numericValue', 0),
            'totalBlockingTime': audits.get('total-blocking-time', {}).get('numericValue', 0)
        }
    
    def _extract_opportunities(self, lighthouse: Dict) -> list:
        """Extract optimization opportunities"""
        audits = lighthouse.get('audits', {})
        opportunities = []
        
        for key, audit in audits.items():
            if audit.get('details', {}).get('type') == 'opportunity':
                opportunities.append({
                    'id': key,
                    'title': audit.get('title'),
                    'description': audit.get('description'),
                    'savings': audit.get('numericValue', 0)
                })
        
        return opportunities
    
    def _extract_diagnostics(self, lighthouse: Dict) -> list:
        """Extract diagnostic information"""
        audits = lighthouse.get('audits', {})
        diagnostics = []
        
        for key, audit in audits.items():
            if audit.get('scoreDisplayMode') == 'informative':
                diagnostics.append({
                    'id': key,
                    'title': audit.get('title'),
                    'description': audit.get('description')
                })
        
        return diagnostics
```

#### Step 3: Content Crawler Lambda

**File**: `src/lambda/content_crawler/handler.py`

```python
import json
from parser import HTMLParser

def lambda_handler(event, context):
    """
    Crawl and parse HTML content.
    """
    try:
        url = event.get('url')
        
        parser = HTMLParser()
        content_data = parser.parse_url(url)
        
        return {
            'statusCode': 200,
            'body': content_data
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': {'error': str(e)}
        }
```

**File**: `src/lambda/content_crawler/parser.py`

```python
import requests
from bs4 import BeautifulSoup
from typing import Dict, List
import json
import re

class HTMLParser:
    """Parse HTML content and extract SEO elements"""
    
    def __init__(self):
        self.headers = {
            'User-Agent': 'Mozilla/5.0 (compatible; SEO-Agent/1.0)'
        }
    
    def parse_url(self, url: str) -> Dict:
        """
        Fetch and parse URL content.
        """
        # Fetch HTML
        response = requests.get(url, headers=self.headers, timeout=30)
        response.raise_for_status()
        
        html_content = response.text
        soup = BeautifulSoup(html_content, 'lxml')
        
        return {
            'httpStatus': response.status_code,
            'responseHeaders': dict(response.headers),
            'htmlElements': self._extract_html_elements(soup),
            'contentMetrics': self._calculate_content_metrics(soup),
            'links': self._extract_links(soup, url),
            'structuredData': self._extract_structured_data(soup)
        }
    
    def _extract_html_elements(self, soup: BeautifulSoup) -> Dict:
        """Extract key HTML elements"""
        return {
            'title': soup.title.string if soup.title else None,
            'metaDescription': self._get_meta_content(soup, 'description'),
            'metaKeywords': self._get_meta_content(soup, 'keywords'),
            'metaRobots': self._get_meta_content(soup, 'robots'),
            'canonicalUrl': self._get_canonical(soup),
            'h1Tags': [h1.get_text(strip=True) for h1 in soup.find_all('h1')],
            'h2Tags': [h2.get_text(strip=True) for h2 in soup.find_all('h2')],
            'h3Tags': [h3.get_text(strip=True) for h3 in soup.find_all('h3')],
            'images': self._extract_images(soup),
            'openGraph': self._extract_open_graph(soup),
            'twitterCard': self._extract_twitter_card(soup)
        }
    
    def _get_meta_content(self, soup: BeautifulSoup, name: str) -> str:
        """Get meta tag content"""
        meta = soup.find('meta', attrs={'name': name})
        if not meta:
            meta = soup.find('meta', attrs={'property': name})
        return meta.get('content', '') if meta else None
    
    def _get_canonical(self, soup: BeautifulSoup) -> str:
        """Get canonical URL"""
        canonical = soup.find('link', rel='canonical')
        return canonical.get('href') if canonical else None
    
    def _extract_images(self, soup: BeautifulSoup) -> List[Dict]:
        """Extract image information"""
        images = []
        for img in soup.find_all('img'):
            images.append({
                'src': img.get('src'),
                'alt': img.get('alt', ''),
                'title': img.get('title', '')
            })
        return images[:50]  # Limit to first 50
    
    def _extract_links(self, soup: BeautifulSoup, base_url: str) -> Dict:
        """Extract internal and external links"""
        from urllib.parse import urljoin, urlparse
        
        base_domain = urlparse(base_url).netloc
        internal = []
        external = []
        
        for link in soup.find_all('a', href=True):
            href = link.get('href')
            absolute_url = urljoin(base_url, href)
            link_domain = urlparse(absolute_url).netloc
            
            if link_domain == base_domain:
                internal.append(absolute_url)
            else:
                external.append(absolute_url)
        
        return {
            'internal': list(set(internal))[:100],
            'external': list(set(external))[:100]
        }
    
    def _extract_structured_data(self, soup: BeautifulSoup) -> List[Dict]:
        """Extract JSON-LD structured data"""
        scripts = soup.find_all('script', type='application/ld+json')
        structured_data = []
        
        for script in scripts:
            try:
                data = json.loads(script.string)
                structured_data.append(data)
            except:
                pass
        
        return structured_data
    
    def _extract_open_graph(self, soup: BeautifulSoup) -> Dict:
        """Extract Open Graph tags"""
        og_data = {}
        og_tags = soup.find_all('meta', property=re.compile(r'^og:'))
        
        for tag in og_tags:
            prop = tag.get('property', '').replace('og:', '')
            content = tag.get('content', '')
            og_data[prop] = content
        
        return og_data
    
    def _extract_twitter_card(self, soup: BeautifulSoup) -> Dict:
        """Extract Twitter Card tags"""
        twitter_data = {}
        twitter_tags = soup.find_all('meta', attrs={'name': re.compile(r'^twitter:')})
        
        for tag in twitter_tags:
            name = tag.get('name', '').replace('twitter:', '')
            content = tag.get('content', '')
            twitter_data[name] = content
        
        return twitter_data
    
    def _calculate_content_metrics(self, soup: BeautifulSoup) -> Dict:
        """Calculate content metrics"""
        # Remove script and style tags
        for script in soup(['script', 'style']):
            script.decompose()
        
        text = soup.get_text()
        words = text.split()
        
        return {
            'wordCount': len(words),
            'characterCount': len(text),
            'paragraphCount': len(soup.find_all('p'))
        }
```

---

### Phase 2: AI Engine & Report Generator

(Implementation continues with AI engine using AWS Bedrock and report generator)

#### Step 4: Deploy Infrastructure

Use CloudFormation or Terraform to deploy:

```bash
# Using CloudFormation
aws cloudformation create-stack \
  --stack-name seo-agent-mvp \
  --template-body file://infrastructure/cloudformation/template.yaml \
  --parameters file://infrastructure/cloudformation/parameters.json \
  --capabilities CAPABILITY_IAM

# Or using Terraform
cd infrastructure/terraform
terraform init
terraform plan
terraform apply
```

---

## Testing

### Unit Tests

```bash
# Run unit tests
pytest tests/unit/ -v

# Run with coverage
pytest tests/unit/ --cov=src --cov-report=html
```

### Integration Tests

```bash
# Run integration tests
pytest tests/integration/ -v
```

### Manual Testing

```bash
# Test input handler
aws lambda invoke \
  --function-name seo-agent-input-handler \
  --payload '{"body":"{\"url\":\"https://example.com\"}"}' \
  response.json

cat response.json
```

---

## Deployment

### Deployment Checklist

- [ ] Set up AWS account and configure CLI
- [ ] Request Bedrock access
- [ ] Obtain PageSpeed Insights API key
- [ ] Create S3 buckets
- [ ] Deploy Lambda functions
- [ ] Configure API Gateway
- [ ] Set up monitoring and alerts
- [ ] Test end-to-end workflow
- [ ] Document API endpoints
- [ ] Create usage examples

---

## Monitoring

### CloudWatch Dashboards

Create dashboards for:
- Request volume
- Error rates
- Latency metrics
- Cost tracking

### Alerts

Set up alerts for:
- High error rates
- Slow response times
- High costs
- API failures

---

## Next Steps

1. Implement remaining Lambda functions
2. Set up CI/CD pipeline
3. Create comprehensive test suite
4. Deploy to staging environment
5. Conduct user acceptance testing
6. Deploy to production
7. Monitor and optimize

---

## Resources

- [AWS Lambda Python Documentation](https://docs.aws.amazon.com/lambda/latest/dg/lambda-python.html)
- [AWS Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [PageSpeed Insights API](https://developers.google.com/speed/docs/insights/v5/get-started)
- [BeautifulSoup Documentation](https://www.crummy.com/software/BeautifulSoup/bs4/doc/)
