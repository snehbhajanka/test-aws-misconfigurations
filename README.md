# AWS Misconfiguration Test Repository

This repository contains intentionally misconfigured AWS infrastructure files designed for security testing, penetration testing, and educational purposes. **DO NOT USE THESE CONFIGURATIONS IN PRODUCTION ENVIRONMENTS.**

## Files Included

### Terraform Files
1. **terraform-s3-misconfigured.tf** - Misconfigured S3 bucket with public access
2. **terraform-s3-remediated.tf** - ✅ **NEW** - S3 bucket with public write access blocked (S3.3 remediation)
3. **terraform-s3-secure.tf** - ✅ **NEW** - Fully secure S3 bucket with all security controls
4. **terraform-ec2-misconfigured.tf** - Misconfigured EC2 instance with multiple security vulnerabilities

### CloudFormation Files
1. **cloudformation-s3-secure.yaml** - ✅ **NEW** - Secure S3 bucket using CloudFormation
2. **cloudformation-rds-misconfig.yaml** - Misconfigured RDS instance 
3. **cloudformation-sg-misconfig.yaml** - Misconfigured Security Group

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

### S3 Bucket Security Remediations ✅
**terraform-s3-remediated.tf** - Addresses AWS Security Hub control S3.3:
- ✅ Public access block enabled
- ✅ ACL changed to public-read (write access blocked)
- ✅ Bucket policy removes PutObject/DeleteObject permissions
- ⚠️ Still educational - missing encryption, versioning, logging

**terraform-s3-secure.tf** & **cloudformation-s3-secure.yaml** - Full security:
- ✅ All public access blocked
- ✅ Server-side encryption enabled
- ✅ Versioning enabled
- ✅ Access logging configured
- ✅ Secure bucket policies
- ✅ Lifecycle policies configured

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
# For S3 misconfigured bucket (original)
terraform init
terraform plan -var-file="terraform-s3-misconfigured.tf"
terraform apply -var-file="terraform-s3-misconfigured.tf"

# For S3 remediated bucket (fixes public write access - S3.3 control)
terraform init
terraform plan -var-file="terraform-s3-remediated.tf"
terraform apply -var-file="terraform-s3-remediated.tf"

# For S3 secure bucket (fully secure configuration)
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
# For S3 secure bucket
aws cloudformation create-stack \
  --stack-name secure-s3-stack \
  --template-body file://cloudformation-s3-secure.yaml \
  --capabilities CAPABILITY_IAM

# For misconfigured resources
aws cloudformation create-stack \
  --stack-name misconfigured-rds-stack \
  --template-body file://cloudformation-rds-misconfig.yaml

aws cloudformation create-stack \
  --stack-name misconfigured-sg-stack \
  --template-body file://cloudformation-sg-misconfig.yaml
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

## ✅ Security Remediation Examples

This repository now includes properly configured examples that address the security misconfigurations:

### AWS Security Hub Control S3.3 Remediation
**Issue**: S3 general purpose buckets should block public write access
**Risk Score**: 10/10
**Files**: `terraform-s3-remediated.tf`, `terraform-s3-secure.tf`, `cloudformation-s3-secure.yaml`

**Remediation Applied**:
1. **Block Public Access Settings**: All settings enabled to prevent public write access
2. **ACL Configuration**: Changed from "public-read-write" to "public-read" or "private"
3. **Bucket Policy**: Removed PutObject and DeleteObject permissions for public access
4. **Additional Security** (in secure versions): Encryption, versioning, access logging

**Verification Steps**:
```bash
# Check public access block settings
aws s3api get-public-access-block --bucket <bucket-name>

# Attempt unauthorized write (should fail)
echo "test" > test.txt
aws s3 cp test.txt s3://<bucket-name>/test.txt --no-sign-request
```

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