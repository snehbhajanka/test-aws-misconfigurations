#!/bin/bash

# S3 Security Validation Script
# This script validates the secure S3 configuration against S3.3 requirements

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

show_help() {
    echo "S3 Security Validation Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  validate-terraform    Validate Terraform configurations"
    echo "  validate-cloudformation  Validate CloudFormation templates"
    echo "  check-s3-compliance   Check S3.3 compliance in deployed resources"
    echo "  help                  Show this help message"
}

validate_terraform() {
    echo "🔍 Validating Terraform configurations..."
    
    # Create temporary directory for validation
    mkdir -p /tmp/terraform-validation
    
    echo "📋 Validating misconfigured S3 configuration..."
    cp terraform-s3-misconfigured.tf /tmp/terraform-validation/
    cd /tmp/terraform-validation
    terraform init -input=false
    terraform validate
    echo "✅ Misconfigured S3 Terraform syntax is valid"
    
    echo ""
    echo "📋 Validating secure S3 configuration..."
    rm -f *.tf
    cp "$SCRIPT_DIR/terraform-s3-secure.tf" .
    terraform init -input=false
    terraform validate
    echo "✅ Secure S3 Terraform syntax is valid"
    
    cd "$SCRIPT_DIR"
    rm -rf /tmp/terraform-validation
    
    echo ""
    echo "🔐 Checking S3.3 compliance in secure configuration..."
    
    # Check for required security settings
    if grep -q "block_public_acls.*=.*true" terraform-s3-secure.tf && \
       grep -q "block_public_policy.*=.*true" terraform-s3-secure.tf && \
       grep -q "ignore_public_acls.*=.*true" terraform-s3-secure.tf && \
       grep -q "restrict_public_buckets.*=.*true" terraform-s3-secure.tf; then
        echo "✅ Public access block settings are properly configured"
    else
        echo "❌ Public access block settings are not properly configured"
        exit 1
    fi
    
    if grep -q 'acl.*=.*"private"' terraform-s3-secure.tf; then
        echo "✅ ACL is set to private"
    else
        echo "❌ ACL is not set to private"
        exit 1
    fi
    
    if grep -q '"s3:PutObject"' terraform-s3-secure.tf && grep -q '"s3:DeleteObject"' terraform-s3-secure.tf && grep -q 'Effect.*=.*"Deny"' terraform-s3-secure.tf; then
        echo "✅ Bucket policy denies public write access"
    else
        echo "❌ Bucket policy does not properly deny public write access"
        exit 1
    fi
    
    echo "✅ Terraform S3.3 compliance validation passed!"
}

validate_cloudformation() {
    echo "🔍 Validating CloudFormation templates..."
    
    if command -v aws &> /dev/null; then
        echo "📋 Validating misconfigured S3 template..."
        aws cloudformation validate-template --template-body file://cloudformation-s3-misconfigured.yaml > /dev/null
        echo "✅ Misconfigured S3 CloudFormation template is valid"
        
        echo "📋 Validating secure S3 template..."
        aws cloudformation validate-template --template-body file://cloudformation-s3-secure.yaml > /dev/null
        echo "✅ Secure S3 CloudFormation template is valid"
    else
        echo "⚠️  AWS CLI not available, skipping CloudFormation validation"
        return 0
    fi
    
    echo ""
    echo "🔐 Checking S3.3 compliance in secure CloudFormation template..."
    
    # Check for required security settings
    if grep -q "BlockPublicAcls:.*true" cloudformation-s3-secure.yaml && \
       grep -q "BlockPublicPolicy:.*true" cloudformation-s3-secure.yaml && \
       grep -q "IgnorePublicAcls:.*true" cloudformation-s3-secure.yaml && \
       grep -q "RestrictPublicBuckets:.*true" cloudformation-s3-secure.yaml; then
        echo "✅ Public access block settings are properly configured"
    else
        echo "❌ Public access block settings are not properly configured"
        exit 1
    fi
    
    if grep -q "AccessControl:.*Private" cloudformation-s3-secure.yaml; then
        echo "✅ Access control is set to private"
    else
        echo "❌ Access control is not set to private"
        exit 1
    fi
    
    if grep -q "s3:PutObject" cloudformation-s3-secure.yaml && grep -q "s3:DeleteObject" cloudformation-s3-secure.yaml && grep -q "Effect:.*Deny" cloudformation-s3-secure.yaml; then
        echo "✅ Bucket policy denies public write access"
    else
        echo "❌ Bucket policy does not properly deny public write access"
        exit 1
    fi
    
    echo "✅ CloudFormation S3.3 compliance validation passed!"
}

check_s3_compliance() {
    echo "🔍 Checking S3.3 compliance in deployed AWS resources..."
    
    if ! command -v aws &> /dev/null; then
        echo "❌ AWS CLI is required but not installed."
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        echo "❌ AWS CLI is not configured or credentials are invalid."
        exit 1
    fi
    
    echo "📋 Listing S3 buckets in your account..."
    buckets=$(aws s3api list-buckets --query 'Buckets[].Name' --output text)
    
    if [ -z "$buckets" ]; then
        echo "ℹ️  No S3 buckets found in your account."
        return 0
    fi
    
    echo "🔐 Checking public access block settings for each bucket..."
    for bucket in $buckets; do
        echo "Checking bucket: $bucket"
        
        # Check public access block settings
        if aws s3api get-public-access-block --bucket "$bucket" &> /dev/null; then
            pab_settings=$(aws s3api get-public-access-block --bucket "$bucket" --query 'PublicAccessBlockConfiguration' --output json 2>/dev/null)
            
            if echo "$pab_settings" | grep -q '"BlockPublicAcls": true' && \
               echo "$pab_settings" | grep -q '"BlockPublicPolicy": true' && \
               echo "$pab_settings" | grep -q '"IgnorePublicAcls": true' && \
               echo "$pab_settings" | grep -q '"RestrictPublicBuckets": true'; then
                echo "  ✅ $bucket: S3.3 compliant (all public access blocked)"
            else
                echo "  ❌ $bucket: S3.3 non-compliant (public access not fully blocked)"
            fi
        else
            echo "  ❌ $bucket: S3.3 non-compliant (no public access block configuration)"
        fi
    done
}

# Main script logic
case "${1:-help}" in
    validate-terraform)
        validate_terraform
        ;;
    validate-cloudformation)
        validate_cloudformation
        ;;
    check-s3-compliance)
        check_s3_compliance
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "❌ Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac