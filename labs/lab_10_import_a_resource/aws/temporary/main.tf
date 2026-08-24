resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name        = "lab-vpc"
    Environment = "dev"
  }
}

resource "aws_subnet" "app" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name        = "lab-subnet"
    Environment = "dev"
  }
}

resource "aws_security_group" "main" {
  name        = "lab-web-sg"
  description = "Lab security group"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name        = "lab-web-sg"
    Environment = "dev"
  }
}
