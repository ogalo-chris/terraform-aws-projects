output "the_main_vpc_details" {
    value = aws_vpc.the_main_vpc
  
}

output "public_subnet_details" {
    value = aws_subnet.public[*]
  
}