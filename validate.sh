#!/bin/bash
# ==============================================================================
# validate.sh — print what you need to try the lab
#
# The registration code is what the WorkSpaces client asks for first; the
# instances have only private IPs, reachable only from inside the WorkSpace.
# ==============================================================================

set -euo pipefail

export AWS_DEFAULT_REGION="us-east-1"
DIRECTORY_NAME="mcloud.mikecloud.com"
WEB_CLIENT_URL="https://us-east-1.webclient.amazonworkspaces.com/login"

get_private_ip_by_name_tag() {
  aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$1" \
              "Name=instance-state-name,Values=running" \
    --query "Reservations[].Instances[].PrivateIpAddress" \
    --output text | xargs
}

regcode=$(aws workspaces describe-workspace-directories \
  --query "Directories[?DirectoryName=='${DIRECTORY_NAME}'].RegistrationCode" \
  --output text)
get_secret() {
  aws secretsmanager get-secret-value --secret-id "$1" \
    --query SecretString --output text
}

admin=$(get_secret admin_ad_credentials_ws)
admin_user=$(echo "${admin}" | jq -r .username)
admin_password=$(echo "${admin}" | jq -r .password)
jsmith=$(get_secret jsmith_ad_credentials_ws)
jsmith_user=$(echo "${jsmith}" | jq -r .username)
jsmith_password=$(echo "${jsmith}" | jq -r .password)
windows_ip=$(get_private_ip_by_name_tag "windows-ad-instance")
linux_ip=$(get_private_ip_by_name_tag "linux-ad-instance")

echo ""
echo "============================================================================"
echo "WorkSpaces - Validation Output"
echo "============================================================================"
echo ""

if [ -n "${regcode}" ] && [ "${regcode}" != "None" ]; then
  printf "NOTE: %-28s %s\n" "WorkSpaces Registration Code:" "${regcode}"
fi

printf "NOTE: %-28s %s\n" "WorkSpaces URL:" "${WEB_CLIENT_URL}"
echo ""
printf "NOTE: %-28s %s\n" "Admin user (WorkSpace):" "${admin_user}"
printf "NOTE: %-28s %s\n" "Admin password:" "${admin_password}"
echo ""
printf "NOTE: %-28s %s\n" "Test user:" "${jsmith_user}"
printf "NOTE: %-28s %s\n" "Test user password:" "${jsmith_password}"
echo ""

if [ -n "${windows_ip}" ] && [ "${windows_ip}" != "None" ]; then
  printf "NOTE: %-28s %s\n" "Windows instance:" "${windows_ip}"
else
  printf "WARN: %-28s %s\n" "Windows instance:" "not found or not running"
fi

if [ -n "${linux_ip}" ] && [ "${linux_ip}" != "None" ]; then
  printf "NOTE: %-28s %s\n" "Linux instance:" "${linux_ip}"
else
  printf "WARN: %-28s %s\n" "Linux instance:" "not found or not running"
fi

echo ""
