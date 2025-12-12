resource "aws_sqs_queue" "main_sqs" {
    name                       = var.sqs_name
    visibility_timeout_seconds = var.visibility_timeout_seconds
    delay_seconds              = var.delay_seconds
    message_retention_seconds  = var.message_retention_seconds
    
    tags = {
        Name = var.sqs_name
    }
  
}

resource "aws_s3_bucket" "main_bucket" {
    bucket = var.s3_bucket_name

    tags = {
        Name = var.s3_bucket_name
    }
  
}