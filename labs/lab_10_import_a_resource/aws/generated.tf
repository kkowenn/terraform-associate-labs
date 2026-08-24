# __generated__ by Terraform
# Please review these resources and move them into your main configuration files.

# __generated__ by Terraform from "sg-0c18fbfaf56ee31ad"
resource "aws_security_group" "main" {
  description            = "Lab security group"
  egress                 = []
  ingress                = []
  name                   = "lab-web-sg"
  region                 = "ap-southeast-7"
  revoke_rules_on_delete = null
  tags = {
    Environment = "dev"
    Name        = "lab-web-sg"
  }
  tags_all = {
    Environment = "dev"
    Name        = "lab-web-sg"
  }
  vpc_id = "vpc-0b728ced2b139c3ab"
}
