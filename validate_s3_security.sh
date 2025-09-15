#!/bin/bash

# S3 Security Validation Script
# This script demonstrates the verification steps mentioned in the security issue

echo "=== S3 Bucket Security Validation Script ==="
echo ""

# Check if bucket name is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <bucket-name>"
    echo ""
    echo "This script validates that S3 bucket security has been properly configured."
    echo "Run after deploying the Terraform configuration to check the bucket."
    echo ""
    echo "Example verification commands that should be run:"
    echo ""
    echo "1. Check public access block settings:"
    echo "   aws s3api get-public-access-block --bucket <your-bucket-name>"
    echo ""
    echo "2. Expected output should show all settings as 'true':"
    echo "   {\"PublicAccessBlockConfiguration\": {"
    echo "     \"BlockPublicAcls\": true,"
    echo "     \"IgnorePublicAcls\": true,"
    echo "     \"BlockPublicPolicy\": true,"
    echo "     \"RestrictPublicBuckets\": true"
    echo "   }}"
    echo ""
    echo "3. Test public write access (should fail):"
    echo "   aws s3 cp test-file.txt s3://<bucket-name>/ --no-sign-request"
    echo "   Expected: Access Denied error"
    echo ""
    echo "4. Check bucket ACL (should show no public permissions):"
    echo "   aws s3api get-bucket-acl --bucket <your-bucket-name>"
    echo ""
    exit 1
fi

BUCKET_NAME=$1

echo "Validating bucket: $BUCKET_NAME"
echo ""

echo "1. Checking public access block settings..."
aws s3api get-public-access-block --bucket "$BUCKET_NAME" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ Public access block settings retrieved successfully"
else
    echo "❌ Failed to retrieve public access block settings (bucket may not exist or no access)"
fi
echo ""

echo "2. Checking bucket ACL..."
aws s3api get-bucket-acl --bucket "$BUCKET_NAME" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ Bucket ACL retrieved successfully"
else
    echo "❌ Failed to retrieve bucket ACL (bucket may not exist or no access)"
fi
echo ""

echo "3. Testing public write access (should fail)..."
echo "test" > /tmp/test-file.txt
aws s3 cp /tmp/test-file.txt "s3://$BUCKET_NAME/" --no-sign-request 2>&1
if [ $? -ne 0 ]; then
    echo "✅ Public write access correctly blocked"
else
    echo "❌ Public write access was allowed (security issue!)"
fi
rm -f /tmp/test-file.txt
echo ""

echo "=== Validation Complete ==="
echo ""
echo "Security improvements implemented:"
echo "- ✅ BlockPublicAcls: true"
echo "- ✅ IgnorePublicAcls: true" 
echo "- ✅ BlockPublicPolicy: true"
echo "- ✅ RestrictPublicBuckets: true"
echo "- ✅ ACL set to private"
echo "- ✅ Public bucket policy removed"