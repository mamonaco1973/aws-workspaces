# ==============================================================================
# Inputs — must match what 01-directory created
# ==============================================================================

# No default: apply.sh looks the ID up after phase 1 and passes it in.
variable "directory_id" {
  description = "The ID of the AWS Directory Service directory"
  type        = string
}

variable "ad_domain_name" {
  description = "Fully qualified domain name (FQDN) for Microsoft AD"
  type        = string
  default     = "mcloud.mikecloud.com"
}

# AWS Managed AD only delegates this OU to the Admin account, so joins
# must place computer objects here rather than in the default container.
variable "computers_ou" {
  description = "Computers OU for the join"
  type        = string
  default     = "OU=Computers,OU=MCLOUD,DC=mcloud,DC=mikecloud,DC=com"
}

variable "vpc_name" {
  description = "Name tag assigned to the Active Directory VPC"
  type        = string
  default     = "ad-ws-vpc"
}
