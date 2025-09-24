# Securely Configured S3 Bucket - PRODUCTION READY
# This file demonstrates secure S3 configurations that address AWS Security Hub findings
# This configuration addresses S3.3: S3 general purpose buckets should block public write access

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

# Securely configured S3 Bucket
resource "aws_s3_bucket" "secure_bucket" {
  bucket = "my-secure-bucket-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "SecureBucket"
    Environment = "Production"
    Purpose     = "Secure S3 configuration example"
    Security    = "CompliantWithS3.3"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# SECURITY FIX 1: Enable Block Public Access settings (addresses S3.3)
resource "aws_s3_bucket_public_access_block" "secure_pab" {
  bucket = aws_s3_bucket.secure_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# SECURITY FIX 2: Private bucket ACL (no public access)
resource "aws_s3_bucket_acl" "secure_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.s3_bucket_acl_ownership,
    aws_s3_bucket_public_access_block.secure_pab
  ]
  bucket = aws_s3_bucket.secure_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_ownership_controls" "s3_bucket_acl_ownership" {
  bucket = aws_s3_bucket.secure_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# SECURITY ENHANCEMENT 3: Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "secure_encryption" {
  bucket = aws_s3_bucket.secure_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# SECURITY ENHANCEMENT 4: Enable versioning
resource "aws_s3_bucket_versioning" "secure_versioning" {
  bucket = aws_s3_bucket.secure_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# SECURITY ENHANCEMENT 5: Enable access logging
resource "aws_s3_bucket_logging" "secure_logging" {
  bucket = aws_s3_bucket.secure_bucket.id

  target_bucket = aws_s3_bucket.secure_bucket.id
  target_prefix = "log/"
}

# SECURITY FIX 6: Secure bucket policy (no public access)
# Instead of allowing public access, this policy demonstrates
# restricted access for specific AWS accounts or roles
resource "aws_s3_bucket_policy" "secure_policy" {
  bucket = aws_s3_bucket.secure_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "RestrictedAccess"
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
      },
    ]
  })
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# SECURITY ENHANCEMENT 7: Lifecycle policy to optimize costs
resource "aws_s3_bucket_lifecycle_configuration" "secure_lifecycle" {
  bucket = aws_s3_bucket.secure_bucket.id

  rule {
    id     = "transition_to_ia"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# Output the bucket information
output "secure_bucket_name" {
  value = aws_s3_bucket.secure_bucket.id
}

output "secure_bucket_domain_name" {
  value = aws_s3_bucket.secure_bucket.bucket_domain_name
}

output "security_status" {
  value = "✅ SECURE: This bucket blocks public write access and follows AWS security best practices (S3.3 compliant)"
}

output "security_controls_implemented" {
  value = [
    "✅ Block Public Access enabled (S3.3)",
    "✅ Private ACL configuration",
    "✅ Secure bucket policy (account-restricted)",
    "✅ Server-side encryption enabled",
    "✅ Versioning enabled",
    "✅ Access logging configured",
    "✅ Lifecycle policies implemented"
  ]
}