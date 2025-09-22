#!/bin/bash

# S3 Security Validation Script
# This script validates that S3 bucket public write access is blocked

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <bucket-name>"
    echo "Example: $0 my-secure-bucket-12345678"
    exit 1
fi

BUCKET_NAME="$1"

echo "🔍 Validating S3 bucket security configuration for: $BUCKET_NAME"
echo ""

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI is not configured or credentials are invalid."
    echo "Run 'aws configure' to set up your credentials."
    exit 1
fi

echo "✅ AWS CLI is configured"
echo ""

# Test 1: Check public access block settings
echo "📋 Test 1: Checking public access block settings..."
if PUBLIC_ACCESS_BLOCK=$(aws s3api get-public-access-block --bucket "$BUCKET_NAME" 2>/dev/null); then
    echo "$PUBLIC_ACCESS_BLOCK" | jq -r '.PublicAccessBlockConfiguration | to_entries[] | "\(.key): \(.value)"'
    
    # Verify all settings are true
    BLOCK_PUBLIC_ACLS=$(echo "$PUBLIC_ACCESS_BLOCK" | jq -r '.PublicAccessBlockConfiguration.BlockPublicAcls')
    IGNORE_PUBLIC_ACLS=$(echo "$PUBLIC_ACCESS_BLOCK" | jq -r '.PublicAccessBlockConfiguration.IgnorePublicAcls')
    BLOCK_PUBLIC_POLICY=$(echo "$PUBLIC_ACCESS_BLOCK" | jq -r '.PublicAccessBlockConfiguration.BlockPublicPolicy')
    RESTRICT_PUBLIC_BUCKETS=$(echo "$PUBLIC_ACCESS_BLOCK" | jq -r '.PublicAccessBlockConfiguration.RestrictPublicBuckets')
    
    if [[ "$BLOCK_PUBLIC_ACLS" == "true" && "$IGNORE_PUBLIC_ACLS" == "true" && 
          "$BLOCK_PUBLIC_POLICY" == "true" && "$RESTRICT_PUBLIC_BUCKETS" == "true" ]]; then
        echo "✅ All public access block settings are correctly enabled"
    else
        echo "❌ Some public access block settings are not properly configured"
        exit 1
    fi
else
    echo "❌ Could not retrieve public access block settings"
    exit 1
fi

echo ""

# Test 2: Check bucket ACL
echo "📋 Test 2: Checking bucket ACL..."
if BUCKET_ACL=$(aws s3api get-bucket-acl --bucket "$BUCKET_NAME" 2>/dev/null); then
    OWNER_DISPLAY_NAME=$(echo "$BUCKET_ACL" | jq -r '.Owner.DisplayName // "Unknown"')
    GRANTS_COUNT=$(echo "$BUCKET_ACL" | jq -r '.Grants | length')
    echo "Bucket owner: $OWNER_DISPLAY_NAME"
    echo "Number of ACL grants: $GRANTS_COUNT"
    
    # Check for public grants
    PUBLIC_GRANTS=$(echo "$BUCKET_ACL" | jq -r '.Grants[] | select(.Grantee.Type == "Group" and (.Grantee.URI | contains("AllUsers") or contains("AuthenticatedUsers")))')
    if [[ -z "$PUBLIC_GRANTS" ]]; then
        echo "✅ No public ACL grants found - bucket ACL is secure"
    else
        echo "❌ Public ACL grants detected:"
        echo "$PUBLIC_GRANTS"
        exit 1
    fi
else
    echo "❌ Could not retrieve bucket ACL"
    exit 1
fi

echo ""

# Test 3: Check bucket policy for write permissions
echo "📋 Test 3: Checking bucket policy for write permissions..."
if BUCKET_POLICY=$(aws s3api get-bucket-policy --bucket "$BUCKET_NAME" 2>/dev/null); then
    POLICY_JSON=$(echo "$BUCKET_POLICY" | jq -r '.Policy')
    
    # Check for public write actions
    WRITE_ACTIONS=$(echo "$POLICY_JSON" | jq -r '.Statement[] | select(.Principal == "*" or .Principal.AWS == "*") | .Action[]?' | grep -E "(Put|Delete|Write)" || true)
    
    if [[ -z "$WRITE_ACTIONS" ]]; then
        echo "✅ No public write permissions found in bucket policy"
    else
        echo "❌ Public write permissions detected in bucket policy:"
        echo "$WRITE_ACTIONS"
        exit 1
    fi
else
    echo "✅ No bucket policy found (which is secure)"
fi

echo ""

# Test 4: Functional test - attempt unauthorized write
echo "📋 Test 4: Functional test - attempting unauthorized write operation..."
echo "test-content-$(date)" > /tmp/test-file.txt

if aws s3 cp /tmp/test-file.txt "s3://$BUCKET_NAME/test-unauthorized-write.txt" --no-sign-request 2>/dev/null; then
    echo "❌ Unauthorized write operation succeeded - bucket is not secure!"
    # Cleanup the test file
    aws s3 rm "s3://$BUCKET_NAME/test-unauthorized-write.txt" --no-sign-request 2>/dev/null || true
    exit 1
else
    echo "✅ Unauthorized write operation failed as expected - bucket is secure"
fi

# Cleanup temp file
rm -f /tmp/test-file.txt

echo ""
echo "🎉 All security validation tests passed!"
echo "✅ S3 bucket '$BUCKET_NAME' successfully blocks public write access"
echo "✅ AWS Security Hub control S3.3 compliance verified"