#!/bin/bash
# ==============================================================================
# destroy.sh — tear the lab down in reverse order
#
# The WorkSpace and servers go first: the directory cannot be deleted while
# WorkSpaces still has it registered. Safe to re-run after a partial destroy.
# ==============================================================================

set -euo pipefail

export AWS_DEFAULT_REGION="us-east-1"
DIRECTORY_NAME="mcloud.mikecloud.com"

# 02-servers declares directory_id without a default, so destroy needs it too.
directory_id=$(aws ds describe-directories \
  --query "DirectoryDescriptions[?Name=='${DIRECTORY_NAME}'].DirectoryId" \
  --output text)

# ------------------------------------------------------------------------------
# Phase 1: WorkSpace, registration and servers
# ------------------------------------------------------------------------------
cd 02-servers
terraform init
terraform destroy -var="directory_id=${directory_id}" -auto-approve
cd ..

# ------------------------------------------------------------------------------
# Phase 2: secrets — force-deleted so a redeploy can reuse the names at once
# instead of waiting out the 7-30 day recovery window
# ------------------------------------------------------------------------------
for secret in akumar jsmith edavis rpatel admin; do
  # A secret already deleted by an earlier run must not stop the teardown.
  aws secretsmanager delete-secret \
    --secret-id "${secret}_ad_credentials_ws" \
    --force-delete-without-recovery >/dev/null \
    || echo "WARN: ${secret}_ad_credentials_ws not deleted (already gone?)"
done

# ------------------------------------------------------------------------------
# Phase 3: managed directory and network
# ------------------------------------------------------------------------------
cd 01-directory
terraform init
terraform destroy -auto-approve
cd ..
