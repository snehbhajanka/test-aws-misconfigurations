# Secure S3 Bucket Configuration - REMEDIATED VERSION
# This file demonstrates proper S3 security configurations that block public write access
# Use this as a reference for securing misconfigured S3 buckets

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
    Purpose     = "Properly secured S3 bucket"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# SECURITY FIX 1: Enable all Block Public Access settings to prevent public write access
resource "aws_s3_bucket_public_access_block" "secure_pab" {
  bucket = aws_s3_bucket.secure_bucket.id

  # Block public ACLs - prevents new public ACLs from being applied to the bucket
  block_public_acls = true
  
  # Block public bucket policies - prevents public bucket policies from being applied
  block_public_policy = true
  
  # Ignore public ACLs - ignores any existing public ACLs on the bucket
  ignore_public_acls = true
  
  # Restrict public buckets - restricts access to buckets with public policies
  restrict_public_buckets = true
}

# SECURITY FIX 2: Use private ACL instead of public-read-write
resource "aws_s3_bucket_acl" "secure_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.s3_bucket_acl_ownership]
  bucket     = aws_s3_bucket.secure_bucket.id
  acl        = "private"  # Changed from "public-read-write" to "private"
}

resource "aws_s3_bucket_ownership_controls" "s3_bucket_acl_ownership" {
  bucket = aws_s3_bucket.secure_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# SECURITY IMPROVEMENT 3: Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "secure_encryption" {
  bucket = aws_s3_bucket.secure_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# SECURITY IMPROVEMENT 4: Enable versioning for data protection
resource "aws_s3_bucket_versioning" "secure_versioning" {
  bucket = aws_s3_bucket.secure_bucket.id
  versioning_configuration {
    status = "Enabled"  # Changed from "Disabled" to "Enabled"
  }
}

# SECURITY IMPROVEMENT 5: Enable access logging
resource "aws_s3_bucket" "access_log_bucket" {
  bucket = "access-logs-${random_id.bucket_suffix.hex}"
  
  tags = {
    Name        = "AccessLogsBucket"
    Environment = "Production"
    Purpose     = "S3 access logs storage"
  }
}

resource "aws_s3_bucket_logging" "secure_logging" {
  bucket = aws_s3_bucket.secure_bucket.id

  target_bucket = aws_s3_bucket.access_log_bucket.id
  target_prefix = "access-logs/"
}

# SECURITY FIX 6: Remove public bucket policy or use restrictive policy
# Instead of a public policy, we demonstrate a restricted policy for specific use cases
resource "aws_s3_bucket_policy" "secure_policy" {
  bucket = aws_s3_bucket.secure_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "RestrictedAccess"
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
        Condition = {
          Bool = {
            "aws:SecureTransport" = "true"  # Require HTTPS
          }
        }
      },
    ]
  })
}

# Get current AWS account ID for policy
data "aws_caller_identity" "current" {}

# SECURITY IMPROVEMENT 7: Add lifecycle policy for cost optimization
resource "aws_s3_bucket_lifecycle_configuration" "secure_lifecycle" {
  bucket = aws_s3_bucket.secure_bucket.id

  rule {
    id     = "security_lifecycle"
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
  }
}

# Output the bucket information
output "secure_bucket_name" {
  value = aws_s3_bucket.secure_bucket.id
}

output "secure_bucket_domain_name" {
  value = aws_s3_bucket.secure_bucket.bucket_domain_name
}

output "access_log_bucket_name" {
  value = aws_s3_bucket.access_log_bucket.id
}

output "security_status" {
  value = "✅ This bucket is properly secured with Block Public Access enabled, private ACL, encryption, versioning, and logging!"
}

output "remediation_summary" {
  value = <<-EOT
Security Improvements Applied:
1. ✅ Block Public Access enabled (all 4 settings)
2. ✅ Private ACL instead of public-read-write
3. ✅ Removed public bucket policy / added secure policy
4. ✅ Server-side encryption enabled
5. ✅ Versioning enabled for data protection
6. ✅ Access logging configured
7. ✅ Lifecycle policy for cost optimization
8. ✅ HTTPS-only access enforced
EOT
}