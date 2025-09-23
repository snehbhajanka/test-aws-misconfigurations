# S3 Bucket with Remediated Public Write Access - EDUCATIONAL EXAMPLE
# This file shows how to fix the public write access misconfiguration
# while keeping the bucket educational for security testing

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

# S3 Bucket with fixed public write access issue
resource "aws_s3_bucket" "remediated_bucket" {
  bucket = "my-remediated-bucket-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "RemediatedBucket"
    Environment = "SecurityTesting"
    Purpose     = "Shows S3.3 control remediation - blocks public write access"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# REMEDIATION: Block public write access (addresses S3.3 control)
resource "aws_s3_bucket_public_access_block" "remediated_pab" {
  bucket = aws_s3_bucket.remediated_bucket.id

  # Block public ACLs and policies to prevent public write access
  block_public_acls       = true  # FIXED: was false
  block_public_policy     = true  # FIXED: was false
  ignore_public_acls      = true  # FIXED: was false
  restrict_public_buckets = true  # FIXED: was false
}

# REMEDIATION: Remove public write permissions from ACL
resource "aws_s3_bucket_acl" "remediated_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.s3_bucket_acl_ownership]
  bucket     = aws_s3_bucket.remediated_bucket.id
  acl        = "public-read"  # FIXED: was "public-read-write"
}

resource "aws_s3_bucket_ownership_controls" "s3_bucket_acl_ownership" {
  bucket = aws_s3_bucket.remediated_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Note: Still missing encryption, versioning, and logging for educational purposes
# These would be included in a fully secure configuration

# REMEDIATION: Bucket policy with no public write permissions
resource "aws_s3_bucket_policy" "remediated_policy" {
  bucket = aws_s3_bucket.remediated_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadOnly"  # FIXED: Removed write permissions
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
          # REMOVED: "s3:PutObject", "s3:DeleteObject" - these allowed public write
        ]
        Resource = [
          aws_s3_bucket.remediated_bucket.arn,
          "${aws_s3_bucket.remediated_bucket.arn}/*",
        ]
      },
    ]
  })
}

# Output the bucket name and URL
output "bucket_name" {
  value = aws_s3_bucket.remediated_bucket.id
}

output "bucket_domain_name" {
  value = aws_s3_bucket.remediated_bucket.bucket_domain_name
}

output "remediation_status" {
  value = "✅ REMEDIATED: Public write access blocked. Bucket now complies with AWS Security Hub control S3.3"
}

output "remediation_summary" {
  value = <<EOF
Remediation Applied:
- ✅ Block Public Access settings enabled
- ✅ ACL changed from public-read-write to public-read  
- ✅ Bucket policy removed PutObject and DeleteObject permissions
- ⚠️  Still missing: encryption, versioning, access logging (see terraform-s3-secure.tf for full security)
EOF
}