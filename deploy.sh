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
    echo "  terraform-deploy-s3-misc      Deploy misconfigured S3 bucket using Terraform"
    echo "  terraform-deploy-s3-secure    Deploy SECURE S3 bucket using Terraform (S3.3 compliant)"
    echo "  terraform-deploy-ec2          Deploy misconfigured EC2 instance using Terraform"
    echo "  terraform-destroy-s3-misc     Destroy misconfigured S3 Terraform resources"
    echo "  terraform-destroy-s3-secure   Destroy secure S3 Terraform resources"
    echo "  terraform-destroy-ec2         Destroy EC2 Terraform resources"
    echo "  cf-deploy-s3-secure          Deploy SECURE S3 bucket using CloudFormation (S3.3 compliant)"
    echo "  cf-deploy-rds                Deploy misconfigured RDS instance using CloudFormation"
    echo "  cf-deploy-sg                 Deploy misconfigured Security Group using CloudFormation"
    echo "  cf-destroy-s3-secure         Destroy secure S3 CloudFormation stack"
    echo "  cf-destroy-rds               Destroy RDS CloudFormation stack"
    echo "  cf-destroy-sg                Destroy Security Group CloudFormation stack"
    echo "  help                         Show this help message"
    echo ""
    echo "⚠️  WARNING: Misconfigured resources are intentionally vulnerable!"
    echo "✅  SECURE: Use secure configurations for production environments!"
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
    echo "🚀 Deploying misconfigured S3 bucket with Terraform..."
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
    echo "⚠️  WARNING: This will create a PUBLICLY ACCESSIBLE S3 bucket!"
    read -p "Are you sure you want to continue? (yes/no): " confirm
    if [[ $confirm == "yes" ]]; then
        terraform apply -auto-approve
        echo "✅ S3 bucket deployed. Remember to destroy it when done!"
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

terraform_deploy_s3_secure() {
    echo "🚀 Deploying SECURE S3 bucket with Terraform (S3.3 compliant)..."
    if ! command -v terraform &> /dev/null; then
        echo "❌ Terraform is required but not installed."
        exit 1
    fi
    
    mkdir -p terraform-s3-secure-work
    cp terraform-s3-secure.tf terraform-s3-secure-work/
    cd terraform-s3-secure-work
    terraform init
    terraform plan
    echo ""
    echo "✅ This will create a SECURE S3 bucket with proper access controls!"
    echo "✅ Block Public Access will be enabled (S3.3 compliant)"
    read -p "Do you want to continue? (yes/no): " confirm
    if [[ $confirm == "yes" ]]; then
        terraform apply -auto-approve
        echo "✅ Secure S3 bucket deployed successfully!"
        echo "✅ Public write access is BLOCKED (S3.3 compliant)"
        echo ""
        echo "🔍 Validation commands:"
        echo "aws s3api get-public-access-block --bucket \$(terraform output -raw secure_bucket_name)"
    else
        echo "Deployment cancelled."
    fi
    cd ..
}

terraform_destroy_s3() {
    echo "🗑️  Destroying misconfigured S3 Terraform resources..."
    if [[ -d "terraform-s3-work" ]]; then
        cd terraform-s3-work
        terraform destroy -auto-approve
        cd ..
        rm -rf terraform-s3-work
        echo "✅ Misconfigured S3 resources destroyed."
    else
        echo "No misconfigured S3 Terraform resources found to destroy."
    fi
}

terraform_destroy_s3_secure() {
    echo "🗑️  Destroying secure S3 Terraform resources..."
    if [[ -d "terraform-s3-secure-work" ]]; then
        cd terraform-s3-secure-work
        terraform destroy -auto-approve
        cd ..
        rm -rf terraform-s3-secure-work
        echo "✅ Secure S3 resources destroyed."
    else
        echo "No secure S3 Terraform resources found to destroy."
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
    echo "🚀 Deploying misconfigured S3 bucket with CloudFormation..."
    echo ""
    echo "⚠️  WARNING: This will create a PUBLICLY ACCESSIBLE S3 bucket!"
    read -p "Are you sure you want to continue? (yes/no): " confirm
    if [[ $confirm == "yes" ]]; then
        aws cloudformation create-stack \
            --stack-name misconfigured-s3-stack \
            --template-body file://cloudformation-s3-misconfigured.yaml
        echo "✅ CloudFormation stack deployment initiated. Check AWS console for progress."
        echo "✅ Remember to destroy the stack when done!"
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

cf_deploy_s3_secure() {
    echo "🚀 Deploying SECURE S3 bucket with CloudFormation (S3.3 compliant)..."
    echo ""
    echo "✅ This will create a SECURE S3 bucket with proper access controls!"
    echo "✅ Block Public Access will be enabled (S3.3 compliant)"
    read -p "Do you want to continue? (yes/no): " confirm
    if [[ $confirm == "yes" ]]; then
        aws cloudformation create-stack \
            --stack-name secure-s3-stack \
            --template-body file://cloudformation-s3-secure.yaml \
            --parameters ParameterKey=Environment,ParameterValue=Production
        echo "✅ CloudFormation stack deployment initiated. Check AWS console for progress."
        echo "✅ Public write access will be BLOCKED (S3.3 compliant)"
        echo ""
        echo "🔍 Validation commands (after deployment completes):"
        echo "aws cloudformation describe-stacks --stack-name secure-s3-stack --query 'Stacks[0].Outputs'"
    else
        echo "Deployment cancelled."
    fi
}

cf_deploy_rds() {
    echo "🚀 Deploying misconfigured RDS instance with CloudFormation..."
    echo ""
    echo "⚠️  WARNING: This will create a misconfigured RDS instance!"
    read -p "Are you sure you want to continue? (yes/no): " confirm
    if [[ $confirm == "yes" ]]; then
        aws cloudformation create-stack \
            --stack-name misconfigured-rds-stack \
            --template-body file://cloudformation-rds-misconfig.yaml
        echo "✅ CloudFormation stack deployment initiated. Check AWS console for progress."
        echo "✅ Remember to destroy the stack when done!"
    else
        echo "Deployment cancelled."
    fi
}

cf_deploy_sg() {
    echo "🚀 Deploying misconfigured Security Group with CloudFormation..."
    echo ""
    echo "⚠️  WARNING: This will create a misconfigured Security Group!"
    read -p "Are you sure you want to continue? (yes/no): " confirm
    if [[ $confirm == "yes" ]]; then
        aws cloudformation create-stack \
            --stack-name misconfigured-sg-stack \
            --template-body file://cloudformation-sg-misconfig.yaml
        echo "✅ CloudFormation stack deployment initiated. Check AWS console for progress."
        echo "✅ Remember to destroy the stack when done!"
    else
        echo "Deployment cancelled."
    fi
}

cf_destroy_s3() {
    echo "🗑️  Destroying misconfigured S3 CloudFormation stack..."
    aws cloudformation delete-stack --stack-name misconfigured-s3-stack
    echo "✅ CloudFormation stack deletion initiated. Check AWS console for progress."
}

cf_destroy_s3_secure() {
    echo "🗑️  Destroying secure S3 CloudFormation stack..."
    aws cloudformation delete-stack --stack-name secure-s3-stack
    echo "✅ CloudFormation stack deletion initiated. Check AWS console for progress."
}

cf_destroy_rds() {
    echo "🗑️  Destroying RDS CloudFormation stack..."
    aws cloudformation delete-stack --stack-name misconfigured-rds-stack
    echo "✅ CloudFormation stack deletion initiated. Check AWS console for progress."
}

cf_destroy_sg() {
    echo "🗑️  Destroying Security Group CloudFormation stack..."
    aws cloudformation delete-stack --stack-name misconfigured-sg-stack
    echo "✅ CloudFormation stack deletion initiated. Check AWS console for progress."
}

cf_destroy_ec2() {
    echo "🗑️  Destroying EC2 CloudFormation stack..."
    aws cloudformation delete-stack --stack-name misconfigured-ec2-stack
    echo "✅ CloudFormation stack deletion initiated. Check AWS console for progress."
}

# Main script logic
case "${1:-help}" in
    terraform-deploy-s3-misc)
        check_requirements
        terraform_deploy_s3
        ;;
    terraform-deploy-s3-secure)
        check_requirements
        terraform_deploy_s3_secure
        ;;
    terraform-deploy-ec2)
        check_requirements
        terraform_deploy_ec2
        ;;
    terraform-destroy-s3-misc)
        check_requirements
        terraform_destroy_s3
        ;;
    terraform-destroy-s3-secure)
        check_requirements
        terraform_destroy_s3_secure
        ;;
    terraform-destroy-ec2)
        check_requirements
        terraform_destroy_ec2
        ;;
    cf-deploy-s3-secure)
        check_requirements
        cf_deploy_s3_secure
        ;;
    cf-deploy-rds)
        check_requirements
        cf_deploy_rds
        ;;
    cf-deploy-sg)
        check_requirements
        cf_deploy_sg
        ;;
    cf-destroy-s3-secure)
        check_requirements
        cf_destroy_s3_secure
        ;;
    cf-destroy-rds)
        check_requirements
        cf_destroy_rds
        ;;
    cf-destroy-sg)
        check_requirements
        cf_destroy_sg
        ;;
    # Legacy commands for backward compatibility
    terraform-deploy-s3)
        check_requirements
        terraform_deploy_s3
        ;;
    terraform-destroy-s3)
        check_requirements
        terraform_destroy_s3
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