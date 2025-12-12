provider "aws" {
    region = "us-east-1"
  
}

module "sqs_s3_deploy" {
    source = "./modules/sqs_workspace"
    sqs_name                    = "${local.workspace}-main_sqs"
    visibility_timeout_seconds  = 30
    delay_seconds               = 0
    message_retention_seconds   = 345600

    s3_bucket_name              = "${local.workspace}-demo-bucket-1234567890"
  
}

locals {
  workspace = terraform.workspace
}

output "deploy_details" {
    value = {
        sqs_queue_url = module.sqs_s3_deploy.sqs_queue_url
        s3_bucket_id  = module.sqs_s3_deploy.s3_bucket_id
    }
  
}