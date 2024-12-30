data "aws_vpc" "existing_vpc" {
  id = "vpc-083ba7e0b42236aa6"  # Replace with your VPC ID
}

data "aws_subnet" "subnet1" {
  id = "subnet-0d63da31ae0352dec"  # Replace with your Subnet ID
}

data "aws_subnet" "subnet2" {
  id = "subnet-006a6f2a8eb19d5d1"  # Replace with your Subnet ID
}
