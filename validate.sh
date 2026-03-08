#!/bin/bash

# ================================================================================
# AWS Region
# --------------------------------------------------------------------------------
# Sets the default AWS region for all CLI calls in this script.
# ================================================================================

export AWS_DEFAULT_REGION=us-east-1


# ================================================================================
# WorkSpaces Registration Code
# --------------------------------------------------------------------------------
# Retrieves the registration code for the target WorkSpaces directory.
# ================================================================================

regcode=$(aws workspaces describe-workspace-directories \
  --region us-east-1 \
  --query "Directories[?DirectoryName=='mcloud.mikecloud.com'].RegistrationCode" \
  --output text)


# ================================================================================
# Windows AD Instance Private DNS
# --------------------------------------------------------------------------------
# Looks up the private DNS name for the Windows AD instance.
# Only instances in the running state are returned.
# ================================================================================

windows_dns_name=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=windows-ad-instance" \
            "Name=instance-state-name,Values=running" \
  --query "Reservations[*].Instances[*].PrivateDnsName" \
  --output text)


# ================================================================================
# Linux AD Instance Private DNS
# --------------------------------------------------------------------------------
# Looks up the private DNS name for the Linux AD instance.
# Only instances in the running state are returned.
# ================================================================================

linux_dns_name=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=linux-ad-instance" \
            "Name=instance-state-name,Values=running" \
  --query "Reservations[*].Instances[*].PrivateDnsName" \
  --output text)


# ------------------------------------------------------------------------------
# Final Quick Start Output
# ------------------------------------------------------------------------------

echo ""
echo "============================================================================"
echo "WorkSpaces Quick Start - Validation Output"
echo "============================================================================"
echo ""

if [ -n "${regcode}" ] && [ "${regcode}" != "None" ]; then
  echo "NOTE: WorkSpaces Registration Code: ${regcode}"
end

echo "NOTE: WorkSpaces URL: https://us-east-1.webclient.amazonworkspaces.com/login"

echo ""

if [ -n "${windows_dns_name}" ] && [ "${windows_dns_name}" != "None" ]; then
  echo "NOTE: Windows instance: ${windows_dns_name}"
else
  echo "WARN: Windows instance not found or not running"
fi

if [ -n "${linux_dns_name}" ] && [ "${linux_dns_name}" != "None" ]; then
  echo "NOTE: Linux instance:   ${linux_dns_name}"
else
  echo "WARN: Linux instance not found or not running"
fi

