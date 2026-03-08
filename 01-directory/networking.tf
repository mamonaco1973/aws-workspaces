# ================================================================================
# VPC
# --------------------------------------------------------------------------------
# Creates the project VPC used by the Active Directory environment.
#
# Key Points
# - Uses a /24 CIDR block.
# - Enables DNS support and DNS hostnames.
# - Hosts public and private subnets for the deployment.
# ================================================================================

resource "aws_vpc" "ad-vpc" {
  cidr_block           = "10.0.0.0/24"  # Project VPC CIDR
  enable_dns_support   = true           # Enable internal DNS resolution
  enable_dns_hostnames = true           # Enable instance DNS hostnames

  tags = {
    Name = var.vpc_name
  }
}

# ================================================================================
# Internet Gateway
# --------------------------------------------------------------------------------
# Creates the internet gateway used by the public subnet.
# ================================================================================

resource "aws_internet_gateway" "ad-igw" {
  vpc_id = aws_vpc.ad-vpc.id  # Attach to project VPC

  tags = {
    Name = "ad-ws-igw"
  }
}

# ================================================================================
# NAT Gateway Elastic IP
# --------------------------------------------------------------------------------
# Allocates the public Elastic IP used by the NAT gateway.
# ================================================================================

resource "aws_eip" "nat_eip" {
  domain = "vpc"  # Allocate EIP for VPC use

  tags = {
    Name = "ad-ws-nat-eip"
  }
}

# ================================================================================
# NAT Gateway
# --------------------------------------------------------------------------------
# Creates the NAT gateway used by private subnets for outbound internet access.
#
# Key Points
# - Deployed in the public NAT subnet.
# - Uses the allocated Elastic IP.
# - Provides egress only for private subnet resources.
# ================================================================================

resource "aws_nat_gateway" "ad-nat-gw" {
  allocation_id = aws_eip.nat_eip.id      # NAT gateway public IP
  subnet_id     = aws_subnet.nat-subnet.id  # Public subnet placement

  tags = {
    Name = "ad-ws-nat-gateway"
  }
}

# ================================================================================
# Public Route Table
# --------------------------------------------------------------------------------
# Route table for the public subnet.
# ================================================================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.ad-vpc.id  # Associate with project VPC

  tags = {
    Name = "public-route-table"
  }
}

# ------------------------------------------------------------------------------
# Default route for public subnet
# ------------------------------------------------------------------------------
resource "aws_route" "public_default_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"                  # Default route
  gateway_id             = aws_internet_gateway.ad-igw.id
}

# ================================================================================
# Private Route Table
# --------------------------------------------------------------------------------
# Route table for private subnets.
# ================================================================================

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.ad-vpc.id  # Associate with project VPC

  tags = {
    Name = "private-route-table"
  }
}

# ------------------------------------------------------------------------------
# Default route for private subnets
# ------------------------------------------------------------------------------
resource "aws_route" "private_default_route" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"                  # Default route
  nat_gateway_id         = aws_nat_gateway.ad-nat-gw.id
}

# ================================================================================
# Public NAT Subnet
# --------------------------------------------------------------------------------
# Creates the public subnet that hosts the NAT gateway.
#
# Notes
# - This subnet uses the first /26 block in the VPC.
# - It is associated with the public route table.
# ================================================================================

resource "aws_subnet" "nat-subnet" {
  vpc_id                  = aws_vpc.ad-vpc.id
  cidr_block              = "10.0.0.0/26"   # Public subnet CIDR
  map_public_ip_on_launch = false           # Do not auto-assign public IPs
  availability_zone_id    = "use1-az1"      # Availability Zone

  tags = {
    Name = "nat-ws-subnet"
  }
}

# ================================================================================
# Private Subnet 1
# --------------------------------------------------------------------------------
# Creates the first private subnet used by internal resources.
# ================================================================================

resource "aws_subnet" "ad-private-subnet-1" {
  vpc_id               = aws_vpc.ad-vpc.id
  cidr_block           = "10.0.0.128/26"  # Private subnet 1 CIDR
  availability_zone_id = "use1-az6"       # Availability Zone

  tags = {
    Name = "ad-ws-private-subnet-1"
  }
}

# ================================================================================
# Private Subnet 2
# --------------------------------------------------------------------------------
# Creates the second private subnet used by internal resources.
# ================================================================================

resource "aws_subnet" "ad-private-subnet-2" {
  vpc_id               = aws_vpc.ad-vpc.id
  cidr_block           = "10.0.0.192/26"  # Private subnet 2 CIDR
  availability_zone_id = "use1-az4"       # Availability Zone

  tags = {
    Name = "ad-ws-private-subnet-2"
  }
}

# ================================================================================
# Route Table Associations
# --------------------------------------------------------------------------------
# Associates each subnet with the correct route table.
# ================================================================================

# ------------------------------------------------------------------------------
# Associate public NAT subnet with public route table
# ------------------------------------------------------------------------------
resource "aws_route_table_association" "public_rta_1" {
  subnet_id      = aws_subnet.nat-subnet.id
  route_table_id = aws_route_table.public.id
}

# ------------------------------------------------------------------------------
# Associate private subnet 1 with private route table
# ------------------------------------------------------------------------------
resource "aws_route_table_association" "private_rta_1" {
  subnet_id      = aws_subnet.ad-private-subnet-1.id
  route_table_id = aws_route_table.private.id
}

# ------------------------------------------------------------------------------
# Associate private subnet 2 with private route table
# ------------------------------------------------------------------------------
resource "aws_route_table_association" "private_rta_2" {
  subnet_id      = aws_subnet.ad-private-subnet-2.id
  route_table_id = aws_route_table.private.id
}