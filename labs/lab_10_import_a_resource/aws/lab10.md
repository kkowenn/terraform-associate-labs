# Terraform Lab 10 – Importing Existing AWS Resources

## Summary

This lab teaches how to bring **existing AWS resources that are not currently tracked in Terraform state** back under Terraform management.

The official lab expects these resources to already exist in AWS:

- VPC: `lab-vpc`
- Subnet: `lab-subnet`
- Security Group: `lab-web-sg`

The main idea is:

```text
Existing AWS resource
        ↓
Terraform does not know it yet
        ↓
Import the resource into Terraform state
        ↓
Terraform starts managing the same real resource
```

Importing changes **Terraform state**, not the AWS resource itself.

---

## Why We Created `aws/temporary/`

`aws/temporary/` is **not part of the original Lab 19 instructions**. We created it because the resources from the previous lab had already been destroyed.

Lab 19 normally starts with live resources left behind by Lab 18. Since those resources no longer existed, we needed a small helper Terraform configuration to recreate them first.

Our directory layout became:

```text
aws/
├── main.tf                 # Actual import lab
├── providers.tf
├── variables.tf
├── generated.tf            # Temporary generated config during import exercise
│
└── temporary/
    ├── main.tf             # Only used to CREATE the prerequisite AWS resources
    ├── terraform.tfstate   # State that belongs only to temporary/
    └── ...
```

Think of it as:

```text
aws/temporary/
    ↓
CREATE prerequisite infrastructure

aws/
    ↓
IMPORT that existing infrastructure
```

Each directory is a separate Terraform **root module** and therefore has its own state.

---

## `temporary/` Process

### 1. Create the resources

Inside `aws/temporary/`, we created only the resources needed for the import lab:

```hcl
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
```

Then:

```bash
cd aws/temporary
terraform init
terraform apply -auto-approve
```

This created real AWS resources such as:

```text
VPC            vpc-...
Subnet         subnet-...
Security Group sg-...
```

### 2. Remove them from the temporary state without deleting AWS resources

To simulate the state expected by the import lab, we removed the resources from Terraform state only:

```bash
terraform state rm aws_vpc.main
terraform state rm aws_subnet.app
terraform state rm aws_security_group.main
```

Important:

```text
terraform state rm
= Terraform forgets the resource
= AWS resource stays alive
```

This is different from:

```text
terraform destroy
= AWS resource is actually deleted
```

After `state rm`, the resources still existed in AWS, but Terraform no longer managed them from `temporary/`.

---

# Actual Import Lab (`aws/`)

The root `aws/` directory is the real import exercise.

At the beginning:

```bash
terraform state list
```

should show no managed resources.

But the real VPC, subnet, and security group already exist in AWS because they were created by `temporary/`.

---

## Import Method 1 – CLI Import

For the VPC, we first write the matching resource block:

```hcl
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name        = "${var.prefix}-vpc"
    Environment = var.environment
  }
}
```

Then import the existing VPC:

```bash
terraform import aws_vpc.main vpc-xxxxxxxxxxxxxxxxx
```

Meaning:

```text
aws_vpc.main
↑ Terraform resource address

vpc-xxxxxxxxxxxxxxxxx
↑ Real AWS resource ID
```

Then verify:

```bash
terraform plan
```

A successful import should eventually produce:

```text
No changes. Your infrastructure matches the configuration.
```

---

## Import Method 2 – `import {}` Block

For the subnet:

```hcl
import {
  to = aws_subnet.app
  id = "subnet-xxxxxxxxxxxxxxxxx"
}

resource "aws_subnet" "app" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.subnet_cidr

  tags = {
    Name        = "${var.prefix}-subnet"
    Environment = var.environment
  }
}
```

Run:

```bash
terraform plan
```

Expected:

```text
Plan: 1 to import, 0 to add, 0 to change, 0 to destroy.
```

Unlike the CLI import command, an `import {}` block performs the import during `terraform apply`:

```bash
terraform apply -auto-approve
```

---

## Generate Resource Configuration Automatically

For the security group, we practiced importing with only an import block first:

```hcl
import {
  to = aws_security_group.main
  id = "sg-xxxxxxxxxxxxxxxxx"
}
```

Then:

```bash
terraform plan -generate-config-out=generated.tf
```

Terraform reads the existing AWS object and creates a draft resource block in:

```text
generated.tf
```

Generated configuration is usually verbose and hardcoded, for example:

```hcl
vpc_id = "vpc-xxxxxxxxxxxxxxxxx"
```

We should clean this up into reusable Terraform:

```hcl
vpc_id = aws_vpc.main.id
```

A cleaned security group looks like:

```hcl
resource "aws_security_group" "main" {
  name        = "${var.prefix}-web-sg"
  description = "Lab security group"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name        = "${var.prefix}-web-sg"
    Environment = var.environment
  }
}
```

---

# Important Concept: Configuration vs State vs AWS

```text
main.tf
= Desired configuration

terraform.tfstate
= What Terraform currently manages / knows about

AWS
= Real infrastructure
```

Before import:

```text
Configuration ✅
State         ❌
AWS resource  ✅
```

After import:

```text
Configuration ✅
State         ✅
AWS resource  ✅
```

A clean `terraform plan` proves they agree.

---

# Why Import Order Matters

The subnet configuration contains:

```hcl
vpc_id = aws_vpc.main.id
```

Therefore the VPC should be imported first.

If Terraform does not know about the existing VPC, it may plan to create a new VPC. Then the imported subnet appears to belong to the wrong VPC and Terraform may propose replacing it.

Correct order:

```text
1. Import VPC
2. Import subnet
3. Import security group
```

---

# Region Must Match

AWS resource IDs are region-specific for these resources.

Our resources were created in:

```text
ap-southeast-7
```

Therefore the provider used by the import root had to point to the same region:

```hcl
provider "aws" {
  region = var.aws_region
}
```

with:

```hcl
variable "aws_region" {
  default = "ap-southeast-7"
}
```

If Terraform searches another region, import may fail with:

```text
Cannot import non-existent remote object
```

even though the resource really exists elsewhere.

---

# CLI Import vs Import Block

| Method                   | Behavior                                                 |
| ------------------------ | -------------------------------------------------------- |
| `terraform import`     | Imports immediately from the CLI                         |
| `import {}`            | Declarative import; imported during`terraform apply`   |
| `-generate-config-out` | Can generate a draft resource block for an import target |

Example CLI:

```bash
terraform import aws_vpc.main vpc-xxxxxxxxxxxxxxxxx
```

Example block:

```hcl
import {
  to = aws_subnet.app
  id = "subnet-xxxxxxxxxxxxxxxxx"
}
```

---

# Cleanup After Successful Import

After all imports are completed:

```bash
terraform state list
```

should show something like:

```text
aws_security_group.main
aws_subnet.app
aws_vpc.main
```

Then:

```bash
terraform plan
```

should return:

```text
No changes. Your infrastructure matches the configuration.
```

Once an `import {}` block has been successfully applied, it can be removed from the configuration for this lab because it was a one-time migration instruction.

Similarly, `generated.tf` can be deleted after its useful resource configuration has been cleaned up and moved into `main.tf`.

Finally, because the root `aws/` Terraform state now manages the resources, cleanup can be done from the import lab root:

```bash
terraform destroy -auto-approve
```

Do **not** destroy from `temporary/` after its resources have been removed from that state. The authoritative Terraform state after importing is the root `aws/` state.

---

# One-Line Mental Model

```text
temporary/ = create resources so we have something to import
aws/       = learn how Terraform adopts those existing resources
```
