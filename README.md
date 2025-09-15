# AWS Misconfiguration Test Repository

This repository contains intentionally misconfigured AWS infrastructure files designed for security testing, penetration testing, and educational purposes. **DO NOT USE THESE CONFIGURATIONS IN PRODUCTION ENVIRONMENTS.**

## Files Included

### Terraform Files
1. **terraform-s3-misconfigured.tf** - Misconfigured S3 bucket with public access
2. **terraform-s3-secure.tf** - ✅ **NEW**: Secure S3 bucket configuration (S3.3 compliant)
3. **terraform-ec2-misconfigured.tf** - Misconfigured EC2 instance with multiple security vulnerabilities

### CloudFormation Files
1. **cloudformation-s3-secure.yaml** - ✅ **NEW**: Secure S3 bucket using CloudFormation (S3.3 compliant)
2. **cloudformation-rds-misconfig.yaml** - Misconfigured RDS resources
3. **cloudformation-sg-misconfig.yaml** - Misconfigured Security Groups

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

### S3 Security Improvements (NEW)
- ✅ **S3.3 Compliance**: Public write access blocked
- ✅ **Secure configurations** available in `terraform-s3-secure.tf` and `cloudformation-s3-secure.yaml`
- ✅ **Best practices** demonstrated for production use
- ✅ **Educational comparison** between misconfigured and secure setups

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
# For S3 misconfigured bucket (educational/testing)
terraform init
terraform plan -var-file="terraform-s3-misconfigured.tf"
terraform apply -var-file="terraform-s3-misconfigured.tf"

# For S3 SECURE bucket (S3.3 compliant - RECOMMENDED)
terraform init
terraform plan -target="terraform-s3-secure.tf"
terraform apply -target="terraform-s3-secure.tf"

# For EC2 misconfigured instance
terraform init
terraform plan -var-file="terraform-ec2-misconfigured.tf"
terraform apply -var-file="terraform-ec2-misconfigured.tf"
```

### CloudFormation Deployment
```bash
# For S3 SECURE bucket (S3.3 compliant - RECOMMENDED)
aws cloudformation create-stack \
  --stack-name secure-s3-stack \
  --template-body file://cloudformation-s3-secure.yaml

# For misconfigured resources (educational/testing only)
aws cloudformation create-stack \
  --stack-name misconfigured-rds-stack \
  --template-body file://cloudformation-rds-misconfig.yaml

aws cloudformation create-stack \
  --stack-name misconfigured-sg-stack \
  --template-body file://cloudformation-sg-misconfig.yaml
```

## 🔒 Security Improvements

### S3.3 Compliance - Block Public Write Access
This repository now includes secure S3 configurations that address the critical S3.3 security misconfiguration:

**❌ Problem:** Public write access allows anyone to upload, modify, or delete objects
**✅ Solution:** Secure configurations block all public write access while maintaining authorized access

#### Key Security Features Implemented:
1. **Public Access Block**: All public access settings enabled
2. **Private ACLs**: Bucket ACL set to private only
3. **Restrictive Policies**: Account-scoped access policies
4. **Encryption**: Server-side encryption enabled
5. **Versioning**: Object versioning enabled for data protection

#### Comparison Files:
- **Vulnerable**: `terraform-s3-misconfigured.tf` (for educational purposes)
- **Secure**: `terraform-s3-secure.tf` (production-ready)
- **CloudFormation Secure**: `cloudformation-s3-secure.yaml` (production-ready)

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
terraform destroy  # For any terraform-deployed resources

# CloudFormation cleanup - SECURE resources
aws cloudformation delete-stack --stack-name secure-s3-stack

# CloudFormation cleanup - MISCONFIGURED resources (if deployed)
aws cloudformation delete-stack --stack-name misconfigured-rds-stack
aws cloudformation delete-stack --stack-name misconfigured-sg-stack
```

## Contributing

If you find additional misconfigurations that should be included or improvements to existing ones, please feel free to contribute via pull requests.

## License

This repository is for educational and testing purposes only. Use at your own risk.