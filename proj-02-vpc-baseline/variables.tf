variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Name prefix for resources"
  type        = string
  default     = "chris_demo"
}

variable "vpc_cidr" {
  description = "CIDR block for the this_VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of CIDRs for public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "List of CIDRs for private subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.2.0/24", "10.0.4.0/24"]
}