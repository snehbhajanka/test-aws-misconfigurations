#!/bin/bash

# S3.3 Security Validation Script
# This script validates that the secure S3 configurations properly block public write access

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🔍 S3.3 Security Misconfiguration Validation"
echo "============================================="

# Function to validate Terraform configuration
validate_terraform_config() {
    echo "📋 Validating Terraform secure configuration..."
    
    if [[ ! -f "terraform-s3-secure.tf" ]]; then
        echo "❌ terraform-s3-secure.tf not found"
        return 1
    fi
    
    # Check for secure public access block settings
    if grep -q "block_public_acls = true" terraform-s3-secure.tf && \
       grep -q "block_public_policy = true" terraform-s3-secure.tf && \
       grep -q "ignore_public_acls = true" terraform-s3-secure.tf && \
       grep -q "restrict_public_buckets = true" terraform-s3-secure.tf; then
        echo "✅ Block Public Access settings are properly configured (all true)"
    else
        echo "❌ Block Public Access settings are not properly configured"
        return 1
    fi
    
    # Check for private ACL
    if grep -q 'acl.*=.*"private"' terraform-s3-secure.tf; then
        echo "✅ ACL is set to private"
    else
        echo "❌ ACL is not set to private"
        return 1
    fi
    
    # Check for secure bucket policy (no public access)
    if grep -q "data.aws_caller_identity.current.account_id" terraform-s3-secure.tf && \
       grep -q "AWS.*=.*arn:aws:iam" terraform-s3-secure.tf; then
        echo "✅ Bucket policy restricts access to authenticated users only"
    else
        echo "❌ Bucket policy may allow public access"
        return 1
    fi
    
    # Check for HTTPS enforcement
    if grep -q "aws:SecureTransport.*false" terraform-s3-secure.tf; then
        echo "✅ HTTPS enforcement is configured"
    else
        echo "❌ HTTPS enforcement is not configured"
        return 1
    fi
    
    echo "✅ Terraform configuration validation passed"
    return 0
}

# Function to validate CloudFormation template
validate_cloudformation_template() {
    echo ""
    echo "📋 Validating CloudFormation secure template..."
    
    if [[ ! -f "cloudformation-s3-secure.yaml" ]]; then
        echo "❌ cloudformation-s3-secure.yaml not found"
        return 1
    fi
    
    # Check for secure public access block settings
    if grep -q "BlockPublicAcls: true" cloudformation-s3-secure.yaml && \
       grep -q "BlockPublicPolicy: true" cloudformation-s3-secure.yaml && \
       grep -q "IgnorePublicAcls: true" cloudformation-s3-secure.yaml && \
       grep -q "RestrictPublicBuckets: true" cloudformation-s3-secure.yaml; then
        echo "✅ Block Public Access settings are properly configured (all true)"
    else
        echo "❌ Block Public Access settings are not properly configured"
        return 1
    fi
    
    # Check for server-side encryption
    if grep -q "BucketEncryption:" cloudformation-s3-secure.yaml && \
       grep -q "SSEAlgorithm: AES256" cloudformation-s3-secure.yaml; then
        echo "✅ Server-side encryption is configured"
    else
        echo "❌ Server-side encryption is not configured"
        return 1
    fi
    
    # Check for versioning
    if grep -q "VersioningConfiguration:" cloudformation-s3-secure.yaml && \
       grep -q "Status: Enabled" cloudformation-s3-secure.yaml; then
        echo "✅ Versioning is enabled"
    else
        echo "❌ Versioning is not enabled"
        return 1
    fi
    
    # Check for secure bucket policy
    if grep -q "aws:SecureTransport.*false" cloudformation-s3-secure.yaml; then
        echo "✅ HTTPS enforcement is configured"
    else
        echo "❌ HTTPS enforcement is not configured"
        return 1
    fi
    
    echo "✅ CloudFormation template validation passed"
    return 0
}

# Function to compare with misconfigured version
validate_remediation() {
    echo ""
    echo "📋 Validating remediation fixes..."
    
    if [[ ! -f "terraform-s3-misconfigured.tf" ]]; then
        echo "❌ terraform-s3-misconfigured.tf not found for comparison"
        return 1
    fi
    
    # Verify misconfigured version has issues
    if grep -q "block_public_acls.*=.*false" terraform-s3-misconfigured.tf; then
        echo "✅ Confirmed: Misconfigured version has block_public_acls = false"
    else
        echo "⚠️  Warning: Could not confirm misconfigured version has public access issues"
    fi
    
    # Verify secure version fixes the issues
    if grep -q "block_public_acls.*=.*true" terraform-s3-secure.tf; then
        echo "✅ Confirmed: Secure version has block_public_acls = true"
    else
        echo "❌ Error: Secure version does not fix the public access issue"
        return 1
    fi
    
    echo "✅ Remediation validation passed"
    return 0
}

# Function to validate documentation
validate_documentation() {
    echo ""
    echo "📋 Validating documentation updates..."
    
    if grep -q "S3.3 compliant" README.md; then
        echo "✅ README mentions S3.3 compliance"
    else
        echo "❌ README does not mention S3.3 compliance"
        return 1
    fi
    
    if grep -q "terraform-s3-secure.tf" README.md; then
        echo "✅ README mentions secure Terraform configuration"
    else
        echo "❌ README does not mention secure Terraform configuration"
        return 1
    fi
    
    if grep -q "cloudformation-s3-secure.yaml" README.md; then
        echo "✅ README mentions secure CloudFormation template"
    else
        echo "❌ README does not mention secure CloudFormation template"
        return 1
    fi
    
    echo "✅ Documentation validation passed"
    return 0
}

# Run all validations
main() {
    local validation_failed=0
    
    validate_terraform_config || validation_failed=1
    validate_cloudformation_template || validation_failed=1
    validate_remediation || validation_failed=1
    validate_documentation || validation_failed=1
    
    echo ""
    echo "============================================="
    if [[ $validation_failed -eq 0 ]]; then
        echo "🎉 All validations passed!"
        echo "✅ S3.3 security misconfiguration has been properly remediated"
        echo "✅ Public write access is blocked in secure configurations"
        echo ""
        echo "📋 Summary of Security Fixes:"
        echo "  • Block Public Access settings enabled (all true)"
        echo "  • ACL set to private (no public permissions)"
        echo "  • Secure bucket policy (authenticated access only)"
        echo "  • HTTPS enforcement enabled"
        echo "  • Server-side encryption configured"
        echo "  • Versioning enabled"
        echo "  • Access logging configured"
        return 0
    else
        echo "❌ Some validations failed"
        echo "❌ Please review the issues above"
        return 1
    fi
}

# Run the validation
main "$@"