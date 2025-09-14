# Secured S3 Bucket Configuration - SECURITY ISSUES REMEDIATED
# This file contains proper S3 security configurations and should be used as a reference
# All critical security misconfigurations have been fixed

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
resource "aws_s3_bucket" "secured_bucket" {
  bucket = "my-secured-bucket-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "SecuredBucket"
    Environment = "SecurityTesting"
    Purpose     = "Previously vulnerable, now secured for testing"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# SECURITY FIX 1: Public access block enabled (blocks public access)
resource "aws_s3_bucket_public_access_block" "secure_pab" {
  bucket = aws_s3_bucket.secured_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# SECURITY FIX 2: Private ACL (no public access)
resource "aws_s3_bucket_acl" "secure_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.s3_bucket_acl_ownership]
  bucket     = aws_s3_bucket.secured_bucket.id
  acl        = "private"
}

resource "aws_s3_bucket_ownership_controls" "s3_bucket_acl_ownership" {
  bucket = aws_s3_bucket.secured_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# SECURITY FIX 3: Server-side encryption enabled
resource "aws_s3_bucket_server_side_encryption_configuration" "secure_encryption" {
  bucket = aws_s3_bucket.secured_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# SECURITY FIX 4: Versioning enabled
resource "aws_s3_bucket_versioning" "secure_versioning" {
  bucket = aws_s3_bucket.secured_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# SECURITY FIX 5: Access logging enabled
resource "aws_s3_bucket" "access_logs_bucket" {
  bucket = "access-logs-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "AccessLogsBucket"
    Environment = "SecurityTesting"
    Purpose     = "S3 access logging"
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
  bucket = aws_s3_bucket.secured_bucket.id

  target_bucket = aws_s3_bucket.access_logs_bucket.id
  target_prefix = "access-logs/"
}

# SECURITY FIX 6: Removed public bucket policy (no public access)

# Output the bucket name and URL
output "bucket_name" {
  value = aws_s3_bucket.secured_bucket.id
}

output "bucket_domain_name" {
  value = aws_s3_bucket.secured_bucket.bucket_domain_name
}

output "security_status" {
  value = "SECURED: This bucket now has proper security configurations including blocked public access, encryption, versioning, and logging!"
}
