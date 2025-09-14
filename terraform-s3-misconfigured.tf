# Secure S3 Bucket Configuration - SECURITY FIXED
# This file now contains properly secured S3 bucket configurations

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

# Secure S3 Bucket with all security controls enabled
resource "aws_s3_bucket" "misconfigured_bucket" {
  bucket = "my-secure-bucket-${random_id.bucket_suffix.hex}"

  tags = {
    Name           = "SecureS3Bucket"
    Environment    = "SecurityTesting"
    Purpose        = "Secure bucket with all security controls enabled"
    SecurityStatus = "FIXED"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# SECURITY FIX: Block public access completely
resource "aws_s3_bucket_public_access_block" "secure_pab" {
  bucket = aws_s3_bucket.misconfigured_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# SECURITY FIX: Private ACL (no public access)
resource "aws_s3_bucket_acl" "secure_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.s3_bucket_acl_ownership]
  bucket     = aws_s3_bucket.misconfigured_bucket.id
  acl        = "private"
}

resource "aws_s3_bucket_ownership_controls" "s3_bucket_acl_ownership" {
  bucket = aws_s3_bucket.misconfigured_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# SECURITY FIX: Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "secure_encryption" {
  bucket = aws_s3_bucket.misconfigured_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# SECURITY FIX: Enable versioning
resource "aws_s3_bucket_versioning" "secure_versioning" {
  bucket = aws_s3_bucket.misconfigured_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# SECURITY FIX: Enable access logging
resource "aws_s3_bucket" "access_logs_bucket" {
  bucket = "access-logs-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "AccessLogsBucket"
    Environment = "SecurityTesting"
    Purpose     = "Store S3 access logs"
  }
}

resource "aws_s3_bucket_public_access_block" "access_logs_pab" {
  bucket = aws_s3_bucket.access_logs_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "secure_logging" {
  bucket = aws_s3_bucket.misconfigured_bucket.id

  target_bucket = aws_s3_bucket.access_logs_bucket.id
  target_prefix = "access-logs/"
}

# SECURITY FIX: Private bucket policy (no public access)
resource "aws_s3_bucket_policy" "secure_policy" {
  bucket = aws_s3_bucket.misconfigured_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyPublicAccess"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.misconfigured_bucket.arn,
          "${aws_s3_bucket.misconfigured_bucket.arn}/*",
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
    ]
  })
}

# Output the bucket name and URL
output "bucket_name" {
  value = aws_s3_bucket.misconfigured_bucket.id
}

output "bucket_domain_name" {
  value = aws_s3_bucket.misconfigured_bucket.bucket_domain_name
}

output "security_status" {
  value = "✅ SECURITY FIXED: This bucket now blocks public access, has encryption enabled, versioning enabled, and access logging configured!"
}
