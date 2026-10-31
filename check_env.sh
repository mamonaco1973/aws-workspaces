#!/bin/bash
# ==============================================================================
# check_env.sh — preflight: required tools on PATH and working AWS credentials
#
# Run by apply.sh before anything is created, so a missing tool fails in
# seconds instead of halfway through a 60-minute directory build.
# ==============================================================================

set -euo pipefail

echo "NOTE: Validating required commands in PATH."

for cmd in aws terraform; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "ERROR: Required command not found: ${cmd}"
    exit 1
  fi
  echo "NOTE: Found required command: ${cmd}"
done

echo "NOTE: Verifying AWS CLI connectivity..."

if ! aws sts get-caller-identity --query "Account" --output text >/dev/null
then
  echo "ERROR: Failed to connect to AWS."
  echo "ERROR: Verify credentials and environment configuration."
  exit 1
fi

echo "NOTE: AWS CLI authentication successful."
