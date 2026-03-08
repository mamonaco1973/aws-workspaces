# ================================================================================
# Unique Security Group Identifier
# --------------------------------------------------------------------------------
# Generates a unique suffix used for security group names. This prevents naming
# collisions across multiple Terraform deployments.
# ================================================================================

resource "random_id" "sg_id" {
  byte_length = 3
}

locals {
  sg_suffix = random_id.sg_id.hex
}


# ================================================================================
# RDP Security Group
# --------------------------------------------------------------------------------
# Allows Remote Desktop Protocol access to Windows instances.
#
# WARNING
# - This configuration allows unrestricted internet access (0.0.0.0/0).
# - This is NOT recommended for production environments.
# - Restrict access to trusted CIDR ranges when possible.
# ================================================================================

resource "aws_security_group" "ad_rdp_sg" {
  name        = "ad-rdp-sg-${local.sg_suffix}"
  description = "allow rdp access from the internet"
  vpc_id      = data.aws_vpc.ad_vpc.id

  # ------------------------------------------------------------------------------
  # Inbound RDP access
  # ------------------------------------------------------------------------------
  ingress {
    description = "allow rdp from anywhere"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ------------------------------------------------------------------------------
  # Allow all outbound traffic
  # ------------------------------------------------------------------------------
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# ================================================================================
# SSH Security Group
# --------------------------------------------------------------------------------
# Allows SSH access to Linux instances.
#
# WARNING
# - This rule allows access from anywhere on the internet.
# - Restrict to trusted IP ranges for production environments.
# ================================================================================

resource "aws_security_group" "ad_ssh_sg" {
  name        = "ad-ssh-sg-${local.sg_suffix}"
  description = "allow ssh access from the internet"
  vpc_id      = data.aws_vpc.ad_vpc.id

  # ------------------------------------------------------------------------------
  # Inbound SSH access
  # ------------------------------------------------------------------------------
  ingress {
    description = "allow ssh from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ------------------------------------------------------------------------------
  # Allow all outbound traffic
  # ------------------------------------------------------------------------------
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# ================================================================================
# Systems Manager Security Group
# --------------------------------------------------------------------------------
# Allows HTTPS communication required for AWS Systems Manager (SSM).
#
# Notes
# - SSM agents communicate over HTTPS (port 443).
# - Typically outbound-only communication is required.
# ================================================================================

resource "aws_security_group" "ad_ssm_sg" {
  name        = "ad-ssm-sg-${local.sg_suffix}"
  description = "allow ssm https communication"
  vpc_id      = data.aws_vpc.ad_vpc.id

  # ------------------------------------------------------------------------------
  # Inbound HTTPS access
  # ------------------------------------------------------------------------------
  ingress {
    description = "allow https for ssm"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ------------------------------------------------------------------------------
  # Allow all outbound traffic
  # ------------------------------------------------------------------------------
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}