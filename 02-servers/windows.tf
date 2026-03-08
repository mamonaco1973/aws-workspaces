# ================================================================================
# Windows EC2 Instance
# --------------------------------------------------------------------------------
# Deploys a Windows Server instance that integrates with the Active Directory
# environment.
#
# Key Points
# - Uses the latest Windows Server 2022 AMI discovered via a data source.
# - Deployed into a private subnet within the AD VPC.
# - Bootstrapped using a PowerShell user-data script.
# - Uses IAM instance profile to access AWS Secrets Manager.
# ================================================================================

resource "aws_instance" "windows_ad_instance" {

  # ------------------------------------------------------------------------------
  # AMI Configuration
  # ------------------------------------------------------------------------------
  # Uses the Windows Server AMI discovered dynamically via the aws_ami
  # data source. This ensures the latest available Windows image is used.
  # ------------------------------------------------------------------------------
  ami = data.aws_ami.windows_ami.id

  # ------------------------------------------------------------------------------
  # Instance Type
  # ------------------------------------------------------------------------------
  # Defines the compute resources for the instance.
  #
  # Windows requires more memory and CPU than Linux instances, therefore a
  # larger instance type is used.
  # ------------------------------------------------------------------------------
  instance_type = "t2.medium"

  # ------------------------------------------------------------------------------
  # Network Placement
  # ------------------------------------------------------------------------------
  # Deploys the instance into the second private subnet of the AD VPC.
  # ------------------------------------------------------------------------------
  subnet_id = data.aws_subnet.ad_private_subnet_2.id

  # ------------------------------------------------------------------------------
  # Security Groups
  # ------------------------------------------------------------------------------
  # Applies security groups required for Windows administration and management.
  #
  # ad_rdp_sg
  # - Allows Remote Desktop access for Windows administration.
  #
  # ad_ssm_sg
  # - Allows AWS Systems Manager connectivity.
  # ------------------------------------------------------------------------------
  vpc_security_group_ids = [
    aws_security_group.ad_rdp_sg.id
  ]

  # ------------------------------------------------------------------------------
  # SSH / RDP Key Pair
  # ------------------------------------------------------------------------------
  # Optional EC2 key pair used for secure administrative access.
  #
  # For Windows instances this key may be used to decrypt the RDP password.
  # ------------------------------------------------------------------------------
  # key_name = aws_key_pair.ec2_key_pair.key_name

  # ------------------------------------------------------------------------------
  # IAM Instance Profile
  # ------------------------------------------------------------------------------
  # Grants the instance permission to access AWS services such as:
  #
  # - AWS Secrets Manager
  # - AWS Systems Manager
  # - Other AWS APIs required during instance initialization
  # ------------------------------------------------------------------------------
  iam_instance_profile = aws_iam_instance_profile.ec2_secrets_profile.name

  # ------------------------------------------------------------------------------
  # User Data Bootstrap Script
  # ------------------------------------------------------------------------------
  # Executes a PowerShell startup script during the first boot.
  #
  # Template Variables
  # - admin_secret : Secrets Manager secret containing AD admin credentials
  # - domain_fqdn  : Active Directory domain name
  # - computers_ou : Organizational Unit where computer objects are created
  # ------------------------------------------------------------------------------
  user_data = templatefile("./scripts/userdata.ps1", {
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
    Name = "windows-ad-instance"
  }
}