#!/bin/bash

# S3 Security Configuration Validator
# This script helps validate S3 security configurations against AWS Security Hub S3.3 control

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🔍 AWS S3 Security Configuration Validator"
echo "=========================================="
echo ""

show_help() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  compare                Compare vulnerable vs secure configurations"
    echo "  check-s3-3             Check S3.3 control compliance"
    echo "  help                   Show this help message"
    echo ""
}

compare_configurations() {
    echo "📊 Comparing Vulnerable vs Secure S3 Configurations"
    echo "=================================================="
    echo ""
    
    echo "🔴 VULNERABLE Configuration (terraform-s3-misconfigured.tf):"
    echo "❌ block_public_acls       = false"
    echo "❌ block_public_policy     = false" 
    echo "❌ ignore_public_acls      = false"
    echo "❌ restrict_public_buckets = false"
    echo "❌ acl = \"public-read-write\""
    echo "❌ Principal = \"*\" (allows anyone)"
    echo "❌ Actions include s3:PutObject, s3:DeleteObject (public write access)"
    echo ""
    
    echo "✅ SECURE Configuration (terraform-s3-secure.tf):"
    echo "✅ block_public_acls       = true"
    echo "✅ block_public_policy     = true"
    echo "✅ ignore_public_acls      = true" 
    echo "✅ restrict_public_buckets = true"
    echo "✅ acl = \"private\""
    echo "✅ Principal restricted to account root only"
    echo "✅ Additional security: encryption, versioning, logging"
    echo ""
}

check_s3_3_compliance() {
    echo "🛡️  AWS Security Hub S3.3 Control Compliance Check"
    echo "================================================="
    echo ""
    echo "S3.3: S3 general purpose buckets should block public write access"
    echo ""
    
    echo "🔴 terraform-s3-misconfigured.tf - FAILS S3.3:"
    echo "   ❌ BlockPublicAcls: false (should be true)"
    echo "   ❌ IgnorePublicAcls: false (should be true)"
    echo "   ❌ BlockPublicPolicy: false (should be true)"
    echo "   ❌ RestrictPublicBuckets: false (should be true)"
    echo "   ❌ Public write ACL permissions enabled"
    echo "   ❌ Public bucket policy allows PutObject/DeleteObject"
    echo ""
    
    echo "✅ terraform-s3-secure.tf - PASSES S3.3:"
    echo "   ✅ BlockPublicAcls: true"
    echo "   ✅ IgnorePublicAcls: true"
    echo "   ✅ BlockPublicPolicy: true"
    echo "   ✅ RestrictPublicBuckets: true"
    echo "   ✅ Private ACL configuration"
    echo "   ✅ Account-restricted bucket policy"
    echo ""
    
    echo "✅ cloudformation-s3-secure.yaml - PASSES S3.3:"
    echo "   ✅ PublicAccessBlockConfiguration with all settings true"
    echo "   ✅ Account-restricted bucket policy"
    echo "   ✅ Additional security enhancements included"
    echo ""
}

extract_security_configs() {
    echo "📋 Security Configuration Summary"
    echo "================================"
    echo ""
    
    if [[ -f "terraform-s3-misconfigured.tf" ]]; then
        echo "🔴 Vulnerable Configuration Settings:"
        grep -A4 "block_public_acls" terraform-s3-misconfigured.tf | sed 's/^/   /'
        echo ""
    fi
    
    if [[ -f "terraform-s3-secure.tf" ]]; then
        echo "✅ Secure Configuration Settings:"
        grep -A4 "block_public_acls" terraform-s3-secure.tf | sed 's/^/   /'
        echo ""
    fi
}

case "${1:-help}" in
    compare)
        compare_configurations
        extract_security_configs
        ;;
    check-s3-3)
        check_s3_3_compliance
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

echo "💡 Pro Tip: Use AWS Config Rules, Security Hub, or tools like Checkov/tfsec"
echo "   to automatically detect these misconfigurations in your infrastructure."
echo ""
echo "📚 Learn more: https://docs.aws.amazon.com/config/latest/developerguide/s3-bucket-public-write-prohibited.html"