# Properly Configured S3 Bucket - SECURE CONFIGURATION REFERENCE
# This file demonstrates proper S3 security configurations

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

# Properly configured S3 Bucket with security best practices
resource "aws_s3_bucket" "secure_bucket" {
  bucket = "my-secure-bucket-${random_id.secure_bucket_suffix.hex}"

  tags = {
    Name        = "SecureBucket"
    Environment = "Production"
    Purpose     = "Properly configured secure S3 bucket"
  }
}

resource "random_id" "secure_bucket_suffix" {
  byte_length = 8
}

# SECURITY BEST PRACTICE: Block all public access
resource "aws_s3_bucket_public_access_block" "secure_pab" {
  bucket = aws_s3_bucket.secure_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# SECURITY BEST PRACTICE: Private ACL only
resource "aws_s3_bucket_acl" "secure_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.secure_bucket_acl_ownership]
  bucket     = aws_s3_bucket.secure_bucket.id
  acl        = "private"
}

resource "aws_s3_bucket_ownership_controls" "secure_bucket_acl_ownership" {
  bucket = aws_s3_bucket.secure_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# SECURITY BEST PRACTICE: Server-side encryption enabled
resource "aws_s3_bucket_server_side_encryption_configuration" "secure_encryption" {
  bucket = aws_s3_bucket.secure_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# SECURITY BEST PRACTICE: Versioning enabled
resource "aws_s3_bucket_versioning" "secure_versioning" {
  bucket = aws_s3_bucket.secure_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# SECURITY BEST PRACTICE: Access logging enabled
resource "aws_s3_bucket_logging" "secure_logging" {
  bucket = aws_s3_bucket.secure_bucket.id

  target_bucket = aws_s3_bucket.secure_logging_bucket.id
  target_prefix = "access-logs/"
}

resource "aws_s3_bucket" "secure_logging_bucket" {
  bucket = "secure-access-logs-${random_id.secure_bucket_suffix.hex}"
}

# SECURITY BEST PRACTICE: Restrictive bucket policy (example for specific use case)
resource "aws_s3_bucket_policy" "secure_policy" {
  bucket = aws_s3_bucket.secure_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureConnections"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.secure_bucket.arn,
          "${aws_s3_bucket.secure_bucket.arn}/*",
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid       = "AllowSSLRequestsOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.secure_bucket.arn,
          "${aws_s3_bucket.secure_bucket.arn}/*",
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# Output the bucket name and URL
output "secure_bucket_name" {
  value = aws_s3_bucket.secure_bucket.id
}

output "secure_bucket_domain_name" {
  value = aws_s3_bucket.secure_bucket.bucket_domain_name
}

output "security_status" {
  value = "✅ This bucket is properly configured with security best practices: encrypted, private, versioned, and logged!"
}