variable "vpc_cidr" {
    description = "CIDR block for the VPC"
    type = string
    default = "10.0.0.0/16"
}
variable "public_subnet_cidrs" {
    description = "List of CIDRs for public subnets (one per AZ)"
    type = list(string)
    default = ["10.0.1.0/24", "10.0.2.0/24"]
}
variable "azs" {
    description = "List of availability zones to use"
    type = list(string)
    default = ["us-east-1a", "us-east-1b"]
}

variable "name_prefix" {
    description = "Name prefix for resources"
    type = string
    default = "demo-educative"
}
