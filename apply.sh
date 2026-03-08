#!/bin/bash

# ================================================================================
# Workspace Apply Script
# --------------------------------------------------------------------------------
# Orchestrates the full deployment workflow for the Active Directory workspace
# environment.
#
# Workflow
# - Validate environment and required tooling
# - Deploy Active Directory infrastructure
# - Retrieve directory ID
# - Deploy EC2 infrastructure joined to the directory
# - Apply optional branding
# - Run deployment validation
# ================================================================================


# ================================================================================
# Step 0: Set AWS Region
# --------------------------------------------------------------------------------
# Sets the default AWS region for all AWS CLI and Terraform operations.
# ================================================================================

export AWS_DEFAULT_REGION=us-east-1


# ================================================================================
# Step 1: Run Environment Preflight Check
# --------------------------------------------------------------------------------
# Validates that required tools and credentials are configured correctly.
#
# Notes
# - check_env.sh should verify AWS CLI, Terraform, and required binaries.
# - Script exits immediately if validation fails.
# ================================================================================

./check_env.sh

if [ $? -ne 0 ]; then
  echo "ERROR: Environment check failed. Exiting."
  exit 1
fi

set -e  # Exit immediately if any command fails


# ================================================================================
# Step 2: Deploy Active Directory Infrastructure
# --------------------------------------------------------------------------------
# Deploys the directory services infrastructure using Terraform.
#
# Components
# - AWS Managed Microsoft Active Directory
# - VPC networking resources
# - Supporting infrastructure
# ================================================================================

cd 01-directory

terraform init
terraform apply -auto-approve

cd ..

# ================================================================================
# Step 3: Discover Directory ID
# --------------------------------------------------------------------------------
# Retrieves the directory ID for the deployed Active Directory instance.
#
# Notes
# - This ID is required by the EC2 provisioning phase.
# - Retrieved dynamically using the AWS CLI.
# ================================================================================

directory_id=$(aws ds describe-directories \
  --region us-east-1 \
  --query "DirectoryDescriptions[?Name=='mcloud.mikecloud.com'].DirectoryId" \
  --output text)


# ================================================================================
# Step 4: Deploy EC2 Infrastructure
# --------------------------------------------------------------------------------
# Launches EC2 servers and joins them to the deployed Active Directory.
#
# Inputs
# - directory_id obtained from the previous step.
# ================================================================================

cd 02-servers

terraform init
terraform apply -var="directory_id=$directory_id" -auto-approve

cd ..


# ================================================================================
# Step 5: Apply Workspace Branding
# --------------------------------------------------------------------------------
# Runs optional branding customization for the workspace environment.
#
# Notes
# - Typically used to customize logos or portal appearance.
# ================================================================================

echo "NOTE: Branding the Workspaces."
# ./brand.sh


# ================================================================================
# Step 6: Validate Deployment
# --------------------------------------------------------------------------------
# Runs the validation script to confirm that the environment deployed correctly.
# ================================================================================

./validate.sh