# ==============================================================================
# Windows domain member — the RDP target from the WorkSpace, and the machine
# that creates the lab's AD groups and users (scripts/userdata.ps1), since a
# managed directory gives no shell on its domain controllers
# ==============================================================================

resource "aws_instance" "windows_ad_instance" {
  ami = data.aws_ami.windows_ami.id

  # Windows Server with RSAT is sluggish on less than 4 GiB.
  instance_type = "t2.medium"
  subnet_id     = data.aws_subnet.ad_private_subnet_2.id

  vpc_security_group_ids = [
    aws_security_group.ad_rdp_sg.id
  ]

  # key_name = aws_key_pair.ec2_key_pair.key_name  # see main.tf

  # Reads the admin and per-user passwords from Secrets Manager.
  iam_instance_profile = aws_iam_instance_profile.ec2_secrets_profile.name

  user_data = templatefile("./scripts/userdata.ps1", {
    admin_secret = "admin_ad_credentials_ws"
    domain_fqdn  = var.ad_domain_name
    computers_ou = var.computers_ou
  })

  tags = {
    Name = "windows-ad-instance" # validate.sh finds the instance by this tag
  }
}
