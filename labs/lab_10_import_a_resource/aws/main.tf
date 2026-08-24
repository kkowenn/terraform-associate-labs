# VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name        = "${var.prefix}-vpc"
    Environment = var.environment
  }
}

# Import existing subnet
import {
  to = aws_subnet.app
  id = "subnet-02461d5559af802c9"
}

# Subnet configuration
resource "aws_subnet" "app" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.subnet_cidr

  tags = {
    Name        = "${var.prefix}-subnet"
    Environment = var.environment
  }
}

import {
  to = aws_security_group.main
  id = "sg-0c18fbfaf56ee31ad"
}

