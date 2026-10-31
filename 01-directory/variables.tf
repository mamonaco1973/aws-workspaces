# ==============================================================================
# Inputs — defaults match the parent AD lab so the same domain, users and
# scripts carry over unchanged
# ==============================================================================

variable "ad_domain_name" {
  description = "Fully qualified domain name (FQDN) for Microsoft AD"
  type        = string
  default     = "mcloud.mikecloud.com"
}

variable "netbios" {
  description = "NetBIOS short name for the AD domain"
  type        = string
  default     = "MCLOUD"
}

# 02-servers finds the VPC by this Name tag, so the two must agree.
variable "vpc_name" {
  description = "Name tag assigned to the Active Directory VPC"
  type        = string
  default     = "ad-ws-vpc"
}
