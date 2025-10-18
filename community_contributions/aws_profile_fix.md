# Fix AWS Profile Support in Deployment Script

## Issue Description
**Problem**: The deployment script fails silently when AWS credentials are configured under a named profile (e.g., "ai", "dev", "prod"), causing frontend files to not be uploaded to S3.

**Symptoms**:
- CloudFront URL returns 404 Not Found errors
- S3 bucket is empty after deployment
- Error message: `Code: NoSuchKey, Message: The specified key does not exist. Key: index.html`
- Deployment script completes without errors but frontend files are missing

**Root Cause**: The `aws s3 sync` command in the deployment script doesn't specify which AWS profile to use, so it fails when the default profile is not configured, even if credentials exist under a named profile.

## Fix Description
**Solution**: Updated the deployment script to explicitly use the "default" AWS profile for S3 operations and added comprehensive troubleshooting documentation.

- This enables developers who have multiple AWS profiles to define the credentials and config to be used while learning.
- The default profile when running the `aws condigure` is `default`. Change this to the right profile being used.

**Code Change**:
```bash
# Before
aws s3 sync ./out "s3://$FRONTEND_BUCKET/" --delete

# After  
aws s3 sync ./out "s3://$FRONTEND_BUCKET/" --delete --profile default
```

### File to be Changed
**`scripts/deploy.sh`** (Line 48)
   - Added `--profile default` flag to `aws s3 sync` command
   - Ensures consistent AWS profile usage for S3 operations