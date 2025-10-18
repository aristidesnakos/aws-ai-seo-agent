# S3 Buckets for AWS AI SEO Agent

# Temp data bucket for intermediate processing
resource "aws_s3_bucket" "temp_data" {
  bucket = "${var.project_name}-${var.environment}-temp-data"
}

resource "aws_s3_bucket_lifecycle_configuration" "temp_data_lifecycle" {
  bucket = aws_s3_bucket.temp_data.id

  rule {
    id     = "delete-after-1-day"
    status = "Enabled"

    expiration {
      days = var.temp_data_retention_days
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "temp_data_encryption" {
  bucket = aws_s3_bucket.temp_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Reports bucket for final analysis reports
resource "aws_s3_bucket" "reports" {
  bucket = "${var.project_name}-${var.environment}-reports"
}

resource "aws_s3_bucket_lifecycle_configuration" "reports_lifecycle" {
  bucket = aws_s3_bucket.reports.id

  rule {
    id     = "delete-after-90-days"
    status = "Enabled"

    expiration {
      days = var.reports_retention_days
    }
  }
}

resource "aws_s3_bucket_versioning" "reports_versioning" {
  bucket = aws_s3_bucket.reports.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "reports_encryption" {
  bucket = aws_s3_bucket.reports.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
