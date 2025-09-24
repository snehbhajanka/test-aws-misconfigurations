# AWS Misconfiguration Test Repository

This repository contains intentionally misconfigured AWS infrastructure files designed for security testing, penetration testing, and educational purposes. **DO NOT USE THESE CONFIGURATIONS IN PRODUCTION ENVIRONMENTS.**

## Files Included

### Terraform Files
1. **terraform-s3-misconfigured.tf** - Misconfigured S3 bucket with public access
2. **terraform-ec2-misconfigured.tf** - Misconfigured EC2 instance with multiple security vulnerabilities
3. **terraform-s3-secure.tf** - ✅ **SECURE** S3 bucket configuration (S3.3 compliant)

### CloudFormation Files
1. **cloudformation-s3-misconfigured.yaml** - Misconfigured S3 bucket using CloudFormation
2. **cloudformation-ec2-misconfigured.yaml** - Misconfigured EC2 instance using CloudFormation
3. **cloudformation-s3-secure.yaml** - ✅ **SECURE** S3 bucket configuration (S3.3 compliant)
4. **cloudformation-rds-misconfig.yaml** - Misconfigured RDS instance
5. **cloudformation-sg-misconfig.yaml** - Misconfigured Security Group

## Security Misconfigurations Included

### S3 Bucket Misconfigurations (Vulnerable)
- ❌ Public access block disabled
- ❌ Public read/write ACL permissions
- ❌ No server-side encryption
- ❌ Versioning disabled
- ❌ No access logging
- ❌ Public bucket policy allowing full access
- ❌ No lifecycle policies
- ❌ No CloudTrail monitoring

### S3 Bucket Secure Configuration (✅ Best Practices)
- ✅ **Block Public Access enabled (S3.3 compliant)**
- ✅ **Private ACL configuration**
- ✅ **Account-restricted bucket policy (no public access)**
- ✅ **Server-side encryption enabled**
- ✅ **Versioning enabled**
- ✅ **Access logging configured**
- ✅ **Lifecycle policies implemented**
- ✅ **Addresses AWS Security Hub S3.3 control**

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
# For MISCONFIGURED S3 bucket (vulnerable)
terraform init
terraform plan -var-file="terraform-s3-misconfigured.tf"
terraform apply -var-file="terraform-s3-misconfigured.tf"

# For SECURE S3 bucket (S3.3 compliant)
terraform init
terraform plan -var-file="terraform-s3-secure.tf"
terraform apply -var-file="terraform-s3-secure.tf"

# For EC2 misconfigured instance
terraform init
terraform plan -var-file="terraform-ec2-misconfigured.tf"
terraform apply -var-file="terraform-ec2-misconfigured.tf"
```

### CloudFormation Deployment
```bash
# For MISCONFIGURED S3 bucket (vulnerable)
aws cloudformation create-stack \
  --stack-name misconfigured-s3-stack \
  --template-body file://cloudformation-s3-misconfigured.yaml

# For SECURE S3 bucket (S3.3 compliant)
aws cloudformation create-stack \
  --stack-name secure-s3-stack \
  --template-body file://cloudformation-s3-secure.yaml

# For EC2 misconfigured instance
aws cloudformation create-stack \
  --stack-name misconfigured-ec2-stack \
  --template-body file://cloudformation-ec2-misconfigured.yaml \
  --capabilities CAPABILITY_NAMED_IAM
```

### Using the Deploy Script
```bash
# Deploy vulnerable resources for testing
./deploy.sh terraform-deploy-s3        # Deploy misconfigured S3
./deploy.sh cf-deploy-s3              # Deploy misconfigured S3 via CloudFormation

# Deploy secure resources (production-ready)
./deploy.sh terraform-deploy-s3-secure # Deploy secure S3 (S3.3 compliant)
./deploy.sh cf-deploy-s3-secure       # Deploy secure S3 via CloudFormation

# Destroy resources
./deploy.sh terraform-destroy-s3-secure
./deploy.sh cf-destroy-s3-secure
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

## 🛡️ AWS Security Hub S3.3 Control Implementation

This repository now includes **secure S3 configurations** that address AWS Security Hub control **S3.3: S3 general purpose buckets should block public write access**.

### What is S3.3?
AWS Security Hub S3.3 control ensures that S3 buckets block public write access to prevent:
- Unauthorized data uploads
- Data corruption by malicious actors
- Compliance violations (PCI DSS, NIST 800-53)
- Reputation damage from hosting malicious content

### Secure Implementation Features:
✅ **Block Public Access Configuration**:
- `BlockPublicAcls: true`
- `IgnorePublicAcls: true` 
- `BlockPublicPolicy: true`
- `RestrictPublicBuckets: true`

✅ **Private ACL** instead of public-read-write
✅ **Account-restricted bucket policy** instead of wildcard Principal
✅ **Additional security enhancements**: encryption, versioning, logging

### Files:
- `terraform-s3-secure.tf` - Terraform secure configuration
- `cloudformation-s3-secure.yaml` - CloudFormation secure configuration

Compare these with the vulnerable versions to understand the differences!

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