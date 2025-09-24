# AWS Misconfiguration Test Repository

This repository contains intentionally misconfigured AWS infrastructure files designed for security testing, penetration testing, and educational purposes. **DO NOT USE THESE CONFIGURATIONS IN PRODUCTION ENVIRONMENTS.**

## Files Included

### Terraform Files
1. **terraform-s3-misconfigured.tf** - Misconfigured S3 bucket with public access
2. **terraform-s3-secure.tf** - ✅ **REMEDIATED** - Secure S3 bucket configuration blocking public write access
3. **terraform-ec2-misconfigured.tf** - Misconfigured EC2 instance with multiple security vulnerabilities

### CloudFormation Files
1. **cloudformation-s3-misconfigured.yaml** - Misconfigured S3 bucket using CloudFormation
2. **cloudformation-s3-secure.yaml** - ✅ **REMEDIATED** - Secure S3 bucket using CloudFormation
3. **cloudformation-ec2-misconfigured.yaml** - Misconfigured EC2 instance using CloudFormation
4. **cloudformation-rds-misconfig.yaml** - Misconfigured RDS instance with security issues
5. **cloudformation-sg-misconfig.yaml** - Misconfigured Security Group with overly permissive rules

### Scripts
1. **deploy.sh** - Automated deployment script for all configurations
2. **validate-s3-security.sh** - ✅ **SECURITY VALIDATION** - Script to validate S3 security configurations

## S3 Security Remediation

### Problem: S3 Buckets with Public Write Access
The misconfigured S3 buckets in this repository allow public write access, which poses critical security risks:
- **Data Loss**: Unauthorized users can delete or overwrite data
- **Data Corruption**: Malicious actors can modify data
- **Compliance Violations**: May violate PCI DSS, NIST 800-53, and other regulations
- **Reputation Damage**: Hosting malicious content can harm organization reputation
- **Financial Loss**: Increased costs from unauthorized usage

### Solution: Block Public Access Configuration
The remediated versions (`terraform-s3-secure.tf` and `cloudformation-s3-secure.yaml`) implement the following security controls:

#### 1. Block Public Access Settings (Critical Fix)
```hcl
# Terraform
resource "aws_s3_bucket_public_access_block" "secure_pab" {
  bucket = aws_s3_bucket.secure_bucket.id
  
  block_public_acls       = true  # Block new public ACLs
  block_public_policy     = true  # Block public bucket policies
  ignore_public_acls      = true  # Ignore existing public ACLs
  restrict_public_buckets = true  # Restrict access to public buckets
}
```

```yaml
# CloudFormation
PublicAccessBlockConfiguration:
  BlockPublicAcls: true
  BlockPublicPolicy: true
  IgnorePublicAcls: true
  RestrictPublicBuckets: true
```

#### 2. Additional Security Improvements
- ✅ Private ACL instead of public-read-write
- ✅ Secure bucket policy with HTTPS-only access
- ✅ Server-side encryption enabled
- ✅ Versioning enabled for data protection
- ✅ Access logging configured
- ✅ Lifecycle policies for cost optimization

#### 3. AWS CLI Remediation Commands
```bash
# Block public access on existing bucket
aws s3api put-public-access-block \
  --bucket <your-bucket-name> \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# Verify settings
aws s3api get-public-access-block --bucket <your-bucket-name>
```

## Security Misconfigurations Included

### S3 Bucket Misconfigurations
- ❌ Public access block disabled
- ❌ Public read/write ACL permissions
- ❌ No server-side encryption
- ❌ Versioning disabled
- ❌ No access logging
- ❌ Public bucket policy allowing full access
- ❌ No lifecycle policies
- ❌ No CloudTrail monitoring

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

### Quick Start with Secure Configurations (Recommended)
```bash
# Deploy secure S3 bucket with Terraform
./deploy.sh terraform-deploy-s3-secure

# Deploy secure S3 bucket with CloudFormation  
./deploy.sh cf-deploy-s3-secure

# Validate configurations
./validate-s3-security.sh validate-config

# Clean up when done
./deploy.sh terraform-destroy-s3-secure
./deploy.sh cf-destroy-s3-secure
```

### Testing Misconfigurations (Use with Caution)
```bash
# Deploy intentionally misconfigured resources (NOT RECOMMENDED for production testing)
./deploy.sh terraform-deploy-s3
./deploy.sh cf-deploy-s3

# Always clean up immediately after testing
./deploy.sh terraform-destroy-s3
./deploy.sh cf-destroy-s3
```

### Validation and Testing
```bash
# Validate Terraform configurations
./validate-s3-security.sh validate-config

# Check actual deployed bucket security (requires bucket name)
./validate-s3-security.sh check-bucket my-secure-bucket-12345678
```

### Prerequisites
- AWS CLI configured with appropriate credentials
- Terraform installed (for .tf files)
- CloudFormation access (for .yaml files)
- jq installed (for validation script)

### Manual Deployment (Legacy)

#### Terraform Deployment
```bash
# For S3 misconfigured bucket
terraform init
terraform plan -var-file="terraform-s3-misconfigured.tf"
terraform apply -var-file="terraform-s3-misconfigured.tf"

# For S3 SECURE bucket (recommended)
terraform init  
terraform plan -var-file="terraform-s3-secure.tf"
terraform apply -var-file="terraform-s3-secure.tf"

# For EC2 misconfigured instance
terraform init
terraform plan -var-file="terraform-ec2-misconfigured.tf"
terraform apply -var-file="terraform-ec2-misconfigured.tf"
```

#### CloudFormation Deployment
```bash
# For S3 misconfigured bucket
aws cloudformation create-stack \
  --stack-name misconfigured-s3-stack \
  --template-body file://cloudformation-s3-misconfigured.yaml

# For S3 SECURE bucket (recommended)
aws cloudformation create-stack \
  --stack-name secure-s3-stack \
  --template-body file://cloudformation-s3-secure.yaml

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