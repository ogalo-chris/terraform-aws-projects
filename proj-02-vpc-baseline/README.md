# Project 02 — VPC Networking

Overview
--------
Creating a modular VPC with public and private subnets across 2 Availability Zones, an Internet Gateway, NAT Gateways (one per AZ), route tables, and optional NACLs. This project is intentionally modular so it can be reused by other projects (EC2, RDS, EKS).

Goals
- Build a VPC that mirrors what cloud engineers create for app infrastructure.
- Support public and private subnets across 2 AZs.
- Provide a simple verification plan and GitHub workflow guidance.

Files
- `main.tf` — root module usage and provider
- `variables.tf` — configurable inputs
- `modules/vpc/*` — reusable VPC module (resources + outputs)

Quick start

### Step 1: Set up remote state (one-time)

Before initializing Terraform, create the S3 bucket and DynamoDB table for state storage:

```bash
chmod +x bootstrap-remote-state.sh
./bootstrap-remote-state.sh
```

This script:
- Creates an S3 bucket to store the Terraform state file (versioned and encrypted)
- Creates a DynamoDB table for state locking (prevents concurrent modifications)
- Blocks all public access to the S3 bucket

**Note:** You only need to run this once per AWS account. If the bucket/table already exist, the script will skip creation.

### Step 2: Create a branch and commit
You need to have created a repo in Github with main before creating the feature branch. 

```bash
git checkout -b feature/proj-02-vpc
git add .
git commit -m "chore(vpc): add vpc baseline module with remote state"
git push origin feature/proj-02-vpc
```

### Step 3: Initialize and plan locally

```bash
export AWS_PROFILE=your-profile   # or configure env creds
terraform init ---backend-config= #You need a backend config since terraform doesn't allow variable in backend.tf
terraform plan -out plan.tfplan
terraform apply "plan.tfplan"
```

During `terraform init`, Terraform will:
1. Detect the `backend.tf` configuration
2. Initialize the local backend first
3. Ask if you want to copy the state to the remote backend — answer **yes**

### Step 4: Verify

- In the AWS console: VPC → Your VPCs, Subnets, Route Tables, NAT Gateways.
- Check S3 bucket: `aws s3 ls | grep vpc-terraform-state`
- Check state file: `aws s3 ls s3://vpc-terraform-state-<ACCOUNT_ID>/vpc/`
- Use an EC2 instance launched into a private subnet (or run a simple reachability test) to confirm outbound internet via NAT.

## Team workflow with remote state

Once remote state is configured:
- **Team members** no longer need to manage local state files.
- **State is centralized** in S3, ensuring a single source of truth.
- **Locking** prevents simultaneous `terraform apply` from corrupting state.
- **All changes** are tracked via git commits and Terraform state history (S3 versioning).

Example team workflow:
```bash
# Developer A
git checkout -b feature/add-nat
# ...make changes...
terraform plan
terraform apply
git push origin feature/add-nat
# Open PR, get approval, merge to main

# Developer B (on main branch)
git pull origin main
terraform init  # downloads latest state
terraform plan  # references latest state
terraform apply  # locks state, applies, unlocks
```

## GitHub Actions CI/CD

This project includes a GitHub Actions workflow (`.github/workflows/terraform-vpc.yml`) that:
- Runs `terraform plan` on every PR and posts the plan as a comment
- Runs `terraform validate` and `terraform fmt` checks
- Automatically runs `terraform apply` when code is merged to `main`

### Setup

See [GITHUB_ACTIONS_SETUP.md](../GITHUB_ACTIONS_SETUP.md) for:
- Creating an IAM role for GitHub Actions
- Adding repository secrets
- Enabling OIDC (OpenID Connect) for secure credential-less deployment
- Testing the workflow

**Quick summary:**
1. Create IAM role `github-actions-terraform`
2. Add secret `AWS_ROLE_TO_ASSUME` to your GitHub repo
3. Enable OIDC provider in AWS
4. Push to a feature branch to trigger `terraform plan` in PR
5. Merge to `main` to trigger `terraform apply`

## Notes

- **Remote state is essential for team collaboration.** Local state files should never be committed to git.
- The bootstrap script uses AWS CLI. Ensure your AWS credentials are configured: `aws sts get-caller-identity`
- State file encryption (S3) and locking (DynamoDB) are standard best practices.
- GitHub Actions uses OIDC to assume an IAM role — no long-lived credentials are stored.
- For more details, see [Terraform Remote State Documentation](https://developer.hashicorp.com/terraform/language/state/remote).

## Backend config: example and safe storage

You should not commit your real `backend.conf` to the repository because it contains account-specific details. Instead:

- Keep a checked-in example file: `backend.conf.example` (provided in this folder).
- Create a real `backend.conf` locally (or in CI) from the example and **do not** commit it. The project `.gitignore` already lists `backend.conf`.

Example (create `backend.conf` locally):

```bash
# from project root
cp backend.conf.example backend.conf
# Edit backend.conf and replace <ACCOUNT_ID> with your AWS account id
sed -i "s/<ACCOUNT_ID>/$(aws sts get-caller-identity --query Account --output text)/" backend.conf

# Initialize Terraform using that concrete backend config
terraform init -backend-config=backend.conf
```

CI / GitHub Actions: supply backend values from secrets

In CI you should avoid storing `backend.conf` in the repo. Instead, create `backend.conf` at runtime using repository Secrets, or pass the individual values with `-backend-config` flags.

Example GitHub Actions step (pseudo):

```yaml
- name: Create backend config
	run: |
		cat > backend.conf <<EOF
		bucket = "${{ secrets.BACKEND_BUCKET }}"
		key = "vpc/terraform.tfstate"
		region = "${{ secrets.BACKEND_REGION }}"
		encrypt = true
		dynamodb_table = "${{ secrets.BACKEND_DDB }}"
		EOF

- name: Terraform init
	run: terraform init -backend-config=backend.conf
```

Store the following repo secrets in GitHub (Actions → Secrets):
- `BACKEND_BUCKET` — S3 bucket name
- `BACKEND_REGION` — region (e.g. `us-east-1`)
- `BACKEND_DDB` — DynamoDB lock table name

This keeps account-specific backend details out of source control while allowing CI to initialize the backend securely.