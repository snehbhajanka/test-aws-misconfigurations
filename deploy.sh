#!/bin/bash

# AWS Misconfiguration Test Deployment Script
# WARNING: This script deploys intentionally vulnerable infrastructure
# DO NOT USE IN PRODUCTION

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

show_help() {
    echo "AWS Misconfiguration Test Deployment Script"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  terraform-deploy-s3     Deploy SECURE S3 bucket using Terraform (SECURITY FIXED)"
    echo "  terraform-deploy-ec2    Deploy misconfigured EC2 instance using Terraform"
    echo "  terraform-destroy-s3    Destroy S3 Terraform resources"
    echo "  terraform-destroy-ec2   Destroy EC2 Terraform resources"
    echo "  cf-deploy-s3           Deploy SECURE S3 bucket using CloudFormation (SECURITY FIXED)"
    echo "  cf-deploy-ec2          Deploy misconfigured EC2 instance using CloudFormation"
    echo "  cf-destroy-s3          Destroy S3 CloudFormation stack"
    echo "  cf-destroy-ec2         Destroy EC2 CloudFormation stack"
    echo "  help                   Show this help message"
    echo ""
    echo "🔒 S3 SECURITY STATUS: Public write access BLOCKED (Issue S3.3 RESOLVED)"
    echo "⚠️  WARNING: EC2 resources remain intentionally misconfigured and vulnerable!"
    echo "⚠️  Always destroy resources after testing to avoid charges and security risks!"
}

check_requirements() {
    if ! command -v aws &> /dev/null; then
        echo "❌ AWS CLI is required but not installed."
        exit 1
    fi

    if ! aws sts get-caller-identity &> /dev/null; then
        echo "❌ AWS CLI is not configured or credentials are invalid."
        echo "Run 'aws configure' to set up your credentials."
        exit 1
    fi
}

terraform_deploy_s3() {
    echo "🚀 Deploying SECURE S3 bucket with Terraform..."
    echo "🔒 SECURITY STATUS: Public write access is BLOCKED (Issue S3.3 RESOLVED)"
    if ! command -v terraform &> /dev/null; then
        echo "❌ Terraform is required but not installed."
        exit 1
    fi
    
    mkdir -p terraform-s3-work
    cp terraform-s3-misconfigured.tf terraform-s3-work/
    cd terraform-s3-work
    terraform init
    terraform plan
    echo ""
    echo "✅ This will create a SECURE S3 bucket with public write access BLOCKED!"
    read -p "Are you sure you want to continue? (yes/no): " confirm
    if [[ $confirm == "yes" ]]; then
        terraform apply -auto-approve
        echo "✅ Secure S3 bucket deployed. Public write access is blocked!"
    else
        echo "Deployment cancelled."
    fi
    cd ..
}

terraform_deploy_ec2() {
    echo "🚀 Deploying misconfigured EC2 instance with Terraform..."
    if ! command -v terraform &> /dev/null; then
        echo "❌ Terraform is required but not installed."
        exit 1
    fi
    
    mkdir -p terraform-ec2-work
    cp terraform-ec2-misconfigured.tf terraform-ec2-work/
    cd terraform-ec2-work
    terraform init
    terraform plan
    echo ""
    echo "⚠️  WARNING: This will create a PUBLICLY ACCESSIBLE EC2 instance with weak security!"
    read -p "Are you sure you want to continue? (yes/no): " confirm
    if [[ $confirm == "yes" ]]; then
        terraform apply -auto-approve
        echo "✅ EC2 instance deployed. Remember to destroy it when done!"
    else
        echo "Deployment cancelled."
    fi
    cd ..
}

terraform_destroy_s3() {
    echo "🗑️  Destroying S3 Terraform resources..."
    if [[ -d "terraform-s3-work" ]]; then
        cd terraform-s3-work
        terraform destroy -auto-approve
        cd ..
        rm -rf terraform-s3-work
        echo "✅ S3 resources destroyed."
    else
        echo "No S3 Terraform resources found to destroy."
    fi
}

terraform_destroy_ec2() {
    echo "🗑️  Destroying EC2 Terraform resources..."
    if [[ -d "terraform-ec2-work" ]]; then
        cd terraform-ec2-work
        terraform destroy -auto-approve
        cd ..
        rm -rf terraform-ec2-work
        echo "✅ EC2 resources destroyed."
    else
        echo "No EC2 Terraform resources found to destroy."
    fi
}

cf_deploy_s3() {
    echo "🚀 Deploying SECURE S3 bucket with CloudFormation..."
    echo "🔒 SECURITY STATUS: Public write access is BLOCKED (Issue S3.3 RESOLVED)"
    echo ""
    echo "✅ This will create a SECURE S3 bucket with comprehensive security controls!"
    read -p "Are you sure you want to continue? (yes/no): " confirm
    if [[ $confirm == "yes" ]]; then
        aws cloudformation create-stack \
            --stack-name misconfigured-s3-stack \
            --template-body file://cloudformation-s3-misconfigured.yaml
        echo "✅ CloudFormation stack deployment initiated. Check AWS console for progress."
        echo "✅ Secure S3 bucket with blocked public write access will be created!"
    else
        echo "Deployment cancelled."
    fi
}

cf_deploy_ec2() {
    echo "🚀 Deploying misconfigured EC2 instance with CloudFormation..."
    echo ""
    echo "⚠️  WARNING: This will create a PUBLICLY ACCESSIBLE EC2 instance with weak security!"
    read -p "Are you sure you want to continue? (yes/no): " confirm
    if [[ $confirm == "yes" ]]; then
        aws cloudformation create-stack \
            --stack-name misconfigured-ec2-stack \
            --template-body file://cloudformation-ec2-misconfigured.yaml \
            --capabilities CAPABILITY_NAMED_IAM
        echo "✅ CloudFormation stack deployment initiated. Check AWS console for progress."
        echo "✅ Remember to destroy the stack when done!"
    else
        echo "Deployment cancelled."
    fi
}

cf_destroy_s3() {
    echo "🗑️  Destroying S3 CloudFormation stack..."
    aws cloudformation delete-stack --stack-name misconfigured-s3-stack
    echo "✅ CloudFormation stack deletion initiated. Check AWS console for progress."
}

cf_destroy_ec2() {
    echo "🗑️  Destroying EC2 CloudFormation stack..."
    aws cloudformation delete-stack --stack-name misconfigured-ec2-stack
    echo "✅ CloudFormation stack deletion initiated. Check AWS console for progress."
}

# Main script logic
case "${1:-help}" in
    terraform-deploy-s3)
        check_requirements
        terraform_deploy_s3
        ;;
    terraform-deploy-ec2)
        check_requirements
        terraform_deploy_ec2
        ;;
    terraform-destroy-s3)
        check_requirements
        terraform_destroy_s3
        ;;
    terraform-destroy-ec2)
        check_requirements
        terraform_destroy_ec2
        ;;
    cf-deploy-s3)
        check_requirements
        cf_deploy_s3
        ;;
    cf-deploy-ec2)
        check_requirements
        cf_deploy_ec2
        ;;
    cf-destroy-s3)
        check_requirements
        cf_destroy_s3
        ;;
    cf-destroy-ec2)
        check_requirements
        cf_destroy_ec2
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