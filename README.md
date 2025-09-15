# AWS Misconfiguration Test Repository

This repository contains intentionally misconfigured AWS infrastructure files designed for security testing, penetration testing, and educational purposes. **DO NOT USE THESE CONFIGURATIONS IN PRODUCTION ENVIRONMENTS.**

## Files Included

### Terraform Files
1. **terraform-s3-misconfigured.tf** - Misconfigured S3 bucket with public access (for security testing)
2. **terraform-s3-secure.tf** - Secure S3 bucket with proper access controls (production-ready)
3. **terraform-ec2-misconfigured.tf** - Misconfigured EC2 instance with multiple security vulnerabilities

### CloudFormation Files
1. **cloudformation-s3-misconfigured.yaml** - S3 bucket template with both misconfigured and secure options
2. **cloudformation-rds-misconfig.yaml** - Misconfigured RDS instance using CloudFormation
3. **cloudformation-sg-misconfig.yaml** - Misconfigured Security Group using CloudFormation

## Security Misconfigurations Included

### S3 Bucket Misconfigurations (Fixed in Secure Versions)
- ❌ Public access block disabled → ✅ Public access block enabled
- ❌ Public read/write ACL permissions → ✅ Private ACL with secure ownership controls
- ❌ No server-side encryption → ✅ AES256 server-side encryption enabled
- ❌ Versioning disabled → ✅ Versioning enabled
- ❌ No access logging → ✅ Access logging to dedicated bucket
- ❌ Public bucket policy allowing full access → ✅ Restrictive policy denying public access
- ❌ No lifecycle policies → ✅ Lifecycle policies for cost optimization
- ❌ No CloudTrail monitoring → ✅ HTTPS-only policy enforced

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
# For misconfigured S3 bucket (security testing)
terraform init
terraform plan -var-file="terraform-s3-misconfigured.tf"
terraform apply -var-file="terraform-s3-misconfigured.tf"

# For secure S3 bucket (production-ready)
terraform init
terraform plan -var-file="terraform-s3-secure.tf"
terraform apply -var-file="terraform-s3-secure.tf"

# For misconfigured EC2 instance
terraform init
terraform plan -var-file="terraform-ec2-misconfigured.tf"
terraform apply -var-file="terraform-ec2-misconfigured.tf"
```

### CloudFormation Deployment
```bash
# For misconfigured S3 bucket
aws cloudformation create-stack \
  --stack-name misconfigured-s3-stack \
  --template-body file://cloudformation-s3-misconfigured.yaml \
  --parameters ParameterKey=BucketMode,ParameterValue=misconfigured \
  --capabilities CAPABILITY_NAMED_IAM

# For secure S3 bucket
aws cloudformation create-stack \
  --stack-name secure-s3-stack \
  --template-body file://cloudformation-s3-misconfigured.yaml \
  --parameters ParameterKey=BucketMode,ParameterValue=secure \
  --capabilities CAPABILITY_NAMED_IAM
```

### Using the Deploy Script
```bash
# Deploy secure S3 bucket (recommended for production)
./deploy.sh terraform-deploy-s3-secure
./deploy.sh cf-deploy-s3-secure

# Deploy misconfigured S3 bucket (for security testing only)
./deploy.sh terraform-deploy-s3-misc
./deploy.sh cf-deploy-s3-misc

# Destroy resources
./deploy.sh terraform-destroy-s3
./deploy.sh cf-destroy-s3
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

1. **DO NOT deploy misconfigured resources in production environments**
2. **These resources will incur AWS charges**
3. **Public S3 buckets may be discovered and abused by attackers**
4. **EC2 instances with weak security groups are vulnerable to attacks**
5. **Always destroy resources after testing**: `terraform destroy` or `aws cloudformation delete-stack`
6. **Monitor your AWS bill and usage during testing**
7. **Use the secure configurations (terraform-s3-secure.tf) for production workloads**

## ✅ Security Remediation

This repository now includes secure alternatives to address the S3.2 security finding:

### S3 Public Read Access Remediation
- **Block Public Access**: All four settings enabled (BlockPublicAcls, IgnorePublicAcls, BlockPublicPolicy, RestrictPublicBuckets)
- **Private ACLs**: Uses "private" ACL instead of "public-read-write"
- **Secure Bucket Policy**: Denies all public access and enforces HTTPS-only
- **Encryption**: AES256 server-side encryption enabled by default
- **Versioning**: Enabled for data protection
- **Access Logging**: Configured to track access attempts
- **Lifecycle Policies**: Implemented for cost optimization

### Validation Commands
```bash
# Verify public access is blocked
aws s3api get-public-access-block --bucket <your-secure-bucket-name>

# Test that public access is denied
curl https://<your-secure-bucket-name>.s3.amazonaws.com/ 
# Should return AccessDenied

# Use the included validation script
./validate-s3-security.sh <your-bucket-name>
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