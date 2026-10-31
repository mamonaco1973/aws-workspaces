#!/bin/bash
# ==============================================================================
# apply.sh — deploy the WorkSpaces lab in two Terraform phases
#
# Phase 2 needs the directory ID that phase 1 creates, so it is looked up by
# name between the phases rather than passed through remote state. Re-running
# is safe: both phases are plain terraform apply and brand.sh overwrites.
# ==============================================================================

set -euo pipefail

# WorkSpaces is not offered in us-east-2, the region the parent AD lab uses.
export AWS_DEFAULT_REGION="us-east-1"
DIRECTORY_NAME="mcloud.mikecloud.com"

./check_env.sh

# ------------------------------------------------------------------------------
# Phase 1: network, secrets and AWS Managed Microsoft AD (30-60 minutes)
# ------------------------------------------------------------------------------
echo "NOTE: Deploying the network and the managed directory..."

cd 01-directory
terraform init
terraform apply -auto-approve
cd ..

directory_id=$(aws ds describe-directories \
  --query "DirectoryDescriptions[?Name=='${DIRECTORY_NAME}'].DirectoryId" \
  --output text)

if [ -z "${directory_id}" ] || [ "${directory_id}" = "None" ]; then
  echo "ERROR: Directory ${DIRECTORY_NAME} not found after phase 1."
  exit 1
fi

# ------------------------------------------------------------------------------
# Phase 2: domain members, WorkSpaces registration and the Admin WorkSpace
# ------------------------------------------------------------------------------
echo "NOTE: Deploying the servers and the WorkSpace..."

cd 02-servers
terraform init
terraform apply -var="directory_id=${directory_id}" -auto-approve
cd ..

echo "NOTE: Branding the WorkSpaces clients."
./brand.sh

./validate.sh
