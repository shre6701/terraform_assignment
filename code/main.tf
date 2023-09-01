terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


provider "aws" {
  region = "us-east-1"
  access_key= "AKIAVQUDP2HZKOLBURDX"
  secret_key= "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"
}

resource "tls_private_key" "rsa_4096"{
    algorithm = "RSA"
    rsa_bits= 4096
}

variable "key_name" {}

resource "aws_key_pair" "key_pair" {
  key_name   = var.key_name
  public_key = tls_private_key.rsa_4096.public_key_openssh
}

resource "local_file" "private_key" {
    content = tls_private_key.rsa_4096.private_key_pem
    filename= var.key_name
}

# Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create a public subnet within the VPC
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a" 
  map_public_ip_on_launch = true
}

# Create a private subnet within the VPC
resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1a"
} 

# Create a security group for SSH access and all outbound traffic
resource "aws_security_group" "my_sg" {
  vpc_id = aws_vpc.my_vpc.id
  name        = "my-security-group"
  description = "My Security Group"

  # Inbound rule for SSH (port 22)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rule for all traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an EC2 instance in the public subnet
resource "aws_instance" "my_instance" {
  ami           = "ami-053b0d53c279acc90" 
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet.id
  key_name      = aws_key_pair.key_pair.key_name
  # Define the root volume
  root_block_device {
    volume_size = 8
    volume_type = "gp2"
  }

  tags = {
    Name    = "MyInstance"
    purpose = "Assignment"
  }

  # Associate the security group with the instance
  vpc_security_group_ids = [aws_security_group.my_sg.id]
}







