#!/bin/bash
# ==============================================================================
# brand.sh — put logo.png and a login message on every WorkSpaces client
#
# Terraform's aws_workspaces_directory has no client-branding arguments, so
# this goes through the CLI. import-client-branding overwrites, so re-running
# is safe. A failure is reported but not fatal: branding is cosmetic and
# should not stop apply.sh before validate.sh prints the registration code.
# ==============================================================================

set -euo pipefail

export AWS_DEFAULT_REGION="us-east-1"
DIRECTORY_NAME="mcloud.mikecloud.com"
LOGO_FILE="logo.png"
LOGIN_MESSAGE="@MikesCloudSolutions"

if [[ ! -f "${LOGO_FILE}" ]]; then
  echo "ERROR: File ${LOGO_FILE} not found."
  exit 1
fi

directory_id=$(aws ds describe-directories \
  --query "DirectoryDescriptions[?Name=='${DIRECTORY_NAME}'].DirectoryId" \
  --output text)

# GNU base64 wraps at 76 columns unless told -w 0; macOS takes -b 0 instead.
logo_b64=$(base64 -w 0 "${LOGO_FILE}" 2>/dev/null \
  || base64 -b 0 "${LOGO_FILE}")

# The payload carries the logo inline, too large for a command-line argument.
tmp_json=$(mktemp)
trap 'rm -f "${tmp_json}"' EXIT

branding="{\"Logo\": \"${logo_b64}\",
  \"LoginMessage\": {\"en_US\": \"${LOGIN_MESSAGE}\"}}"

cat > "${tmp_json}" <<EOF
{
  "ResourceId": "${directory_id}",
  "DeviceTypeWindows": ${branding},
  "DeviceTypeWeb": ${branding},
  "DeviceTypeIos": ${branding},
  "DeviceTypeAndroid": ${branding},
  "DeviceTypeLinux": ${branding},
  "DeviceTypeOsx": ${branding}
}
EOF

echo "NOTE: Uploading branding to all client types..."

if aws workspaces import-client-branding \
     --cli-input-json "file://${tmp_json}" >/dev/null; then
  echo "NOTE: Branding applied successfully to all clients."
else
  echo "ERROR: Failed to apply branding."
fi
