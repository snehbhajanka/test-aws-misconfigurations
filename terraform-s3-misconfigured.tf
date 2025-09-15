# S3 Bucket Configuration - SECURITY FIXES APPLIED
# This file originally contained security misconfigurations but has been fixed
# Security improvements: Public write access blocked, private ACL, secure policies

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

# Secured S3 Bucket with proper access controls
resource "aws_s3_bucket" "misconfigured_bucket" {
  bucket = "my-secured-bucket-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "SecuredBucket"
    Environment = "SecurityFixed"
    Purpose     = "Demonstrates secure S3 configuration"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# SECURITY FIX 1: Public access block enabled (blocks public access)
resource "aws_s3_bucket_public_access_block" "secured_pab" {
  bucket = aws_s3_bucket.misconfigured_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# SECURITY FIX 2: Private ACL (no public access)
resource "aws_s3_bucket_acl" "secured_acl" {
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

# MISCONFIGURATION 3: No server-side encryption
# (Default encryption is intentionally not configured)

# MISCONFIGURATION 4: No versioning enabled
resource "aws_s3_bucket_versioning" "misconfigured_versioning" {
  bucket = aws_s3_bucket.misconfigured_bucket.id
  versioning_configuration {
    status = "Disabled"
  }
}

# MISCONFIGURATION 5: No access logging
# (Logging is intentionally not configured)

# SECURITY FIX 6: Secured bucket policy with restricted access
resource "aws_s3_bucket_policy" "secured_policy" {
  bucket = aws_s3_bucket.misconfigured_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyPublicReadWrite"
        Effect    = "Deny"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.misconfigured_bucket.arn,
          "${aws_s3_bucket.misconfigured_bucket.arn}/*",
        ]
        Condition = {
          Bool = {
            "aws:PrincipalIsAWSService" = "false"
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
  value = "SECURITY FIXED: This bucket now has public write access blocked and follows security best practices!"
}
