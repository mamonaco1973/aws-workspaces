# ================================================================================
# AWS Provider Configuration
# --------------------------------------------------------------------------------
# Configures the AWS provider used by this Terraform module.
#
# Key Points
# - Sets the default AWS region.
# - All resources and data sources in this module will use this region.
# ================================================================================

provider "aws" {
  region = "us-east-1"
}

# ================================================================================
# Active Directory Credential Secrets
# --------------------------------------------------------------------------------
# Retrieves credential secrets stored in AWS Secrets Manager.
#
# Key Points
# - Each secret contains a JSON object with username and password.
# - Credentials are used for authentication during instance bootstrap.
# - Secrets are created in the directory deployment phase.
# ================================================================================

# ------------------------------------------------------------------------------
# Raj Patel credentials
# ------------------------------------------------------------------------------
data "aws_secretsmanager_secret" "rpatel_secret" {
  name = "rpatel_ad_credentials_ws"
}

# ------------------------------------------------------------------------------
# Emily Davis credentials
# ------------------------------------------------------------------------------
data "aws_secretsmanager_secret" "edavis_secret" {
  name = "edavis_ad_credentials_ws"
}

# ------------------------------------------------------------------------------
# Active Directory administrator credentials
# ------------------------------------------------------------------------------
data "aws_secretsmanager_secret" "admin_secret" {
  name = "admin_ad_credentials_ws"
}

# ------------------------------------------------------------------------------
# John Smith credentials
# ------------------------------------------------------------------------------
data "aws_secretsmanager_secret" "jsmith_secret" {
  name = "jsmith_ad_credentials_ws"
}

# ------------------------------------------------------------------------------
# Amit Kumar credentials
# ------------------------------------------------------------------------------
data "aws_secretsmanager_secret" "akumar_secret" {
  name = "akumar_ad_credentials_ws"
}

# ================================================================================
# Active Directory VPC
# --------------------------------------------------------------------------------
# Retrieves the VPC used by the Active Directory deployment.
# ================================================================================

data "aws_vpc" "ad_vpc" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

# ================================================================================
# Active Directory Private Subnet 1
# --------------------------------------------------------------------------------
# Retrieves the first private subnet inside the AD VPC.
#
# Key Points
# - Matches the subnet by Name tag.
# - Restricts the lookup to the AD VPC.
# ================================================================================

data "aws_subnet" "ad_private_subnet_1" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.ad_vpc.id]
  }

  filter {
    name   = "tag:Name"
    values = ["ad-ws-private-subnet-1"]
  }
}

# ================================================================================
# Active Directory Private Subnet 2
# --------------------------------------------------------------------------------
# Retrieves the second private subnet inside the AD VPC.
#
# Key Points
# - Matches the subnet by Name tag.
# - Restricts the lookup to the AD VPC.
# ================================================================================

data "aws_subnet" "ad_private_subnet_2" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.ad_vpc.id]
  }

  filter {
    name   = "tag:Name"
    values = ["ad-ws-private-subnet-2"]
  }
}

# ================================================================================
# Ubuntu AMI
# --------------------------------------------------------------------------------
# Retrieves the most recent Ubuntu 24.04 LTS image published by Canonical.
#
# Key Points
# - Ensures the instance uses the latest security-patched image.
# - Filters for the x86_64 Ubuntu Noble release.
# ================================================================================

data "aws_ami" "ubuntu_ami" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical official account

  filter {
    name   = "name"
    values = ["*ubuntu-noble-24.04-amd64-*"]
  }
}

# ================================================================================
# Windows Server AMI
# --------------------------------------------------------------------------------
# Retrieves the most recent Windows Server 2022 image published by AWS.
#
# Key Points
# - Used for Windows-based instances in the deployment.
# - Ensures the latest base image with security updates.
# ================================================================================

data "aws_ami" "windows_ami" {
  most_recent = true
  owners      = ["amazon"]  # AWS official account

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }
}

# ================================================================================
# Optional EC2 SSH Key Pair
# --------------------------------------------------------------------------------
# Defines an SSH key pair that can be used for instance login.
#
# Notes
# - Requires a local public key file.
# - Currently disabled but retained for optional use.
# ================================================================================

# resource "aws_key_pair" "ec2_key_pair" {
#   key_name   = "ec2-key-pair"
#   public_key = file("./key.pem.pub")
# }