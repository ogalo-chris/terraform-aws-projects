provider "aws" {
    region = var.region

}

module "vpc" {
    source = "./vpc"

}

output "vpc" {
  value = module.vpc
}