# Quick Reference Guide - AWS AI SEO Agent

## Key Commands

### Setup
```bash
# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env with your credentials

# Run tests
pytest tests/ -v
```

### Analysis
```bash
# Basic analysis
python seo_agent.py --url https://example.com

# With options
python seo_agent.py --url https://example.com --format markdown --mobile-only
```

## API Quick Reference

### Analyze Endpoint
```bash
POST /api/v1/analyze
Content-Type: application/json
X-API-Key: your-api-key

{
  "url": "https://example.com",
  "options": {
    "includeMobile": true,
    "includeDesktop": true
  }
}
```

### Response Structure
```json
{
  "status": "success",
  "data": {
    "overallScore": 65,
    "recommendations": [...]
  }
}
```

## SEO Recommendation Categories

| Category | Focus Area | Examples |
|----------|-----------|----------|
| **Technical SEO** | Site infrastructure | HTTPS, robots.txt, sitemaps, structured data |
| **On-Page SEO** | Content optimization | Title tags, meta descriptions, headers, keywords |
| **Performance** | Speed & efficiency | Image optimization, caching, minification |
| **Content Quality** | Content value | Readability, depth, freshness, engagement |
| **Mobile** | Mobile experience | Responsive design, mobile speed, touch targets |

## Recommendation Severity Levels

- 🔴 **Critical**: Must fix immediately (security, major SEO issues)
- 🟠 **High**: Fix soon (significant impact on rankings/UX)
- 🟡 **Medium**: Fix when possible (moderate impact)
- 🟢 **Low**: Nice to have (minor improvements)

## Core Web Vitals Thresholds

| Metric | Good | Needs Improvement | Poor |
|--------|------|-------------------|------|
| **LCP** (Largest Contentful Paint) | ≤ 2.5s | 2.5s - 4.0s | > 4.0s |
| **FID** (First Input Delay) | ≤ 100ms | 100ms - 300ms | > 300ms |
| **CLS** (Cumulative Layout Shift) | ≤ 0.1 | 0.1 - 0.25 | > 0.25 |

## Common Issues & Quick Fixes

### Missing Alt Text
```html
<!-- Before -->
<img src="image.jpg">

<!-- After -->
<img src="image.jpg" alt="Descriptive text here">
```

### Meta Description
```html
<!-- Before -->
<meta name="description" content="Welcome">

<!-- After -->
<meta name="description" content="Comprehensive 150-160 character description with keywords and call to action">
```

### Image Optimization
```bash
# Convert to WebP
convert image.jpg -quality 85 image.webp

# Responsive images
<img srcset="img-400.webp 400w, img-800.webp 800w" 
     sizes="(max-width: 600px) 400px, 800px"
     src="img-800.webp" alt="Description">
```

### Lazy Loading
```html
<img src="image.jpg" loading="lazy" alt="Description">
```

### Structured Data
```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Organization",
  "name": "Company Name",
  "url": "https://example.com"
}
</script>
```

## Error Codes

| Code | Status | Meaning |
|------|--------|---------|
| INVALID_URL | 400 | URL format is invalid |
| URL_NOT_ACCESSIBLE | 400 | Cannot access URL |
| RATE_LIMIT_EXCEEDED | 429 | Too many requests |
| PAGESPEED_API_ERROR | 500 | PageSpeed API failed |
| AI_ANALYSIS_ERROR | 500 | AI processing failed |

## AWS Services Used

- **Lambda**: Serverless compute
- **Bedrock**: AI/ML models
- **S3**: Storage for reports
- **API Gateway**: REST API
- **Secrets Manager**: API keys
- **CloudWatch**: Monitoring

## File Locations

```
aws-ai-seo-agent/
├── PRD.md                 # Product requirements
├── ARCHITECTURE.md        # Technical architecture
├── API.md                 # API documentation
├── IMPLEMENTATION.md      # Implementation guide
├── CONTRIBUTING.md        # Contribution guidelines
├── examples/              # Example files
│   └── sample_output.json
├── src/                   # Source code
│   └── lambda/           # Lambda functions
└── tests/                # Test files
```

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| AWS_REGION | AWS region | us-east-1 |
| PAGESPEED_API_KEY | Google API key | AIza... |
| BEDROCK_MODEL_ID | AI model ID | anthropic.claude-3... |
| S3_REPORTS_BUCKET | S3 bucket name | seo-agent-reports |

## Useful Links

- **PageSpeed Insights**: https://pagespeed.web.dev/
- **Google Search Console**: https://search.google.com/search-console
- **Web.dev**: https://web.dev/
- **Schema.org**: https://schema.org/
- **AWS Documentation**: https://docs.aws.amazon.com/

## Support

- GitHub Issues: Report bugs and request features
- Documentation: Check PRD.md and other docs
- Examples: See examples/ directory

---

**Version**: 1.0.0  
**Last Updated**: 2025-10-18
