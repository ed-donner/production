# Fix GitHub Actions OIDC access to AWS

Use this guide when a GitHub Actions deployment fails with:

```text
Could not assume role with OIDC:
Not authorized to perform sts:AssumeRoleWithWebIdentity
```

Older IAM trust policies identify a repository by name:

```text
repo:<GITHUB_OWNER>/<REPOSITORY_NAME>:*
```

The updated subject includes the numeric owner ID, repository ID, and GitHub environment:

```text
repo:<GITHUB_OWNER>@<OWNER_ID>/<REPOSITORY_NAME>@<REPOSITORY_ID>:environment:<ENVIRONMENT>
```

Replace every placeholder locally. Do not add real account or repository details to this guide.

## Get the GitHub IDs

### Private repositories

Use the GitHub CLI. It handles authentication without requiring you to manage a token manually.

If needed, install `gh` and sign in:

```bash
gh auth login
```

Then run:

```bash
gh api repos/<GITHUB_OWNER>/<REPOSITORY_NAME> \
  --jq '{github_owner_id: .owner.id, github_repository_id: .id}'
```

The signed-in account must have access to the repository.

### Public repositories

You can open this URL in a browser:

```text
https://api.github.com/repos/<GITHUB_OWNER>/<REPOSITORY_NAME>
```

In the JSON response:

- The top-level `id` is `<REPOSITORY_ID>`.
- The `id` inside the `owner` object is `<OWNER_ID>`.

You can also use PowerShell:

```powershell
$repository = Invoke-RestMethod "https://api.github.com/repos/<GITHUB_OWNER>/<REPOSITORY_NAME>"

[PSCustomObject]@{
  github_owner_id      = $repository.owner.id
  github_repository_id = $repository.id
}
```

Or use `curl`:

```bash
curl -s "https://api.github.com/repos/<GITHUB_OWNER>/<REPOSITORY_NAME>"
```

In the response, use the top-level `id` as `<REPOSITORY_ID>` and `owner.id` as `<OWNER_ID>`.

These three unauthenticated methods return `404 Not Found` for a private repository. Use the GitHub CLI instead.

## Update `github-oidc.tf`

Make two changes in `terraform/github-oidc.tf`.

### 1. Replace the repository variable

Find:

```hcl
variable "github_repository" {
  description = "GitHub repository in format 'owner/repo'"
  type        = string
}
```

Replace it with:

```hcl
variable "github_repository" {
  description = "GitHub repository in format 'owner/repo'"
  type        = string

  validation {
    condition     = can(regex("^[^/]+/[^/]+$", var.github_repository))
    error_message = "GitHub repository must use the format 'owner/repo'."
  }
}

variable "github_owner_id" {
  description = "Immutable numeric GitHub owner ID"
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.github_owner_id))
    error_message = "GitHub owner ID must contain only digits."
  }
}

variable "github_repository_id" {
  description = "Immutable numeric GitHub repository ID"
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.github_repository_id))
    error_message = "GitHub repository ID must contain only digits."
  }
}

variable "github_environments" {
  description = "GitHub environments allowed to assume the deployment role"
  type        = set(string)
  default     = ["dev", "test", "prod"]

  validation {
    condition     = length(var.github_environments) > 0 && length(setsubtract(var.github_environments, ["dev", "test", "prod"])) == 0
    error_message = "GitHub environments must be one or more of: dev, test, prod."
  }
}

locals {
  github_repository_parts = split("/", var.github_repository)
  github_oidc_repository  = "${local.github_repository_parts[0]}@${var.github_owner_id}/${local.github_repository_parts[1]}@${var.github_repository_id}"
}
```

Change `dev`, `test`, and `prod` if the workflows use different environment names. The spelling and capitalization must match the workflow.

### 2. Replace the old subject

Find this block inside `aws_iam_role.github_actions`:

```hcl
StringLike = {
  "token.actions.githubusercontent.com:sub" = "repo:${var.github_repository}:*"
}
```

Replace it with:

```hcl
StringLike = {
  "token.actions.githubusercontent.com:sub" = [
    for environment in var.github_environments :
    "repo:${local.github_oidc_repository}:environment:${environment}"
  ]
}
```

Do not change the audience condition:

```hcl
StringEquals = {
  "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
}
```

## Apply the change

Run these commands from the `terraform` directory:

```bash
terraform fmt github-oidc.tf
terraform validate
```

Then update the role:

```bash
terraform apply \
  -target=aws_iam_role.github_actions \
  -var="github_repository=<GITHUB_OWNER>/<REPOSITORY_NAME>" \
  -var="github_owner_id=<OWNER_ID>" \
  -var="github_repository_id=<REPOSITORY_ID>"
```

The plan should show an in-place update to `assume_role_policy`. Stop if Terraform plans to destroy or recreate the role.

The attached IAM policies do not need to be targeted. They control what the role can do after authentication. The trust policy controls who can assume it.

## Check the workflow

The workflow needs permission to request an OIDC token:

```yaml
permissions:
  id-token: write
  contents: read
```

The job also needs an environment that matches the trust policy:

```yaml
jobs:
  deploy:
    environment: dev
```

The AWS credentials step must use the role that was updated:

```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
    aws-region: ${{ secrets.DEFAULT_AWS_REGION }}
```

Do not print `AWS_ROLE_ARN` or other secret values in workflow logs.

## If it still fails

Check the owner ID, repository ID, environment name, audience, role ARN, and AWS account. One incorrect value is enough for AWS to reject the token.

If Terraform reports `Backend initialization required`, initialize the existing backend with the project's normal backend settings. A workspace does not replace `terraform init`. Do not migrate or reconfigure state unless you know where the IAM role is tracked.

If `github-oidc.tf` is part of the normal deployment configuration, the pipeline must receive the three GitHub variables. Otherwise, OIDC authentication may succeed and the later Terraform step will stop because required variables are missing.

## Complete `github-oidc.tf` example

Copy the template below if the smaller edits are difficult to apply. Replace `<IAM_ROLE_NAME>` with the existing IAM role name so Terraform updates that role instead of creating another one.

```hcl
# This creates an IAM role that GitHub Actions can assume.
# Keep this file if the role remains managed by this Terraform state.

variable "github_repository" {
  description = "GitHub repository in format 'owner/repo'"
  type        = string

  validation {
    condition     = can(regex("^[^/]+/[^/]+$", var.github_repository))
    error_message = "GitHub repository must use the format 'owner/repo'."
  }
}

variable "github_owner_id" {
  description = "Immutable numeric GitHub owner ID"
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.github_owner_id))
    error_message = "GitHub owner ID must contain only digits."
  }
}

variable "github_repository_id" {
  description = "Immutable numeric GitHub repository ID"
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.github_repository_id))
    error_message = "GitHub repository ID must contain only digits."
  }
}

variable "github_environments" {
  description = "GitHub environments allowed to assume the deployment role"
  type        = set(string)
  default     = ["dev", "test", "prod"]

  validation {
    condition     = length(var.github_environments) > 0 && length(setsubtract(var.github_environments, ["dev", "test", "prod"])) == 0
    error_message = "GitHub environments must be one or more of: dev, test, prod."
  }
}

locals {
  github_repository_parts = split("/", var.github_repository)
  github_oidc_repository  = "${local.github_repository_parts[0]}@${var.github_owner_id}/${local.github_repository_parts[1]}@${var.github_repository_id}"
}

# aws_caller_identity.current is already defined in main.tf.

# GitHub OIDC provider
# If this already exists in the AWS account, import it into the current state:
# terraform import aws_iam_openid_connect_provider.github arn:aws:iam::<AWS_ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "1b511abead59c6ce207077c0bf0e0043b1382612"
  ]
}

# IAM role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  name = "<IAM_ROLE_NAME>"

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
            "token.actions.githubusercontent.com:sub" = [
              for environment in var.github_environments :
              "repo:${local.github_oidc_repository}:environment:${environment}"
            ]
          }
        }
      }
    ]
  })

  tags = {
    Name       = "GitHub Actions Deploy Role"
    Repository = var.github_repository
    ManagedBy  = "terraform"
  }
}

# Attached policies
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

resource "aws_iam_role_policy_attachment" "github_dynamodb" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
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

# Additional permissions
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
