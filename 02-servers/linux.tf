# ================================================================================
# Linux EC2 Instance
# --------------------------------------------------------------------------------
# Deploys a Linux instance used for Active Directory integration testing.
#
# Key Points
# - Uses the latest Ubuntu AMI discovered via a data source.
# - Deployed into a private subnet.
# - Uses IAM instance profile for secure AWS API access.
# - Bootstrapped with a user-data script that joins the AD domain.
# ================================================================================

resource "aws_instance" "linux_ad_instance" {

  # ------------------------------------------------------------------------------
  # AMI Configuration
  # ------------------------------------------------------------------------------
  # Uses the Ubuntu AMI discovered dynamically via the aws_ami data source.
  # ------------------------------------------------------------------------------
  ami = data.aws_ami.ubuntu_ami.id

  # ------------------------------------------------------------------------------
  # Instance Type
  # ------------------------------------------------------------------------------
  # Defines the compute resources for the instance.
  # ------------------------------------------------------------------------------
  instance_type = "t2.micro"

  # ------------------------------------------------------------------------------
  # Network Placement
  # ------------------------------------------------------------------------------
  # Deploys the instance into the private AD subnet.
  # ------------------------------------------------------------------------------
  subnet_id = data.aws_subnet.ad_private_subnet_1.id

  # ------------------------------------------------------------------------------
  # Security Groups
  # ------------------------------------------------------------------------------
  # Applies security groups required for instance management.
  #
  # ad_ssh_sg
  # - Allows inbound SSH access.
  #
  # ad_ssm_sg
  # - Allows AWS Systems Manager connectivity.
  # ------------------------------------------------------------------------------
  vpc_security_group_ids = [
    aws_security_group.ad_ssh_sg.id,
    aws_security_group.ad_ssm_sg.id
  ]

  # ------------------------------------------------------------------------------
  # SSH Key Pair
  # ------------------------------------------------------------------------------
  # Optional SSH key used for direct login access.
  # ------------------------------------------------------------------------------
  # key_name = aws_key_pair.ec2_key_pair.key_name

  # ------------------------------------------------------------------------------
  # IAM Instance Profile
  # ------------------------------------------------------------------------------
  # Grants the instance permission to access AWS services such as:
  # - Secrets Manager
  # - S3
  # - Systems Manager
  # ------------------------------------------------------------------------------
  iam_instance_profile = aws_iam_instance_profile.ec2_secrets_profile.name

  # ------------------------------------------------------------------------------
  # User Data Bootstrap Script
  # ------------------------------------------------------------------------------
  # Executes a startup script that configures the instance at boot time.
  #
  # Template Variables
  # - admin_secret : Secrets Manager secret containing AD admin credentials
  # - domain_fqdn  : Active Directory domain name
  # - computers_ou : AD Organizational Unit for computer objects
  # ------------------------------------------------------------------------------
  user_data = templatefile("./scripts/userdata.sh", {
    admin_secret = "admin_ad_credentials_ws"
    domain_fqdn  = "mcloud.mikecloud.com"
    computers_ou = "OU=Computers,OU=MCLOUD,DC=mcloud,DC=mikecloud,DC=com"
  })

  # ------------------------------------------------------------------------------
  # Resource Tags
  # ------------------------------------------------------------------------------
  # Used for identification and resource organization.
  # ------------------------------------------------------------------------------
  tags = {
    Name = "linux-ad-instance"
  }
}