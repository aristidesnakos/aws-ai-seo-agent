# Contributing to AWS AI SEO Agent

Thank you for your interest in contributing to the AWS AI SEO Agent! This document provides guidelines and instructions for contributing.

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [Development Workflow](#development-workflow)
4. [Coding Standards](#coding-standards)
5. [Testing Guidelines](#testing-guidelines)
6. [Pull Request Process](#pull-request-process)
7. [Issue Reporting](#issue-reporting)

---

## Code of Conduct

This project adheres to a code of conduct that all contributors are expected to follow:

- Be respectful and inclusive
- Welcome newcomers and help them get started
- Focus on what is best for the community
- Show empathy towards other community members

---

## Getting Started

### Prerequisites

Before you begin, ensure you have:
- Python 3.11 or higher
- AWS CLI configured
- Git installed
- An AWS account (for testing)

### Fork and Clone

1. Fork the repository on GitHub
2. Clone your fork locally:
```bash
git clone https://github.com/YOUR_USERNAME/aws-ai-seo-agent.git
cd aws-ai-seo-agent
```

3. Add upstream remote:
```bash
git remote add upstream https://github.com/aristidesnakos/aws-ai-seo-agent.git
```

### Set Up Development Environment

```bash
# Create virtual environment
python3.11 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
pip install -r requirements-dev.txt

# Copy environment template
cp .env.example .env
# Edit .env with your credentials
```

---

## Development Workflow

### 1. Create a Branch

Always create a new branch for your work:

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/issue-description
```

Branch naming conventions:
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `refactor/` - Code refactoring
- `test/` - Test additions or updates

### 2. Make Your Changes

- Write clear, concise commit messages
- Follow the coding standards (see below)
- Add tests for new functionality
- Update documentation as needed

### 3. Test Your Changes

```bash
# Run unit tests
pytest tests/unit/ -v

# Run integration tests
pytest tests/integration/ -v

# Run with coverage
pytest --cov=src --cov-report=html

# Check code style
black src/ tests/
flake8 src/ tests/
pylint src/
mypy src/
```

### 4. Keep Your Branch Updated

```bash
git fetch upstream
git rebase upstream/main
```

### 5. Push Your Changes

```bash
git push origin feature/your-feature-name
```

---

## Coding Standards

### Python Style Guide

We follow PEP 8 with some specific conventions:

#### Formatting
- Use Black for automatic formatting (line length: 88)
- Use isort for import sorting
- Maximum line length: 88 characters

#### Naming Conventions
- Classes: `PascalCase`
- Functions/methods: `snake_case`
- Constants: `UPPER_CASE`
- Private methods: `_leading_underscore`

#### Documentation
- Use Google-style docstrings
- Include type hints for all functions
- Document all public APIs

Example:
```python
from typing import Dict, List, Optional

def analyze_url(url: str, options: Optional[Dict] = None) -> Dict[str, any]:
    """
    Analyze a URL for SEO issues.
    
    Args:
        url: The URL to analyze (must include protocol)
        options: Optional configuration dictionary
            - includeMobile (bool): Include mobile analysis
            - includeDesktop (bool): Include desktop analysis
    
    Returns:
        Dictionary containing analysis results with keys:
            - overallScore (int): Overall SEO score (0-100)
            - recommendations (List[Dict]): List of recommendations
    
    Raises:
        ValueError: If URL is invalid
        RequestException: If URL cannot be accessed
    
    Example:
        >>> result = analyze_url('https://example.com')
        >>> print(result['overallScore'])
        65
    """
    if not url:
        raise ValueError("URL is required")
    
    # Implementation
    return {}
```

### File Organization

```python
# Standard library imports
import json
import os
from typing import Dict, List

# Third-party imports
import boto3
import requests
from bs4 import BeautifulSoup

# Local imports
from .models import Recommendation
from .utils import validate_url
```

### Error Handling

```python
# Good
try:
    response = requests.get(url, timeout=30)
    response.raise_for_status()
except requests.Timeout:
    logger.error(f"Timeout accessing {url}")
    raise
except requests.RequestException as e:
    logger.error(f"Error accessing {url}: {str(e)}")
    raise

# Bad - don't catch generic Exception
try:
    response = requests.get(url)
except Exception as e:
    pass  # Don't silently fail
```

### Logging

```python
import logging

logger = logging.getLogger(__name__)

# Use appropriate log levels
logger.debug("Detailed diagnostic information")
logger.info("General informational messages")
logger.warning("Warning messages for potential issues")
logger.error("Error messages for failures")
logger.critical("Critical errors requiring immediate attention")

# Include context in log messages
logger.info(f"Analyzing URL: {url}")
logger.error(f"Failed to parse HTML for {url}: {str(e)}")
```

---

## Testing Guidelines

### Test Structure

```
tests/
├── unit/
│   ├── test_validator.py
│   ├── test_parser.py
│   └── test_ai_engine.py
├── integration/
│   ├── test_api_flow.py
│   └── test_lambda_integration.py
└── fixtures/
    ├── sample_html.html
    └── sample_pagespeed_response.json
```

### Writing Tests

#### Unit Tests

```python
import pytest
from src.lambda.input_handler.validator import validate_url

class TestURLValidator:
    """Test URL validation functionality"""
    
    def test_valid_url(self):
        """Test that valid URLs are accepted"""
        result = validate_url("https://example.com")
        assert result['valid'] is True
    
    def test_invalid_url_format(self):
        """Test that invalid URL formats are rejected"""
        result = validate_url("not-a-url")
        assert result['valid'] is False
        assert 'Invalid URL format' in result['message']
    
    def test_missing_protocol(self):
        """Test that URLs without protocol are rejected"""
        result = validate_url("example.com")
        assert result['valid'] is False
    
    @pytest.mark.parametrize("url,expected", [
        ("https://example.com", True),
        ("http://example.com", True),
        ("ftp://example.com", False),
        ("", False),
    ])
    def test_url_protocols(self, url, expected):
        """Test various URL protocols"""
        result = validate_url(url)
        assert result['valid'] is expected
```

#### Integration Tests

```python
import boto3
import pytest
from moto import mock_lambda

@mock_lambda
def test_input_handler_integration():
    """Test input handler Lambda integration"""
    # Setup
    lambda_client = boto3.client('lambda', region_name='us-east-1')
    
    # Create mock Lambda function
    lambda_client.create_function(
        FunctionName='test-function',
        Runtime='python3.11',
        Role='arn:aws:iam::123456789012:role/test-role',
        Handler='handler.lambda_handler',
        Code={'ZipFile': b'fake code'}
    )
    
    # Test
    # Add your test logic here
```

#### Fixtures

```python
import pytest

@pytest.fixture
def sample_html():
    """Sample HTML content for testing"""
    return """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Test Page</title>
        <meta name="description" content="Test description">
    </head>
    <body>
        <h1>Main Heading</h1>
        <p>Content here</p>
    </body>
    </html>
    """

@pytest.fixture
def sample_pagespeed_response():
    """Sample PageSpeed API response"""
    return {
        "lighthouseResult": {
            "categories": {
                "performance": {"score": 0.85}
            }
        }
    }
```

### Test Coverage

- Aim for 80%+ code coverage
- All new features must include tests
- Bug fixes should include regression tests

```bash
# Generate coverage report
pytest --cov=src --cov-report=html
open htmlcov/index.html
```

---

## Pull Request Process

### Before Submitting

1. **Update Documentation**: Ensure all documentation is current
2. **Run Tests**: All tests must pass
3. **Code Quality**: Run linters and formatters
4. **Commit Messages**: Write clear, descriptive commit messages

### Commit Message Format

```
type(scope): brief description

Longer explanation if needed. Wrap at 72 characters.

Fixes #123
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Test additions or updates
- `chore`: Maintenance tasks

Examples:
```
feat(parser): add support for JSON-LD extraction

Add functionality to extract and parse JSON-LD structured data
from HTML pages. This enhances SEO analysis by identifying
schema.org markup.

Fixes #45
```

### Creating a Pull Request

1. Push your branch to your fork
2. Go to the original repository on GitHub
3. Click "New Pull Request"
4. Select your branch
5. Fill out the PR template:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed

## Checklist
- [ ] Code follows style guidelines
- [ ] Documentation updated
- [ ] Tests added/updated
- [ ] All tests pass
- [ ] No new warnings
```

### Review Process

1. Automated checks run (tests, linters)
2. Code review by maintainers
3. Address feedback
4. Approval and merge

---

## Issue Reporting

### Before Creating an Issue

1. Search existing issues to avoid duplicates
2. Gather relevant information:
   - Python version
   - AWS region
   - Error messages
   - Steps to reproduce

### Issue Template

```markdown
**Description**
Clear description of the issue

**Steps to Reproduce**
1. Step 1
2. Step 2
3. Step 3

**Expected Behavior**
What you expected to happen

**Actual Behavior**
What actually happened

**Environment**
- Python version: 3.11
- AWS region: us-east-1
- OS: Ubuntu 22.04

**Error Messages**
```
Paste error messages here
```

**Additional Context**
Any other relevant information
```

### Issue Labels

- `bug`: Something isn't working
- `enhancement`: New feature or request
- `documentation`: Documentation improvements
- `good first issue`: Good for newcomers
- `help wanted`: Extra attention needed
- `question`: Further information requested

---

## Development Tips

### Local Testing

```bash
# Test Lambda function locally
python -c "
from src.lambda.input_handler.handler import lambda_handler
event = {'body': '{\"url\":\"https://example.com\"}'}
result = lambda_handler(event, None)
print(result)
"
```

### Debugging

```python
# Use ipdb for debugging
import ipdb

def my_function():
    x = calculate_something()
    ipdb.set_trace()  # Debugger stops here
    return process(x)
```

### AWS Local Testing

Use LocalStack for local AWS service testing:

```bash
# Install LocalStack
pip install localstack

# Start LocalStack
localstack start

# Configure AWS CLI for LocalStack
aws configure set aws_access_key_id test
aws configure set aws_secret_access_key test
aws configure set region us-east-1
```

---

## Resources

### Python Resources
- [PEP 8 Style Guide](https://pep8.org/)
- [Python Type Hints](https://docs.python.org/3/library/typing.html)
- [pytest Documentation](https://docs.pytest.org/)

### AWS Resources
- [AWS Lambda Python](https://docs.aws.amazon.com/lambda/latest/dg/lambda-python.html)
- [AWS Bedrock](https://docs.aws.amazon.com/bedrock/)
- [boto3 Documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html)

### SEO Resources
- [Google SEO Guide](https://developers.google.com/search/docs)
- [PageSpeed Insights API](https://developers.google.com/speed/docs/insights/v5/get-started)
- [Web Vitals](https://web.dev/vitals/)

---

## Questions?

- Open an issue for questions
- Join our discussions
- Check existing documentation

Thank you for contributing to AWS AI SEO Agent! 🚀
