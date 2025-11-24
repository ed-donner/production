# Day 4: Infrastructure as Code with Terraform

## From Manual to Automated Deployment

Welcome to Day 4! Today marks a significant shift in how we deploy our Digital Twin. We're moving from manual AWS Console operations to Infrastructure as Code (IaC) using Terraform. This transformation brings version control, repeatability, and the ability to deploy multiple environments with a single command. By the end of today, you'll be managing dev, test, and production environments like a professional DevOps engineer!

## What You'll Learn Today

- **Terraform fundamentals** - Infrastructure as Code concepts
- **State management** - How Terraform tracks your resources
- **Workspaces** - Managing multiple environments
- **Automated deployment** - One-command infrastructure provisioning
- **Environment isolation** - Separate dev, test, and production
- **Optional: Custom domains** - Professional DNS configuration

## Part 1: Clean Slate - Remove Manual Resources

Before we embrace automation, let's clean up all the resources we created manually in Days 2 and 3. This final console tour will help reinforce what Terraform will manage for us.

### Step 1: Delete Lambda Function

1. Sign in to AWS Console as `aiengineer`
2. Navigate to **Lambda**
3. Select `twin-api` function
4. Click **Actions** → **Delete**
5. Type "delete" to confirm
6. Click **Delete**

### Step 2: Delete API Gateway

1. Navigate to **API Gateway**
2. Click on `twin-api-gateway`
3. Click **Actions** → **Delete**
4. Type the API name to confirm
5. Click **Delete**

### Step 3: Empty and Delete S3 Buckets

**Memory Bucket:**
1. Navigate to **S3**
2. Click on your memory bucket (e.g., `twin-memory-xyz`)
3. Click **Empty**
4. Type "permanently delete" to confirm
5. Click **Empty**
6. After emptying, click **Delete**
7. Type the bucket name to confirm
8. Click **Delete bucket**

**Frontend Bucket:**
1. Click on your frontend bucket (e.g., `twin-frontend-xyz`)
2. Repeat the empty and delete process

### Step 4: Delete CloudFront Distribution

1. Navigate to **CloudFront**
2. Select your distribution
3. Click **Disable** (if it's enabled)
4. Wait for status to change to "Deployed" (5-10 minutes)
5. Once disabled, click **Delete**
6. Click **Delete** to confirm

### Step 5: Verify Clean State

1. Check each service to ensure no twin-related resources remain:
   - Lambda: No `twin-api` functions
   - API Gateway: No `twin-api-gateway` APIs
   - S3: No `twin-` prefixed buckets
   - CloudFront: No distributions for your twin

✅ **Checkpoint**: You now have a clean AWS account, ready for Terraform to manage everything!

## Part 2: Understanding Terraform

### What is Infrastructure as Code?

Infrastructure as Code (IaC) treats your infrastructure configuration as source code. Instead of clicking through console interfaces, you define your infrastructure in text files that can be:
- **Version controlled** - Track changes over time
- **Reviewed** - Use pull requests for infrastructure changes
- **Automated** - Deploy with CI/CD pipelines
- **Repeatable** - Create identical environments

### Key Terraform Concepts

**1. Resources**: The building blocks - each AWS service you want to create
```hcl
resource "aws_s3_bucket" "example" {
  bucket = "my-bucket-name"
}
```

**2. State**: Terraform's record of what it has created
- Stored in `terraform.tfstate` file
- Maps your configuration to real resources
- Critical for updates and deletions

**3. Providers**: Plugins that interact with cloud providers
```hcl
provider "aws" {
  region = "us-east-1"
}
```

**4. Variables**: Parameterize your configuration
```hcl
variable "environment" {
  description = "Environment name"
  type        = string
}
```

**5. Workspaces**: Separate state for different environments
- Each workspace has its own state file
- Perfect for dev/test/prod separation

### Step 1: Install Terraform

As of August 2025, Terraform installation has changed due to licensing updates. We'll use the official distribution.

**Mac (using Homebrew):**
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

**Mac/Linux (manual):**
1. Visit: https://developer.hashicorp.com/terraform/install
2. Download the appropriate package for your system
3. Extract and move to PATH:
```bash
# Example for Mac (adjust URL for your system)
curl -O https://releases.hashicorp.com/terraform/1.10.0/terraform_1.10.0_darwin_amd64.zip
unzip terraform_1.10.0_darwin_amd64.zip
sudo mv terraform /usr/local/bin/
```

**Windows:**
1. Visit: https://developer.hashicorp.com/terraform/install
2. Download the Windows package
3. Extract the .exe file
4. Add to your PATH:
   - Right-click "This PC" → Properties
   - Advanced system settings → Environment Variables
   - Edit PATH and add the Terraform directory

**Verify Installation:**
```bash
terraform --version
```

You should see something like: `Terraform v1.10.0` (version may vary)

### Step 2: Update .gitignore

Add Terraform-specific entries to your `.gitignore`:

```gitignore
# Terraform
*.tfstate
*.tfstate.*
.terraform/
.terraform.lock.hcl
terraform.tfstate.d/
*.tfvars
!terraform.tfvars
!prod.tfvars

# Lambda packages
lambda-deployment.zip
lambda-package/

# Environment files
.env
.env.*

# Node
node_modules/
out/
.next/

# Python
__pycache__/
*.pyc
.venv/
uv.lock

# IDE
.vscode/
.idea/
*.swp
.DS_Store
```

## Part 3: Create Terraform Configuration

### Step 1: Create Terraform Directory Structure

In Cursor's file explorer (the left sidebar):

1. Right-click in the file explorer in the blank space below all the files
2. Select **New Folder**
3. Name it `terraform`

Your project structure should now have:
```
twin/
├── backend/
├── frontend/
├── memory/
└── terraform/   (new)
```

### Step 2: Create Provider Configuration

Create `terraform/versions.tf`:

```hcl
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  # Uses AWS CLI configuration (aws configure)
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
```

### Step 3: Define Variables

Create `terraform/variables.tf`:

```hcl
variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be one of: dev, test, prod."
  }
}

variable "bedrock_model_id" {
  description = "Bedrock model ID"
  type        = string
  default     = "amazon.nova-micro-v1:0"
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 60
}

variable "api_throttle_burst_limit" {
  description = "API Gateway throttle burst limit"
  type        = number
  default     = 10
}

variable "api_throttle_rate_limit" {
  description = "API Gateway throttle rate limit"
  type        = number
  default     = 5
}

variable "use_custom_domain" {
  description = "Attach a custom domain to CloudFront"
  type        = bool
  default     = false
}

variable "root_domain" {
  description = "Apex domain name, e.g. mydomain.com"
  type        = string
  default     = ""
}
```

### Step 4: Create Main Infrastructure

Create `terraform/main.tf`:

```hcl
# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

locals {
  aliases = var.use_custom_domain && var.root_domain != "" ? [
    var.root_domain,
    "www.${var.root_domain}"
  ] : []

  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# S3 bucket for conversation memory
resource "aws_s3_bucket" "memory" {
  bucket = "${local.name_prefix}-memory-${data.aws_caller_identity.current.account_id}"
  tags   = local.common_tags
}

resource "aws_s3_bucket_public_access_block" "memory" {
  bucket = aws_s3_bucket.memory.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "memory" {
  bucket = aws_s3_bucket.memory.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# S3 bucket for frontend static website
resource "aws_s3_bucket" "frontend" {
  bucket = "${local.name_prefix}-frontend-${data.aws_caller_identity.current.account_id}"
  tags   = local.common_tags
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "404.html"
  }
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
      },
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.frontend]
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${local.name_prefix}-lambda-role"
  tags = local.common_tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_bedrock" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonBedrockFullAccess"
  role       = aws_iam_role.lambda_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_s3" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.lambda_role.name
}

# Lambda function
resource "aws_lambda_function" "api" {
  filename         = "${path.module}/../backend/lambda-deployment.zip"
  function_name    = "${local.name_prefix}-api"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_handler.handler"
  source_code_hash = filebase64sha256("${path.module}/../backend/lambda-deployment.zip")
  runtime          = "python3.12"
  architectures    = ["x86_64"]
  timeout          = var.lambda_timeout
  tags             = local.common_tags

  environment {
    variables = {
      CORS_ORIGINS     = var.use_custom_domain ? "https://${var.root_domain},https://www.${var.root_domain}" : "https://${aws_cloudfront_distribution.main.domain_name}"
      S3_BUCKET        = aws_s3_bucket.memory.id
      USE_S3           = "true"
      BEDROCK_MODEL_ID = var.bedrock_model_id
    }
  }

  # Ensure Lambda waits for the distribution to exist
  depends_on = [aws_cloudfront_distribution.main]
}

# API Gateway HTTP API
resource "aws_apigatewayv2_api" "main" {
  name          = "${local.name_prefix}-api-gateway"
  protocol_type = "HTTP"
  tags          = local.common_tags

  cors_configuration {
    allow_credentials = false
    allow_headers     = ["*"]
    allow_methods     = ["GET", "POST", "OPTIONS"]
    allow_origins     = ["*"]
    max_age           = 300
  }
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true
  tags        = local.common_tags

  default_route_settings {
    throttling_burst_limit = var.api_throttle_burst_limit
    throttling_rate_limit  = var.api_throttle_rate_limit
  }
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.api.invoke_arn
}

# API Gateway Routes
resource "aws_apigatewayv2_route" "get_root" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "post_chat" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "POST /chat"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_route" "get_health" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "GET /health"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}

# CloudFront distribution
resource "aws_cloudfront_distribution" "main" {
  aliases = local.aliases
  
  viewer_certificate {
    acm_certificate_arn            = var.use_custom_domain ? aws_acm_certificate.site[0].arn : null
    cloudfront_default_certificate = var.use_custom_domain ? false : true
    ssl_support_method             = var.use_custom_domain ? "sni-only" : null
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  origin {
    domain_name = aws_s3_bucket_website_configuration.frontend.website_endpoint
    origin_id   = "S3-${aws_s3_bucket.frontend.id}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  tags                = local.common_tags

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.frontend.id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }
}

# Optional: Custom domain configuration (only created when use_custom_domain = true)
data "aws_route53_zone" "root" {
  count        = var.use_custom_domain ? 1 : 0
  name         = var.root_domain
  private_zone = false
}

resource "aws_acm_certificate" "site" {
  count                     = var.use_custom_domain ? 1 : 0
  provider                  = aws.us_east_1
  domain_name               = var.root_domain
  subject_alternative_names = ["www.${var.root_domain}"]
  validation_method         = "DNS"
  lifecycle { create_before_destroy = true }
  tags = local.common_tags
}

resource "aws_route53_record" "site_validation" {
  for_each = var.use_custom_domain ? {
    for dvo in aws_acm_certificate.site[0].domain_validation_options :
    dvo.domain_name => dvo
  } : {}

  zone_id = data.aws_route53_zone.root[0].zone_id
  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  ttl     = 300
  records = [each.value.resource_record_value]
}

resource "aws_acm_certificate_validation" "site" {
  count           = var.use_custom_domain ? 1 : 0
  provider        = aws.us_east_1
  certificate_arn = aws_acm_certificate.site[0].arn
  validation_record_fqdns = [
    for r in aws_route53_record.site_validation : r.fqdn
  ]
}

resource "aws_route53_record" "alias_root" {
  count   = var.use_custom_domain ? 1 : 0
  zone_id = data.aws_route53_zone.root[0].zone_id
  name    = var.root_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "alias_root_ipv6" {
  count   = var.use_custom_domain ? 1 : 0
  zone_id = data.aws_route53_zone.root[0].zone_id
  name    = var.root_domain
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "alias_www" {
  count   = var.use_custom_domain ? 1 : 0
  zone_id = data.aws_route53_zone.root[0].zone_id
  name    = "www.${var.root_domain}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "alias_www_ipv6" {
  count   = var.use_custom_domain ? 1 : 0
  zone_id = data.aws_route53_zone.root[0].zone_id
  name    = "www.${var.root_domain}"
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}
```

### Step 5: Define Outputs

Create `terraform/outputs.tf`:

```hcl
output "api_gateway_url" {
  description = "URL of the API Gateway"
  value       = aws_apigatewayv2_api.main.api_endpoint
}

output "cloudfront_url" {
  description = "URL of the CloudFront distribution"
  value       = "https://${aws_cloudfront_distribution.main.domain_name}"
}

output "s3_frontend_bucket" {
  description = "Name of the S3 bucket for frontend"
  value       = aws_s3_bucket.frontend.id
}

output "s3_memory_bucket" {
  description = "Name of the S3 bucket for memory storage"
  value       = aws_s3_bucket.memory.id
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.api.function_name
}

output "custom_domain_url" {
  description = "Root URL of the production site"
  value       = var.use_custom_domain ? "https://${var.root_domain}" : ""
}
```

### Step 6: Create Default Variable Values

Create `terraform/terraform.tfvars`:

```hcl
project_name             = "twin"
environment              = "dev"
bedrock_model_id         = "amazon.nova-micro-v1:0"
lambda_timeout           = 60
api_throttle_burst_limit = 10
api_throttle_rate_limit  = 5
use_custom_domain        = false
root_domain              = ""
```

### Step 7: Update Frontend to Use Environment Variables

Before we create our deployment scripts, we need to update the frontend to use environment variables for the API URL instead of hardcoding it.

Update `frontend/components/twin.tsx` - find the fetch call (around line 43) and replace:

```typescript
// Find this line:
const response = await fetch('http://localhost:8000/chat', {

// Replace with:
const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000'}/chat`, {
```

This change allows the frontend to:
- Use `http://localhost:8000` during local development
- Use the production API URL (set via environment variable) when deployed

**Note**: Next.js requires environment variables accessible in the browser to be prefixed with `NEXT_PUBLIC_`.

## Part 4: Create Deployment Scripts

### Step 1: Create Scripts Directory

In Cursor's file explorer (the left sidebar):

1. Right-click in the File Explorer in the blank space under the files
2. Select **New Folder**
3. Name it `scripts`

### Step 2: Create Shell Script for Mac/Linux

**Important**: All students (including Windows users) need to create this file, as it will be used by GitHub Actions on Day 5.

Create `scripts/deploy.sh`:

```bash
#!/bin/bash
set -e

ENVIRONMENT=${1:-dev}          # dev | test | prod
PROJECT_NAME=${2:-twin}

echo "🚀 Deploying ${PROJECT_NAME} to ${ENVIRONMENT}..."

# 1. Build Lambda package
cd "$(dirname "$0")/.."        # project root
echo "📦 Building Lambda package..."
(cd backend && uv run deploy.py)

# 2. Terraform workspace & apply
cd terraform
terraform init -input=false

if ! terraform workspace list | grep -q "$ENVIRONMENT"; then
  terraform workspace new "$ENVIRONMENT"
else
  terraform workspace select "$ENVIRONMENT"
fi

# Use prod.tfvars for production environment
if [ "$ENVIRONMENT" = "prod" ]; then
  TF_APPLY_CMD=(terraform apply -var-file=prod.tfvars -var="project_name=$PROJECT_NAME" -var="environment=$ENVIRONMENT" -auto-approve)
else
  TF_APPLY_CMD=(terraform apply -var="project_name=$PROJECT_NAME" -var="environment=$ENVIRONMENT" -auto-approve)
fi

echo "🎯 Applying Terraform..."
"${TF_APPLY_CMD[@]}"

API_URL=$(terraform output -raw api_gateway_url)
FRONTEND_BUCKET=$(terraform output -raw s3_frontend_bucket)
CUSTOM_URL=$(terraform output -raw custom_domain_url 2>/dev/null || true)

# 3. Build + deploy frontend
cd ../frontend

# Create production environment file with API URL
echo "📝 Setting API URL for production..."
echo "NEXT_PUBLIC_API_URL=$API_URL" > .env.production

npm install
npm run build
aws s3 sync ./out "s3://$FRONTEND_BUCKET/" --delete
cd ..

# 4. Final messages
echo -e "\n✅ Deployment complete!"
echo "🌐 CloudFront URL : $(terraform -chdir=terraform output -raw cloudfront_url)"
if [ -n "$CUSTOM_URL" ]; then
  echo "🔗 Custom domain  : $CUSTOM_URL"
fi
echo "📡 API Gateway    : $API_URL"
```

**For Mac/Linux users only** - make it executable:
```bash
chmod +x scripts/deploy.sh
```

**Windows users**: You don't need to run the chmod command, just create the file.

### Step 3: Create PowerShell Script for Windows

**Mac/Linux users**: You can skip this step - it's only needed for Windows users.

Create `scripts/deploy.ps1`:

```powershell
param(
    [string]$Environment = "dev",   # dev | test | prod
    [string]$ProjectName = "twin"
)
$ErrorActionPreference = "Stop"

Write-Host "Deploying $ProjectName to $Environment ..." -ForegroundColor Green

# 1. Build Lambda package
Set-Location (Split-Path $PSScriptRoot -Parent)   # project root
Write-Host "Building Lambda package..." -ForegroundColor Yellow
Set-Location backend
uv run deploy.py
Set-Location ..

# 2. Terraform workspace & apply
Set-Location terraform
terraform init -input=false

if (-not (terraform workspace list | Select-String $Environment)) {
    terraform workspace new $Environment
} else {
    terraform workspace select $Environment
}

if ($Environment -eq "prod") {
    terraform apply -var-file="prod.tfvars" -var="project_name=$ProjectName" -var="environment=$Environment" -auto-approve
} else {
    terraform apply -var="project_name=$ProjectName" -var="environment=$Environment" -auto-approve
}

$ApiUrl        = terraform output -raw api_gateway_url
$FrontendBucket = terraform output -raw s3_frontend_bucket
try { $CustomUrl = terraform output -raw custom_domain_url } catch { $CustomUrl = "" }

# 3. Build + deploy frontend
Set-Location ..\frontend

# Create production environment file with API URL
Write-Host "Setting API URL for production..." -ForegroundColor Yellow
"NEXT_PUBLIC_API_URL=$ApiUrl" | Out-File .env.production -Encoding utf8

npm install
npm run build
aws s3 sync .\out "s3://$FrontendBucket/" --delete
Set-Location ..

# 4. Final summary
$CfUrl = terraform -chdir=terraform output -raw cloudfront_url
Write-Host "Deployment complete!" -ForegroundColor Green
Write-Host "CloudFront URL : $CfUrl" -ForegroundColor Cyan
if ($CustomUrl) {
    Write-Host "Custom domain  : $CustomUrl" -ForegroundColor Cyan
}
Write-Host "API Gateway    : $ApiUrl" -ForegroundColor Cyan

```

## Part 5: Deploy Development Environment

### Step 1: Initialize Terraform

```bash
cd terraform
terraform init
```

You should see:
```
Initializing the backend...
Initializing provider plugins...
- Installing hashicorp/aws v6.x.x...
Terraform has been successfully initialized!
```

### Step 2: Deploy Using the Script

**Mac/Linux from the project root:**
```bash
./scripts/deploy.sh dev
```

**Windows (PowerShell) from the project root:**
```powershell
.\scripts\deploy.ps1 -Environment dev
```

The script will:
1. Build the Lambda package
2. Create a `dev` workspace in Terraform
3. Deploy all infrastructure
4. Build and deploy the frontend
5. Display the URLs

### Step 3: Test Your Development Environment

1. Visit the CloudFront URL shown in the output
2. Test the chat functionality
3. Verify everything works as before

✅ **Checkpoint**: Your dev environment is now deployed via Terraform!

## Part 6: Deploy Test Environment

Now let's deploy a completely separate test environment:

### Step 1: Deploy Test Environment

**Mac/Linux:**
```bash
./scripts/deploy.sh test
```

**Windows (PowerShell):**
```powershell
.\scripts\deploy.ps1 -Environment test
```

### Step 2: Verify Separate Resources

Check the AWS Console - you'll see separate resources for test:
- `twin-test-api` Lambda function
- `twin-test-memory` S3 bucket
- `twin-test-frontend` S3 bucket
- `twin-test-api-gateway` API Gateway
- Separate CloudFront distribution

### Step 3: Test Both Environments

1. Open dev CloudFront URL in one browser tab
2. Open test CloudFront URL in another tab
3. Have different conversations - they're completely isolated!

## Part 7: Destroying Infrastructure

When you're done with an environment, you need to properly clean it up. Since S3 buckets must be empty before deletion, we'll create scripts to handle this automatically.

### Step 1: Create Destroy Script for Mac/Linux

Create `scripts/destroy.sh`:

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

# Get AWS Account ID for bucket names
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Get bucket names with account ID
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

Make it executable:
```bash
chmod +x scripts/destroy.sh
```

### Step 2: Create Destroy Script for Windows

Create `scripts/destroy.ps1`:

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

# Get AWS Account ID for bucket names
$awsAccountId = aws sts get-caller-identity --query Account --output text

# Define bucket names with account ID
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
    terraform destroy -var-file="prod.tfvars" -var="project_name=$ProjectName" -var="environment=$Environment" -auto-approve
} else {
    terraform destroy -var="project_name=$ProjectName" -var="environment=$Environment" -auto-approve
}

Write-Host "Infrastructure for $Environment has been destroyed!" -ForegroundColor Green
Write-Host ""
Write-Host "  To remove the workspace completely, run:" -ForegroundColor Cyan
Write-Host "   terraform workspace select default" -ForegroundColor White
Write-Host "   terraform workspace delete $Environment" -ForegroundColor White
```

### Step 3: Using the Destroy Scripts

To destroy a specific environment:

**Mac/Linux:**
```bash
# Destroy dev environment
./scripts/destroy.sh dev

# Destroy test environment
./scripts/destroy.sh test

# Destroy prod environment
./scripts/destroy.sh prod
```

**Windows (PowerShell):**
```powershell
# Destroy dev environment
.\scripts\destroy.ps1 -Environment dev

# Destroy test environment
.\scripts\destroy.ps1 -Environment test

# Destroy prod environment
.\scripts\destroy.ps1 -Environment prod
```

### What Gets Destroyed

The destroy scripts will:
1. Empty S3 buckets (frontend and memory)
2. Delete all AWS resources created by Terraform:
   - Lambda functions
   - API Gateway
   - S3 buckets
   - CloudFront distributions
   - IAM roles and policies
   - Route 53 records (if custom domain)
   - ACM certificates (if custom domain)

### Important Notes

- **CloudFront**: Distributions can take 5-15 minutes to fully delete
- **Workspaces**: The scripts destroy resources but keep the workspace. To fully remove a workspace:
  ```bash
  terraform workspace select default
  terraform workspace delete dev  # or test, prod
  ```
- **Cost Savings**: Always destroy unused environments to avoid charges


## Part 8: OPTIONAL - Add a Custom Domain

If you want a professional domain for your production twin, follow these steps.

### Step 1: Register a Domain (if needed)

**Important**: Domain registration requires billing permissions, so you'll need to sign in as the **root user** for this step.

**Option A: Register through AWS Route 53**
1. Sign out of your IAM user account
2. Sign in to AWS Console as the **root user**
3. Go to Route 53 in AWS Console
4. Click **Registered domains** → **Register domain**
5. Search for your desired domain
6. Add to cart and complete purchase (typically $12-40/year depending on domain)
7. Wait for registration (5-30 minutes)
8. Once registered, sign back in as your IAM user (`aiengineer`) to continue

**Option B: Use existing domain**
- If you already own a domain elsewhere:
  - Transfer DNS to Route 53, or
  - Create a hosted zone and update nameservers at your registrar

### Step 2: Create Hosted Zone (if not auto-created)

If Route 53 didn't auto-create a hosted zone:
1. Go to Route 53 → **Hosted zones**
2. Click **Create hosted zone**
3. Enter your domain name
4. Type: Public hosted zone
5. Click **Create**

### Step 3: Create Production Configuration

Create `terraform/prod.tfvars`:

```hcl
project_name             = "twin"
environment              = "prod"
bedrock_model_id         = "amazon.nova-lite-v1:0"  # Use better model for production
lambda_timeout           = 60
api_throttle_burst_limit = 20
api_throttle_rate_limit  = 10
use_custom_domain        = true
root_domain              = "yourdomain.com"  # Replace with your actual domain
```

### Step 4: Deploy Production with Domain

**Mac/Linux:**
```bash
./scripts/deploy.sh prod
```

**Windows (PowerShell):**
```powershell
.\scripts\deploy.ps1 -Environment prod
```

The deployment will:
1. Create SSL certificate in ACM
2. Validate domain ownership via DNS
3. Configure CloudFront with your domain
4. Set up Route 53 records

**Note**: Certificate validation can take 5-30 minutes. The script will wait.

### Step 5: Test Your Custom Domain

Once deployed:
1. Visit `https://yourdomain.com`
2. Visit `https://www.yourdomain.com`
3. Both should show your Digital Twin!

## Understanding Terraform Workspaces

### How Workspaces Isolate Environments

Each workspace maintains its own state file:
```
terraform.tfstate.d/
├── dev/
│   └── terraform.tfstate
├── test/
│   └── terraform.tfstate
└── prod/
    └── terraform.tfstate
```

### Managing Workspaces

**List workspaces:**
```bash
terraform workspace list
```

**Switch workspace:**
```bash
terraform workspace select dev
```

**Show current workspace:**
```bash
terraform workspace show
```

### Resource Naming

Resources are named with environment prefix:
- Dev: `twin-dev-api`, `twin-dev-memory`
- Test: `twin-test-api`, `twin-test-memory`
- Prod: `twin-prod-api`, `twin-prod-memory`

## Cost Optimization

### Environment-Specific Settings

Our configuration uses different settings per environment:

**Development:**
- Nova Micro model (cheapest)
- Lower API throttling
- No custom domain

**Test:**
- Nova Micro model
- Standard throttling
- No custom domain

**Production:**
- Nova Lite model (better quality)
- Higher throttling limits
- Custom domain with SSL

### Cost-Saving Tips

1. **Destroy unused environments** - Don't leave test running
2. **Use appropriate models** - Nova Micro for dev/test
3. **Set API throttling** - Prevent runaway costs
4. **Monitor with tags** - All resources tagged with environment

## Troubleshooting

### Terraform State Issues

If Terraform gets confused about resources:

```bash
# Refresh state from AWS
terraform refresh

# If resource exists in AWS but not state
terraform import aws_lambda_function.api twin-dev-api
```

### Deployment Script Failures

**"Lambda package not found"**
- Ensure Docker is running
- Run `cd backend && uv run deploy.py` manually

**"S3 bucket already exists"**
- Bucket names must be globally unique
- Change project_name in terraform.tfvars

**"Certificate validation timeout"**
- Check Route 53 has the validation records
- Wait longer (can take up to 30 minutes)

### Frontend Not Updating

After deployment, CloudFront may cache old content:

```bash
# Get distribution ID
aws cloudfront list-distributions --query "DistributionList.Items[?Comment=='twin-dev'].Id" --output text

# Create invalidation
aws cloudfront create-invalidation --distribution-id YOUR_ID --paths "/*"
```

## Best Practices

### 1. Version Control

Always commit your Terraform files:
```bash
git add terraform/*.tf terraform/*.tfvars
git commit -m "Add Terraform infrastructure"
```

Never commit:
- `terraform.tfstate` files
- `.terraform/` directory
- AWS credentials

### 2. Plan Before Apply

Review changes before applying:
```bash
terraform plan
```

### 3. Use Variables

Don't hardcode values - use variables:
```hcl
# Good
bucket = "${local.name_prefix}-memory"

# Bad
bucket = "twin-dev-memory"
```

### 4. Tag Everything

Our configuration tags all resources:
```hcl
tags = {
  Project     = var.project_name
  Environment = var.environment
  ManagedBy   = "terraform"
}
```

## What You've Accomplished Today!

- ✅ Learned Infrastructure as Code with Terraform
- ✅ Automated entire AWS deployment
- ✅ Created multiple isolated environments
- ✅ Implemented one-command deployment
- ✅ Set up professional deployment scripts
- ✅ Optional: Configured custom domain with SSL

## Architecture Summary

Your Terraform manages:

```
Terraform Configuration
    ├── S3 Buckets (Frontend + Memory)
    ├── Lambda Function with IAM Role
    ├── API Gateway with Routes
    ├── CloudFront Distribution
    └── Optional: Route 53 + ACM Certificate

Managed via Workspaces:
    ├── dev/   (Development environment)
    ├── test/  (Testing environment)
    └── prod/  (Production with custom domain)
```

## Next Steps

Tomorrow (Day 5), we'll add CI/CD with GitHub Actions:
- Automated testing on pull requests
- Deployment pipelines for each environment
- Infrastructure change reviews
- Automated rollbacks
- Complete infrastructure teardown

Your Digital Twin now has professional Infrastructure as Code that any team can deploy and manage!

## Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)

Congratulations on automating your infrastructure deployment! 🚀