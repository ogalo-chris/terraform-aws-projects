# Remote State Bootstrap
# This script creates the S3 bucket and DynamoDB table needed for Terraform remote state.
# Run this once before running `terraform init` in the main project.

set -euo pipefail

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="vpc-terraform-state-${ACCOUNT_ID}"
TABLE_NAME="vpc-terraform-locks"
REGION="us-east-1"

echo "Using AWS account: ${ACCOUNT_ID}, region: ${REGION}"

# Check if bucket exists and is accessible
if aws s3api head-bucket --bucket "$BUCKET_NAME" >/dev/null 2>&1; then
  echo "S3 bucket $BUCKET_NAME already exists and is accessible."
else
  echo "S3 bucket $BUCKET_NAME does not exist or is not owned by this account. Attempting to create..."
  if [ "$REGION" = "us-east-1" ]; then
    # us-east-1 requires no LocationConstraint
    if aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$REGION"; then
      echo "Created bucket $BUCKET_NAME in $REGION"
    else
      echo "Failed to create bucket $BUCKET_NAME in $REGION" >&2
      aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$REGION" || true
      exit 1
    fi
  else
    if aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$REGION" --create-bucket-configuration LocationConstraint="$REGION"; then
      echo "Created bucket $BUCKET_NAME in $REGION"
    else
      echo "Failed to create bucket $BUCKET_NAME in $REGION" >&2
      exit 1
    fi
  fi
fi

echo "Enabling versioning on S3 bucket..."
aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled

echo "Enabling server-side encryption on S3 bucket..."
aws s3api put-bucket-encryption \
  --bucket "$BUCKET_NAME" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

echo "Blocking public access to S3 bucket..."
aws s3api put-public-access-block \
  --bucket "$BUCKET_NAME" \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

echo "Creating DynamoDB table for state locking: $TABLE_NAME"
if aws dynamodb describe-table --table-name "$TABLE_NAME" >/dev/null 2>&1; then
  echo "DynamoDB table $TABLE_NAME already exists."
else
  aws dynamodb create-table \
    --table-name "$TABLE_NAME" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region "$REGION"
  echo "Created DynamoDB table $TABLE_NAME"
fi

echo "✓ Remote state infrastructure created successfully!"
echo "You can now run: terraform init"
