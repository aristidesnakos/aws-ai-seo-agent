# API Specification - AWS AI SEO Agent

## Overview

This document specifies the REST API endpoints for the AWS AI SEO Agent service.

**Base URL**: `https://api.seo-agent.aws.example.com`
**Version**: v1
**Authentication**: API Key

---

## Authentication

All API requests must include an API key in the request header.

### Header
```
X-API-Key: your-api-key-here
```

### Error Response (401 Unauthorized)
```json
{
  "status": "error",
  "code": "UNAUTHORIZED",
  "message": "Invalid or missing API key"
}
```

---

## Endpoints

### 1. Analyze URL

Analyze a URL and generate SEO recommendations.

**Endpoint**: `POST /api/v1/analyze`

**Request Headers**:
```
Content-Type: application/json
X-API-Key: your-api-key-here
```

**Request Body**:
```json
{
  "url": "https://example.com",
  "options": {
    "includeDesktop": true,
    "includeMobile": true,
    "categories": ["technical", "onpage", "performance", "content", "mobile"],
    "generateMarkdown": false,
    "detailLevel": "standard"
  }
}
```

**Request Parameters**:

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| url | string | Yes | - | Full URL to analyze (must include protocol) |
| options | object | No | {} | Analysis options |
| options.includeDesktop | boolean | No | true | Include desktop metrics |
| options.includeMobile | boolean | No | true | Include mobile metrics |
| options.categories | array | No | all | SEO categories to analyze |
| options.generateMarkdown | boolean | No | false | Generate markdown report |
| options.detailLevel | enum | No | "standard" | "minimal", "standard", or "detailed" |

**Success Response (200 OK)**:
```json
{
  "status": "success",
  "data": {
    "analysisId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "url": "https://example.com",
    "analyzedAt": "2025-10-18T13:39:00Z",
    "processingTime": 24.5,
    "overallScore": 65,
    "scores": {
      "technical": 70,
      "onpage": 60,
      "performance": 55,
      "content": 75,
      "mobile": 65
    },
    "summary": {
      "criticalIssues": 3,
      "highPriorityIssues": 8,
      "mediumPriorityIssues": 12,
      "lowPriorityIssues": 5,
      "totalRecommendations": 28
    },
    "quickWins": [
      {
        "id": "rec-001",
        "title": "Add missing alt text to images",
        "impact": "High",
        "effort": "Easy",
        "estimatedTime": "30 minutes"
      }
    ],
    "coreWebVitals": {
      "mobile": {
        "LCP": {
          "value": 2.8,
          "unit": "s",
          "rating": "needs improvement"
        },
        "FID": {
          "value": 95,
          "unit": "ms",
          "rating": "good"
        },
        "CLS": {
          "value": 0.15,
          "unit": "score",
          "rating": "needs improvement"
        }
      },
      "desktop": {
        "LCP": {
          "value": 1.5,
          "unit": "s",
          "rating": "good"
        },
        "FID": {
          "value": 45,
          "unit": "ms",
          "rating": "good"
        },
        "CLS": {
          "value": 0.08,
          "unit": "score",
          "rating": "good"
        }
      }
    },
    "recommendations": [
      {
        "id": "rec-001",
        "category": "Performance",
        "subcategory": "Images",
        "title": "Optimize image sizes and formats",
        "severity": "High",
        "impact": "High",
        "effort": "Medium",
        "estimatedTime": "2-4 hours",
        "description": "Multiple images are not optimized for web delivery. Large image files are significantly impacting page load time and LCP metric.",
        "currentState": {
          "unoptimizedImages": 15,
          "totalImageSize": "4.2 MB",
          "largestImage": "hero-image.jpg (1.8 MB)"
        },
        "targetState": {
          "expectedImageSize": "800 KB",
          "expectedSavings": "80%"
        },
        "actionItems": [
          {
            "step": 1,
            "action": "Convert images to WebP format",
            "details": "Use tools like ImageMagick or online converters"
          },
          {
            "step": 2,
            "action": "Implement responsive images with srcset",
            "details": "Provide different image sizes for different viewport sizes"
          },
          {
            "step": 3,
            "action": "Enable lazy loading for below-fold images",
            "details": "Add loading='lazy' attribute to <img> tags"
          }
        ],
        "resources": [
          {
            "title": "Using WebP Images",
            "url": "https://web.dev/serve-images-webp/"
          },
          {
            "title": "Responsive Images Guide",
            "url": "https://developer.mozilla.org/en-US/docs/Learn/HTML/Multimedia_and_embedding/Responsive_images"
          }
        ],
        "expectedImpprovement": {
          "LCP": "Reduce by 40-50%",
          "pageLoadTime": "Reduce by 2-3 seconds",
          "overallScore": "+8 points"
        },
        "affectedUrls": [
          "/",
          "/products",
          "/about"
        ],
        "technicalDetails": {
          "files": [
            "hero-image.jpg",
            "product-1.png",
            "product-2.png"
          ],
          "currentFormat": "JPEG/PNG",
          "recommendedFormat": "WebP",
          "compressionRatio": "70-80%"
        }
      },
      {
        "id": "rec-002",
        "category": "On-Page SEO",
        "subcategory": "Meta Tags",
        "title": "Optimize meta description length",
        "severity": "Medium",
        "impact": "Medium",
        "effort": "Easy",
        "estimatedTime": "15 minutes",
        "description": "The meta description is too short and doesn't effectively summarize the page content.",
        "currentState": {
          "metaDescription": "Welcome to our site",
          "length": 21,
          "optimalRange": "150-160 characters"
        },
        "targetState": {
          "recommendedLength": "150-160 characters",
          "shouldInclude": ["primary keyword", "value proposition", "call to action"]
        },
        "actionItems": [
          {
            "step": 1,
            "action": "Write comprehensive meta description",
            "details": "Include primary keyword, unique value proposition, and call to action"
          }
        ],
        "resources": [
          {
            "title": "Meta Description Best Practices",
            "url": "https://moz.com/learn/seo/meta-description"
          }
        ],
        "expectedImprovement": {
          "clickThroughRate": "Increase by 5-15%",
          "overallScore": "+2 points"
        },
        "affectedUrls": ["/"]
      }
    ],
    "reportUrls": {
      "json": "https://s3.amazonaws.com/seo-reports/a1b2c3d4.json",
      "markdown": null
    },
    "pageSpeedInsights": {
      "mobile": {
        "performanceScore": 55,
        "url": "https://pagespeed.web.dev/analysis?url=https://example.com"
      },
      "desktop": {
        "performanceScore": 78,
        "url": "https://pagespeed.web.dev/analysis?url=https://example.com"
      }
    }
  }
}
```

**Error Responses**:

**400 Bad Request** - Invalid URL:
```json
{
  "status": "error",
  "code": "INVALID_URL",
  "message": "The provided URL is invalid or malformed",
  "details": {
    "url": "htp://example.com",
    "reason": "Invalid protocol. Expected http:// or https://"
  }
}
```

**400 Bad Request** - URL not accessible:
```json
{
  "status": "error",
  "code": "URL_NOT_ACCESSIBLE",
  "message": "The URL could not be accessed",
  "details": {
    "url": "https://example.com",
    "statusCode": 404,
    "reason": "Page not found"
  }
}
```

**429 Too Many Requests**:
```json
{
  "status": "error",
  "code": "RATE_LIMIT_EXCEEDED",
  "message": "Rate limit exceeded",
  "details": {
    "limit": 100,
    "window": "1 minute",
    "retryAfter": 45
  }
}
```

**500 Internal Server Error** - PageSpeed API Error:
```json
{
  "status": "error",
  "code": "PAGESPEED_API_ERROR",
  "message": "Failed to fetch PageSpeed Insights data",
  "details": {
    "reason": "API rate limit exceeded",
    "retryable": true
  }
}
```

**500 Internal Server Error** - AI Analysis Error:
```json
{
  "status": "error",
  "code": "AI_ANALYSIS_ERROR",
  "message": "Failed to generate AI recommendations",
  "details": {
    "reason": "Model timeout",
    "retryable": true
  }
}
```

**503 Service Unavailable**:
```json
{
  "status": "error",
  "code": "SERVICE_UNAVAILABLE",
  "message": "Service temporarily unavailable",
  "details": {
    "reason": "High load",
    "retryAfter": 120
  }
}
```

---

### 2. Get Analysis Status (Future)

Check the status of a long-running analysis.

**Endpoint**: `GET /api/v1/analyze/{analysisId}`

**Path Parameters**:
- `analysisId`: UUID of the analysis

**Response**:
```json
{
  "status": "success",
  "data": {
    "analysisId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "status": "completed",
    "progress": 100,
    "createdAt": "2025-10-18T13:39:00Z",
    "completedAt": "2025-10-18T13:39:24Z",
    "result": {
      "url": "https://example.com",
      "overallScore": 65
    }
  }
}
```

---

### 3. List Recent Analyses (Future)

Get a list of recent analyses for the API key.

**Endpoint**: `GET /api/v1/analyses`

**Query Parameters**:
- `limit`: Number of results (default: 10, max: 100)
- `offset`: Pagination offset (default: 0)
- `sort`: Sort order (default: "desc")

**Response**:
```json
{
  "status": "success",
  "data": {
    "analyses": [
      {
        "analysisId": "a1b2c3d4",
        "url": "https://example.com",
        "analyzedAt": "2025-10-18T13:39:00Z",
        "overallScore": 65,
        "status": "completed"
      }
    ],
    "pagination": {
      "total": 50,
      "limit": 10,
      "offset": 0,
      "hasMore": true
    }
  }
}
```

---

## Data Models

### Recommendation Object

```typescript
interface Recommendation {
  id: string;                    // Unique identifier
  category: string;              // "Technical" | "On-Page" | "Performance" | "Content" | "Mobile"
  subcategory?: string;          // More specific category
  title: string;                 // Short title
  severity: string;              // "Critical" | "High" | "Medium" | "Low"
  impact: string;                // "High" | "Medium" | "Low"
  effort: string;                // "Easy" | "Medium" | "Hard"
  estimatedTime?: string;        // Human-readable time estimate
  description: string;           // Detailed description
  currentState?: object;         // Current state of the issue
  targetState?: object;          // Desired state
  actionItems: ActionItem[];     // Steps to fix
  resources?: Resource[];        // Helpful links
  expectedImprovement?: object;  // Expected impact metrics
  affectedUrls?: string[];       // URLs affected
  technicalDetails?: object;     // Additional technical info
}

interface ActionItem {
  step: number;
  action: string;
  details?: string;
}

interface Resource {
  title: string;
  url: string;
}
```

### Core Web Vitals Object

```typescript
interface CoreWebVitals {
  mobile: {
    LCP: Metric;
    FID: Metric;
    CLS: Metric;
  };
  desktop: {
    LCP: Metric;
    FID: Metric;
    CLS: Metric;
  };
}

interface Metric {
  value: number;
  unit: string;
  rating: "good" | "needs improvement" | "poor";
}
```

---

## Rate Limits

| Plan | Requests per Minute | Requests per Day |
|------|---------------------|------------------|
| Free | 10 | 100 |
| Basic | 100 | 1,000 |
| Pro | 1,000 | 10,000 |
| Enterprise | Custom | Custom |

When rate limit is exceeded, the API returns a 429 status code with a `retryAfter` value in seconds.

---

## Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| UNAUTHORIZED | 401 | Invalid or missing API key |
| INVALID_URL | 400 | Malformed or invalid URL |
| URL_NOT_ACCESSIBLE | 400 | URL cannot be accessed |
| INVALID_REQUEST | 400 | Request body validation failed |
| RATE_LIMIT_EXCEEDED | 429 | Too many requests |
| PAGESPEED_API_ERROR | 500 | PageSpeed Insights API error |
| CRAWLER_ERROR | 500 | Failed to crawl URL |
| AI_ANALYSIS_ERROR | 500 | AI model error |
| SERVICE_UNAVAILABLE | 503 | Service temporarily unavailable |
| INTERNAL_ERROR | 500 | Unexpected server error |

---

## Best Practices

### 1. Error Handling
Always check the `status` field in the response. If it's "error", check the `code` field to determine the error type.

```javascript
const response = await fetch('https://api.seo-agent.aws.example.com/api/v1/analyze', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-API-Key': 'your-api-key'
  },
  body: JSON.stringify({ url: 'https://example.com' })
});

const data = await response.json();

if (data.status === 'error') {
  if (data.code === 'RATE_LIMIT_EXCEEDED') {
    // Wait and retry
    await sleep(data.details.retryAfter * 1000);
    // Retry request
  } else if (data.code === 'URL_NOT_ACCESSIBLE') {
    // Handle inaccessible URL
  }
} else {
  // Process successful response
  console.log(data.data.recommendations);
}
```

### 2. Rate Limiting
Implement exponential backoff when retrying failed requests.

```javascript
async function analyzeWithRetry(url, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      const response = await analyze(url);
      return response;
    } catch (error) {
      if (error.code === 'RATE_LIMIT_EXCEEDED') {
        const delay = Math.pow(2, i) * 1000;
        await sleep(delay);
      } else {
        throw error;
      }
    }
  }
}
```

### 3. Caching
Cache analysis results to avoid redundant API calls.

```javascript
const cache = new Map();

async function getCachedAnalysis(url) {
  const cacheKey = url.toLowerCase();
  
  if (cache.has(cacheKey)) {
    const cached = cache.get(cacheKey);
    const age = Date.now() - cached.timestamp;
    
    // Cache for 24 hours
    if (age < 24 * 60 * 60 * 1000) {
      return cached.data;
    }
  }
  
  const analysis = await analyze(url);
  cache.set(cacheKey, {
    data: analysis,
    timestamp: Date.now()
  });
  
  return analysis;
}
```

### 4. URL Validation
Validate URLs before sending to the API.

```javascript
function isValidUrl(url) {
  try {
    const parsed = new URL(url);
    return parsed.protocol === 'http:' || parsed.protocol === 'https:';
  } catch {
    return false;
  }
}
```

---

## Examples

### cURL

```bash
curl -X POST https://api.seo-agent.aws.example.com/api/v1/analyze \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-api-key-here" \
  -d '{
    "url": "https://example.com",
    "options": {
      "includeMobile": true,
      "includeDesktop": true,
      "generateMarkdown": false
    }
  }'
```

### Python

```python
import requests

url = "https://api.seo-agent.aws.example.com/api/v1/analyze"
headers = {
    "Content-Type": "application/json",
    "X-API-Key": "your-api-key-here"
}
payload = {
    "url": "https://example.com",
    "options": {
        "includeMobile": True,
        "includeDesktop": True
    }
}

response = requests.post(url, json=payload, headers=headers)
data = response.json()

if data["status"] == "success":
    print(f"Overall Score: {data['data']['overallScore']}")
    for rec in data['data']['recommendations']:
        print(f"- {rec['title']} ({rec['severity']})")
```

### JavaScript (Node.js)

```javascript
const axios = require('axios');

async function analyzeSEO(targetUrl) {
  try {
    const response = await axios.post(
      'https://api.seo-agent.aws.example.com/api/v1/analyze',
      {
        url: targetUrl,
        options: {
          includeMobile: true,
          includeDesktop: true
        }
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': 'your-api-key-here'
        }
      }
    );

    const { data } = response.data;
    console.log(`Overall Score: ${data.overallScore}`);
    console.log(`Total Recommendations: ${data.summary.totalRecommendations}`);
    
    // Print quick wins
    console.log('\nQuick Wins:');
    data.quickWins.forEach(win => {
      console.log(`- ${win.title} (${win.estimatedTime})`);
    });

    return data;
  } catch (error) {
    if (error.response) {
      console.error(`Error: ${error.response.data.message}`);
    } else {
      console.error(`Error: ${error.message}`);
    }
  }
}

analyzeSEO('https://example.com');
```

---

## Changelog

### v1.0.0 (2025-10-18)
- Initial API release
- POST /api/v1/analyze endpoint
- Support for mobile and desktop analysis
- AI-powered recommendations
- Core Web Vitals integration

### Future Versions
- v1.1.0: Add GET /api/v1/analyze/{id} for status checking
- v1.2.0: Add GET /api/v1/analyses for listing analyses
- v1.3.0: Add webhook support for async notifications
- v2.0.0: Add batch analysis endpoint

---

## Support

For API support, please contact:
- Email: api-support@seo-agent.aws.example.com
- Documentation: https://docs.seo-agent.aws.example.com
- Status: https://status.seo-agent.aws.example.com
