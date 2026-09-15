# AWSAutomation

[![validate](https://github.com/jjohns-dev/AWSAutomation/actions/workflows/ci.yml/badge.svg)](https://github.com/jjohns-dev/AWSAutomation/actions/workflows/ci.yml)
[![release](https://github.com/jjohns-dev/AWSAutomation/actions/workflows/release.yml/badge.svg)](https://github.com/jjohns-dev/AWSAutomation/actions/workflows/release.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![PowerShell 5.1+](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://github.com/PowerShell/PowerShell)

A PowerShell module for automating, auditing, and reporting on AWS resources. It covers a broad surface of AWS services — EC2, IAM, S3, SSM, CloudFormation, CloudWatch, Elastic Load Balancing, Route 53, ACM, Secrets Manager, KMS, and SSO — with functions designed for cloud/ops engineers who work heavily in the AWS CLI and PowerShell ecosystem.

## Requirements

| Requirement | Value |
|---|---|
| PowerShell | 5.1+ (Desktop & Core) |
| Platform | Windows, Linux, macOS |

## Installation

Clone the repository and import the module directly:

```powershell
git clone https://github.com/jjohns-dev/AWSAutomation.git
Import-Module ./AWSAutomation/AWSAutomation.psd1
```

Install the required dependencies manually:

```powershell
Install-Module ImportExcel
Install-Module AWS.Tools.Common
Install-Module AWS.Tools.CloudFormation
Install-Module AWS.Tools.CloudWatch
Install-Module AWS.Tools.EC2
Install-Module AWS.Tools.ElasticLoadBalancingV2
Install-Module AWS.Tools.IdentityManagement
Install-Module AWS.Tools.KeyManagementService
Install-Module AWS.Tools.RDS
Install-Module AWS.Tools.Route53
Install-Module AWS.Tools.S3
Install-Module AWS.Tools.SimpleSystemsManagement
Install-Module AWS.Tools.SecurityToken
Install-Module AWS.Tools.SSO
Install-Module AWS.Tools.SSOOIDC
```

## Usage

```powershell
Import-Module AWSAutomation

# Get a summary of all EC2 instances in us-east-1
Get-Instance -Region us-east-1

# Export an IAM credential report to Excel
Get-IAMReport -OutputPath ./iam-report.xlsx

# Find S3 buckets with insecure policies
Find-InsecureS3BucketPolicy

# Assume a role and return temporary credentials
Get-RoleCredential -RoleArn 'arn:aws:iam::123456789012:role/MyRole'
```

## Module Layout

```
AWSAutomation/
├── .devcontainer/        # Dev container configuration
├── .github/
│   ├── workflows/
│   │   ├── validate.yml  # CI: PSScriptAnalyzer + Pester on every PR
│   │   └── release.yml   # Publish to PowerShell Gallery on release
│   └── release.yml       # Automated release notes config
├── Build/                # Build and packaging scripts (PSake/InvokeBuild)
├── Private/              # Internal helpers and custom type extensions (.ps1xml)
├── Public/               # Exported functions — one file per function
├── Tests/                # Pester test suite
├── AWSAutomation.psd1    # Module manifest (version, dependencies, exports)
└── AWSAutomation.psm1    # Root module loader
```

## Functions

### EC2 / Compute

| Function | Description |
|---|---|
| `Copy-EC2Instance` | Clone an existing EC2 instance to a new instance |
| `Get-Instance` | Retrieve EC2 instance details with enriched output |
| `Get-LatestImage` | Find the latest AMI matching a given name pattern |
| `Get-WindowsDisk` | Get disk/volume info from Windows EC2 instances via SSM |
| `Export-EC2UsageReport` | Export an EC2 usage and sizing report to Excel |
| `Update-CFNStackAMI` | Update a CloudFormation stack parameter with a new AMI ID |

### Networking / VPC

| Function | Description |
|---|---|
| `Get-NetworkInfo` | Get enriched VPC, subnet, and network interface details |
| `Get-SecurityGroupInfo` | Get security group rules with readable source/destination info |
| `Find-NextSubnet` | Calculate the next available subnet CIDR in a VPC |
| `Get-LoadBalancer` | Get Application and Network Load Balancer details |

### S3

| Function | Description |
|---|---|
| `Get-S3Report` | Generate a report of S3 buckets and their configurations |
| `Get-S3Url` | Build a pre-signed or public URL for an S3 object |
| `Find-InsecureS3BucketPolicy` | Find buckets with overly permissive bucket policies |
| `Find-PublicS3Object` | Find publicly accessible S3 objects across buckets |

### IAM

| Function | Description |
|---|---|
| `Get-IAMReport` | Generate an IAM credential and access report |
| `Export-IAMRolePolicy` | Export all inline and managed policies for an IAM role |
| `Get-RoleCredential` | Assume a role and return temporary STS credentials |

### SSM / Patch Management

| Function | Description |
|---|---|
| `Get-SSMInstance` | Get instances registered with AWS Systems Manager |
| `Get-SSMNonCompliance` | Report on instances out of SSM compliance |
| `Get-AssociationStatus` | Get the status of SSM State Manager associations |
| `Get-PatchInfo` | Get patch compliance details for managed instances |
| `Get-ScanStatus` | Get Amazon Inspector scan status for instances |
| `Invoke-SSMRunCommand` | Send and monitor an SSM Run Command document |

### CloudFormation

| Function | Description |
|---|---|
| `ConvertTo-CFStackParam` | Convert a hashtable into CloudFormation parameter format |
| `Export-CFNStackDrift` | Export drift detection results for a CloudFormation stack |

### CloudWatch / Alarms

| Function | Description |
|---|---|
| `New-CWRecoveryAlarm` | Create a CloudWatch alarm that triggers EC2 instance recovery |
| `New-HealthCheck` | Create a Route 53 health check for an endpoint |
| `New-HealthCheckAlarm` | Create a CloudWatch alarm tied to a Route 53 health check |

### Route 53

| Function | Description |
|---|---|
| `Get-R53Record` | Get DNS records from a Route 53 hosted zone |

### Secrets Manager / SSO

| Function | Description |
|---|---|
| `Export-SECSecret` | Export secrets from AWS Secrets Manager |
| `Set-AwsSsoCredential` | Authenticate via AWS SSO and write credentials to the profile store |

### Logging / Utilities

| Function | Description |
|---|---|
| `ConvertFrom-CFLog` | Parse CloudFront access log files into PowerShell objects |
| `ConvertFrom-ELBLog` | Parse ELB access log files into PowerShell objects |
| `Edit-AWSProfile` | Add, update, or remove entries in the AWS credentials/config files |
| `Get-AwsServiceReference` | Look up the AWS service endpoint or documentation reference |
| `Get-CertificateReport` | Report on ACM certificates and their expiration status |

## Contributing

Contributions are welcome. Please open an issue first to discuss proposed changes, then:

1. Fork the repository and create a feature branch off `main`
2. Make your changes in `Public/` (one function per file, matching the filename to the function name)
3. Add or update Pester tests in `Tests/`
4. Ensure `PSScriptAnalyzer` passes with no errors
5. Open a pull request against `main`

See [CONTRIBUTING.md](CONTRIBUTING.md) for full guidelines including code style, commit conventions, and the build system.

## License

Distributed under the MIT License. See [LICENSE](LICENSE) for details.
