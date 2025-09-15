# Intentionally Misconfigured S3 Bucket - FOR SECURITY TESTING ONLY
# This file contains multiple security misconfigurations and should NOT be used in production

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

# Misconfigured S3 Bucket with public access
resource "aws_s3_bucket" "misconfigured_bucket" {
  bucket = "my-misconfigured-bucket-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "MisconfiguredBucket"
    Environment = "SecurityTesting"
    Purpose     = "Intentionally vulnerable for testing"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# SECURITY FIX: Block public write access (S3.3 compliance)
# This fixes the critical security vulnerability while maintaining read-only public access for educational purposes
resource "aws_s3_bucket_public_access_block" "misconfigured_pab" {
  bucket = aws_s3_bucket.misconfigured_bucket.id

  # FIXED: Block public ACLs to prevent public write access
  block_public_acls = true
  # FIXED: Block public policies to prevent public write access  
  block_public_policy = true
  # FIXED: Ignore public ACLs to prevent public write access
  ignore_public_acls = true
  # FIXED: Restrict public buckets to prevent public write access
  restrict_public_buckets = true
}

# SECURITY FIX: Remove public write ACL (S3.3 compliance)
# Changed from public-read-write to private to block public write access
resource "aws_s3_bucket_acl" "misconfigured_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.s3_bucket_acl_ownership]
  bucket     = aws_s3_bucket.misconfigured_bucket.id
  acl        = "private" # FIXED: Removed public write access
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

# SECURITY FIX: Removed public write access from bucket policy (S3.3 compliance)
# Policy now only allows read operations, blocking all write operations from public access
resource "aws_s3_bucket_policy" "misconfigured_policy" {
  bucket = aws_s3_bucket.misconfigured_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadOnly" # FIXED: Changed from PublicReadWrite
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject", # Read access maintained for educational purposes
          "s3:ListBucket" # List access maintained for educational purposes
          # REMOVED: s3:PutObject - BLOCKS PUBLIC WRITE ACCESS
          # REMOVED: s3:DeleteObject - BLOCKS PUBLIC DELETE ACCESS
        ]
        Resource = [
          aws_s3_bucket.misconfigured_bucket.arn,
          "${aws_s3_bucket.misconfigured_bucket.arn}/*",
        ]
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

output "security_warnings" {
  value = "✅ SECURITY FIXED: S3.3 - Public write access has been blocked. Bucket now has restricted access with public write operations disabled."
}
