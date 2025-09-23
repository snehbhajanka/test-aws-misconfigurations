# Secure S3 Bucket Configuration - FOR PRODUCTION USE
# This file contains secure S3 bucket configurations that follow AWS security best practices
# This configuration blocks public read access as per AWS Security Hub Control ID S3.2

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
    Purpose     = "Secure bucket following security best practices"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# SECURITY FIX 1: Public access block enabled (blocks public access)
resource "aws_s3_bucket_public_access_block" "secure_pab" {
  bucket = aws_s3_bucket.secure_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# SECURITY FIX 2: Private ACL instead of public
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

  target_bucket = aws_s3_bucket.secure_bucket.id
  target_prefix = "access-logs/"
}

# SECURITY FIX 6: No public bucket policy - only authenticated access
# Note: If a bucket policy is needed, it should restrict access to specific principals
# Example restrictive policy (commented out):
# resource "aws_s3_bucket_policy" "secure_policy" {
#   bucket = aws_s3_bucket.secure_bucket.id
#
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid       = "AuthenticatedAccessOnly"
#         Effect    = "Allow"
#         Principal = {
#           AWS = "arn:aws:iam::ACCOUNT-ID:root"
#         }
#         Action = [
#           "s3:GetObject",
#           "s3:PutObject",
#           "s3:ListBucket"
#         ]
#         Resource = [
#           aws_s3_bucket.secure_bucket.arn,
#           "${aws_s3_bucket.secure_bucket.arn}/*",
#         ]
#       },
#     ]
#   })
# }

# SECURITY FIX 7: Enable lifecycle policies
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

    expiration {
      days = 90
    }
  }
}

# Output the bucket name and URL
output "secure_bucket_name" {
  value = aws_s3_bucket.secure_bucket.id
}

output "secure_bucket_domain_name" {
  value = aws_s3_bucket.secure_bucket.bucket_domain_name
}

output "security_status" {
  value = "✅ This bucket is securely configured with public access blocked, encryption enabled, versioning enabled, and proper access controls!"
}

output "security_features" {
  value = {
    public_access_blocked = "✅ All public access blocked"
    encryption_enabled    = "✅ Server-side encryption enabled"
    versioning_enabled    = "✅ Versioning enabled"
    logging_enabled       = "✅ Access logging enabled"
    lifecycle_configured  = "✅ Lifecycle policies configured"
    acl_private           = "✅ Private ACL configured"
  }
}