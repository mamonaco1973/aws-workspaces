# ================================================================================
# Terraform Variables
# --------------------------------------------------------------------------------
# Defines configurable inputs used by the Active Directory deployment.
#
# Key Points
# - Allows domain and network settings to be customized.
# - Defaults are provided for quick start deployments.
# - Values can be overridden using tfvars or CLI variables.
# ================================================================================


# ================================================================================
# Active Directory Domain Configuration
# --------------------------------------------------------------------------------
# Variables used to configure the Microsoft Active Directory deployment.
# ================================================================================

# ------------------------------------------------------------------------------
# Active Directory FQDN
# ------------------------------------------------------------------------------
variable "ad_domain_name" {
  description = "Fully qualified domain name (FQDN) for Microsoft AD"
  type        = string
  default     = "mcloud.mikecloud.com"
}

# ------------------------------------------------------------------------------
# NetBIOS Domain Name
# ------------------------------------------------------------------------------
variable "netbios" {
  description = "NetBIOS short name for the AD domain"
  type        = string
  default     = "MCLOUD"
}


# ================================================================================
# Networking Configuration
# --------------------------------------------------------------------------------
# Variables used for VPC naming and network identification.
# ================================================================================

# ------------------------------------------------------------------------------
# VPC Name
# ------------------------------------------------------------------------------
variable "vpc_name" {
  description = "Name tag assigned to the Active Directory VPC"
  type        = string
  default     = "ad-ws-vpc"
}