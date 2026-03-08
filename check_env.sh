#!/bin/bash

# ================================================================================
# Environment Validation Script
# --------------------------------------------------------------------------------
# Performs a preflight validation of the local environment before running the
# Terraform deployment.
#
# Validation Checks
# - Required command line tools exist in PATH
# - AWS CLI credentials are configured and working
#
# This script should be executed before any infrastructure deployment.
# ================================================================================


# ================================================================================
# Check Required Commands
# --------------------------------------------------------------------------------
# Verifies that required binaries are available in the system PATH.
#
# Required Tools
# - aws        : AWS CLI used for environment checks and automation
# - terraform  : Infrastructure as Code deployment tool
# ================================================================================

echo "NOTE: Validating that required commands are found in your PATH."

commands=("aws" "terraform")  # Required binaries

all_found=true                # Tracks command validation state

# ------------------------------------------------------------------------------
# Iterate through required commands
# ------------------------------------------------------------------------------
for cmd in "${commands[@]}"; do

  # Check if command exists in PATH
  if ! command -v "$cmd" &> /dev/null; then
    echo "ERROR: $cmd is not found in the current PATH."
    all_found=false
  else
    echo "NOTE: $cmd is found in the current PATH."
  fi

done


# ================================================================================
# Command Validation Result
# --------------------------------------------------------------------------------
# Stops execution if required tools are missing.
# ================================================================================

if [ "$all_found" = true ]; then
  echo "NOTE: All required commands are available."
else
  echo "ERROR: One or more commands are missing."
  exit 1
fi


# ================================================================================
# Validate AWS CLI Connectivity
# --------------------------------------------------------------------------------
# Confirms that AWS credentials are configured and the CLI can authenticate.
#
# Method
# - Calls STS get-caller-identity
# - Returns the account ID if authentication succeeds
# ================================================================================

echo "NOTE: Checking AWS CLI connection."

aws sts get-caller-identity \
  --query "Account" \
  --output text >> /dev/null


# ------------------------------------------------------------------------------
# Check authentication result
# ------------------------------------------------------------------------------
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to connect to AWS."
  echo "ERROR: Verify credentials and environment configuration."
  exit 1
else
  echo "NOTE: Successfully logged into AWS."
fi