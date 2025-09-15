# S3 Bucket Configuration - REMEDIATED FOR PUBLIC WRITE ACCESS
# This file has been updated to fix the critical S3.3 security misconfiguration
# Public write access has been blocked while maintaining some misconfigurations for educational purposes

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

# S3 Bucket with remediated public write access controls
resource "aws_s3_bucket" "misconfigured_bucket" {
  bucket = "my-remediated-bucket-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "RemediatedBucket"
    Environment = "SecurityTesting"
    Purpose     = "Public write access blocked - S3.3 remediation applied"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# REMEDIATION APPLIED: Public access block enabled (blocks public write access)
# This fixes the critical S3.3 security misconfiguration
resource "aws_s3_bucket_public_access_block" "misconfigured_pab" {
  bucket = aws_s3_bucket.misconfigured_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# REMEDIATION APPLIED: Private ACL instead of public read/write
# This fixes the public write access vulnerability
resource "aws_s3_bucket_acl" "misconfigured_acl" {
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

# REMEDIATION APPLIED: Secure bucket policy - removed public write access
# The policy now only allows public read access, blocking write operations
resource "aws_s3_bucket_policy" "misconfigured_policy" {
  bucket = aws_s3_bucket.misconfigured_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadOnly"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
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
  value = "✅ REMEDIATED: This bucket now blocks public write access! Public access block enabled, private ACL set, and bucket policy restricts write operations."
}
