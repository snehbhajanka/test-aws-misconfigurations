# AWS Misconfiguration Test Repository

This repository contains intentionally misconfigured AWS infrastructure files designed for security testing, penetration testing, and educational purposes. **DO NOT USE THESE CONFIGURATIONS IN PRODUCTION ENVIRONMENTS.**

## Files Included

### Terraform Files
1. **terraform-s3-misconfigured.tf** - Misconfigured S3 bucket with public access
2. **terraform-s3-secure.tf** - Secure S3 bucket configuration (S3.3 compliant)
3. **terraform-ec2-misconfigured.tf** - Misconfigured EC2 instance with multiple security vulnerabilities

### CloudFormation Files
1. **cloudformation-s3-misconfigured.yaml** - Misconfigured S3 bucket using CloudFormation
2. **cloudformation-s3-secure.yaml** - Secure S3 bucket using CloudFormation (S3.3 compliant)
3. **cloudformation-rds-misconfig.yaml** - Misconfigured RDS instance using CloudFormation
4. **cloudformation-sg-misconfig.yaml** - Misconfigured Security Groups using CloudFormation

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

### S3 Bucket Secure Configuration (S3.3 Compliance)
- ✅ Public access block enabled (all settings: true)
- ✅ Private ACL permissions only
- ✅ Server-side encryption enabled (AES256)
- ✅ Versioning enabled
- ✅ Access logging enabled
- ✅ Secure bucket policy (denies public write access)
- ✅ Lifecycle policies configured
- ✅ Comprehensive tagging for compliance

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
# For S3 misconfigured bucket
terraform init
terraform plan -var-file="terraform-s3-misconfigured.tf"
terraform apply -var-file="terraform-s3-misconfigured.tf"

# For S3 secure bucket (S3.3 compliant)
terraform init
terraform plan -target="terraform-s3-secure.tf"
terraform apply -target="terraform-s3-secure.tf"

# For EC2 misconfigured instance
terraform init
terraform plan -var-file="terraform-ec2-misconfigured.tf"
terraform apply -var-file="terraform-ec2-misconfigured.tf"

# Using the deployment script (recommended)
./deploy.sh terraform-deploy-s3         # Deploy misconfigured S3
./deploy.sh terraform-deploy-s3-secure  # Deploy secure S3
```

### CloudFormation Deployment
```bash
# For S3 misconfigured bucket
aws cloudformation create-stack \
  --stack-name misconfigured-s3-stack \
  --template-body file://cloudformation-s3-misconfigured.yaml

# For S3 secure bucket (S3.3 compliant)
aws cloudformation create-stack \
  --stack-name secure-s3-stack \
  --template-body file://cloudformation-s3-secure.yaml

# For EC2 misconfigured instance
aws cloudformation create-stack \
  --stack-name misconfigured-ec2-stack \
  --template-body file://cloudformation-ec2-misconfigured.yaml \
  --capabilities CAPABILITY_NAMED_IAM

# Using the deployment script (recommended)
./deploy.sh cf-deploy-s3         # Deploy misconfigured S3
./deploy.sh cf-deploy-s3-secure  # Deploy secure S3
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

## S3.3 Security Control Remediation

This repository now includes secure S3 configurations that address the **S3.3** security control requirement: *"S3 general purpose buckets should block public write access"*.

### Key Security Fixes Implemented:

1. **Public Access Block Configuration**:
   - `block_public_acls = true`
   - `block_public_policy = true`
   - `ignore_public_acls = true`
   - `restrict_public_buckets = true`

2. **Secure ACL Configuration**:
   - Changed from `public-read-write` to `private`

3. **Secure Bucket Policy**:
   - Explicitly denies public write operations (`PutObject`, `DeleteObject`, `PutObjectAcl`, `PutBucketAcl`)
   - Allows authenticated access only

4. **Additional Security Enhancements**:
   - Server-side encryption enabled
   - Versioning enabled
   - Access logging configured
   - Lifecycle policies implemented

### Verification Steps:

```bash
# Deploy the secure configuration
./deploy.sh terraform-deploy-s3-secure

# Verify public access block settings
aws s3api get-public-access-block --bucket <your-secure-bucket-name>

# Test that public write access is blocked
aws s3 cp test-file.txt s3://<your-secure-bucket-name>/ --no-sign-request
# This should fail with access denied

# Run automated validation
./validate-s3-security.sh validate-terraform
./validate-s3-security.sh validate-cloudformation  # (requires AWS CLI configuration)
./validate-s3-security.sh check-s3-compliance      # (checks deployed buckets)
```

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