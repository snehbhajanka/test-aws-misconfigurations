#!/bin/bash

# S3 Public Write Access Validation Script
# This script validates that S3 buckets properly block public write access
# Addresses AWS Security Hub control S3.3

set -e

echo "🔍 S3 Public Write Access Validation Script"
echo "==========================================="
echo ""

# Function to validate Terraform syntax
validate_terraform_syntax() {
    local file=$1
    echo "📝 Validating Terraform syntax for $file..."
    
    if command -v terraform &> /dev/null; then
        # Create temporary directory for validation
        temp_dir=$(mktemp -d)
        cp "$file" "$temp_dir/"
        cd "$temp_dir"
        
        if terraform fmt -check=true -diff=true "$file" &> /dev/null; then
            echo "✅ Terraform syntax valid for $file"
        else
            echo "⚠️  Terraform formatting issues in $file (auto-fixable)"
        fi
        
        if terraform validate &> /dev/null; then
            echo "✅ Terraform configuration valid for $file"
        else
            echo "❌ Terraform validation failed for $file"
            terraform validate
        fi
        
        cd - > /dev/null
        rm -rf "$temp_dir"
    else
        echo "⚠️  Terraform not installed, skipping syntax validation"
    fi
    echo ""
}

# Function to validate CloudFormation syntax
validate_cloudformation_syntax() {
    local file=$1
    echo "📝 Validating CloudFormation syntax for $file..."
    
    if command -v aws &> /dev/null; then
        if aws cloudformation validate-template --template-body "file://$file" &> /dev/null; then
            echo "✅ CloudFormation template valid for $file"
        else
            echo "❌ CloudFormation validation failed for $file"
            aws cloudformation validate-template --template-body "file://$file"
        fi
    else
        echo "⚠️  AWS CLI not installed, skipping CloudFormation validation"
    fi
    echo ""
}

# Function to check S3 configuration compliance
check_s3_compliance() {
    local file=$1
    local config_type=$2
    echo "🔒 Checking S3.3 control compliance for $file ($config_type)..."
    
    case $config_type in
        "misconfigured")
            if grep -q "block_public_acls.*=.*false" "$file" && \
               grep -q "public-read-write" "$file" && \
               grep -q "s3:PutObject" "$file" && \
               grep -q "s3:DeleteObject" "$file"; then
                echo "❌ VULNERABLE: Public write access enabled (expected for misconfigured example)"
            else
                echo "⚠️  Configuration may not demonstrate vulnerability clearly"
            fi
            ;;
        "remediated")
            # Simple check - look for the actual ACL setting
            if grep -q 'acl.*=.*"public-read"' "$file" && \
               grep -q "block_public_acls.*=.*true" "$file" && \
               grep -q "block_public_policy.*=.*true" "$file"; then
                echo "✅ SECURE: Public write access blocked (S3.3 compliant)"
            else
                echo "❌ Configuration may still allow public write access"
            fi
            ;;
        "secure")
            if grep -q "block_public_acls.*=.*true" "$file" && \
               grep -q "block_public_policy.*=.*true" "$file" && \
               grep -q "ignore_public_acls.*=.*true" "$file" && \
               grep -q "restrict_public_buckets.*=.*true" "$file"; then
                echo "✅ SECURE: Full public access blocked (S3.3 compliant + enhanced)"
            else
                echo "❌ Configuration may not fully block public access"
            fi
            ;;
        "cloudformation-secure")
            if grep -q "BlockPublicAcls:.*true" "$file" && \
               grep -q "BlockPublicPolicy:.*true" "$file" && \
               grep -q "IgnorePublicAcls:.*true" "$file" && \
               grep -q "RestrictPublicBuckets:.*true" "$file"; then
                echo "✅ SECURE: Full public access blocked (S3.3 compliant + enhanced)"
            else
                echo "❌ Configuration may not fully block public access"
            fi
            ;;
    esac
    echo ""
}

# Main validation
echo "🚀 Starting validation..."
echo ""

# Validate Terraform files
if [[ -f "terraform-s3-misconfigured.tf" ]]; then
    validate_terraform_syntax "terraform-s3-misconfigured.tf"
    check_s3_compliance "terraform-s3-misconfigured.tf" "misconfigured"
fi

if [[ -f "terraform-s3-remediated.tf" ]]; then
    validate_terraform_syntax "terraform-s3-remediated.tf"
    check_s3_compliance "terraform-s3-remediated.tf" "remediated"
fi

if [[ -f "terraform-s3-secure.tf" ]]; then
    validate_terraform_syntax "terraform-s3-secure.tf"
    check_s3_compliance "terraform-s3-secure.tf" "secure"
fi

# Validate CloudFormation files
if [[ -f "cloudformation-s3-secure.yaml" ]]; then
    validate_cloudformation_syntax "cloudformation-s3-secure.yaml"
    check_s3_compliance "cloudformation-s3-secure.yaml" "cloudformation-secure"
fi

echo "✅ Validation completed!"
echo ""
echo "📋 Summary:"
echo "- terraform-s3-misconfigured.tf: Demonstrates public write vulnerability"
echo "- terraform-s3-remediated.tf: Fixes public write access (S3.3 control)"
echo "- terraform-s3-secure.tf: Full security implementation" 
echo "- cloudformation-s3-secure.yaml: CloudFormation secure implementation"
echo ""
echo "🎯 AWS Security Hub Control S3.3: S3 general purpose buckets should block public write access"
echo "📖 More info: https://docs.aws.amazon.com/securityhub/latest/userguide/s3-controls.html#s3-3"