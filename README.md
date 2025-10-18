# AWS AI SEO Agent

An intelligent AI agent built on AWS infrastructure that automatically analyzes web pages and provides actionable SEO recommendations by combining performance metrics from PageSpeed Insights with content analysis from web crawls.

## Overview

The AWS AI SEO Agent takes a URL, fetches performance data from Google PageSpeed Insights API, crawls the web page content, and uses AWS AI services (Bedrock) to generate comprehensive, prioritized SEO recommendations.

## Key Features

- 🚀 **Performance Analysis**: Integration with PageSpeed Insights API for Core Web Vitals
- 🔍 **Content Crawling**: Deep HTML analysis for on-page SEO factors
- 🤖 **AI-Powered Insights**: AWS Bedrock-powered recommendation engine
- 📊 **Structured Reports**: JSON and Markdown formatted analysis reports
- ⚡ **Fast & Scalable**: Serverless architecture on AWS Lambda

## Quick Start

### Prerequisites
- AWS Account with Bedrock access
- Google PageSpeed Insights API key
- Python 3.11+

### Installation
```bash
# Clone the repository
git clone https://github.com/aristidesnakos/aws-ai-seo-agent.git
cd aws-ai-seo-agent

# Install dependencies
pip install -r requirements.txt

# Configure environment variables
cp .env.example .env
# Edit .env with your API keys
```

### Usage
```bash
# Analyze a URL
python seo_agent.py --url https://example.com

# Generate markdown report
python seo_agent.py --url https://example.com --format markdown
```

## Documentation

📄 **[Product Requirements Document (PRD)](./PRD.md)** - Comprehensive MVP specifications, architecture, and implementation guide

🤖 **[AWS Agent Implementation Guide](./AWS_AGENT_GUIDE.md)** - Detailed guide for implementing the AI agent on AWS with Bedrock

## Architecture

The system consists of five main components:
1. **Input Handler**: URL validation and workflow orchestration
2. **PageSpeed Collector**: Fetches performance metrics
3. **Content Crawler**: Analyzes HTML structure and SEO elements
4. **AI Analysis Engine**: Generates recommendations using AWS Bedrock
5. **Report Generator**: Formats output in JSON/Markdown

## SEO Analysis Categories

- **Technical SEO**: Robots.txt, sitemaps, HTTPS, structured data
- **On-Page SEO**: Title tags, meta descriptions, headers, content quality
- **Performance**: Image optimization, caching, Core Web Vitals
- **Content Quality**: Readability, depth, freshness
- **Mobile Optimization**: Responsive design, mobile performance

## Output Example

```json
{
  "url": "https://example.com",
  "overallScore": 65,
  "recommendations": [
    {
      "category": "Performance",
      "title": "Optimize image sizes",
      "severity": "High",
      "impact": "High",
      "effort": "Medium",
      "actionItems": [
        "Compress images using WebP format",
        "Implement lazy loading"
      ],
      "expectedImprovement": "20% reduction in LCP"
    }
  ]
}
```

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

## License

This project is licensed under the terms specified in the [LICENSE](./LICENSE) file.

## Roadmap

See the [PRD.md](./PRD.md) for detailed implementation phases and future enhancements.

## Support

For issues and questions, please open a GitHub issue.
