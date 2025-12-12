variable "sqs_name" {
    description = "name of the main sqs"
    type        = string
    default     = "main_sqs"
  
}

variable "visibility_timeout_seconds" {
    description = "visibility timeout seconds for the sqs"
    type        = number
    default     = 30
  
}

variable "delay_seconds" {
    description = "delay seconds for the sqs"
    type        = number
    default     = 0
  
}

variable "message_retention_seconds" {
    description = "message retention seconds for the sqs"
    type        = number
    default     = 345600
  
}

variable "s3_bucket_name" {
    description = "name of the s3 bucket"
    type        = string
    default     = "my-unique-s3-bucket-1234567890"
  
}