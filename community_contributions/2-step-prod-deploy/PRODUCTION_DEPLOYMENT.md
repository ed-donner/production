# Deploying to Production with GitHub Actions

This guide walks you through deploying your Digital Twin to production using GitHub Actions with custom domain setup.

## Prerequisites

- GitHub repository with code pushed
- AWS account configured with GitHub OIDC authentication
- GitHub secrets configured (AWS_ROLE_ARN, DEFAULT_AWS_REGION, AWS_ACCOUNT_ID)
- Domain registered (via Route 53 or external registrar)

## Deployment Process Overview

Production deployment with a custom domain requires a **two-phase process** due to DNS validation:

1. **Phase 1**: Initial deployment creates Route53 hosted zone and ACM certificate
2. **Nameserver Configuration**: Update your domain registrar with Route53 nameservers
3. **Phase 2**: Re-run deployment after DNS propagation to complete the setup

## Step 1: Initial Production Deployment

### 1.1 Trigger the Deployment Workflow

1. Go to your GitHub repository
2. Click the **Actions** tab
3. Select **Deploy Digital Twin** from the left sidebar
4. Click **Run workflow** (button on the right)
5. Configure the workflow:
   - **Branch**: `main`
   - **Environment**: `prod`
6. Click **Run workflow** to start

### 1.2 Monitor the Deployment

The workflow will execute these steps:

1. **Checkout code** - Downloads your repository
2. **Configure AWS credentials** - Uses OIDC to authenticate with AWS
3. **Set up Python** - Installs Python 3.12
4. **Install uv** - Package manager for Python
5. **Setup Terraform** - Installs Terraform
6. **Setup Node.js** - For frontend build
7. **Setup Terraform Backend** - Creates/verifies S3 bucket and DynamoDB table for state
8. **Build Lambda Package** - Packages backend code
9. **Check DNS and Certificate Setup (Prod Only)** - This is the critical step

### 1.3 Expected Behavior: Deployment Pauses

The workflow will **intentionally fail** on the first run with a message like:

```
⚠️  DEPLOYMENT PAUSED - ACTION REQUIRED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📝 Step 1: Update nameservers at your domain registrar

   Use these nameservers:
   → ns-1234.awsdns-12.org
   → ns-5678.awsdns-56.co.uk
   → ns-9012.awsdns-90.com
   → ns-3456.awsdns-34.net

📝 Step 2: Wait 5-30 minutes for DNS propagation

   Verify with: dig NS yourdomain.com +short

📝 Step 3: Wait for ACM certificate validation (happens automatically)

   Check status with:
   aws acm list-certificates --region us-east-1 \
     --query "CertificateSummaryList[?DomainName=='yourdomain.com'].Status"

📝 Step 4: Re-run this workflow once certificate shows 'ISSUED'

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**This is expected!** Copy the nameserver values for the next step.

## Step 2: Update Domain Nameservers

### 2.1 Locate the Nameservers

From the failed workflow run:
1. Click on the failed workflow run
2. Expand the **Check DNS and Certificate Setup (Prod Only)** step
3. Scroll down to find the nameserver list

### 2.2 Update Your Domain Registrar

The process varies by registrar, but generally:

**For Namecheap:**
1. Log in to Namecheap
2. Go to **Domain List** → Select your domain
3. Find **Nameservers** section
4. Select **Custom DNS**
5. Enter the 4 nameservers from AWS Route53
6. Click **Save**

**For GoDaddy:**
1. Log in to GoDaddy
2. Go to **My Products** → **Domains**
3. Click on your domain → **Manage DNS**
4. Scroll to **Nameservers** → Click **Change**
5. Select **Custom** nameservers
6. Enter the 4 nameservers
7. Click **Save**

**For AWS Route 53 (if registered through AWS):**
- Nameservers are automatically configured - skip this step!

### 2.3 Verify DNS Propagation

Wait 5-30 minutes (sometimes up to 48 hours, but usually quick), then verify:

```bash
# Check if nameservers have propagated
dig NS yourdomain.com +short

# Should return the Route53 nameservers
```

Alternative online tools:
- https://www.whatsmydns.net/ (check NS records globally)
- https://dnschecker.org/

## Step 3: Wait for Certificate Validation

Once DNS has propagated, AWS Certificate Manager will automatically validate your domain ownership via DNS. This typically takes 5-30 minutes.

### 3.1 Check Certificate Status (Optional)

You can monitor certificate validation status:

```bash
# List certificates and their status
aws acm list-certificates --region us-east-1 \
  --query "CertificateSummaryList[?DomainName=='yourdomain.com'].[DomainName,Status]" \
  --output table
```

Wait until the status shows **ISSUED**.

## Step 4: Re-run the Deployment

Once the certificate is issued:

### 4.1 Trigger Second Deployment

1. Go back to your GitHub repository
2. Click **Actions** tab
3. Select **Deploy Digital Twin**
4. Click **Run workflow**
5. Configure:
   - **Branch**: `main`
   - **Environment**: `prod`
6. Click **Run workflow**

### 4.2 Monitor Completion

This time, the workflow will:
1. Detect that Route53 zone exists ✅
2. Detect that certificate is validated ✅
3. Proceed with full deployment:
   - Run deployment script
   - Build Lambda package
   - Deploy infrastructure with Terraform
   - Build and deploy frontend
   - Invalidate CloudFront cache

### 4.3 Verify Success

Once the workflow completes successfully:

1. Expand the **Deployment Summary** step
2. You'll see:
   ```
   ✅ Deployment Complete!
   🌐 CloudFront URL: https://d123456789.cloudfront.net
   📡 API Gateway: https://abc123.execute-api.us-east-1.amazonaws.com
   🪣 Frontend Bucket: twin-prod-frontend-123456789012
   ```

3. Visit your custom domain:
   - `https://yourdomain.com`
   - `https://www.yourdomain.com`

Both should work and show your Digital Twin!

## Key Differences from Day 4 Deployment

### Deploy Workflow Differences

The GitHub Actions `deploy.yml` includes additional production-specific steps not in the Day 5 tutorial:

#### Additional Step: Setup Terraform Backend

```yaml
- name: Setup Terraform Backend
  run: |
    # Creates S3 bucket and DynamoDB table if they don't exist
    # This ensures remote state storage is available
```

This step is **automated** in the GitHub Actions workflow but was **manual** in Day 4's local setup.

#### Additional Step: Check DNS and Certificate Setup

```yaml
- name: Check DNS and Certificate Setup (Prod Only)
  if: github.event.inputs.environment == 'prod'
  run: |
    # Checks for Route53 hosted zone
    # Creates zone and certificate on first run
    # Validates certificate status on subsequent runs
    # Pauses deployment if certificate not validated
```

This step is **unique to GitHub Actions** and handles the two-phase deployment automatically.

### Destroy Workflow Differences

The workflows in your repository match the Day 5 tutorial exactly - no differences.

### Script Differences: The `-reconfigure` Flag

#### In `scripts/deploy.sh` (line 18):

**Your current version (Day 5):**
```bash
terraform init -input=false -reconfigure \
  -backend-config="bucket=twin-terraform-state-${AWS_ACCOUNT_ID}" \
  -backend-config="key=${ENVIRONMENT}/terraform.tfstate" \
  -backend-config="region=${AWS_REGION}" \
  -backend-config="dynamodb_table=twin-terraform-locks" \
  -backend-config="encrypt=true"
```

**Day 4 version (without -reconfigure):**
```bash
terraform init -input=false
```

#### In `scripts/destroy.sh` (line 27):

**Your current version (Day 5):**
```bash
terraform init -input=false -reconfigure \
  -backend-config="bucket=twin-terraform-state-${AWS_ACCOUNT_ID}" \
  -backend-config="key=${ENVIRONMENT}/terraform.tfstate" \
  -backend-config="region=${AWS_REGION}" \
  -backend-config="dynamodb_table=twin-terraform-locks" \
  -backend-config="encrypt=true"
```

**Day 4 version:**
```bash
# No backend configuration - used local state only
```

#### Why `-reconfigure`?

The `-reconfigure` flag tells Terraform to:
- Reconfigure the backend even if already initialized
- Useful in CI/CD where the `.terraform/` directory may not exist
- Prevents interactive prompts about backend changes
- Safe to use multiple times without issues

**Day 4**: Local state files (no remote backend)
**Day 5**: S3 backend with `-reconfigure` for reliable CI/CD

## Troubleshooting

### Deployment Fails: "Could not assume role"

**Problem**: GitHub Actions can't authenticate with AWS.

**Solution**:
1. Verify `AWS_ROLE_ARN` secret is correct
2. Check that GitHub repository name matches OIDC trust policy
3. Ensure role exists: `github-actions-twin-deploy`

### Deployment Fails: "Certificate validation timeout"

**Problem**: ACM certificate hasn't been validated.

**Solution**:
1. Verify nameservers are updated at registrar
2. Wait longer (DNS propagation can take up to 48 hours)
3. Check DNS propagation: `dig NS yourdomain.com +short`
4. Verify validation records exist in Route53

### Deployment Fails: "Hosted zone not found"

**Problem**: Route53 hosted zone wasn't created.

**Solution**:
1. This means the first deployment didn't reach the DNS creation step
2. Check workflow logs for errors before the DNS step
3. Verify AWS credentials have Route53 permissions

### Frontend Not Updating

**Problem**: CloudFront serving cached content.

**Solution**: The workflow includes automatic cache invalidation, but you can manually trigger:
```bash
# Get distribution ID
DIST_ID=$(aws cloudfront list-distributions \
  --query "DistributionList.Items[?Comment=='twin-prod'].Id" \
  --output text)

# Invalidate cache
aws cloudfront create-invalidation \
  --distribution-id $DIST_ID \
  --paths "/*"
```

## Summary

**Production deployment requires two runs:**

1. **First run**: Creates DNS infrastructure → **Expected to fail** → Copy nameservers
2. **Update nameservers** at domain registrar → Wait for DNS propagation
3. **Second run**: Completes deployment → Success!

**Key files modified for CI/CD:**
- `.github/workflows/deploy.yml` - Added backend setup and DNS validation steps
- `.github/workflows/destroy.yml` - Matches Day 5 exactly
- `scripts/deploy.sh` - Added `-reconfigure` and backend config
- `scripts/destroy.sh` - Added `-reconfigure` and backend config

The `-reconfigure` flag ensures reliable Terraform initialization in CI/CD environments where the state might change between runs.
