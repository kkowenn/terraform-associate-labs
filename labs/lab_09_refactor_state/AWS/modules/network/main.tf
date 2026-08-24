variable "vpc_id" {
  description = "ID of the VPC where the subnet will be created"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  type        = string
}

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name for tagging"
  type        = string
}


resource "aws_subnet" "app" {
  vpc_id     = var.vpc_id
  cidr_block = var.subnet_cidr

  tags = {
    Name        = "${var.prefix}-subnet"
    Environment = var.environment
  }
}
