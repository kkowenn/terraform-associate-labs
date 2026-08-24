# Create one bucket for each name in the list
module "s3_buckets" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.13.0"

  for_each = toset(var.bucket_names) # <-- Create a bucket for each name in the list

  bucket_prefix = "${var.environment}-${each.value}-"

  tags = {
    Terraform   = "true"
    Environment = var.environment
    Name        = each.value
  }
}

# Use the VPC module from the Terraform Registry
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.19.0"

  name = "${var.environment}-vpc"
  cidr = var.vpc_cidr

  azs             = ["${var.region}a", "${var.region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}


