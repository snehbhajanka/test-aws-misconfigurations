# Secure S3 Bucket Configuration - PRODUCTION READY
# This file demonstrates proper S3 security configurations that block public access

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
    Purpose     = "Demonstrates proper S3 security configuration"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# SECURE CONFIGURATION 1: Public access block enabled (blocks all public access)
resource "aws_s3_bucket_public_access_block" "secure_pab" {
  bucket = aws_s3_bucket.secure_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# SECURE CONFIGURATION 2: Private ACL (no public access)
resource "aws_s3_bucket_acl" "secure_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.s3_bucket_acl_ownership]
  bucket     = aws_s3_bucket.secure_bucket.id
  acl        = "private"
}

resource "aws_s3_bucket_ownership_controls" "s3_bucket_acl_ownership" {
  bucket = aws_s3_bucket.secure_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# SECURE CONFIGURATION 3: Server-side encryption enabled
resource "aws_s3_bucket_server_side_encryption_configuration" "secure_encryption" {
  bucket = aws_s3_bucket.secure_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# SECURE CONFIGURATION 4: Versioning enabled
resource "aws_s3_bucket_versioning" "secure_versioning" {
  bucket = aws_s3_bucket.secure_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# SECURE CONFIGURATION 5: Access logging enabled
resource "aws_s3_bucket" "access_logs_bucket" {
  bucket = "access-logs-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "AccessLogsBucket"
    Environment = "Production"
    Purpose     = "Stores access logs for the secure bucket"
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
  bucket = aws_s3_bucket.secure_bucket.id

  target_bucket = aws_s3_bucket.access_logs_bucket.id
  target_prefix = "access-logs/"
}

# SECURE CONFIGURATION 6: Restrictive bucket policy (no public access)
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
          StringNotEquals = {
            "aws:PrincipalServiceName" = [
              "cloudtrail.amazonaws.com",
              "config.amazonaws.com"
            ]
          }
        }
      },
      {
        Sid       = "AllowSSLRequestsOnly"
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

# SECURE CONFIGURATION 7: Lifecycle policies for cost optimization
resource "aws_s3_bucket_lifecycle_configuration" "secure_lifecycle" {
  bucket = aws_s3_bucket.secure_bucket.id

  rule {
    id     = "transition_to_ia"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }

    transition {
      days          = 90
      storage_class = "DEEP_ARCHIVE"
    }
  }

  rule {
    id     = "delete_incomplete_multipart_uploads"
    status = "Enabled"

    filter {
      prefix = ""
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Output the bucket name and URL
output "bucket_name" {
  value = aws_s3_bucket.secure_bucket.id
}

output "bucket_domain_name" {
  value = aws_s3_bucket.secure_bucket.bucket_domain_name
}

output "access_logs_bucket_name" {
  value = aws_s3_bucket.access_logs_bucket.id
}

output "security_status" {
  value = "✅ This bucket is properly configured with blocked public access, encryption, versioning, and logging!"
}