terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

# vpc
resource "aws_vpc" "msa_vpc" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "msa-vpc"
  }
}

# subnet
resource "aws_subnet" "msa_subnet_a" {
  vpc_id = aws_vpc.msa_vpc.id

  cidr_block = "10.0.1.0/24"

  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "msa-subnet-a"
  }
}

resource "aws_subnet" "msa_subnet_c" {
  vpc_id     = aws_vpc.msa_vpc.id
  cidr_block = "10.0.2.0/24"

  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "msa-subnet-c"
  }
}

# igw
resource "aws_internet_gateway" "msa_igw" {
  vpc_id = aws_vpc.msa_vpc.id

  tags = {
    Name = "msa-igw"
  }
}

# route table
resource "aws_route_table" "msa_public_rt" {
  vpc_id = aws_vpc.msa_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.msa_igw.id
  }

  tags = {
    Name = "msa-public-rt"
  }
}

# Subnet A에 위에서 만든 "경로 규칙"을 적용
resource "aws_route_table_association" "msa_rt_assoc_a" {
  subnet_id      = aws_subnet.msa_subnet_a.id
  route_table_id = aws_route_table.msa_public_rt.id
}

# Subnet C에 위에서 만든 "경로 규칙"을 적용
resource "aws_route_table_association" "msa_rt_assoc_c" {
  subnet_id      = aws_subnet.msa_subnet_c.id
  route_table_id = aws_route_table.msa_public_rt.id
}