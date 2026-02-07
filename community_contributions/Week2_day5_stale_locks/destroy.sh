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
  -backend-config="dynamodb_table=twin-terraform-locks" \
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

# Function to run terraform destroy with lock handling
run_terraform_destroy() {
    if [ "$ENVIRONMENT" = "prod" ] && [ -f "prod.tfvars" ]; then
        terraform destroy -var-file=prod.tfvars -var="project_name=$PROJECT_NAME" -var="environment=$ENVIRONMENT" -auto-approve
    else
        terraform destroy -var="project_name=$PROJECT_NAME" -var="environment=$ENVIRONMENT" -auto-approve
    fi
}

# Try to run destroy, handle lock errors
set +e  # Temporarily disable exit on error to handle lock errors
run_terraform_destroy 2>&1 | tee /tmp/terraform_output.log
DESTROY_EXIT_CODE=${PIPESTATUS[0]}
set -e  # Re-enable exit on error

if [ $DESTROY_EXIT_CODE -ne 0 ]; then
    # Check if the error was due to a state lock
    if grep -q "Error acquiring the state lock" /tmp/terraform_output.log; then
        echo "⚠️  State lock detected. Attempting to force unlock..."
        # Extract lock ID from the error message (works with both GNU and BSD grep)
        LOCK_ID=$(grep "ID:" /tmp/terraform_output.log | sed -n 's/.*ID:[[:space:]]*\([0-9a-f-]*\).*/\1/p' | head -1)
        if [ -n "$LOCK_ID" ]; then
            echo "🔓 Force unlocking state lock: $LOCK_ID"
            terraform force-unlock -force "$LOCK_ID" || true
            echo "🔄 Retrying terraform destroy..."
            set +e
            run_terraform_destroy
            RETRY_EXIT_CODE=$?
            set -e
            if [ $RETRY_EXIT_CODE -ne 0 ]; then
                echo "❌ Destroy failed after unlocking. Please check the error above."
                exit 1
            fi
        else
            echo "❌ Could not extract lock ID. Please unlock manually."
            exit 1
        fi
    else
        # Some other error occurred
        exit 1
    fi
fi

echo "✅ Infrastructure for ${ENVIRONMENT} has been destroyed!"
echo ""
echo "💡 To remove the workspace completely, run:"
echo "   terraform workspace select default"
echo "   terraform workspace delete $ENVIRONMENT"