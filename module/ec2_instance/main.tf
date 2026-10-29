provider "aws" {
  region = "ap-south-1"
}

variable "ami" {
  description = "AMI id for ec2"
}

variable "instance_type" {
  description = "instance type"
}

variable "subnet" {
  description = "subnet in whcih u want to create instance"
}

resource "aws_instance" "ec2_workspace" {
  ami = var.ami
  instance_type = var.instance_type
  subnet_id = var.subnet
  associate_public_ip_address = true
  tags = {
    Name = "ec2-${terraform.workspace}"
  }
}

output "public_ip" {
  value = aws_instance.ec2_workspace.public_ip
}