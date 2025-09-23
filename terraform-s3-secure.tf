# Properly Configured S3 Bucket - SECURE CONFIGURATION
# This file shows the correct way to configure S3 buckets with proper security controls
# This configuration blocks public write access as recommended by AWS Security Hub control S3.3

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

# Secure S3 Bucket with blocked public write access
resource "aws_s3_bucket" "secure_bucket" {
  bucket = "my-secure-bucket-${random_id.secure_bucket_suffix.hex}"

  tags = {
    Name        = "SecureBucket"
    Environment = "SecurityTesting"
    Purpose     = "Demonstrates proper S3 security configuration"
  }
}

resource "random_id" "secure_bucket_suffix" {
  byte_length = 8
}

# SECURITY CONTROL: Block Public Access enabled (prevents public access)
resource "aws_s3_bucket_public_access_block" "secure_pab" {
  bucket = aws_s3_bucket.secure_bucket.id

  # Block all public access to prevent unauthorized read/write operations
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# SECURITY CONTROL: Private ACL (no public access)
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

# SECURITY CONTROL: Server-side encryption enabled
resource "aws_s3_bucket_server_side_encryption_configuration" "secure_encryption" {
  bucket = aws_s3_bucket.secure_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# SECURITY CONTROL: Versioning enabled for data protection
resource "aws_s3_bucket_versioning" "secure_versioning" {
  bucket = aws_s3_bucket.secure_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# SECURITY CONTROL: Access logging enabled
resource "aws_s3_bucket_logging" "secure_logging" {
  bucket = aws_s3_bucket.secure_bucket.id

  target_bucket = aws_s3_bucket.access_log_bucket.id
  target_prefix = "access-logs/"
}

# Separate bucket for access logs (also secure)
resource "aws_s3_bucket" "access_log_bucket" {
  bucket = "my-secure-access-logs-${random_id.secure_bucket_suffix.hex}"

  tags = {
    Name        = "SecureAccessLogsBucket"
    Environment = "SecurityTesting"
    Purpose     = "Stores access logs for secure bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "access_log_pab" {
  bucket = aws_s3_bucket.access_log_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# SECURITY CONTROL: Restrictive bucket policy (no public access)
resource "aws_s3_bucket_policy" "secure_policy" {
  depends_on = [aws_s3_bucket_public_access_block.secure_pab]
  bucket     = aws_s3_bucket.secure_bucket.id

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
      {
        Sid    = "AllowSSLRequestsOnly"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
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

# Output the bucket information
output "secure_bucket_name" {
  value = aws_s3_bucket.secure_bucket.id
}

output "secure_bucket_domain_name" {
  value = aws_s3_bucket.secure_bucket.bucket_domain_name
}

output "security_status" {
  value = "✅ This bucket is properly configured with blocked public write access, encryption, versioning, and access logging!"
}

output "compliance_info" {
  value = "This configuration meets AWS Security Hub control S3.3 - S3 general purpose buckets should block public write access"
}