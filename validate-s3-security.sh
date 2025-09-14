#!/bin/bash

# S3 Security Validation Script
# Validates that the S3 bucket configuration blocks public write access

echo "🔒 S3 Security Configuration Validation"
echo "========================================"

TERRAFORM_FILE="terraform-s3-misconfigured.tf"

# Check if terraform file exists
if [ ! -f "$TERRAFORM_FILE" ]; then
    echo "❌ Error: $TERRAFORM_FILE not found"
    exit 1
fi

echo "📋 Checking S3 Security Configurations..."

# Function to check configuration
check_config() {
    local search_pattern="$1"
    local expected_value="$2"
    local description="$3"
    
    if grep -q "$search_pattern.*=.*$expected_value" "$TERRAFORM_FILE"; then
        echo "✅ $description: SECURE"
        return 0
    else
        echo "❌ $description: VULNERABLE"
        return 1
    fi
}

# Security checks
CHECKS_PASSED=0
TOTAL_CHECKS=6

echo ""
echo "🔍 Security Check Results:"
echo "-------------------------"

# Check 1: Block Public ACLs
if check_config "block_public_acls" "true" "Block Public ACLs"; then
    ((CHECKS_PASSED++))
fi

# Check 2: Ignore Public ACLs  
if check_config "ignore_public_acls" "true" "Ignore Public ACLs"; then
    ((CHECKS_PASSED++))
fi

# Check 3: Block Public Policy
if check_config "block_public_policy" "true" "Block Public Policy"; then
    ((CHECKS_PASSED++))
fi

# Check 4: Restrict Public Buckets
if check_config "restrict_public_buckets" "true" "Restrict Public Buckets"; then
    ((CHECKS_PASSED++))
fi

# Check 5: Private ACL
if check_config "acl" "private" "Private ACL"; then
    ((CHECKS_PASSED++))
fi

# Check 6: Secure bucket policy (check for Deny effect)
if check_config "Effect" "Deny" "Deny Public Access Policy"; then
    ((CHECKS_PASSED++))
fi

echo ""
echo "📊 Validation Summary:"
echo "====================="
echo "Checks Passed: $CHECKS_PASSED/$TOTAL_CHECKS"

if [ $CHECKS_PASSED -eq $TOTAL_CHECKS ]; then
    echo "🎉 SUCCESS: All S3 security configurations are properly secured!"
    echo "🔒 Public write access has been successfully blocked."
    exit 0
else
    echo "⚠️  WARNING: Some security configurations may still be vulnerable."
    echo "❌ Public write access may still be possible."
    exit 1
fi