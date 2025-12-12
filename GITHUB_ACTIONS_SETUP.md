# GitHub Actions Setup for Terraform CI/CD

This document explains how to set up the GitHub Actions workflow for automated Terraform deployments.

## Prerequisites

- GitHub repository with the Terraform code
- AWS account with appropriate permissions
- GitHub repository settings access (to add secrets)

## Step 1: Create an IAM Role for GitHub Actions

GitHub Actions will assume an IAM role to deploy infrastructure. This is more secure than storing long-lived AWS credentials.

### Using AWS CLI:

```bash
# Create the IAM role
aws iam create-role \
  --role-name github-actions-terraform \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
        },
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Condition": {
          "StringEquals": {
            "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
          },
          "StringLike": {
            "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_ORG/YOUR_REPO:*"
          }
        }
      }
    ]
  }'

# Attach policy for VPC, S3, and DynamoDB access
aws iam put-role-policy \
  --role-name github-actions-terraform \
  --policy-name terraform-vpc-policy \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ec2:*",
          "s3:*",
          "dynamodb:*",
          "iam:GetRole",
          "iam:PassRole"
        ],
        "Resource": "*"
      }
    ]
  }'
```

Replace:
- `ACCOUNT_ID` — your AWS account ID (run `aws sts get-caller-identity --query Account --output text`)
- `YOUR_GITHUB_ORG/YOUR_REPO` — your GitHub org and repo (e.g., `chris/terraform-aws-projects`)

### Via AWS Console:

1. Go to **IAM → Roles → Create role**
2. Select **Web identity** → **token.actions.githubusercontent.com**
3. Set **Audience** to `sts.amazonaws.com`
4. Add condition: `token.actions.githubusercontent.com:sub` matches `repo:YOUR_ORG/YOUR_REPO:*`
5. Attach policies: `AmazonEC2FullAccess`, `AmazonS3FullAccess`, `AmazonDynamoDBFullAccess`
6. Name the role `github-actions-terraform`

## Step 2: Add GitHub Repository Secrets

Go to your GitHub repository:
1. **Settings → Secrets and variables → Actions**
2. Create a new **Repository Secret**:
   - **Name:** `AWS_ROLE_TO_ASSUME`
   - **Value:** `arn:aws:iam::ACCOUNT_ID:role/github-actions-terraform`

Replace `ACCOUNT_ID` with your AWS account ID.

## Step 3: Enable OIDC in GitHub

GitHub Actions uses OIDC (OpenID Connect) to assume the IAM role without storing credentials.

### Check if OIDC provider exists:

```bash
aws iam list-open-id-connect-providers | grep token.actions.githubusercontent.com
```

If not found, create it:

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

## Step 4: Test the Workflow

1. **Create a branch and make a change:**
   ```bash
   git checkout -b feature/test-cicd
   # Make a small change to proj-02-vpc-baseline/variables.tf
   git add .
   git commit -m "test: trigger cicd workflow"
   git push origin feature/test-cicd
   ```

2. **Open a Pull Request** on GitHub

3. **Watch the workflow:**
   - Go to **Actions** tab
   - The `Terraform Plan` job should run and post the plan output as a comment on the PR

4. **Merge to main** to trigger `Terraform Apply`:
   - Merge the PR to main
   - The `Terraform Apply` job should run automatically
   - Check **Actions** to see the deployment progress

## Workflow Details

### `terraform-plan` job (runs on PR)
- **Trigger:** Pull request with changes to `proj-02-vpc-baseline/**`
- **Steps:**
  1. Check code format (`terraform fmt`)
  2. Validate syntax (`terraform validate`)
  3. Generate plan (`terraform plan`)
  4. Post plan as PR comment

### `terraform-apply` job (runs on merge to main)
- **Trigger:** Push to `main` branch with changes to `proj-02-vpc-baseline/**`
- **Steps:**
  1. Validate syntax
  2. Generate plan
  3. Apply plan (`terraform apply -auto-approve`)
  4. Display outputs

## Troubleshooting

### Error: "Unable to assume role"
- Ensure the IAM role exists: `aws iam get-role --role-name github-actions-terraform`
- Verify the secret `AWS_ROLE_TO_ASSUME` matches the role ARN exactly
- Check OIDC provider is configured

### Error: "Permission denied" on AWS resources
- Ensure the IAM role has appropriate permissions
- Example policy for this project: EC2, S3, DynamoDB, IAM (get/pass role)

### Workflow not triggering
- Check the `paths` filter in the workflow YAML matches your directory
- Ensure the workflow file is on the `main` branch

## Security Best Practices

✅ **Using this setup:**
- No long-lived AWS credentials stored in GitHub
- IAM role scoped to GitHub Actions
- Role assumes identity based on OIDC token (time-limited)
- All actions logged in CloudTrail

✅ **Additional recommendations:**
- Restrict IAM role permissions to minimum needed (principle of least privilege)
- Use branch protection rules to require PR reviews before merge
- Add manual approval step in workflow for prod deployments (optional)
- Audit CloudTrail logs for all assume-role actions

## Reference

- [GitHub Actions with AWS](https://github.com/aws-actions/configure-aws-credentials)
- [Terraform GitHub Actions](https://github.com/hashicorp/setup-terraform)
- [AWS OIDC Federated Access](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-idp_oidc.html)
