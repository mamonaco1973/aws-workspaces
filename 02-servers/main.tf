# ==============================================================================
# Provider — same region as 01-directory (WorkSpaces is not in us-east-2)
# ==============================================================================

provider "aws" {
  region = "us-east-1"
}

# ==============================================================================
# Phase-1 lookups — this phase has its own state, so everything 01-directory
# created is found by name rather than through remote state
# ==============================================================================

# Secret ARNs scope the instances' read policy in roles.tf.
data "aws_secretsmanager_secret" "rpatel_secret" {
  name = "rpatel_ad_credentials_ws"
}

data "aws_secretsmanager_secret" "edavis_secret" {
  name = "edavis_ad_credentials_ws"
}

data "aws_secretsmanager_secret" "admin_secret" {
  name = "admin_ad_credentials_ws"
}

data "aws_secretsmanager_secret" "jsmith_secret" {
  name = "jsmith_ad_credentials_ws"
}

data "aws_secretsmanager_secret" "akumar_secret" {
  name = "akumar_ad_credentials_ws"
}

data "aws_vpc" "ad_vpc" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

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

# ==============================================================================
# AMIs — newest published images, so each deploy starts patched
# ==============================================================================

data "aws_ami" "ubuntu_ami" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["*ubuntu-noble-24.04-amd64-*"]
  }
}

data "aws_ami" "windows_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }
}

# ------------------------------------------------------------------------------
# Optional key pair — unused: AD users sign in with domain passwords, and the
# instances are reached from the WorkSpace, not with a key from your machine.
# Uncomment (and key_name in linux.tf/windows.tf) for break-glass access.
# ------------------------------------------------------------------------------
# resource "aws_key_pair" "ec2_key_pair" {
#   key_name   = "ec2-key-pair"
#   public_key = file("./key.pem.pub")
# }
