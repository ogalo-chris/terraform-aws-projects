resource "aws_vpc" "the_main_vpc" {
    cidr_block = var.vpc_cidr
    
    tags = {
        Name = "${var.name_prefix}-vpc"
    }
  
}

resource "aws_subnet" "public" {
    count = 2
    vpc_id            = aws_vpc.the_main_vpc.id
    cidr_block        = var.public_subnet_cidrs[count.index]
    availability_zone = var.azs[count.index]
    tags = {
        Name = "${var.name_prefix}-public-subnet-${count.index + 1}"
    }
}