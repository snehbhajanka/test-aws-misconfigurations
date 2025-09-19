# AWS Misconfiguration Test Repository

This repository contains intentionally misconfigured AWS infrastructure files designed for security testing, penetration testing, and educational purposes. **DO NOT USE THESE CONFIGURATIONS IN PRODUCTION ENVIRONMENTS.**

## Files Included

### Terraform Files
1. **terraform-s3-misconfigured.tf** - Misconfigured S3 bucket with public access
2. **terraform-s3-secure.tf** - ✅ **SECURE** S3 bucket configuration (S3.3 compliant)
3. **terraform-ec2-misconfigured.tf** - Misconfigured EC2 instance with multiple security vulnerabilities

### CloudFormation Files
1. **cloudformation-s3-secure.yaml** - ✅ **SECURE** S3 bucket using CloudFormation (S3.3 compliant)
2. **cloudformation-rds-misconfig.yaml** - Misconfigured RDS instance using CloudFormation
3. **cloudformation-sg-misconfig.yaml** - Misconfigured Security Group using CloudFormation

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

### ✅ S3 Bucket Security Fixes (S3.3 Compliant)
The secure configurations (`terraform-s3-secure.tf` and `cloudformation-s3-secure.yaml`) implement proper security controls:
- ✅ **Block Public Access enabled** - All settings set to `true` to prevent public write access
- ✅ **Private ACL** - No public read/write permissions
- ✅ **Server-side encryption enabled** - AES256 encryption by default
- ✅ **Versioning enabled** - Object versioning for data protection
- ✅ **Access logging configured** - Detailed access logs for monitoring
- ✅ **Secure bucket policy** - Authenticated access only, HTTPS required
- ✅ **Lifecycle policies** - Cost optimization with automated transitions
- ✅ **CloudWatch monitoring** - Comprehensive logging and alerting

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
# For MISCONFIGURED S3 bucket (testing purposes only)
terraform init
terraform plan -var-file="terraform-s3-misconfigured.tf"
terraform apply -var-file="terraform-s3-misconfigured.tf"

# For SECURE S3 bucket (production ready - S3.3 compliant)
terraform init
terraform plan terraform-s3-secure.tf
terraform apply terraform-s3-secure.tf

# For EC2 misconfigured instance
terraform init
terraform plan -var-file="terraform-ec2-misconfigured.tf"
terraform apply -var-file="terraform-ec2-misconfigured.tf"
```

### CloudFormation Deployment
```bash
# For SECURE S3 bucket (production ready - S3.3 compliant)
aws cloudformation create-stack \
  --stack-name secure-s3-stack \
  --template-body file://cloudformation-s3-secure.yaml \
  --parameters ParameterKey=Environment,ParameterValue=Production

# For misconfigured RDS instance
aws cloudformation create-stack \
  --stack-name misconfigured-rds-stack \
  --template-body file://cloudformation-rds-misconfig.yaml

# For misconfigured Security Group
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

## ✅ S3.3 Security Validation

To verify that the secure S3 configurations properly block public write access, run these AWS CLI commands:

### Validation Commands
```bash
# 1. Verify Block Public Access Settings (should all be true)
aws s3api get-public-access-block --bucket <your-secure-bucket-name>

# Expected output:
# {
#     "PublicAccessBlockConfiguration": {
#         "BlockPublicAcls": true,
#         "IgnorePublicAcls": true,
#         "BlockPublicPolicy": true,
#         "RestrictPublicBuckets": true
#     }
# }

# 2. Verify bucket ACL is private (should not show public permissions)
aws s3api get-bucket-acl --bucket <your-secure-bucket-name>

# 3. Test that public write access is blocked
# This command should FAIL with access denied:
aws s3 cp test-file.txt s3://<your-secure-bucket-name>/ --no-sign-request

# 4. Verify bucket policy denies insecure connections
aws s3api get-bucket-policy --bucket <your-secure-bucket-name>
```

### Compliance Verification
The secure configurations meet these compliance requirements:
- ✅ **S3.3**: Block public write access to S3 buckets
- ✅ **PCI DSS**: Data protection requirements
- ✅ **NIST 800-53**: Access control measures
- ✅ **SOC 2**: Security and availability criteria

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
terraform destroy  # For misconfigured resources
terraform destroy terraform-s3-secure.tf  # For secure S3 resources

# CloudFormation cleanup
aws cloudformation delete-stack --stack-name secure-s3-stack
aws cloudformation delete-stack --stack-name misconfigured-rds-stack
aws cloudformation delete-stack --stack-name misconfigured-sg-stack
```

## Contributing

If you find additional misconfigurations that should be included or improvements to existing ones, please feel free to contribute via pull requests.

## License

This repository is for educational and testing purposes only. Use at your own risk.