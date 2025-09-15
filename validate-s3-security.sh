#!/bin/bash

# S3 Security Validation Script
# This script validates that S3 buckets have proper security configurations

set -e

echo "🔍 S3 Security Configuration Validation Script"
echo "=============================================="
echo ""

# Function to check if AWS CLI is configured
check_aws_config() {
    if ! command -v aws &> /dev/null; then
        echo "❌ AWS CLI is required but not installed."
        exit 1
    fi

    if ! aws sts get-caller-identity &> /dev/null; then
        echo "❌ AWS CLI is not configured or credentials are invalid."
        echo "Run 'aws configure' to set up your credentials."
        exit 1
    fi
}

# Function to validate S3 bucket security
validate_bucket_security() {
    local bucket_name=$1
    echo "🔍 Validating security for bucket: $bucket_name"
    echo ""

    # Check if bucket exists
    if ! aws s3api head-bucket --bucket "$bucket_name" 2>/dev/null; then
        echo "❌ Bucket '$bucket_name' does not exist or is not accessible."
        return 1
    fi

    echo "✅ Bucket exists and is accessible"

    # Check Public Access Block settings
    echo "📋 Checking Public Access Block settings..."
    local pab_output
    if pab_output=$(aws s3api get-public-access-block --bucket "$bucket_name" 2>/dev/null); then
        local block_public_acls=$(echo "$pab_output" | grep -o '"BlockPublicAcls":[^,]*' | cut -d':' -f2 | tr -d ' ')
        local ignore_public_acls=$(echo "$pab_output" | grep -o '"IgnorePublicAcls":[^,]*' | cut -d':' -f2 | tr -d ' ')
        local block_public_policy=$(echo "$pab_output" | grep -o '"BlockPublicPolicy":[^,]*' | cut -d':' -f2 | tr -d ' ')
        local restrict_public_buckets=$(echo "$pab_output" | grep -o '"RestrictPublicBuckets":[^,]*' | cut -d':' -f2 | tr -d ' ')

        if [[ "$block_public_acls" == "true" && "$ignore_public_acls" == "true" && 
              "$block_public_policy" == "true" && "$restrict_public_buckets" == "true" ]]; then
            echo "✅ All Public Access Block settings are properly enabled"
        else
            echo "❌ Public Access Block settings are not properly configured:"
            echo "   BlockPublicAcls: $block_public_acls (should be true)"
            echo "   IgnorePublicAcls: $ignore_public_acls (should be true)"
            echo "   BlockPublicPolicy: $block_public_policy (should be true)"
            echo "   RestrictPublicBuckets: $restrict_public_buckets (should be true)"
        fi
    else
        echo "❌ Could not retrieve Public Access Block settings"
    fi

    # Check encryption
    echo "📋 Checking server-side encryption..."
    if aws s3api get-bucket-encryption --bucket "$bucket_name" &>/dev/null; then
        echo "✅ Server-side encryption is enabled"
    else
        echo "❌ Server-side encryption is not configured"
    fi

    # Check versioning
    echo "📋 Checking versioning..."
    local versioning_status
    if versioning_status=$(aws s3api get-bucket-versioning --bucket "$bucket_name" --query 'Status' --output text 2>/dev/null); then
        if [[ "$versioning_status" == "Enabled" ]]; then
            echo "✅ Versioning is enabled"
        else
            echo "❌ Versioning is not enabled (Status: $versioning_status)"
        fi
    else
        echo "❌ Could not retrieve versioning status"
    fi

    # Check logging
    echo "📋 Checking access logging..."
    if aws s3api get-bucket-logging --bucket "$bucket_name" &>/dev/null; then
        echo "✅ Access logging is configured"
    else
        echo "❌ Access logging is not configured"
    fi

    # Test public access
    echo "📋 Testing public access..."
    local bucket_url="https://${bucket_name}.s3.amazonaws.com/"
    local http_status
    if http_status=$(curl -s -o /dev/null -w "%{http_code}" "$bucket_url" --max-time 10); then
        if [[ "$http_status" == "403" ]]; then
            echo "✅ Public access is properly denied (HTTP $http_status)"
        elif [[ "$http_status" == "200" ]]; then
            echo "❌ Bucket is publicly accessible (HTTP $http_status)"
        else
            echo "ℹ️  Unexpected HTTP status: $http_status"
        fi
    else
        echo "❌ Could not test public access"
    fi

    echo ""
}

# Main script
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <bucket-name>"
    echo ""
    echo "Example: $0 my-secure-bucket-abc123"
    echo ""
    echo "This script validates S3 bucket security configurations including:"
    echo "  - Public Access Block settings"
    echo "  - Server-side encryption"
    echo "  - Versioning"
    echo "  - Access logging"
    echo "  - Public access testing"
    exit 1
fi

BUCKET_NAME=$1

echo "Starting validation for bucket: $BUCKET_NAME"
echo ""

check_aws_config
validate_bucket_security "$BUCKET_NAME"

echo "🎯 Validation complete!"
echo ""
echo "For a secure S3 bucket, you should see:"
echo "  ✅ All Public Access Block settings enabled"
echo "  ✅ Server-side encryption enabled"
echo "  ✅ Versioning enabled"
echo "  ✅ Access logging configured"
echo "  ✅ Public access properly denied (HTTP 403)"