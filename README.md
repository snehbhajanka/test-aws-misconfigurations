# AWS Misconfiguration Test Repository

This repository contains AWS infrastructure files designed for security testing, penetration testing, and educational purposes. The S3 configurations have been **secured to block public write access** following AWS Security Hub control S3.3, while EC2 configurations remain intentionally misconfigured for testing. **DO NOT USE THESE CONFIGURATIONS IN PRODUCTION ENVIRONMENTS.**

## Files Included

### Terraform Files
1. **terraform-s3-misconfigured.tf** - Secure S3 bucket configuration (public write access blocked)
2. **terraform-ec2-misconfigured.tf** - Misconfigured EC2 instance with multiple security vulnerabilities

### CloudFormation Files
1. **cloudformation-s3-misconfigured.yaml** - Secure S3 bucket using CloudFormation (public write access blocked)
2. **cloudformation-ec2-misconfigured.yaml** - Misconfigured EC2 instance using CloudFormation

### Utility Scripts
1. **deploy.sh** - Automated deployment script for all configurations
2. **validate-s3-security.sh** - Security validation script for S3 bucket configurations

## Security Misconfigurations Included

### S3 Bucket Security Status
- ✅ Public write access blocked (fixed)
- ✅ Public access block enabled (fixed)
- ✅ Private ACL permissions (fixed)
- ❌ No server-side encryption
- ❌ Versioning disabled
- ❌ No access logging
- ✅ Public bucket policy restricted to read-only (fixed)
- ❌ No lifecycle policies
- ❌ No CloudTrail monitoring

**Note**: Critical security issue S3.3 has been resolved. Public write access is now blocked while maintaining read access for demonstration purposes.

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
# For secure S3 bucket
terraform init
terraform plan -var-file="terraform-s3-misconfigured.tf"
terraform apply -var-file="terraform-s3-misconfigured.tf"

# For EC2 misconfigured instance
terraform init
terraform plan -var-file="terraform-ec2-misconfigured.tf"
terraform apply -var-file="terraform-ec2-misconfigured.tf"
```

### CloudFormation Deployment
```bash
# For secure S3 bucket
aws cloudformation create-stack \
  --stack-name secure-s3-stack \
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

## ⚠️ Important Warnings

1. **DO NOT deploy these in production environments**
2. **These resources will incur AWS charges**
3. **S3 buckets are now secure but EC2 instances remain vulnerable to attacks**
4. **Always destroy resources after testing**: `terraform destroy` or `aws cloudformation delete-stack`
5. **Monitor your AWS bill and usage during testing**

## Educational Use Cases

- Security training and awareness
- Penetration testing practice
- Security tool validation
- Infrastructure security scanning
- DevSecOps pipeline testing
- Compliance testing

## Validation and Testing Steps

### S3 Security Validation
After deploying the S3 bucket, verify that public write access is blocked:

#### Automated Validation Script
```bash
# Use the provided validation script
./validate-s3-security.sh <your-bucket-name>
```

#### Manual Validation Steps

1. **Console Verification**:
   - Navigate to the AWS Management Console and open the Amazon S3 console
   - Select the bucket and verify that all Block Public Access settings are enabled
   - Check that the bucket ACL is set to "Private"

2. **CLI Verification**:
   ```bash
   # Check public access block settings
   aws s3api get-public-access-block --bucket <your-bucket-name>
   
   # Verify bucket ACL
   aws s3api get-bucket-acl --bucket <your-bucket-name>
   
   # Check bucket policy
   aws s3api get-bucket-policy --bucket <your-bucket-name>
   ```

3. **Functional Testing**:
   ```bash
   # This should succeed (read access allowed)
   aws s3 ls s3://<your-bucket-name>/
   
   # This should fail (write access blocked)
   echo "test" | aws s3 cp - s3://<your-bucket-name>/test.txt --no-sign-request
   ```

## Cleanup

Always remember to clean up resources after testing:

```bash
# Terraform cleanup
terraform destroy

# CloudFormation cleanup
aws cloudformation delete-stack --stack-name secure-s3-stack
aws cloudformation delete-stack --stack-name misconfigured-ec2-stack
```

## Contributing

If you find additional misconfigurations that should be included or improvements to existing ones, please feel free to contribute via pull requests.

## License

This repository is for educational and testing purposes only. Use at your own risk.