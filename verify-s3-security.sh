#!/bin/bash

# S3 Security Verification Script
# This script validates that S3 security fixes have been applied correctly

set -e

echo "🔒 S3 Security Verification Script"
echo "=================================="

# Function to check Terraform configuration
check_terraform_s3() {
    echo ""
    echo "📋 Checking Terraform S3 configuration..."
    
    local tf_file="terraform-s3-misconfigured.tf"
    
    if [[ ! -f "$tf_file" ]]; then
        echo "❌ Terraform file not found: $tf_file"
        return 1
    fi
    
    # Check public access block settings
    if grep -q "block_public_acls.*=.*true" "$tf_file" && \
       grep -q "block_public_policy.*=.*true" "$tf_file" && \
       grep -q "ignore_public_acls.*=.*true" "$tf_file" && \
       grep -q "restrict_public_buckets.*=.*true" "$tf_file"; then
        echo "✅ Public access block settings are correctly configured"
    else
        echo "❌ Public access block settings are not properly configured"
        return 1
    fi
    
    # Check ACL is private
    if grep -q 'acl.*=.*"private"' "$tf_file"; then
        echo "✅ Bucket ACL is set to private"
    else
        echo "❌ Bucket ACL is not set to private"
        return 1
    fi
    
    # Check that public bucket policy is removed/commented
    if ! grep -q 'resource "aws_s3_bucket_policy"' "$tf_file" || \
       grep -q '# resource "aws_s3_bucket_policy"' "$tf_file"; then
        echo "✅ Public bucket policy is removed or commented out"
    else
        echo "❌ Public bucket policy is still active"
        return 1
    fi
    
    echo "✅ Terraform S3 configuration passes security checks"
}

# Function to check CloudFormation configuration
check_cloudformation_s3() {
    echo ""
    echo "📋 Checking CloudFormation S3 configuration..."
    
    local cf_file="cloudformation-s3-misconfigured.yaml"
    
    if [[ ! -f "$cf_file" ]]; then
        echo "❌ CloudFormation file not found: $cf_file"
        return 1
    fi
    
    # Check public access block configuration
    if grep -q "BlockPublicAcls: true" "$cf_file" && \
       grep -q "IgnorePublicAcls: true" "$cf_file" && \
       grep -q "BlockPublicPolicy: true" "$cf_file" && \
       grep -q "RestrictPublicBuckets: true" "$cf_file"; then
        echo "✅ CloudFormation public access block settings are correct"
    else
        echo "❌ CloudFormation public access block settings are missing or incorrect"
        return 1
    fi
    
    # Check for encryption
    if grep -q "BucketEncryption:" "$cf_file"; then
        echo "✅ CloudFormation template includes encryption configuration"
    else
        echo "⚠️  CloudFormation template could include encryption configuration"
    fi
    
    # Check for versioning
    if grep -q "VersioningConfiguration:" "$cf_file"; then
        echo "✅ CloudFormation template includes versioning configuration"
    else
        echo "⚠️  CloudFormation template could include versioning configuration"
    fi
    
    echo "✅ CloudFormation S3 configuration passes security checks"
}

# Function to validate YAML syntax
validate_yaml() {
    echo ""
    echo "📋 Validating YAML syntax..."
    
    if command -v yamllint &> /dev/null; then
        for yaml_file in *.yaml; do
            if [[ -f "$yaml_file" ]]; then
                echo "Checking $yaml_file..."
                if yamllint "$yaml_file" >/dev/null 2>&1; then
                    echo "✅ $yaml_file syntax is valid"
                else
                    echo "❌ $yaml_file has syntax issues"
                fi
            fi
        done
    else
        echo "⚠️  yamllint not available, skipping YAML validation"
    fi
}

# Main execution
main() {
    echo "Starting S3 security verification..."
    
    check_terraform_s3
    check_cloudformation_s3
    validate_yaml
    
    echo ""
    echo "🎉 S3 Security Verification Complete!"
    echo ""
    echo "Summary of fixes applied:"
    echo "• Public write access blocked (AWS Security Hub S3.3 compliance)"
    echo "• All public access block settings enabled"
    echo "• Bucket ACL set to private"
    echo "• Public bucket policies removed"
    echo "• CloudFormation templates follow security best practices"
    echo ""
    echo "The S3 configurations now prevent unauthorized public write access."
}

# Run the script
main "$@"