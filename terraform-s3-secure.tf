# Secure S3 Bucket Configuration - REMEDIATED
# This file demonstrates the secure configuration for S3 buckets to prevent public write access

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

# Secure S3 Bucket with proper access controls
resource "aws_s3_bucket" "secure_bucket" {
  bucket = "my-secure-bucket-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "SecureBucket"
    Environment = "SecurityTesting"
    Purpose     = "Demonstrating secure S3 configuration"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# SECURITY FIX 1: Enable all Block Public Access settings
resource "aws_s3_bucket_public_access_block" "secure_pab" {
  bucket = aws_s3_bucket.secure_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# SECURITY FIX 2: Use private ACL instead of public-read-write
resource "aws_s3_bucket_acl" "secure_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.s3_bucket_acl_ownership]
  bucket     = aws_s3_bucket.secure_bucket.id
  acl        = "private"
}

resource "aws_s3_bucket_ownership_controls" "s3_bucket_acl_ownership" {
  bucket = aws_s3_bucket.secure_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# SECURITY ENHANCEMENT: Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "secure_encryption" {
  bucket = aws_s3_bucket.secure_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# SECURITY ENHANCEMENT: Enable versioning
resource "aws_s3_bucket_versioning" "secure_versioning" {
  bucket = aws_s3_bucket.secure_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# SECURITY FIX 3: Secure bucket policy - NO public access
# This example shows a restrictive policy that allows access only from specific AWS principals
# Uncomment and modify as needed for your specific use case
/*
resource "aws_s3_bucket_policy" "secure_policy" {
  bucket = aws_s3_bucket.secure_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyPublicAccess"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.secure_bucket.arn,
          "${aws_s3_bucket.secure_bucket.arn}/*",
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
*/

# Output the bucket name and security status
output "secure_bucket_name" {
  value = aws_s3_bucket.secure_bucket.id
}

output "secure_bucket_domain_name" {
  value = aws_s3_bucket.secure_bucket.bucket_domain_name
}

output "security_status" {
  value = "✅ This bucket is properly secured with public access blocked, private ACL, and encryption enabled!"
}