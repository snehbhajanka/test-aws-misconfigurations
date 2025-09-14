# Secure S3 Bucket Configuration - Addresses S3.3 Security Control
# This file demonstrates proper S3 security configuration that blocks public write access

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

# Secure S3 Bucket with proper public access controls
resource "aws_s3_bucket" "secure_bucket" {
  bucket = "my-secure-bucket-${random_id.secure_bucket_suffix.hex}"

  tags = {
    Name        = "SecureBucket"
    Environment = "Production"
    Purpose     = "Demonstrates secure S3 configuration"
    Compliance  = "S3.3-Compliant"
  }
}

resource "random_id" "secure_bucket_suffix" {
  byte_length = 8
}

# SECURITY FIX 1: Enable public access block to prevent public access
resource "aws_s3_bucket_public_access_block" "secure_pab" {
  bucket = aws_s3_bucket.secure_bucket.id

  # Block all public access settings to prevent public write access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# SECURITY FIX 2: Use private ACL instead of public-read-write
resource "aws_s3_bucket_acl" "secure_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.secure_bucket_acl_ownership,
    aws_s3_bucket_public_access_block.secure_pab
  ]
  bucket = aws_s3_bucket.secure_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_ownership_controls" "secure_bucket_acl_ownership" {
  bucket = aws_s3_bucket.secure_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# SECURITY FIX 3: Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "secure_encryption" {
  bucket = aws_s3_bucket.secure_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# SECURITY FIX 4: Enable versioning for data protection
resource "aws_s3_bucket_versioning" "secure_versioning" {
  bucket = aws_s3_bucket.secure_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# SECURITY FIX 5: Enable access logging
resource "aws_s3_bucket_logging" "secure_logging" {
  bucket = aws_s3_bucket.secure_bucket.id

  target_bucket = aws_s3_bucket.secure_bucket.id
  target_prefix = "access-logs/"
}

# SECURITY FIX 6: Secure bucket policy - NO public write access
resource "aws_s3_bucket_policy" "secure_policy" {
  depends_on = [aws_s3_bucket_public_access_block.secure_pab]
  bucket     = aws_s3_bucket.secure_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyPublicWriteAccess"
        Effect    = "Deny"
        Principal = "*"
        Action = [
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:PutObjectAcl",
          "s3:PutBucketAcl"
        ]
        Resource = [
          aws_s3_bucket.secure_bucket.arn,
          "${aws_s3_bucket.secure_bucket.arn}/*",
        ]
      },
      {
        Sid    = "AllowAuthenticatedAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.secure_bucket.arn,
          "${aws_s3_bucket.secure_bucket.arn}/*",
        ]
      }
    ]
  })
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# SECURITY FIX 7: Add lifecycle policy for cost optimization
resource "aws_s3_bucket_lifecycle_configuration" "secure_lifecycle" {
  bucket = aws_s3_bucket.secure_bucket.id

  rule {
    id     = "secure_lifecycle_rule"
    status = "Enabled"

    filter {
      prefix = ""
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Output the secure bucket information
output "secure_bucket_name" {
  value       = aws_s3_bucket.secure_bucket.id
  description = "Name of the secure S3 bucket"
}

output "secure_bucket_domain_name" {
  value       = aws_s3_bucket.secure_bucket.bucket_domain_name
  description = "Domain name of the secure S3 bucket"
}

output "security_compliance" {
  value       = "✅ This bucket is properly configured to block public write access (S3.3 compliant)"
  description = "Security compliance status"
}

output "public_access_block_status" {
  value = {
    block_public_acls       = aws_s3_bucket_public_access_block.secure_pab.block_public_acls
    block_public_policy     = aws_s3_bucket_public_access_block.secure_pab.block_public_policy
    ignore_public_acls      = aws_s3_bucket_public_access_block.secure_pab.ignore_public_acls
    restrict_public_buckets = aws_s3_bucket_public_access_block.secure_pab.restrict_public_buckets
  }
  description = "Public access block configuration status"
}