provider "aws" {
  region = "ap-south-1"
}

variable "ami" {
  description = "AMI id for ec2"
}

variable "instance_type" {
  description = "instance type"
  type = map(string)

  default = {
    "dev" = "t3.small"
    "qa" = "t3.micro"
    "prod" = "c7i-flex.large"
  }
}

variable "subnet" {
  description = "subnet in whcih u want to create instance"
}

module "ec2_instnace" {
  source = "./module/ec2_instance"
  ami = var.ami
  instance_type = lookup(var.instance_type, terraform.workspace, "t3.small")
  subnet = var.subnet
}

output "public_ip" {
  value = module.ec2_instnace.public_ip
}