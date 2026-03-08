# ================================================================================
# AWS Provider Configuration
# --------------------------------------------------------------------------------
# Configures the AWS provider used by this Terraform project.
#
# Key Points
# - Sets the default AWS region for all resources in this configuration.
# - Resources will be deployed to us-east-1 unless overridden elsewhere.
# ================================================================================

provider "aws" {
  region = "us-east-1"  # Default AWS region
}