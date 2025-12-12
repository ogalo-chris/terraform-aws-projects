output "sqs_queue_url" {
  description = "URL of the SQS queue"
  value       = aws_sqs_queue.main_sqs.url
}

output "sqs_queue_id" {
  description = "ID of the SQS queue"
  value       = aws_sqs_queue.main_sqs.id
}

output "s3_bucket_id" {
  description = "ID of the S3 bucket"
  value       = aws_s3_bucket.main_bucket.id
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.main_bucket.bucket
}
