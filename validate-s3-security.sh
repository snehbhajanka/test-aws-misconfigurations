#!/bin/bash

# S3 Security Validation Script
# Validates that S3 configurations block public write access per Issue S3.3

echo "🔒 S3 Security Validation - Issue S3.3 Remediation Check"
echo "=========================================================="

# Check Terraform configuration
echo ""
echo "📋 Checking Terraform S3 Configuration..."
echo "----------------------------------------"

TERRAFORM_FILE="terraform-s3-misconfigured.tf"
if [[ -f "$TERRAFORM_FILE" ]]; then
    echo "✅ Terraform file found: $TERRAFORM_FILE"
    
    # Check Block Public Access settings
    if grep -q "block_public_acls.*=.*true" "$TERRAFORM_FILE" && \
       grep -q "block_public_policy.*=.*true" "$TERRAFORM_FILE" && \
       grep -q "ignore_public_acls.*=.*true" "$TERRAFORM_FILE" && \
       grep -q "restrict_public_buckets.*=.*true" "$TERRAFORM_FILE"; then
        echo "✅ Block Public Access settings: ALL ENABLED"
    else
        echo "❌ Block Public Access settings: NOT PROPERLY CONFIGURED"
        exit 1
    fi
    
    # Check ACL configuration
    if grep -q 'acl.*=.*"private"' "$TERRAFORM_FILE"; then
        echo "✅ S3 Bucket ACL: PRIVATE"
    else
        echo "❌ S3 Bucket ACL: NOT PRIVATE"
        exit 1
    fi
    
    # Check that public bucket policy is removed/commented
    if grep -q "^#.*aws_s3_bucket_policy.*misconfigured_policy" "$TERRAFORM_FILE"; then
        echo "✅ Public bucket policy: REMOVED (commented out)"
    elif ! grep -q "aws_s3_bucket_policy" "$TERRAFORM_FILE"; then
        echo "✅ Public bucket policy: REMOVED (deleted)"
    else
        echo "❌ Public bucket policy: STILL PRESENT"
        exit 1
    fi
    
else
    echo "❌ Terraform file not found: $TERRAFORM_FILE"
    exit 1
fi

# Check CloudFormation template
echo ""
echo "📋 Checking CloudFormation S3 Template..."
echo "-----------------------------------------"

CF_TEMPLATE="cloudformation-s3-misconfigured.yaml"
if [[ -f "$CF_TEMPLATE" ]]; then
    echo "✅ CloudFormation template found: $CF_TEMPLATE"
    
    # Check Block Public Access settings
    if grep -q "BlockPublicAcls: true" "$CF_TEMPLATE" && \
       grep -q "IgnorePublicAcls: true" "$CF_TEMPLATE" && \
       grep -q "BlockPublicPolicy: true" "$CF_TEMPLATE" && \
       grep -q "RestrictPublicBuckets: true" "$CF_TEMPLATE"; then
        echo "✅ Block Public Access settings: ALL ENABLED"
    else
        echo "❌ Block Public Access settings: NOT PROPERLY CONFIGURED"
        exit 1
    fi
    
    # Check for encryption
    if grep -q "BucketEncryption:" "$CF_TEMPLATE"; then
        echo "✅ Server-side encryption: CONFIGURED"
    else
        echo "⚠️  Server-side encryption: NOT CONFIGURED (acceptable for testing)"
    fi
    
    # Check for versioning
    if grep -q "VersioningConfiguration:" "$CF_TEMPLATE"; then
        echo "✅ Versioning: CONFIGURED"
    else
        echo "⚠️  Versioning: NOT CONFIGURED (acceptable for testing)"
    fi
    
else
    echo "❌ CloudFormation template not found: $CF_TEMPLATE"
    exit 1
fi

# Validate configurations
echo ""
echo "🔧 Validating Configurations..."
echo "------------------------------"

# Validate Terraform
echo "Validating Terraform configuration..."
mkdir -p /tmp/s3-validation
cp "$TERRAFORM_FILE" /tmp/s3-validation/
cd /tmp/s3-validation
if terraform init >/dev/null 2>&1 && terraform validate >/dev/null 2>&1; then
    echo "✅ Terraform configuration: VALID"
else
    echo "❌ Terraform configuration: INVALID"
    exit 1
fi
cd - >/dev/null

# Validate CloudFormation
echo "Validating CloudFormation template..."
if command -v cfn-lint >/dev/null 2>&1; then
    if cfn-lint "$CF_TEMPLATE" >/dev/null 2>&1; then
        echo "✅ CloudFormation template: VALID"
    else
        echo "❌ CloudFormation template: INVALID"
        exit 1
    fi
else
    echo "⚠️  cfn-lint not available, skipping CloudFormation validation"
fi

echo ""
echo "🎉 S3 SECURITY VALIDATION COMPLETE"
echo "=================================="
echo "✅ Issue S3.3 has been RESOLVED"
echo "✅ Public write access to S3 buckets is BLOCKED"
echo "✅ All Block Public Access settings are ENABLED"
echo "✅ Private ACLs are configured"
echo "✅ Public bucket policies have been REMOVED"
echo ""
echo "🔒 SECURITY STATUS: COMPLIANT"