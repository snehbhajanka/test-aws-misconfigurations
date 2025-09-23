# AWS Misconfiguration Test Repository

This repository contains intentionally misconfigured AWS infrastructure files designed for security testing, penetration testing, and educational purposes. **DO NOT USE THESE CONFIGURATIONS IN PRODUCTION ENVIRONMENTS.**

## Files Included

### Terraform Files
1. **terraform-s3-misconfigured.tf** - Misconfigured S3 bucket with public access (for security testing)
2. **terraform-s3-secure.tf** - Secure S3 bucket with proper access controls (production-ready)
3. **terraform-ec2-misconfigured.tf** - Misconfigured EC2 instance with multiple security vulnerabilities

### CloudFormation Files
1. **cloudformation-s3-misconfigured.yaml** - Misconfigured S3 bucket using CloudFormation
2. **cloudformation-ec2-misconfigured.yaml** - Misconfigured EC2 instance using CloudFormation

## Security Misconfigurations Included

### S3 Bucket Configurations

#### Misconfigured S3 Bucket (Security Testing Only)
- ❌ Public access block disabled
- ❌ Public read/write ACL permissions
- ❌ No server-side encryption
- ❌ Versioning disabled
- ❌ No access logging
- ❌ Public bucket policy allowing full access
- ❌ No lifecycle policies
- ❌ No CloudTrail monitoring

#### Secure S3 Bucket (Production Ready)
- ✅ Public access block enabled (all settings = true)
- ✅ Private ACL permissions only
- ✅ Server-side encryption enabled (AES256)
- ✅ Versioning enabled
- ✅ Access logging configured
- ✅ No public bucket policies
- ✅ Lifecycle policies configured
- ✅ Follows AWS Security Hub Control ID S3.2

### EC2 Instance Misconfigurations
- ❌ Security groups allowing access from 0.0.0.0/0 on multiple ports (SSH, RDP, HTTP, HTTPS, databases)
- ❌ IAM roles with excessive permissions (PowerUserAccess, IAMFullAccess)
- ❌ Hardcoded credentials in user data
- ❌ Unencrypted EBS volumes
- ❌ IMDSv1 enabled (vulnerable to SSRF attacks)
- ❌ No detailed monitoring
- ❌ Public IP assignment
- ❌ Weak user passwords
- ❌ SSH password authentication enabled
- ❌ Firewall disabled
- ❌ Sudo access without password requirements
- ❌ Sensitive information exposed via web interface

## Usage

### Prerequisites
- AWS CLI configured with appropriate credentials
- Terraform installed (for .tf files)
- CloudFormation access (for .yaml files)

### Terraform Deployment
```bash
# For S3 misconfigured bucket (testing only)
terraform init
terraform plan -var-file="terraform-s3-misconfigured.tf"
terraform apply -var-file="terraform-s3-misconfigured.tf"

# For S3 secure bucket (production ready)
terraform init
terraform plan -var-file="terraform-s3-secure.tf"
terraform apply -var-file="terraform-s3-secure.tf"

# For EC2 misconfigured instance
terraform init
terraform plan -var-file="terraform-ec2-misconfigured.tf"
terraform apply -var-file="terraform-ec2-misconfigured.tf"
```

### Using the Deploy Script
```bash
# Deploy misconfigured S3 bucket for testing
./deploy.sh terraform-deploy-s3-misconfig

# Deploy secure S3 bucket for production
./deploy.sh terraform-deploy-s3-secure

# Deploy misconfigured EC2 instance for testing
./deploy.sh terraform-deploy-ec2

# Destroy S3 resources (handles both configurations)
./deploy.sh terraform-destroy-s3

# Destroy EC2 resources
./deploy.sh terraform-destroy-ec2

# Show help
./deploy.sh help
```

### CloudFormation Deployment
```bash
# For S3 misconfigured bucket
aws cloudformation create-stack \
  --stack-name misconfigured-s3-stack \
  --template-body file://cloudformation-s3-misconfigured.yaml

# For EC2 misconfigured instance
aws cloudformation create-stack \
  --stack-name misconfigured-ec2-stack \
  --template-body file://cloudformation-ec2-misconfigured.yaml \
  --capabilities CAPABILITY_NAMED_IAM
```

## Security Testing Tools

These misconfigurations can be detected by various security scanning tools:
- **AWS Config Rules**
- **AWS Security Hub**
- **AWS Inspector**
- **Scout Suite**
- **Prowler**
- **CloudSploit**
- **Checkov**
- **Terrascan**
- **tfsec**

## S3 Security Best Practices

This repository now includes both misconfigured and secure S3 bucket configurations to demonstrate the difference:

### ❌ Misconfigured S3 (terraform-s3-misconfigured.tf)
- Public access block disabled - allows public access
- Public read/write ACL - anyone can read/write
- No encryption - data stored in plain text
- No versioning - no protection against accidental deletion
- Public bucket policy - unrestricted access

### ✅ Secure S3 (terraform-s3-secure.tf)
- **Public access block enabled** - Blocks all public access (AWS Security Hub Control S3.2)
- **Private ACL only** - Restricts access to authorized users
- **Server-side encryption** - Data encrypted at rest
- **Versioning enabled** - Protection against accidental deletion
- **Access logging** - Audit trail of bucket access
- **Lifecycle policies** - Cost optimization and data management

The secure configuration addresses **AWS Security Hub Control ID S3.2**: *S3 general purpose buckets should block public read access*

## ⚠️ Important Warnings

1. **DO NOT deploy these in production environments**
2. **These resources will incur AWS charges**
3. **Public S3 buckets may be discovered and abused by attackers**
4. **EC2 instances with weak security groups are vulnerable to attacks**
5. **Always destroy resources after testing**: `terraform destroy` or `aws cloudformation delete-stack`
6. **Monitor your AWS bill and usage during testing**

## Educational Use Cases

- Security training and awareness
- Penetration testing practice
- Security tool validation
- Infrastructure security scanning
- DevSecOps pipeline testing
- Compliance testing

## Cleanup

Always remember to clean up resources after testing:

```bash
# Terraform cleanup
terraform destroy

# CloudFormation cleanup
aws cloudformation delete-stack --stack-name misconfigured-s3-stack
aws cloudformation delete-stack --stack-name misconfigured-ec2-stack
```

## Contributing

If you find additional misconfigurations that should be included or improvements to existing ones, please feel free to contribute via pull requests.

## License

This repository is for educational and testing purposes only. Use at your own risk.