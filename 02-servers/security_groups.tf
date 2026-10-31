# ==============================================================================
# Security groups — RDP to the Windows server, SSH to the Linux one
#
# The rules say 0.0.0.0/0, but neither instance has a public IP and the
# subnets have no inbound route, so in practice only sources inside the VPC
# (the WorkSpace) can reach them. The descriptions below predate the move to
# private subnets; they are left as-is because changing a security group's
# description forces Terraform to replace it.
# ==============================================================================

# Random suffix so the names don't collide with another deployment's groups.
resource "random_id" "sg_id" {
  byte_length = 3
}

locals {
  sg_suffix = random_id.sg_id.hex
}

resource "aws_security_group" "ad_rdp_sg" {
  name        = "ad-rdp-sg-${local.sg_suffix}"
  description = "allow rdp access from the internet"
  vpc_id      = data.aws_vpc.ad_vpc.id

  ingress {
    description = "allow rdp from anywhere"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ad_ssh_sg" {
  name        = "ad-ssh-sg-${local.sg_suffix}"
  description = "allow ssh access from the internet"
  vpc_id      = data.aws_vpc.ad_vpc.id

  ingress {
    description = "allow ssh from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
