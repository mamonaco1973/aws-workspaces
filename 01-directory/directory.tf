# ==============================================================================
# AWS Managed Microsoft AD — the domain WorkSpaces authenticates against and
# the two servers join. Standard edition is the cheapest that WorkSpaces
# accepts; creation takes 30 to 60 minutes.
# ==============================================================================

resource "aws_directory_service_directory" "ad_directory" {
  name        = var.ad_domain_name
  password    = random_password.admin_password.result
  edition     = "Standard"
  type        = "MicrosoftAD"
  short_name  = var.netbios
  description = "mikecloud.com example for youtube channel"

  # Two subnets in different AZs are required: one domain controller in each.
  # Both must also be AZs where WorkSpaces runs (see networking.tf).
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

# ==============================================================================
# DHCP options — point the whole VPC's DNS at the domain controllers so the
# instances (and the WorkSpace) can resolve and join the domain
# ==============================================================================

resource "aws_vpc_dhcp_options" "ad_dhcp_options" {
  domain_name         = "mikecloud.com"
  domain_name_servers = aws_directory_service_directory.ad_directory.dns_ip_addresses

  tags = {
    Name = "ad-ws-dhcp-options"
  }
}

resource "aws_vpc_dhcp_options_association" "ad_dhcp_association" {
  vpc_id          = aws_vpc.ad-vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.ad_dhcp_options.id
}
