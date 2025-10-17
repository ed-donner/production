# Day 5: CI/CD with GitHub Actions

## From Local Development to Professional DevOps

Welcome to the final day of Week 2! Today we're implementing the complete DevOps lifecycle - from version control to continuous deployment to infrastructure teardown. You'll set up GitHub Actions to automatically deploy your Digital Twin whenever you push code, manage multiple environments through a web interface, and ensure everything can be cleanly removed when you're done. This is how professional teams manage production infrastructure!

## What You'll Learn Today

- **Git and GitHub** - Version control for infrastructure and code
- **Remote state management** - Terraform state in S3 with locking
- **GitHub Actions** - CI/CD pipelines for automated deployment
- **GitHub Secrets** - Secure credential management
- **OIDC authentication** - Modern AWS authentication without long-lived keys
- **Multi-environment workflows** - Automated and manual deployments
- **Infrastructure cleanup** - Complete teardown strategies

## Part 1: Clean Up Existing Infrastructure

Before setting up CI/CD, let's remove all existing environments to start fresh.

### Step 1: Destroy All Environments

We'll use the destroy scripts created on Day 4 to clean up dev, test, and prod environments.

**Mac/Linux:**
```bash

# Destroy dev environment
./scripts/destroy.sh dev

# Destroy test environment  
./scripts/destroy.sh test

# Destroy prod environment (if you created one)
./scripts/destroy.sh prod
```

**Windows (PowerShell):**
```powershell

# Destroy dev environment
.\scripts\destroy.ps1 -Environment dev

# Destroy test environment
.\scripts\destroy.ps1 -Environment test

# Destroy prod environment (if you created one)
.\scripts\destroy.ps1 -Environment prod
```

Each destruction will take 5-10 minutes as CloudFront distributions are removed.

### Step 2: Clean Up Terraform Workspaces

After resources are destroyed, remove the workspaces:

```bash
cd terraform

# Switch to default workspace
terraform workspace select default

# Delete the workspaces
terraform workspace delete dev
terraform workspace delete test
terraform workspace delete prod

cd ..
```

### Step 3: Verify Clean State

1. Check AWS Console to ensure no twin-related resources remain:
   - Lambda: No functions starting with `twin-`
   - S3: No buckets starting with `twin-`
   - API Gateway: No APIs starting with `twin-`
   - CloudFront: No twin distributions

✅ **Checkpoint**: Your AWS account is now clean, ready for CI/CD deployment!

## Part 2: Initialize Git Repository

### Step 1: Create .gitignore

Ensure your `.gitignore` in the project root (`twin/.gitignore`) is complete:

```gitignore
# Terraform
*.tfstate
*.tfstate.*
.terraform/
.terraform.lock.hcl
terraform.tfstate.d/
*.tfvars.secret

# Lambda packages
lambda-deployment.zip
lambda-package/

# Memory storage (contains conversation history)
memory/

# Environment files
.env
.env.*
!.env.example

# Node
node_modules/
out/
.next/
*.log

# Python
__pycache__/
*.pyc
.venv/
venv/

# IDE
.vscode/
.idea/
*.swp
.DS_Store
Thumbs.db

# AWS
.aws/
```

### Step 2: Create Example Environment File

Create `.env.example` to help others understand required environment variables:

```bash
# AWS Configuration
AWS_ACCOUNT_ID=your_12_digit_account_id
DEFAULT_AWS_REGION=us-east-1

# Project Configuration
PROJECT_NAME=twin
```

### Step 3: Initialize Git Repository

First, clean up any git repositories that might have been created by the tooling:

**Mac/Linux:**
```bash
cd twin

# Remove any git repos created by create-next-app or uv (if they exist)
rm -rf frontend/.git backend/.git 2>/dev/null

# Initialize git repository with main as the default branch
git init -b main

# If you get an error that -b is not supported (older Git versions), use:
# git init
# git checkout -b main

# Configure git (replace with your details)
git config user.name "Your Name"
git config user.email "your.email@example.com"
```

**Windows (PowerShell):**
```powershell
cd twin

# Remove any git repos created by create-next-app or uv (if they exist)
Remove-Item -Path frontend/.git -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path backend/.git -Recurse -Force -ErrorAction SilentlyContinue

# Initialize git repository with main as the default branch
git init -b main

# If you get an error that -b is not supported (older Git versions), use:
# git init
# git checkout -b main

# Configure git (replace with your details)
git config user.name "Your Name"
git config user.email "your.email@example.com"
```

After configuring git, continue with adding and committing files:

```bash
# Add all files
git add .

# Create initial commit
git commit -m "Initial commit: Digital Twin infrastructure and application"
```

### Step 4: Create GitHub Repository

1. Go to [github.com](https://github.com) and sign in
2. Click the **+** icon in the top right → **New repository**
3. Configure your repository:
   - Repository name: `digital-twin` (or your preferred name)
   - Description: "AI Digital Twin deployed on AWS with Terraform"
   - Public or Private: Your choice (private recommended if using real personal data)
   - DO NOT initialize with README, .gitignore, or license
4. Click **Create repository**

### Step 5: Push to GitHub

After creating the repository, GitHub will show you commands. Use these:

```bash
# Add GitHub as remote (replace YOUR_USERNAME with your GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/digital-twin.git

# Push to GitHub (we're already on main branch from Step 3)
git push -u origin main
```

If prompted for authentication:
- Username: Your GitHub username
- Password: Use a Personal Access Token (not your password)
  - Go to GitHub → Settings → Developer settings → Personal access tokens
  - Generate a token with `repo` scope

✅ **Checkpoint**: Your code is now on GitHub! Refresh your GitHub repository page to see all files.

## Part 3: Set Up S3 Backend for Terraform State

### Step 1: Create State Management Resources

Create `terraform/backend-setup.tf`:

```hcl
# This file creates the S3 bucket for Terraform state
# Run this once per AWS account, then remove the file

resource "aws_s3_bucket" "terraform_state" {
  bucket = "twin-terraform-state-${data.aws_caller_identity.current.account_id}"
  use_lockfile = true # This will prevent the overlap use of this terraform state.
  tags = {
    Name        = "Terraform State Store"
    Environment = "global"
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Note: aws_caller_identity.current is already defined in main.tf

output "state_bucket_name" {
  value = aws_s3_bucket.terraform_state.id
}

```

### Step 2: Create Backend Resources - note 1 line is different for Mac/Linux or PC:

```bash
cd terraform

# IMPORTANT: Make sure you're in the default workspace
terraform workspace select default

# Initialize Terraform
terraform init

# Apply just the backend resources (one line - copy and paste this entire command - different for Mac/Linux and PC)

# Mac/Linux version:
terraform apply -target=aws_s3_bucket.terraform_state -target=aws_s3_bucket_versioning.terraform_state -target=aws_s3_bucket_server_side_encryption_configuration.terraform_state -target=aws_s3_bucket_public_access_block.terraform_state
# PC version
terraform apply --% -target="aws_s3_bucket.terraform_state" -target="aws_s3_bucket_versioning.terraform_state" -target="aws_s3_bucket_server_side_encryption_configuration.terraform_state" -target="aws_s3_bucket_public_access_block.terraform_state"

# Verify the resources were created
terraform output
```

The bucket is now ready for storing Terraform state.

### Step 3: Remove Setup File

Now that the backend resources exist, remove the setup file:

```bash
rm backend-setup.tf
```

### Step 4: Update Scripts for S3 Backend

We need to update both deployment and destroy scripts to work with the S3 backend.

#### Update Deploy Script

Update `scripts/deploy.sh` to include backend configuration. Find the terraform init line and replace it:

```bash
# Old line:
terraform init -input=false

# New lines:
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=${DEFAULT_AWS_REGION:-us-east-1}
terraform init -input=false \
  -backend-config="bucket=twin-terraform-state-${AWS_ACCOUNT_ID}" \
  -backend-config="key=${ENVIRONMENT}/terraform.tfstate" \
  -backend-config="region=${AWS_REGION}" \
  -backend-config="encrypt=true"
```

Update `scripts/deploy.ps1` similarly:

```powershell
# Old line:
terraform init -input=false

# New lines:
$awsAccountId = aws sts get-caller-identity --query Account --output text
$awsRegion = if ($env:DEFAULT_AWS_REGION) { $env:DEFAULT_AWS_REGION } else { "us-east-1" }
terraform init -input=false `
  -backend-config="bucket=twin-terraform-state-$awsAccountId" `
  -backend-config="key=$Environment/terraform.tfstate" `
  -backend-config="region=$awsRegion" `
  -backend-config="encrypt=true"
```

#### Update Destroy Script

Replace your entire `scripts/destroy.sh` with this updated version that includes S3 backend support:

```bash
#!/bin/bash
set -e

# Check if environment parameter is provided
if [ $# -eq 0 ]; then
    echo "❌ Error: Environment parameter is required"
    echo "Usage: $0 <environment>"
    echo "Example: $0 dev"
    echo "Available environments: dev, test, prod"
    exit 1
fi

ENVIRONMENT=$1
PROJECT_NAME=${2:-twin}

echo "🗑️ Preparing to destroy ${PROJECT_NAME}-${ENVIRONMENT} infrastructure..."

# Navigate to terraform directory
cd "$(dirname "$0")/../terraform"

# Get AWS Account ID and Region for backend configuration
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=${DEFAULT_AWS_REGION:-us-east-1}

# Initialize terraform with S3 backend
echo "🔧 Initializing Terraform with S3 backend..."
terraform init -input=false \
  -backend-config="bucket=twin-terraform-state-${AWS_ACCOUNT_ID}" \
  -backend-config="key=${ENVIRONMENT}/terraform.tfstate" \
  -backend-config="region=${AWS_REGION}" \
  -backend-config="encrypt=true"

# Check if workspace exists
if ! terraform workspace list | grep -q "$ENVIRONMENT"; then
    echo "❌ Error: Workspace '$ENVIRONMENT' does not exist"
    echo "Available workspaces:"
    terraform workspace list
    exit 1
fi

# Select the workspace
terraform workspace select "$ENVIRONMENT"

echo "📦 Emptying S3 buckets..."

# Get bucket names with account ID (matching Day 4 naming)
FRONTEND_BUCKET="${PROJECT_NAME}-${ENVIRONMENT}-frontend-${AWS_ACCOUNT_ID}"
MEMORY_BUCKET="${PROJECT_NAME}-${ENVIRONMENT}-memory-${AWS_ACCOUNT_ID}"

# Empty frontend bucket if it exists
if aws s3 ls "s3://$FRONTEND_BUCKET" 2>/dev/null; then
    echo "  Emptying $FRONTEND_BUCKET..."
    aws s3 rm "s3://$FRONTEND_BUCKET" --recursive
else
    echo "  Frontend bucket not found or already empty"
fi

# Empty memory bucket if it exists
if aws s3 ls "s3://$MEMORY_BUCKET" 2>/dev/null; then
    echo "  Emptying $MEMORY_BUCKET..."
    aws s3 rm "s3://$MEMORY_BUCKET" --recursive
else
    echo "  Memory bucket not found or already empty"
fi

echo "🔥 Running terraform destroy..."

# Create a dummy lambda zip if it doesn't exist (needed for destroy in GitHub Actions)
if [ ! -f "../backend/lambda-deployment.zip" ]; then
    echo "Creating dummy lambda package for destroy operation..."
    echo "dummy" | zip ../backend/lambda-deployment.zip -
fi

# Run terraform destroy with auto-approve
if [ "$ENVIRONMENT" = "prod" ] && [ -f "prod.tfvars" ]; then
    terraform destroy -var-file=prod.tfvars -var="project_name=$PROJECT_NAME" -var="environment=$ENVIRONMENT" -auto-approve
else
    terraform destroy -var="project_name=$PROJECT_NAME" -var="environment=$ENVIRONMENT" -auto-approve
fi

echo "✅ Infrastructure for ${ENVIRONMENT} has been destroyed!"
echo ""
echo "💡 To remove the workspace completely, run:"
echo "   terraform workspace select default"
echo "   terraform workspace delete $ENVIRONMENT"
```

Replace your entire `scripts/destroy.ps1` with this updated version:

```powershell
param(
    [Parameter(Mandatory=$true)]
    [string]$Environment,
    [string]$ProjectName = "twin"
)

# Validate environment parameter
if ($Environment -notmatch '^(dev|test|prod)$') {
    Write-Host "Error: Invalid environment '$Environment'" -ForegroundColor Red
    Write-Host "Available environments: dev, test, prod" -ForegroundColor Yellow
    exit 1
}

Write-Host "Preparing to destroy $ProjectName-$Environment infrastructure..." -ForegroundColor Yellow

# Navigate to terraform directory
Set-Location (Join-Path (Split-Path $PSScriptRoot -Parent) "terraform")

# Get AWS Account ID for backend configuration
$awsAccountId = aws sts get-caller-identity --query Account --output text
$awsRegion = if ($env:DEFAULT_AWS_REGION) { $env:DEFAULT_AWS_REGION } else { "us-east-1" }

# Initialize terraform with S3 backend
Write-Host "Initializing Terraform with S3 backend..." -ForegroundColor Yellow
terraform init -input=false `
  -backend-config="bucket=twin-terraform-state-$awsAccountId" `
  -backend-config="key=$Environment/terraform.tfstate" `
  -backend-config="region=$awsRegion" `
  -backend-config="encrypt=true"

# Check if workspace exists
$workspaces = terraform workspace list
if (-not ($workspaces | Select-String $Environment)) {
    Write-Host "Error: Workspace '$Environment' does not exist" -ForegroundColor Red
    Write-Host "Available workspaces:" -ForegroundColor Yellow
    terraform workspace list
    exit 1
}

# Select the workspace
terraform workspace select $Environment

Write-Host "Emptying S3 buckets..." -ForegroundColor Yellow

# Define bucket names with account ID (matching Day 4 naming)
$FrontendBucket = "$ProjectName-$Environment-frontend-$awsAccountId"
$MemoryBucket = "$ProjectName-$Environment-memory-$awsAccountId"

# Empty frontend bucket if it exists
try {
    aws s3 ls "s3://$FrontendBucket" 2>$null | Out-Null
    Write-Host "  Emptying $FrontendBucket..." -ForegroundColor Gray
    aws s3 rm "s3://$FrontendBucket" --recursive
} catch {
    Write-Host "  Frontend bucket not found or already empty" -ForegroundColor Gray
}

# Empty memory bucket if it exists
try {
    aws s3 ls "s3://$MemoryBucket" 2>$null | Out-Null
    Write-Host "  Emptying $MemoryBucket..." -ForegroundColor Gray
    aws s3 rm "s3://$MemoryBucket" --recursive
} catch {
    Write-Host "  Memory bucket not found or already empty" -ForegroundColor Gray
}

Write-Host "Running terraform destroy..." -ForegroundColor Yellow

# Run terraform destroy with auto-approve
if ($Environment -eq "prod" -and (Test-Path "prod.tfvars")) {
    terraform destroy -var-file=prod.tfvars `
                     -var="project_name=$ProjectName" `
                     -var="environment=$Environment" `
                     -auto-approve
} else {
    terraform destroy -var="project_name=$ProjectName" `
                     -var="environment=$Environment" `
                     -auto-approve
}

Write-Host "Infrastructure for $Environment has been destroyed!" -ForegroundColor Green
Write-Host ""
Write-Host "  To remove the workspace completely, run:" -ForegroundColor Cyan
Write-Host "   terraform workspace select default" -ForegroundColor White
Write-Host "   terraform workspace delete $Environment" -ForegroundColor White
```

## Part 4: Configure GitHub Repository Secrets

### Step 1: Create AWS IAM Role for GitHub Actions

As of August 2025, GitHub strongly recommends using OpenID Connect (OIDC) for AWS authentication. This is more secure than storing long-lived access keys.

Create `terraform/github-oidc.tf`:

```hcl
# This creates an IAM role that GitHub Actions can assume
# Run this once, then you can remove the file

variable "github_repository" {
  description = "GitHub repository in format 'owner/repo'"
  type        = string
}

# Note: aws_caller_identity.current is already defined in main.tf

# GitHub OIDC Provider
# Note: If this already exists in your account, you'll need to import it:
# terraform import aws_iam_openid_connect_provider.github arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
  
  client_id_list = [
    "sts.amazonaws.com"
  ]
  
  # This thumbprint is from GitHub's documentation
  # Verify current value at: https://github.blog/changelog/2023-06-27-github-actions-update-on-oidc-integration-with-aws/
  thumbprint_list = [
    "1b511abead59c6ce207077c0bf0e0043b1382612"
  ]
}

# IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  name = "github-actions-twin-deploy"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repository}:*"
          }
        }
      }
    ]
  })
  
  tags = {
    Name        = "GitHub Actions Deploy Role"
    Repository  = var.github_repository
    ManagedBy   = "terraform"
  }
}

# Attach necessary policies
resource "aws_iam_role_policy_attachment" "github_lambda" {
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
  role       = aws_iam_role.github_actions.name
}

resource "aws_iam_role_policy_attachment" "github_s3" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.github_actions.name
}

resource "aws_iam_role_policy_attachment" "github_apigateway" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonAPIGatewayAdministrator"
  role       = aws_iam_role.github_actions.name
}

resource "aws_iam_role_policy_attachment" "github_cloudfront" {
  policy_arn = "arn:aws:iam::aws:policy/CloudFrontFullAccess"
  role       = aws_iam_role.github_actions.name
}

resource "aws_iam_role_policy_attachment" "github_iam_read" {
  policy_arn = "arn:aws:iam::aws:policy/IAMReadOnlyAccess"
  role       = aws_iam_role.github_actions.name
}

resource "aws_iam_role_policy_attachment" "github_bedrock" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonBedrockFullAccess"
  role       = aws_iam_role.github_actions.name
}

resource "aws_iam_role_policy_attachment" "github_acm" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCertificateManagerFullAccess"
  role       = aws_iam_role.github_actions.name
}

resource "aws_iam_role_policy_attachment" "github_route53" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
  role       = aws_iam_role.github_actions.name
}

# Custom policy for additional permissions
resource "aws_iam_role_policy" "github_additional" {
  name = "github-actions-additional"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:UpdateAssumeRolePolicy",
          "iam:PassRole",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:ListInstanceProfilesForRole",
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      }
    ]
  })
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}
```

### Step 2: Create the GitHub Actions Role

```bash
cd terraform

# IMPORTANT: Make sure you're in the default workspace
terraform workspace select default

# First, check if the OIDC provider already exists

**Mac/Linux:**
```bash
aws iam list-open-id-connect-providers | grep token.actions.githubusercontent.com
```

**Windows (PowerShell):**
```powershell
aws iam list-open-id-connect-providers | Select-String "token.actions.githubusercontent.com"
```

If it exists, you'll see an ARN like: `arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com`

In that case, import it first:

**Mac/Linux:**
```bash
# Get your AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Your AWS Account ID is: $AWS_ACCOUNT_ID"

# Only run this if the provider already exists:
# terraform import aws_iam_openid_connect_provider.github arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com
```

**Windows (PowerShell):**
```powershell
# Get your AWS Account ID
$awsAccountId = aws sts get-caller-identity --query Account --output text
Write-Host "Your AWS Account ID is: $awsAccountId"

# Only run this if the provider already exists:
# terraform import aws_iam_openid_connect_provider.github "arn:aws:iam::${awsAccountId}:oidc-provider/token.actions.githubusercontent.com"
```

### Apply the GitHub OIDC Resources

Now you need to apply the resources. The command differs depending on whether the OIDC provider already exists:

#### Scenario A: OIDC Provider Does NOT Exist (First Time)

If the grep/Select-String command above found nothing, the OIDC provider doesn't exist yet. Create it along with the IAM role:

**⚠️ IMPORTANT**: Replace `YOUR_GITHUB_USERNAME` with your actual GitHub username.
For example: if your GitHub username is 'johndoe', use: `johndoe/digital-twin`

**Mac/Linux:**
```bash
# Apply ALL resources including OIDC provider (this is one long command - copy and paste it all)
terraform apply -target=aws_iam_openid_connect_provider.github -target=aws_iam_role.github_actions -target=aws_iam_role_policy_attachment.github_lambda -target=aws_iam_role_policy_attachment.github_s3 -target=aws_iam_role_policy_attachment.github_apigateway -target=aws_iam_role_policy_attachment.github_cloudfront -target=aws_iam_role_policy_attachment.github_iam_read -target=aws_iam_role_policy_attachment.github_bedrock -target=aws_iam_role_policy_attachment.github_acm -target=aws_iam_role_policy_attachment.github_route53 -target=aws_iam_role_policy.github_additional -var="github_repository=YOUR_GITHUB_USERNAME/digital-twin"
```

**Windows (PowerShell):**
```powershell
# Apply ALL resources including OIDC provider (this is one long command - copy and paste it all)
terraform apply -target="aws_iam_openid_connect_provider.github" -target="aws_iam_role.github_actions" -target="aws_iam_role_policy_attachment.github_lambda" -target="aws_iam_role_policy_attachment.github_s3" -target="aws_iam_role_policy_attachment.github_apigateway" -target="aws_iam_role_policy_attachment.github_cloudfront" -target="aws_iam_role_policy_attachment.github_iam_read" -target="aws_iam_role_policy_attachment.github_bedrock" -target="aws_iam_role_policy_attachment.github_acm" -target="aws_iam_role_policy_attachment.github_route53" -target="aws_iam_role_policy.github_additional" -var="github_repository=YOUR_GITHUB_USERNAME/digital-twin"
```

#### Scenario B: OIDC Provider Already Exists (You Imported It)

If you ran the import command above, you've already imported the OIDC provider. Now create just the IAM role and policies:

**Note**: During the import, you were prompted for `var.github_repository`. You entered something like `your-username/digital-twin` (e.g., `ed-donner/twin`).

**⚠️ IMPORTANT**: Use the same repository name below that you used during import.

**Mac/Linux:**
```bash
# Apply ONLY the IAM role and policies (NOT the OIDC provider) - one long command
terraform apply -target=aws_iam_role.github_actions -target=aws_iam_role_policy_attachment.github_lambda -target=aws_iam_role_policy_attachment.github_s3 -target=aws_iam_role_policy_attachment.github_apigateway -target=aws_iam_role_policy_attachment.github_cloudfront -target=aws_iam_role_policy_attachment.github_iam_read -target=aws_iam_role_policy_attachment.github_bedrock -target=aws_iam_role_policy_attachment.github_acm -target=aws_iam_role_policy_attachment.github_route53 -target=aws_iam_role_policy.github_additional -var="github_repository=YOUR_GITHUB_USERNAME/your-repo-name"
```

**Windows (PowerShell):**
```powershell
# Apply ONLY the IAM role and policies (NOT the OIDC provider) - one long command
terraform apply -target="aws_iam_role.github_actions" -target="aws_iam_role_policy_attachment.github_lambda" -target="aws_iam_role_policy_attachment.github_s3" -target="aws_iam_role_policy_attachment.github_apigateway" -target="aws_iam_role_policy_attachment.github_cloudfront" -target="aws_iam_role_policy_attachment.github_iam_read" -target="aws_iam_role_policy_attachment.github_bedrock" -target="aws_iam_role_policy_attachment.github_acm" -target="aws_iam_role_policy_attachment.github_route53" -target="aws_iam_role_policy.github_additional" -var="github_repository=myrepo/digital-twin"
```

### Get the Role ARN and Clean Up

After either scenario succeeds:

```bash
# Note the role ARN from the output
terraform output github_actions_role_arn

# Remove the setup file after creating
rm github-oidc.tf    # Mac/Linux
Remove-Item github-oidc.tf    # Windows PowerShell
```

**Important**: Save the Role ARN from the terraform output - you'll need it for the next step.

### Step 3: Configure Terraform Backend

Now that all setup resources are created, configure Terraform to use the S3 backend.

Create `terraform/backend.tf`:

```hcl
terraform {
  backend "s3" {
    # These values will be set by deployment scripts
    # For local development, they can be passed via -backend-config
  }
}
```

This file tells Terraform to use S3 for state storage, but doesn't specify the bucket name or other details. Those will be provided by the deployment scripts using `-backend-config` flags.

### Step 4: Add Secrets to GitHub

1. Go to your GitHub repository
2. Click **Settings** tab
3. In the left sidebar, click **Secrets and variables** → **Actions**
4. Click **New repository secret** for each of these:

**Secret 1: AWS_ROLE_ARN**
- Name: `AWS_ROLE_ARN`
- Value: The ARN from terraform output (like `arn:aws:iam::123456789012:role/github-actions-twin-deploy`)

**Secret 2: DEFAULT_AWS_REGION**
- Name: `DEFAULT_AWS_REGION`
- Value: `us-east-1` (or your preferred region)

**Secret 3: AWS_ACCOUNT_ID**
- Name: `AWS_ACCOUNT_ID`
- Value: Your 12-digit AWS account ID

### Step 5: Verify Secrets

After adding all secrets, you should see 3 repository secrets:
- AWS_ROLE_ARN
- DEFAULT_AWS_REGION  
- AWS_ACCOUNT_ID

✅ **Checkpoint**: GitHub can now securely authenticate with your AWS account!

## Part 5: Create GitHub Actions Workflows

### Step 1: Create Workflow Directory

In Cursor's Explorer panel (left sidebar):

1. Right-click in the Explorer panel (on any empty space or on the project root)
2. Select **New Folder**
3. Name it `.github` (with the dot)
4. Right-click on the `.github` folder you just created
5. Select **New Folder**
6. Name it `workflows`

You should now have `.github/workflows/` in your project.

### Step 2: Create Deployment Workflow

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy Digital Twin

on:
  push:
    branches: [main]
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy'
        required: true
        default: 'dev'
        type: choice
        options:
          - dev
          - test
          - prod

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    name: Deploy to ${{ github.event.inputs.environment || 'dev' }}
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment || 'dev' }}
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          role-session-name: github-actions-deploy
          aws-region: ${{ secrets.DEFAULT_AWS_REGION }}

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Install uv
        run: |
          curl -LsSf https://astral.sh/uv/install.sh | sh
          echo "$HOME/.local/bin" >> $GITHUB_PATH

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_wrapper: false  # Important: disable wrapper to get raw outputs

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: frontend/package-lock.json

      - name: Run Deployment Script
        run: |
          # Set environment variables for the script
          export AWS_ACCOUNT_ID=${{ secrets.AWS_ACCOUNT_ID }}
          export DEFAULT_AWS_REGION=${{ secrets.DEFAULT_AWS_REGION }}
          
          # Make script executable and run it
          chmod +x scripts/deploy.sh
          ./scripts/deploy.sh ${{ github.event.inputs.environment || 'dev' }}
        env:
          AWS_ROLE_ARN: ${{ secrets.AWS_ROLE_ARN }}
          
      - name: Get Deployment URLs
        id: deploy_outputs
        working-directory: ./terraform
        run: |
          terraform workspace select ${{ github.event.inputs.environment || 'dev' }}
          echo "cloudfront_url=$(terraform output -raw cloudfront_url)" >> $GITHUB_OUTPUT
          echo "api_url=$(terraform output -raw api_gateway_url)" >> $GITHUB_OUTPUT
          echo "frontend_bucket=$(terraform output -raw s3_frontend_bucket)" >> $GITHUB_OUTPUT

      - name: Invalidate CloudFront
        run: |
          DISTRIBUTION_ID=$(aws cloudfront list-distributions \
            --query "DistributionList.Items[?Origins.Items[?DomainName=='${{ steps.deploy_outputs.outputs.frontend_bucket }}.s3-website-${{ secrets.DEFAULT_AWS_REGION }}.amazonaws.com']].Id | [0]" \
            --output text)
          
          if [ "$DISTRIBUTION_ID" != "None" ] && [ -n "$DISTRIBUTION_ID" ]; then
            aws cloudfront create-invalidation \
              --distribution-id $DISTRIBUTION_ID \
              --paths "/*"
          fi

      - name: Deployment Summary
        run: |
          echo "✅ Deployment Complete!"
          echo "🌐 CloudFront URL: ${{ steps.deploy_outputs.outputs.cloudfront_url }}"
          echo "📡 API Gateway: ${{ steps.deploy_outputs.outputs.api_url }}"
          echo "🪣 Frontend Bucket: ${{ steps.deploy_outputs.outputs.frontend_bucket }}"
```

### Step 3: Create Destroy Workflow

Create `.github/workflows/destroy.yml`:

```yaml
name: Destroy Environment

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to destroy'
        required: true
        type: choice
        options:
          - dev
          - test
          - prod
      confirm:
        description: 'Type the environment name to confirm destruction'
        required: true

permissions:
  id-token: write
  contents: read

jobs:
  destroy:
    name: Destroy ${{ github.event.inputs.environment }}
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment }}
    
    steps:
      - name: Verify confirmation
        run: |
          if [ "${{ github.event.inputs.confirm }}" != "${{ github.event.inputs.environment }}" ]; then
            echo "❌ Confirmation does not match environment name!"
            echo "You entered: '${{ github.event.inputs.confirm }}'"
            echo "Expected: '${{ github.event.inputs.environment }}'"
            exit 1
          fi
          echo "✅ Destruction confirmed for ${{ github.event.inputs.environment }}"

      - name: Checkout code
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          role-session-name: github-actions-destroy
          aws-region: ${{ secrets.DEFAULT_AWS_REGION }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_wrapper: false  # Important: disable wrapper to get raw outputs

      - name: Run Destroy Script
        run: |
          # Set environment variables for the script
          export AWS_ACCOUNT_ID=${{ secrets.AWS_ACCOUNT_ID }}
          export DEFAULT_AWS_REGION=${{ secrets.DEFAULT_AWS_REGION }}
          
          # Make script executable and run it
          chmod +x scripts/destroy.sh
          ./scripts/destroy.sh ${{ github.event.inputs.environment }}
        env:
          AWS_ROLE_ARN: ${{ secrets.AWS_ROLE_ARN }}

      - name: Destruction Complete
        run: |
          echo "✅ Environment ${{ github.event.inputs.environment }} has been destroyed!"
```

### Step 4: Commit and Push All Changes

```bash
# Add all changes (workflows, backend.tf, updated scripts)
git add .

# See what's being committed
git status

# Commit
git commit -m "Add CI/CD with GitHub Actions, S3 backend, and updated scripts"

# Push to GitHub
git push
```

## Part 6: Test Deployments

### Step 1: Automatic Dev Deployment

Since we pushed to the main branch, GitHub Actions should automatically trigger a deployment to dev:

1. Go to your GitHub repository
2. Click **Actions** tab
3. You should see "Deploy Digital Twin" workflow running
4. Click on it to watch the progress
5. Wait for completion (5-10 minutes)

Once the deployment completes successfully:

6. Expand the **"Deployment Summary"** step at the bottom of the workflow
7. You'll see your deployment URLs:
   - 🌐 **CloudFront URL**: `https://[something].cloudfront.net` - this is your Digital Twin app!
   - 📡 **API Gateway**: The backend API endpoint
   - 🪣 **Frontend Bucket**: The S3 bucket name
8. Click on the CloudFront URL to open your Digital Twin in a browser

### Step 2: Manual Test Deployment

Let's deploy to the test environment:

1. In GitHub, go to **Actions** tab
2. Click **Deploy Digital Twin** on the left
3. Click **Run workflow** dropdown
4. Select:
   - Branch: `main`
   - Environment: `test`
5. Click **Run workflow**
6. Watch the deployment progress

### Step 3: Manual Production Deployment

If you have a custom domain configured:

1. In GitHub, go to **Actions** tab
2. Click **Deploy Digital Twin**
3. Click **Run workflow**
4. Select:
   - Branch: `main`
   - Environment: `prod`
5. Click **Run workflow**

### Step 4: Verify Deployments

After each deployment completes:
1. Check the workflow summary for the CloudFront URL
2. Visit the URL to test your Digital Twin
3. Have a conversation to verify it's working

✅ **Checkpoint**: You now have CI/CD deploying to multiple environments!

## Part 7: Fix UI Focus Issue and Add Avatar

Let's fix the annoying focus issue and optionally add a profile picture.

### Step 1: Add Profile Picture (Optional)

If you have a profile picture:

1. Add your profile picture as `frontend/public/avatar.png`
2. Keep it small (ideally under 100KB)
3. Square aspect ratio works best (e.g., 200x200px)

### Step 2: Update Twin Component

Update `frontend/components/twin.tsx` to fix the focus issue and add avatar:

Find the `sendMessage` function and add a ref for the input. Here's the complete updated component:

```typescript
'use client';

import { useState, useRef, useEffect } from 'react';
import { Send, Bot, User } from 'lucide-react';

interface Message {
    id: string;
    role: 'user' | 'assistant';
    content: string;
    timestamp: Date;
}

export default function Twin() {
    const [messages, setMessages] = useState<Message[]>([]);
    const [input, setInput] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const [sessionId, setSessionId] = useState<string>('');
    const messagesEndRef = useRef<HTMLDivElement>(null);
    const inputRef = useRef<HTMLInputElement>(null);

    const scrollToBottom = () => {
        messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
    };

    useEffect(() => {
        scrollToBottom();
    }, [messages]);

    const sendMessage = async () => {
        if (!input.trim() || isLoading) return;

        const userMessage: Message = {
            id: Date.now().toString(),
            role: 'user',
            content: input,
            timestamp: new Date(),
        };

        setMessages(prev => [...prev, userMessage]);
        setInput('');
        setIsLoading(true);

        try {
            const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000'}/chat`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    message: userMessage.content,
                    session_id: sessionId || undefined,
                }),
            });

            if (!response.ok) throw new Error('Failed to send message');

            const data = await response.json();

            if (!sessionId) {
                setSessionId(data.session_id);
            }

            const assistantMessage: Message = {
                id: (Date.now() + 1).toString(),
                role: 'assistant',
                content: data.response,
                timestamp: new Date(),
            };

            setMessages(prev => [...prev, assistantMessage]);
        } catch (error) {
            console.error('Error:', error);
            const errorMessage: Message = {
                id: (Date.now() + 1).toString(),
                role: 'assistant',
                content: 'Sorry, I encountered an error. Please try again.',
                timestamp: new Date(),
            };
            setMessages(prev => [...prev, errorMessage]);
        } finally {
            setIsLoading(false);
            // Refocus the input after message is sent
            setTimeout(() => {
                inputRef.current?.focus();
            }, 100);
        }
    };

    const handleKeyPress = (e: React.KeyboardEvent) => {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            sendMessage();
        }
    };

    // Check if avatar exists
    const [hasAvatar, setHasAvatar] = useState(false);
    useEffect(() => {
        // Check if avatar.png exists
        fetch('/avatar.png', { method: 'HEAD' })
            .then(res => setHasAvatar(res.ok))
            .catch(() => setHasAvatar(false));
    }, []);

    return (
        <div className="flex flex-col h-full bg-gray-50 rounded-lg shadow-lg">
            {/* Header */}
            <div className="bg-gradient-to-r from-slate-700 to-slate-800 text-white p-4 rounded-t-lg">
                <h2 className="text-xl font-semibold flex items-center gap-2">
                    <Bot className="w-6 h-6" />
                    AI Digital Twin
                </h2>
                <p className="text-sm text-slate-300 mt-1">Your AI course companion</p>
            </div>

            {/* Messages */}
            <div className="flex-1 overflow-y-auto p-4 space-y-4">
                {messages.length === 0 && (
                    <div className="text-center text-gray-500 mt-8">
                        {hasAvatar ? (
                            <img 
                                src="/avatar.png" 
                                alt="Digital Twin Avatar" 
                                className="w-20 h-20 rounded-full mx-auto mb-3 border-2 border-gray-300"
                            />
                        ) : (
                            <Bot className="w-12 h-12 mx-auto mb-3 text-gray-400" />
                        )}
                        <p>Hello! I&apos;m your Digital Twin.</p>
                        <p className="text-sm mt-2">Ask me anything about AI deployment!</p>
                    </div>
                )}

                {messages.map((message) => (
                    <div
                        key={message.id}
                        className={`flex gap-3 ${
                            message.role === 'user' ? 'justify-end' : 'justify-start'
                        }`}
                    >
                        {message.role === 'assistant' && (
                            <div className="flex-shrink-0">
                                {hasAvatar ? (
                                    <img 
                                        src="/avatar.png" 
                                        alt="Digital Twin Avatar" 
                                        className="w-8 h-8 rounded-full border border-slate-300"
                                    />
                                ) : (
                                    <div className="w-8 h-8 bg-slate-700 rounded-full flex items-center justify-center">
                                        <Bot className="w-5 h-5 text-white" />
                                    </div>
                                )}
                            </div>
                        )}

                        <div
                            className={`max-w-[70%] rounded-lg p-3 ${
                                message.role === 'user'
                                    ? 'bg-slate-700 text-white'
                                    : 'bg-white border border-gray-200 text-gray-800'
                            }`}
                        >
                            <p className="whitespace-pre-wrap">{message.content}</p>
                            <p
                                className={`text-xs mt-1 ${
                                    message.role === 'user' ? 'text-slate-300' : 'text-gray-500'
                                }`}
                            >
                                {message.timestamp.toLocaleTimeString()}
                            </p>
                        </div>

                        {message.role === 'user' && (
                            <div className="flex-shrink-0">
                                <div className="w-8 h-8 bg-gray-600 rounded-full flex items-center justify-center">
                                    <User className="w-5 h-5 text-white" />
                                </div>
                            </div>
                        )}
                    </div>
                ))}

                {isLoading && (
                    <div className="flex gap-3 justify-start">
                        <div className="flex-shrink-0">
                            {hasAvatar ? (
                                <img 
                                    src="/avatar.png" 
                                    alt="Digital Twin Avatar" 
                                    className="w-8 h-8 rounded-full border border-slate-300"
                                />
                            ) : (
                                <div className="w-8 h-8 bg-slate-700 rounded-full flex items-center justify-center">
                                    <Bot className="w-5 h-5 text-white" />
                                </div>
                            )}
                        </div>
                        <div className="bg-white border border-gray-200 rounded-lg p-3">
                            <div className="flex space-x-2">
                                <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" />
                                <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce delay-100" />
                                <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce delay-200" />
                            </div>
                        </div>
                    </div>
                )}

                <div ref={messagesEndRef} />
            </div>

            {/* Input */}
            <div className="border-t border-gray-200 p-4 bg-white rounded-b-lg">
                <div className="flex gap-2">
                    <input
                        ref={inputRef}
                        type="text"
                        value={input}
                        onChange={(e) => setInput(e.target.value)}
                        onKeyDown={handleKeyPress}
                        placeholder="Type your message..."
                        className="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-slate-600 focus:border-transparent text-gray-800"
                        disabled={isLoading}
                        autoFocus
                    />
                    <button
                        onClick={sendMessage}
                        disabled={!input.trim() || isLoading}
                        className="px-4 py-2 bg-slate-700 text-white rounded-lg hover:bg-slate-800 focus:outline-none focus:ring-2 focus:ring-slate-600 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                    >
                        <Send className="w-5 h-5" />
                    </button>
                </div>
            </div>
        </div>
    );
}
```

### Step 3: Commit and Push the Fix

```bash
# Add changes
git add frontend/components/twin.tsx
git add frontend/public/avatar.png  # Only if you added an avatar

# Commit
git commit -m "Fix input focus issue and add avatar support"

# Push to trigger deployment
git push
```

This push will automatically trigger a deployment to dev!

### Step 4: Verify the Fix

Once the GitHub Actions workflow completes:

1. Visit your dev environment CloudFront URL
2. Send a message
3. The input field should automatically regain focus after the response
4. If you added an avatar, it should appear instead of the bot icon

✅ **Checkpoint**: The annoying focus issue is fixed!

## Part 8: Explore AWS Console and CloudWatch

Now let's explore what's happening behind the scenes in AWS.

### Step 1: Sign In as IAM User

Sign in to AWS Console as `aiengineer` (your IAM user).

### Step 2: Explore Lambda Functions

1. Navigate to **Lambda**
2. You should see three functions:
   - `twin-dev-api`
   - `twin-test-api`
   - `twin-prod-api` (if deployed)
3. Click on `twin-dev-api`
4. Go to **Monitor** tab
5. View:
   - Invocations graph
   - Duration metrics
   - Error count
   - Success rate

### Step 3: View CloudWatch Logs

1. In Lambda, click **View CloudWatch logs**
2. Click on the latest log stream
3. You can see:
   - Each API request
   - Bedrock model calls
   - Response times
   - Any errors

### Step 4: Check Bedrock Usage

1. Navigate to **CloudWatch**
2. Click **Metrics** → **All metrics**
3. Click **AWS/Bedrock**
4. Select **By Model Id**
5. View metrics for your Nova model:
   - InvocationLatency
   - InputTokenCount
   - OutputTokenCount

### Step 5: View S3 Memory Storage

1. Navigate to **S3**
2. Click on `twin-dev-memory` bucket
3. You'll see JSON files for each conversation session
4. Click on a file to view the conversation history

### Step 6: API Gateway Metrics

1. Navigate to **API Gateway**
2. Click on `twin-dev-api-gateway`
3. Click **Dashboard**
4. View:
   - API calls
   - Latency
   - 4xx and 5xx errors

### Step 7: CloudFront Analytics

1. Navigate to **CloudFront**
2. Click on your dev distribution
3. Go to **Reports & analytics**
4. View:
   - Cache statistics
   - Popular objects
   - Viewers by location

## Part 9: Environment Management via GitHub

### Step 1: Test Environment Destruction

Let's test destroying an environment through GitHub Actions:

1. Go to your GitHub repository
2. Click **Actions** tab
3. Click **Destroy Environment** on the left
4. Click **Run workflow**
5. Select:
   - Branch: `main`
   - Environment: `test`
   - Confirm: Type `test` in the confirmation field
6. Click **Run workflow**
7. Watch the destruction progress (5-10 minutes)

### Step 2: Verify Destruction

After the workflow completes:

1. Check AWS Console
2. Verify all `twin-test-*` resources are gone:
   - Lambda function
   - API Gateway
   - S3 buckets
   - CloudFront distribution

### Step 3: Redeploy Test

Let's redeploy to test:

1. In GitHub Actions, click **Deploy Digital Twin**
2. Run workflow with environment: `test`
3. Wait for completion
4. Verify the test environment is back online

## Part 10: Final Cleanup and Cost Review

### Step 1: Destroy All Environments

Use GitHub Actions to destroy all environments:

1. Destroy dev environment:
   - Run **Destroy Environment** workflow
   - Environment: `dev`
   - Confirm: Type `dev`

2. Destroy test environment (if not already destroyed):
   - Run **Destroy Environment** workflow
   - Environment: `test`
   - Confirm: Type `test`

3. Destroy prod environment (if you created one):
   - Run **Destroy Environment** workflow
   - Environment: `prod`
   - Confirm: Type `prod`

### Step 2: Sign In as Root User

Now let's verify everything is clean and check costs:

1. Sign out from IAM user
2. Sign in as **root user**

### Step 3: Verify Complete Cleanup

#### Option A: Check Individual Services

Check each service to ensure all project resources are removed:

1. **Lambda**: No functions starting with `twin-`
2. **S3**: Only the `twin-terraform-state-*` bucket should remain
3. **API Gateway**: No `twin-` APIs
4. **CloudFront**: No twin distributions
5. **IAM**: The `github-actions-twin-deploy` role should remain

#### Option B: Use Resource Explorer (Recommended)

AWS Resource Explorer gives you a complete inventory of ALL resources in your account:

1. In AWS Console, search for **Resource Explorer**
2. If not set up, click **Quick setup** (one-time setup, takes 2 minutes)
3. Once ready, click **Resource search**
4. In the search box, type: `tag.Project:twin`
5. This shows all resources tagged with our project

To see ALL resources in your account (to find anything you might have missed):

1. In Resource Explorer, click **Resource search**
2. Leave the search box empty
3. Click **Search**
4. This shows EVERY resource in your account
5. Sort by **Type** to group similar resources
6. Look for any unexpected resources that might be costing money

#### Option C: Use AWS Tag Editor

Another way to find all tagged resources:

1. In AWS Console, search for **Tag Editor**
2. Select:
   - Regions: **All regions**
   - Resource types: **All supported resource types**
   - Tags: Key = `Project`, Value = `twin`
3. Click **Search resources**
4. This shows all project resources across all regions

#### Option D: Check Cost and Usage Report

To see what's actually costing money:

1. Go to **Billing & Cost Management**
2. Click **Cost Explorer** → **Cost and usage**
3. Group by: **Service**
4. Filter: Last 7 days
5. Any service showing costs indicates active resources

### Step 4: Review Costs

1. Navigate to **Billing & Cost Management**
2. Click **Cost Explorer**
3. Set date range to last 7 days
4. Filter by service to see costs:
   - Lambda: Usually under $1
   - API Gateway: Usually under $1
   - S3: Minimal (cents)
   - CloudFront: Minimal (cents)
   - Bedrock: Depends on usage, typically under $5

### Step 5: Optional - Clean Up GitHub Actions Resources

The remaining resources have minimal ongoing costs:
- **IAM Role** (`github-actions-twin-deploy`): FREE - No cost for IAM
- **S3 State Bucket** (`twin-terraform-state-*`): ~$0.02/month for storing state files

**Total monthly cost if left running: Less than $0.05**

If you want to completely remove everything (only do this if you're completely done with the course):

```bash
# Sign in as IAM user first, then:
cd twin/terraform

# 1. Delete the IAM role for GitHub Actions
aws iam detach-role-policy --role-name github-actions-twin-deploy --policy-arn arn:aws:iam::aws:policy/AWSLambda_FullAccess
aws iam detach-role-policy --role-name github-actions-twin-deploy --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
aws iam detach-role-policy --role-name github-actions-twin-deploy --policy-arn arn:aws:iam::aws:policy/AmazonAPIGatewayAdministrator
aws iam detach-role-policy --role-name github-actions-twin-deploy --policy-arn arn:aws:iam::aws:policy/CloudFrontFullAccess
aws iam detach-role-policy --role-name github-actions-twin-deploy --policy-arn arn:aws:iam::aws:policy/IAMReadOnlyAccess
aws iam detach-role-policy --role-name github-actions-twin-deploy --policy-arn arn:aws:iam::aws:policy/AmazonBedrockFullAccess
aws iam detach-role-policy --role-name github-actions-twin-deploy --policy-arn arn:aws:iam::aws:policy/AWSCertificateManagerFullAccess
aws iam detach-role-policy --role-name github-actions-twin-deploy --policy-arn arn:aws:iam::aws:policy/AmazonRoute53FullAccess
aws iam delete-role-policy --role-name github-actions-twin-deploy --policy-name github-actions-additional
aws iam delete-role --role-name github-actions-twin-deploy

# 2. Empty and delete the state bucket
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws s3 rm s3://twin-terraform-state-${AWS_ACCOUNT_ID} --recursive
aws s3 rb s3://twin-terraform-state-${AWS_ACCOUNT_ID}

```

**Recommendation**: Leave these resources in place. They cost almost nothing and allow you to easily redeploy the project later if needed.

## Congratulations! 🎉

You've successfully completed Week 2 and built a production-grade AI deployment system!

### What You've Accomplished This Week

**Day 1**: Built a local Digital Twin with memory
**Day 2**: Deployed to AWS with Lambda, S3, CloudFront
**Day 3**: Integrated AWS Bedrock for AI responses
**Day 4**: Automated with Terraform and multiple environments
**Day 5**: Implemented CI/CD with GitHub Actions

### Your Final Architecture

```
GitHub Repository
    ↓ (Push to main)
GitHub Actions (CI/CD)
    ↓ (Automated deployment)
AWS Infrastructure
    ├── Dev Environment
    ├── Test Environment
    └── Prod Environment

Each Environment:
    ├── CloudFront → S3 (Frontend)
    ├── API Gateway → Lambda (Backend)
    ├── Bedrock (AI)
    └── S3 (Memory)

All Managed by:
    ├── Terraform (IaC)
    ├── GitHub Actions (CI/CD)
    └── S3 (State)
```

### Key Skills You've Learned

1. **Modern DevOps Practices**
   - Infrastructure as Code
   - CI/CD pipelines
   - Multi-environment management
   - Automated testing and deployment

2. **AWS Services Mastery**
   - Serverless computing (Lambda)
   - API management (API Gateway)
   - Static hosting (S3, CloudFront)
   - AI services (Bedrock)
   - State management

3. **Security Best Practices**
   - OIDC authentication
   - IAM roles and policies
   - Secrets management
   - Least privilege access

4. **Professional Development Workflow**
   - Version control with Git
   - Pull request workflows
   - Automated deployments
   - Infrastructure testing

## Best Practices Going Forward

### Development Workflow

1. **Always use branches for features** (even though we didn't today)
   ```bash
   git checkout -b feature/new-feature
   # Make changes
   git push -u origin feature/new-feature
   # Create pull request
   ```

2. **Test in dev/test before prod**
   - Deploy to dev automatically
   - Manually promote to test
   - Carefully deploy to prod

3. **Monitor costs regularly**
   - Check CloudWatch metrics
   - Review billing dashboard weekly
   - Set up anomaly detection

### Security Reminders

1. **Never commit secrets**
   - Use GitHub Secrets
   - Use environment variables
   - Use AWS Secrets Manager for sensitive data

2. **Rotate credentials regularly**
   - Update IAM roles periodically
   - Refresh API keys
   - Review access logs

3. **Follow least privilege**
   - Only grant necessary permissions
   - Use separate roles for different purposes
   - Audit permissions regularly

## Troubleshooting Common Issues

### GitHub Actions Failures

**"Could not assume role"**
- Check AWS_ROLE_ARN secret is correct
- Verify GitHub repository name matches OIDC configuration
- Ensure role trust policy is correct

**"Terraform state lock"**
- Someone else might be deploying
- Check S3 state object for locks
- Force unlock if needed: `terraform force-unlock LOCK_ID`

**"S3 bucket already exists"**
- Bucket names must be globally unique
- Add random suffix or use account ID

### Deployment Issues

**Frontend not updating**
- CloudFront cache needs invalidation
- Check GitHub Actions ran successfully
- Verify S3 sync completed

**API returning 403**
- Check CORS configuration
- Verify API Gateway deployment
- Check Lambda permissions

**Bedrock not responding**
- Verify model access is granted
- Check IAM role has Bedrock permissions
- Review CloudWatch logs

## Next Steps and Extensions

### Potential Enhancements

1. **Add Testing**
   - Unit tests for Lambda
   - Integration tests for API
   - End-to-end tests with Cypress

2. **Enhance Monitoring**
   - Custom CloudWatch dashboards
   - Alerts for errors
   - Performance monitoring

3. **Add Features**
   - User authentication
   - Multiple twin personalities
   - Conversation analytics
   - Voice interface

4. **Improve CI/CD**
   - Blue-green deployments
   - Canary releases
   - Automatic rollbacks

### Learning Resources

- [GitHub Actions Documentation](https://docs.github.com/actions)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices)
- [DevOps on AWS](https://aws.amazon.com/devops/)

## Final Notes

### Keeping Costs Low

To minimize ongoing costs:
1. Destroy environments when not in use
2. Use Nova Micro for development
3. Set API rate limiting
4. Monitor usage regularly
5. Use the AWS Free Tier effectively

### Repository Maintenance

Keep your repository healthy:
1. Regular dependency updates
2. Security scanning with Dependabot
3. Clear documentation
4. Meaningful commit messages
5. Protected main branch

You've built something amazing - a fully automated, production-ready AI application with professional DevOps practices. This is how real companies deploy and manage their infrastructure!

Great job completing Week 2! 🚀
