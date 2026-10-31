# ==============================================================================
# Linux domain member — the SSH target from the WorkSpace. No public IP; it
# joins the domain at boot (scripts/userdata.sh) so AD users can log in.
# ==============================================================================

resource "aws_instance" "linux_ad_instance" {
  ami           = data.aws_ami.ubuntu_ami.id
  instance_type = "t2.micro"
  subnet_id     = data.aws_subnet.ad_private_subnet_1.id

  vpc_security_group_ids = [
    aws_security_group.ad_ssh_sg.id
  ]

  # key_name = aws_key_pair.ec2_key_pair.key_name  # see main.tf

  # Reads the AD admin password from Secrets Manager to perform the join.
  iam_instance_profile = aws_iam_instance_profile.ec2_secrets_profile.name

  user_data = templatefile("./scripts/userdata.sh", {
    admin_secret = "admin_ad_credentials_ws"
    domain_fqdn  = var.ad_domain_name
    computers_ou = var.computers_ou
  })

  tags = {
    Name = "linux-ad-instance" # validate.sh finds the instance by this tag
  }
}
