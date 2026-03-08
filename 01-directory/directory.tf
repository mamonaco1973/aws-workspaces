# ================================================================================
# AWS Managed Microsoft Active Directory
# --------------------------------------------------------------------------------
# Deploys an AWS Managed Microsoft AD directory and integrates it with the
# project VPC.
#
# Key Points
# - Uses the generated Admin password from accounts.tf.
# - Deploys MicrosoftAD in two private subnets for high availability.
# - Configures the NetBIOS short name for domain logon compatibility.
# ================================================================================

# ------------------------------------------------------------------------------
# AWS Managed Microsoft AD directory
# ------------------------------------------------------------------------------
resource "aws_directory_service_directory" "ad_directory" {
  name        = "mcloud.mikecloud.com"            # Directory FQDN
  password    = random_password.admin_password.result
  edition     = "Standard"                        # Directory edition
  type        = "MicrosoftAD"                     # Managed Microsoft AD
  short_name  = "MCLOUD"                          # NetBIOS domain name
  description = "mikecloud.com example for youtube channel"

  # ----------------------------------------------------------------------------
  # VPC placement
  # ----------------------------------------------------------------------------
  # Deploys the directory controllers into two private subnets in the project
  # VPC.
  # ----------------------------------------------------------------------------
  vpc_settings {
    vpc_id = aws_vpc.ad-vpc.id

    subnet_ids = [
      aws_subnet.ad-private-subnet-1.id,
      aws_subnet.ad-private-subnet-2.id
    ]
  }

  tags = {
    Name = "mikecloud"
  }
}

# ================================================================================
# VPC DHCP Options for Active Directory
# --------------------------------------------------------------------------------
# Configures the VPC to use the directory DNS servers returned by AWS Managed
# Microsoft AD.
#
# Key Points
# - Domain-joined instances use the AD DNS servers automatically.
# - DHCP options are applied at the VPC level.
# ================================================================================

# ------------------------------------------------------------------------------
# DHCP options set for AD DNS
# ------------------------------------------------------------------------------
resource "aws_vpc_dhcp_options" "ad_dhcp_options" {
  domain_name         = "mikecloud.com"   # DNS suffix for the VPC
  domain_name_servers = aws_directory_service_directory.ad_directory.dns_ip_addresses                                 

  tags = {
    Name = "ad-ws-dhcp-options"
  }
}

# ------------------------------------------------------------------------------
# Associate DHCP options set with the VPC
# ------------------------------------------------------------------------------
resource "aws_vpc_dhcp_options_association" "ad_dhcp_association" {
  vpc_id          = aws_vpc.ad-vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.ad_dhcp_options.id
}