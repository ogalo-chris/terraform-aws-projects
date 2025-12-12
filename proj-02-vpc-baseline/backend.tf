terraform {
  backend "s3" {
    bucket         = "vpc-terraform-state-${data.aws_caller_identity.current.account_id}"
    key            = "vpc/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "vpc-terraform-locks"
  }
}

data "aws_caller_identity" "current" {}
