# Create the primary VPC for workloads
resource "aws_vpc" "main" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name       = "terraform-course"
    Enviroment = "lab"
    Managed_By = "Terraform"
 }
}
