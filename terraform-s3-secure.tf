# Secure S3 Bucket Configuration - PRODUCTION READY
# This file demonstrates proper S3 security configurations to prevent public write access
# Implements remediation for S3.3 security misconfiguration

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
    Environment = "Production"
    Purpose     = "Properly configured secure S3 bucket"
    Security    = "BlockPublicAccess"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# SECURITY FIX 1: Enable Block Public Access Settings (S3.3 Remediation)
# All Block Public Access settings enabled to prevent public write access
resource "aws_s3_bucket_public_access_block" "secure_pab" {
  bucket = aws_s3_bucket.secure_bucket.id

  # Block all public ACLs - prevents setting bucket ACLs that grant public access
  block_public_acls = true
  
  # Block all public bucket policies - prevents attaching bucket policies that grant public access
  block_public_policy = true
  
  # Ignore existing public ACLs - treats existing public ACLs as if they don't grant public access
  ignore_public_acls = true
  
  # Restrict public buckets - restricts access to buckets with public policies to only AWS service principals and authorized users
  restrict_public_buckets = true
}

# SECURITY FIX 2: Private ACL (no public access)
# Using private ACL instead of public-read-write
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

# SECURITY FIX 4: Enable versioning
resource "aws_s3_bucket_versioning" "secure_versioning" {
  bucket = aws_s3_bucket.secure_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# SECURITY FIX 5: Enable access logging
resource "aws_s3_bucket_logging" "secure_logging" {
  bucket = aws_s3_bucket.secure_bucket.id

  target_bucket = aws_s3_bucket.access_logs_bucket.id
  target_prefix = "access-logs/"
}

# Separate bucket for storing access logs
resource "aws_s3_bucket" "access_logs_bucket" {
  bucket = "access-logs-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "AccessLogsBucket"
    Environment = "Production"
    Purpose     = "Store S3 access logs"
  }
}

# Block public access for logs bucket too
resource "aws_s3_bucket_public_access_block" "logs_bucket_pab" {
  bucket = aws_s3_bucket.access_logs_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# SECURITY FIX 6: Secure bucket policy (no public access)
# Example of a secure bucket policy that allows access only to authenticated AWS users
resource "aws_s3_bucket_policy" "secure_policy" {
  bucket = aws_s3_bucket.secure_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowAuthenticatedAccess"
        Effect    = "Allow"
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
      }
    ]
  })
}

# Get current AWS account ID for bucket policy
data "aws_caller_identity" "current" {}

# SECURITY ENHANCEMENT: Add lifecycle policy to manage costs
resource "aws_s3_bucket_lifecycle_configuration" "secure_lifecycle" {
  bucket = aws_s3_bucket.secure_bucket.id

  rule {
    id     = "lifecycle_rule"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
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
  value       = aws_s3_bucket.secure_bucket.id
  description = "Name of the secure S3 bucket"
}

output "secure_bucket_domain_name" {
  value       = aws_s3_bucket.secure_bucket.bucket_domain_name
  description = "Domain name of the secure S3 bucket"
}

output "public_access_block_status" {
  value = {
    block_public_acls       = aws_s3_bucket_public_access_block.secure_pab.block_public_acls
    block_public_policy     = aws_s3_bucket_public_access_block.secure_pab.block_public_policy
    ignore_public_acls      = aws_s3_bucket_public_access_block.secure_pab.ignore_public_acls
    restrict_public_buckets = aws_s3_bucket_public_access_block.secure_pab.restrict_public_buckets
  }
  description = "Block Public Access settings for the secure bucket"
}

output "security_compliance" {
  value       = "✅ This bucket is properly configured with Block Public Access settings enabled, preventing public write access (S3.3 compliance)"
  description = "Security compliance status"
}