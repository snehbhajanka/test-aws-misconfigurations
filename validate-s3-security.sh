#!/bin/bash

# S3 Security Validation Script
# This script validates that S3 buckets have proper security configurations

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

show_help() {
    echo "S3 Security Validation Script"
    echo ""
    echo "Usage: $0 [COMMAND] [BUCKET_NAME]"
    echo ""
    echo "Commands:"
    echo "  validate-config     Validate Terraform configuration files"
    echo "  check-bucket        Check actual S3 bucket security settings (requires bucket name)"
    echo "  help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 validate-config"
    echo "  $0 check-bucket my-secure-bucket-12345678"
}

# Function to validate Terraform configuration files
validate_terraform_config() {
    echo "🔍 Validating Terraform S3 configurations..."
    echo ""
    
    # Check if secure configuration exists
    if [[ ! -f "terraform-s3-secure.tf" ]]; then
        echo "❌ terraform-s3-secure.tf not found"
        return 1
    fi
    
    echo "✅ Found terraform-s3-secure.tf"
    
    # Check for security settings in secure configuration
    echo "🔍 Checking security settings in secure configuration..."
    
    # Check Block Public Access settings
    if grep -q "block_public_acls.*=.*true" terraform-s3-secure.tf; then
        echo "✅ Block Public ACLs: Enabled"
    else
        echo "❌ Block Public ACLs: Not properly configured"
    fi
    
    if grep -q "block_public_policy.*=.*true" terraform-s3-secure.tf; then
        echo "✅ Block Public Policy: Enabled"
    else
        echo "❌ Block Public Policy: Not properly configured"
    fi
    
    if grep -q "ignore_public_acls.*=.*true" terraform-s3-secure.tf; then
        echo "✅ Ignore Public ACLs: Enabled"
    else
        echo "❌ Ignore Public ACLs: Not properly configured"
    fi
    
    if grep -q "restrict_public_buckets.*=.*true" terraform-s3-secure.tf; then
        echo "✅ Restrict Public Buckets: Enabled"
    else
        echo "❌ Restrict Public Buckets: Not properly configured"
    fi
    
    # Check ACL setting
    if grep -q 'acl.*=.*"private"' terraform-s3-secure.tf; then
        echo "✅ Bucket ACL: Private"
    else
        echo "❌ Bucket ACL: Not set to private"
    fi
    
    # Check encryption
    if grep -q "aws_s3_bucket_server_side_encryption_configuration" terraform-s3-secure.tf; then
        echo "✅ Server-side encryption: Configured"
    else
        echo "❌ Server-side encryption: Not configured"
    fi
    
    # Check versioning
    if grep -q 'status.*=.*"Enabled"' terraform-s3-secure.tf; then
        echo "✅ Versioning: Enabled"
    else
        echo "❌ Versioning: Not enabled"
    fi
    
    echo ""
    echo "🔍 Checking misconfigured file for comparison..."
    
    # Check misconfigured settings
    if grep -q "block_public_acls.*=.*false" terraform-s3-misconfigured.tf; then
        echo "⚠️  Misconfigured file has Block Public ACLs disabled (as expected for demo)"
    fi
    
    if grep -q 'acl.*=.*"public-read-write"' terraform-s3-misconfigured.tf; then
        echo "⚠️  Misconfigured file has public-read-write ACL (as expected for demo)"
    fi
    
    echo ""
    echo "✅ Configuration validation complete!"
}

# Function to check actual S3 bucket settings
check_bucket_security() {
    local bucket_name="$1"
    
    if [[ -z "$bucket_name" ]]; then
        echo "❌ Bucket name is required for this command"
        echo "Usage: $0 check-bucket <bucket-name>"
        return 1
    fi
    
    echo "🔍 Checking security settings for bucket: $bucket_name"
    echo ""
    
    # Check if AWS CLI is available
    if ! command -v aws &> /dev/null; then
        echo "❌ AWS CLI is required but not installed."
        return 1
    fi
    
    # Check if bucket exists and is accessible
    if ! aws s3api head-bucket --bucket "$bucket_name" &> /dev/null; then
        echo "❌ Cannot access bucket '$bucket_name'. Check if it exists and you have permissions."
        return 1
    fi
    
    echo "✅ Bucket '$bucket_name' is accessible"
    
    # Check Public Access Block settings
    echo "🔍 Checking Public Access Block settings..."
    
    if public_access_block=$(aws s3api get-public-access-block --bucket "$bucket_name" 2>/dev/null); then
        echo "$public_access_block" | jq -r '
            .PublicAccessBlockConfiguration | 
            "Block Public ACLs: " + (.BlockPublicAcls | tostring) + 
            "\nIgnore Public ACLs: " + (.IgnorePublicAcls | tostring) + 
            "\nBlock Public Policy: " + (.BlockPublicPolicy | tostring) + 
            "\nRestrict Public Buckets: " + (.RestrictPublicBuckets | tostring)'
        
        # Check if all settings are true
        all_blocked=$(echo "$public_access_block" | jq -r '.PublicAccessBlockConfiguration | [.BlockPublicAcls, .IgnorePublicAcls, .BlockPublicPolicy, .RestrictPublicBuckets] | all')
        
        if [[ "$all_blocked" == "true" ]]; then
            echo "✅ All Public Access Block settings are enabled - public write access is blocked!"
        else
            echo "❌ Some Public Access Block settings are disabled - bucket may allow public write access!"
        fi
    else
        echo "❌ Could not retrieve Public Access Block settings (they may not be configured)"
    fi
    
    echo ""
    echo "🔍 Checking bucket ACL..."
    
    # Check bucket ACL
    if bucket_acl=$(aws s3api get-bucket-acl --bucket "$bucket_name" 2>/dev/null); then
        public_grants=$(echo "$bucket_acl" | jq -r '.Grants[] | select(.Grantee.URI? // "" | contains("AllUsers") or contains("AuthenticatedUsers")) | .Permission' | wc -l)
        
        if [[ "$public_grants" -eq 0 ]]; then
            echo "✅ No public ACL grants found - bucket ACL is secure"
        else
            echo "❌ Found $public_grants public ACL grants - bucket may allow public access"
            echo "$bucket_acl" | jq -r '.Grants[] | select(.Grantee.URI? // "" | contains("AllUsers") or contains("AuthenticatedUsers"))'
        fi
    else
        echo "❌ Could not retrieve bucket ACL"
    fi
    
    echo ""
    echo "🔍 Checking bucket policy..."
    
    # Check bucket policy
    if bucket_policy=$(aws s3api get-bucket-policy --bucket "$bucket_name" 2>/dev/null); then
        public_statements=$(echo "$bucket_policy" | jq -r '.Policy | fromjson | .Statement[] | select(.Principal == "*" or .Principal.AWS? == "*") | .Effect + ": " + (.Action | if type == "array" then join(", ") else . end)')
        
        if [[ -n "$public_statements" ]]; then
            echo "⚠️  Found public policy statements:"
            echo "$public_statements"
        else
            echo "✅ No wildcard public policy statements found"
        fi
    else
        echo "✅ No bucket policy found (or access denied)"
    fi
    
    echo ""
    echo "✅ Bucket security check complete!"
}

# Main script logic
case "${1:-help}" in
    validate-config)
        validate_terraform_config
        ;;
    check-bucket)
        check_bucket_security "$2"
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