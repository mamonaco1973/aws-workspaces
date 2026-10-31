# ==============================================================================
# VPC — one /24 split into a public subnet for the NAT gateway and two private
# subnets for the directory, the servers and the WorkSpace
# ==============================================================================

resource "aws_vpc" "ad-vpc" {
  cidr_block           = "10.0.0.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true # private DNS names that validate.sh prints

  tags = {
    Name = var.vpc_name
  }
}

# ==============================================================================
# Outbound only — nothing in the private subnets has a public IP, but the
# servers still need the internet for apt, the AWS CLI installer and the
# Secrets Manager endpoint. Inbound access is through the WorkSpace.
# ==============================================================================

resource "aws_internet_gateway" "ad-igw" {
  vpc_id = aws_vpc.ad-vpc.id

  tags = {
    Name = "ad-ws-igw"
  }
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "ad-ws-nat-eip"
  }
}

resource "aws_nat_gateway" "ad-nat-gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.nat-subnet.id

  tags = {
    Name = "ad-ws-nat-gateway"
  }
}

# ------------------------------------------------------------------------------
# Route tables — public subnet out through the IGW, private ones via the NAT
# ------------------------------------------------------------------------------

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.ad-vpc.id

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route" "public_default_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ad-igw.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.ad-vpc.id

  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route" "private_default_route" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.ad-nat-gw.id
}

# ==============================================================================
# Subnets — pinned by AZ ID, not AZ name: AZ names are shuffled per account,
# and WorkSpaces only runs in some us-east-1 AZs (use1-az2, -az4, -az6). The
# directory's two subnets must both be in supported ones.
# ==============================================================================

# Only the NAT gateway lives here; it takes its public address from the EIP,
# so instances launched into it get none.
resource "aws_subnet" "nat-subnet" {
  vpc_id                  = aws_vpc.ad-vpc.id
  cidr_block              = "10.0.0.0/26"
  map_public_ip_on_launch = false
  availability_zone_id    = "use1-az1"

  tags = {
    Name = "nat-ws-subnet"
  }
}

resource "aws_subnet" "ad-private-subnet-1" {
  vpc_id               = aws_vpc.ad-vpc.id
  cidr_block           = "10.0.0.128/26"
  availability_zone_id = "use1-az6"

  tags = {
    Name = "ad-ws-private-subnet-1"
  }
}

resource "aws_subnet" "ad-private-subnet-2" {
  vpc_id               = aws_vpc.ad-vpc.id
  cidr_block           = "10.0.0.192/26"
  availability_zone_id = "use1-az4"

  tags = {
    Name = "ad-ws-private-subnet-2"
  }
}

resource "aws_route_table_association" "public_rta_1" {
  subnet_id      = aws_subnet.nat-subnet.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_rta_1" {
  subnet_id      = aws_subnet.ad-private-subnet-1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_rta_2" {
  subnet_id      = aws_subnet.ad-private-subnet-2.id
  route_table_id = aws_route_table.private.id
}
