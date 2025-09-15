# Secure S3 Bucket Configuration - DEMONSTRATES PROPER SECURITY SETTINGS
# This file shows how to properly configure S3 buckets to block public write access
# Addresses security misconfiguration S3.3: Block Public Write Access for S3 Buckets

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
  bucket = "my-secure-bucket-${random_id.secure_bucket_suffix.hex}"

  tags = {
    Name        = "SecureBucket"
    Environment = "SecurityTesting"
    Purpose     = "Demonstrates secure S3 configuration"
    Security    = "S3.3-Compliant"
  }
}

resource "random_id" "secure_bucket_suffix" {
  byte_length = 8
}

# SECURITY FIX 1: Enable public access block (prevents public access)
resource "aws_s3_bucket_public_access_block" "secure_pab" {
  bucket = aws_s3_bucket.secure_bucket.id

  block_public_acls       = true # FIXED: Block public ACLs
  block_public_policy     = true # FIXED: Block public bucket policies
  ignore_public_acls      = true # FIXED: Ignore public ACLs
  restrict_public_buckets = true # FIXED: Restrict public bucket access
}

# SECURITY FIX 2: Private ACL (no public access)
resource "aws_s3_bucket_acl" "secure_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.secure_bucket_acl_ownership]
  bucket     = aws_s3_bucket.secure_bucket.id
  acl        = "private" # FIXED: Changed from "public-read-write" to "private"
}

resource "aws_s3_bucket_ownership_controls" "secure_bucket_acl_ownership" {
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
    bucket_key_enabled = true
  }
}

# SECURITY ENHANCEMENT: Enable versioning
resource "aws_s3_bucket_versioning" "secure_versioning" {
  bucket = aws_s3_bucket.secure_bucket.id
  versioning_configuration {
    status = "Enabled" # FIXED: Changed from "Disabled" to "Enabled"
  }
}

# SECURITY FIX 3: Restrictive bucket policy (no public access)
resource "aws_s3_bucket_policy" "secure_policy" {
  bucket = aws_s3_bucket.secure_bucket.id

  # This policy only allows access from the bucket owner account
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
          StringNotEquals = {
            "aws:PrincipalAccount" = "${data.aws_caller_identity.current.account_id}"
          }
        }
      },
    ]
  })
}

# Get current AWS account ID for the policy
data "aws_caller_identity" "current" {}

# Output the secure bucket name and URL
output "secure_bucket_name" {
  value = aws_s3_bucket.secure_bucket.id
}

output "secure_bucket_domain_name" {
  value = aws_s3_bucket.secure_bucket.bucket_domain_name
}

output "security_status" {
  value = "✅ SUCCESS: This bucket is properly secured against public write access (S3.3 compliant)!"
}

output "security_features" {
  value = {
    public_access_blocked = "✅ All public access blocked"
    private_acl           = "✅ Private ACL configured"
    encryption_enabled    = "✅ Server-side encryption enabled"
    versioning_enabled    = "✅ Versioning enabled"
    restrictive_policy    = "✅ Account-restricted bucket policy"
  }
}