provider "aws" {
  region     = "us-east-2"
  access_key = ""
  secret_key = ""
}

resource "aws_vpc" "mnkvpc" {
  cidr_block       = "11.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "demo-mnkvpc"
  }
}

resource "aws_subnet" "psub" {
  vpc_id     = aws_vpc.mnkvpc.id
  cidr_block = "11.0.1.0/24"

  tags = {
    Name = "public"
  }
}

resource "aws_subnet" "prvsub" {
  vpc_id     = aws_vpc.mnkvpc.id
  cidr_block = "11.0.2.0/24"

  tags = {
    Name = "private"
  }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.mnkvpc.id
  
    tags = {
      Name = "IGW"
    }
  }

  resource "aws_eip" "eip" {
    vpc      = true
  }
resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.prvsub.id

  tags = {
    Name = "gw NAT"
  }
}
resource "aws_route_table" "rt1" {
    vpc_id = aws_vpc.mnkvpc.id
        
    route {
      cidr_block = "0.0.0.0/0"
      gateway_id =aws_internet_gateway.igw.id
    }
  
    tags = {
      Name = "public-test"
    }
  }

  resource "aws_route_table" "rt2" {
    vpc_id = aws_vpc.mnkvpc.id
        
    route {
      cidr_block = "0.0.0.0/0"
      gateway_id =aws_nat_gateway.ngw.id
    }
  
    tags = {
      Name = "pivate-test"
    }
  }

  resource "aws_route_table_association" "as_1" {
    subnet_id      = aws_subnet.psub.id
    route_table_id = aws_route_table.rt1.id
  }

  resource "aws_route_table_association" "as_2" {
    subnet_id      = aws_subnet.prvsub.id
    route_table_id = aws_route_table.rt2.id
  }

  resource "aws_security_group" "sg" {
    name        = "sg"
    description = "Allow TLS inbound traffic"
    vpc_id      = aws_vpc.mnkvpc.id
  
    ingress {
      description      = "TLS from VPC"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = [aws_vpc.mnkvpc.cidr_block]
     
    }
  
    egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      
    }
  
    tags = {
      Name = "sg"
    }
  }
