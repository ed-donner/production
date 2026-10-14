<# 
.SYNOPSIS
Cross-verify that the AWS resources created by Terraform parts 2-7 are gone.

.HOW TO RUN
1) Open PowerShell in the project root:
   cd C:your project folder
2) Run with default region (us-east-1):
   powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\aws_verify_deleted_parts_2_7.ps1
3) Or run with an explicit region:
   powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\aws_verify_deleted_parts_2_7.ps1 -Region us-east-1

.DESCRIPTION
This script checks for the resource names/prefixes used in your Terraform code (Project=alex and "alex-*" names).
It focuses on the infrastructure layer (not local files).

.NOTES
Some services can take a few minutes to fully delete after terraform destroy.
If you still see resources, wait 2-5 minutes and re-run.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\scripts\aws_verify_deleted_parts_2_7.ps1 -Region us-east-1

#>

param(
  [string]$Region = "us-east-1"
)

$ErrorActionPreference = "SilentlyContinue"

function Get-AccountId {
  try {
    return (aws sts get-caller-identity --query Account --output text --region $Region).Trim()
  } catch {
    throw "Failed to determine AWS account id. Confirm AWS CLI auth/region."
  }
}

function Run-AwsList {
  param(
    [string]$Description,
    [scriptblock]$Command
  )

  try {
    $out = & $Command 2>$null
    if ($null -eq $out) { $out = "" }
    $out = [string]$out
    $out = $out.Trim()

    # AWS CLI often returns literal "None" when a query matches nothing.
    if (($out.Length -gt 0) -and ($out -ne "None") -and ($out -ne "null")) {
      Write-Host "FOUND: $Description" -ForegroundColor Yellow
      Write-Host $out -ForegroundColor Yellow
      return $true
    }

    Write-Host "OK: $Description (nothing found)" -ForegroundColor Green
    return $false
  } catch {
    Write-Host "SKIP/ERROR: $Description ($($_.Exception.Message))" -ForegroundColor DarkYellow
    return $false
  }
}

$accountId = Get-AccountId
Write-Host "AWS account: $accountId"
Write-Host "Region: $Region"
Write-Host ""

$found = $false

# -----------------------------
# Tag-based check (broad net)
# -----------------------------
$found = (Run-AwsList -Description "Tagged resources with Project=alex (resourcegroupstaggingapi)" -Command {
  aws resourcegroupstaggingapi get-resources `
    --region $Region `
    --tag-filters Key=Project,Values=alex `
    --query "ResourceTagMappingList[].ResourceARN" `
    --output text
} ) -or $found

# -----------------------------
# S3 buckets
# -----------------------------
$found = (Run-AwsList -Description "S3 buckets matching alex-frontend|alex-vectors|alex-lambda-packages" -Command {
  $names = aws s3api list-buckets --region $Region --query "Buckets[].Name" --output text
  if ($null -eq $names) { return "" }
  $names = [string]$names
  $names.Split("`t", [System.StringSplitOptions]::RemoveEmptyEntries) | Where-Object {
    $_ -like "alex-frontend-*" -or $_ -like "alex-vectors-*" -or $_ -like "alex-lambda-packages-*"
  }
} ) -or $found

# More precise bucket-name checks (avoid query complexities)
$frontBucket = "alex-frontend-$accountId"
$vectorsBucket = "alex-vectors-$accountId"
$lambdaPkgBucket = "alex-lambda-packages-$accountId"

$found = (Run-AwsList -Description "S3 bucket exists: $frontBucket" -Command {
  aws s3api head-bucket --bucket $frontBucket --region $Region --output text
} ) -or $found

$found = (Run-AwsList -Description "S3 bucket exists: $vectorsBucket" -Command {
  aws s3api head-bucket --bucket $vectorsBucket --region $Region --output text
} ) -or $found

$found = (Run-AwsList -Description "S3 bucket exists: $lambdaPkgBucket" -Command {
  aws s3api head-bucket --bucket $lambdaPkgBucket --region $Region --output text
} ) -or $found

# -----------------------------
# Lambda functions
# -----------------------------
$found = (Run-AwsList -Description "Lambda functions with name prefix alex-" -Command {
  aws lambda list-functions --region $Region `
    --query "Functions[?starts_with(FunctionName, 'alex-')].FunctionName" `
    --output text
} ) -or $found

# -----------------------------
# SQS queues
# -----------------------------
$found = (Run-AwsList -Description "SQS queues with prefix alex-" -Command {
  aws sqs list-queues --region $Region --output text --query "QueueUrls[]" |
    ForEach-Object { $_ } |
    Where-Object { $_ -match "alex-" }
} ) -or $found

# -----------------------------
# SageMaker endpoint
# -----------------------------
$found = (Run-AwsList -Description "SageMaker endpoints containing alex" -Command {
  aws sagemaker list-endpoints --region $Region `
    --query "Endpoints[].EndpointName" `
    --output text |
    ForEach-Object { $_ } |
    Where-Object { $_ -like "alex*"} 
} ) -or $found

# -----------------------------
# RDS Aurora cluster + instance + subnet group + SG
# -----------------------------
$found = (Run-AwsList -Description "RDS cluster alex-aurora-cluster" -Command {
  aws rds describe-db-clusters --region $Region `
    --query "DBClusters[?DBClusterIdentifier=='alex-aurora-cluster'].DBClusterIdentifier" `
    --output text
} ) -or $found

$found = (Run-AwsList -Description "RDS instance alex-aurora-instance-1" -Command {
  aws rds describe-db-instances --region $Region `
    --query "DBInstances[?DBInstanceIdentifier=='alex-aurora-instance-1'].DBInstanceIdentifier" `
    --output text
} ) -or $found

$found = (Run-AwsList -Description "RDS DB subnet group alex-aurora-subnet-group" -Command {
  aws rds describe-db-subnet-groups --region $Region `
    --query "DBSubnetGroups[?DBSubnetGroupName=='alex-aurora-subnet-group'].DBSubnetGroupName" `
    --output text
} ) -or $found

$found = (Run-AwsList -Description "EC2 security group alex-aurora-sg" -Command {
  aws ec2 describe-security-groups --region $Region `
    --filters Name=group-name,Values=alex-aurora-sg `
    --query "SecurityGroups[].GroupId" `
    --output text
} ) -or $found

$found = (Run-AwsList -Description "Secrets Manager secrets alex-aurora-credentials-*" -Command {
  aws secretsmanager list-secrets --region $Region `
    --query "SecretList[?starts_with(Name, 'alex-aurora-credentials-')].Name" `
    --output text
} ) -or $found

# -----------------------------
# ECR + App Runner + CloudFront + API Gateway
# -----------------------------
$found = (Run-AwsList -Description "ECR repository alex-researcher" -Command {
  aws ecr describe-repositories --region $Region `
    --repository-names alex-researcher `
    --query "repositories[].repositoryName" `
    --output text
} ) -or $found

$found = (Run-AwsList -Description "App Runner services containing alex" -Command {
  aws apprunner list-services --region $Region `
    --query "ServiceSummaryList[?contains(ServiceName, 'alex')].ServiceName" `
    --output text
} ) -or $found

$found = (Run-AwsList -Description "CloudFront distribution comment: 'Alex Financial Advisor Frontend'" -Command {
  aws cloudfront list-distributions --region $Region `
    --query "DistributionList.Items[?Comment=='Alex Financial Advisor Frontend'].Id" `
    --output text
} ) -or $found

$found = (Run-AwsList -Description "API Gateway v2 API named alex-api-gateway" -Command {
  aws apigatewayv2 get-apis --region $Region `
    --query "Items[?Name=='alex-api-gateway'].Name" `
    --output text
} ) -or $found

# -----------------------------
# EventBridge Scheduler (aws scheduler)
# -----------------------------
$found = (Run-AwsList -Description "EventBridge Scheduler schedules named alex*" -Command {
  aws scheduler list-schedules --region $Region `
    --query "Schedules[?starts_with(Name, 'alex')].Name" `
    --output text
} ) -or $found

# -----------------------------
# IAM roles/policies (broad-ish)
# -----------------------------
$found = (Run-AwsList -Description "IAM roles with prefix alex-" -Command {
  aws iam list-roles --region $Region `
    --query "Roles[?starts_with(RoleName, 'alex-')].RoleName" `
    --output text
} ) -or $found

Write-Host ""

if ($found) {
  Write-Host "RESULT: One or more expected resources are still present in AWS." -ForegroundColor Yellow
  Write-Host "Wait a few minutes and re-run, or run terraform destroy again / check CloudTrail if deletions are blocked."
  exit 1
}

Write-Host "RESULT: No remaining alex Terraform resources detected by the checks above." -ForegroundColor Green
exit 0

