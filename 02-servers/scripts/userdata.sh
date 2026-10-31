#!/bin/bash
# ==============================================================================
# Linux domain member — joins mcloud.mikecloud.com with realm and SSSD so AD
# users can SSH in with their domain passwords from the WorkSpace.
#
# Rendered by Terraform templatefile(), which fills its dollar-brace
# placeholders at plan time, so shell variables use the bare $VAR form only.
# Idempotent: the join, the sed edits and the sudoers file all check first.
# ==============================================================================

set -euo pipefail

LOG=/root/userdata.log
touch "$LOG"
chmod 600 "$LOG"
exec > >(tee -a "$LOG" | logger -t user-data -s 2>/dev/console) 2>&1
trap 'echo "ERROR at line $LINENO"; exit 1' ERR

echo "user-data start: $(date -Is)"

ADMIN_SECRET="${admin_secret}"
DOMAIN_FQDN="${domain_fqdn}"
COMPUTERS_OU="${computers_ou}"

# ------------------------------------------------------------------------------
# Packages — realmd/SSSD for the join, oddjob-mkhomedir so first login gets a
# home directory, jq to read the secret
# ------------------------------------------------------------------------------
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y \
  less unzip curl jq \
  realmd sssd-ad sssd-tools libnss-sss libpam-sss \
  adcli samba-common-bin samba-libs \
  oddjob oddjob-mkhomedir packagekit krb5-user \
  nano vim

# The Ubuntu image has no AWS CLI; it is needed to read the join password.
cd /tmp
curl -s https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip
unzip -q awscliv2.zip
./aws/install --update
rm -rf awscliv2.zip aws

# ------------------------------------------------------------------------------
# Domain join — the password comes from Secrets Manager via the instance
# role, so it never appears in user data or Terraform state for this phase
# ------------------------------------------------------------------------------
SECRET_JSON="$(aws secretsmanager get-secret-value \
  --secret-id "$ADMIN_SECRET" \
  --query SecretString \
  --output text)"

ADMIN_PASSWORD="$(echo "$SECRET_JSON" | jq -r '.password')"
# Stored as MCLOUD\Admin; realm wants the bare name.
ADMIN_USERNAME="$(echo "$SECRET_JSON" | jq -r '.username' | sed 's/.*\\//')"

if ! realm list | grep -qi "$DOMAIN_FQDN"; then
  echo "$ADMIN_PASSWORD" | realm join -U "$ADMIN_USERNAME" "$DOMAIN_FQDN" \
    --computer-ou="$COMPUTERS_OU" --verbose >> /root/join.log 2>&1
fi

# ------------------------------------------------------------------------------
# SSH and SSSD — AD users sign in with passwords, by short name, and get the
# uidNumber/gidNumber set in AD rather than SSSD's hashed IDs
# ------------------------------------------------------------------------------
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' \
  /etc/ssh/sshd_config.d/60-cloudimg-settings.conf

sed -i 's/use_fully_qualified_names = True/use_fully_qualified_names = False/g' \
  /etc/sssd/sssd.conf
sed -i 's/ldap_id_mapping = True/ldap_id_mapping = False/g' /etc/sssd/sssd.conf
sed -i 's|fallback_homedir = /home/%u@%d|fallback_homedir = /home/%u|' \
  /etc/sssd/sssd.conf

# An empty .Xauthority in skel stops the "file does not exist" warning on
# the first X-forwarded login.
touch /etc/skel/.Xauthority
chmod 600 /etc/skel/.Xauthority

pam-auth-update --enable mkhomedir
systemctl restart sssd
systemctl restart ssh

# ------------------------------------------------------------------------------
# Sudo for the AD linux-admins group
# ------------------------------------------------------------------------------
SUDO_FILE=/etc/sudoers.d/10-linux-admins
if [ ! -f "$SUDO_FILE" ]; then
  echo "%linux-admins ALL=(ALL) NOPASSWD:ALL" > "$SUDO_FILE"
  chmod 440 "$SUDO_FILE"
fi

echo "user-data complete: $(date -Is)"
