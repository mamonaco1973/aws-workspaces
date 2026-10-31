# ==============================================================================
# Credentials — every password is generated here and kept only in Secrets
# Manager; the instances read them at boot through their IAM role, and you
# read them from the console to sign in. The _ws suffix keeps these apart
# from the parent AD lab's secrets if both are deployed in one account.
# ==============================================================================

# ------------------------------------------------------------------------------
# Directory Admin — also the WorkSpace's user
# ------------------------------------------------------------------------------

# Special characters limited to a set that survives the bash and PowerShell
# user-data scripts without quoting trouble.
resource "random_password" "admin_password" {
  length           = 24
  special          = true
  override_special = "!@#$%"
}

resource "aws_secretsmanager_secret" "admin_secret" {
  name        = "admin_ad_credentials_ws"
  description = "AD Admin Credentials"

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_secretsmanager_secret_version" "admin_secret_version" {
  secret_id = aws_secretsmanager_secret.admin_secret.id

  secret_string = jsonencode({
    username = "MCLOUD\\Admin"
    password = random_password.admin_password.result
  })
}

# ------------------------------------------------------------------------------
# Demo users — created in AD by the Windows instance's user data
# ------------------------------------------------------------------------------

# John Smith
resource "random_password" "jsmith_password" {
  length           = 24
  special          = true
  override_special = "!@#$%"
}

resource "aws_secretsmanager_secret" "jsmith_secret" {
  name        = "jsmith_ad_credentials_ws"
  description = "John Smith AD Credentials"

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_secretsmanager_secret_version" "jsmith_secret_version" {
  secret_id = aws_secretsmanager_secret.jsmith_secret.id

  secret_string = jsonencode({
    username = "MCLOUD\\jsmith"
    password = random_password.jsmith_password.result
  })
}

# Emily Davis
resource "random_password" "edavis_password" {
  length           = 24
  special          = true
  override_special = "!@#$%"
}

resource "aws_secretsmanager_secret" "edavis_secret" {
  name        = "edavis_ad_credentials_ws"
  description = "Emily Davis AD Credentials"

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_secretsmanager_secret_version" "edavis_secret_version" {
  secret_id = aws_secretsmanager_secret.edavis_secret.id

  secret_string = jsonencode({
    username = "MCLOUD\\edavis"
    password = random_password.edavis_password.result
  })
}

# Raj Patel
resource "random_password" "rpatel_password" {
  length           = 24
  special          = true
  override_special = "!@#$%"
}

resource "aws_secretsmanager_secret" "rpatel_secret" {
  name        = "rpatel_ad_credentials_ws"
  description = "Raj Patel AD Credentials"

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_secretsmanager_secret_version" "rpatel_secret_version" {
  secret_id = aws_secretsmanager_secret.rpatel_secret.id

  secret_string = jsonencode({
    username = "MCLOUD\\rpatel"
    password = random_password.rpatel_password.result
  })
}

# Amit Kumar
resource "random_password" "akumar_password" {
  length           = 24
  special          = true
  override_special = "!@#$%"
}

resource "aws_secretsmanager_secret" "akumar_secret" {
  name        = "akumar_ad_credentials_ws"
  description = "Amit Kumar AD Credentials"

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_secretsmanager_secret_version" "akumar_secret_version" {
  secret_id = aws_secretsmanager_secret.akumar_secret.id

  secret_string = jsonencode({
    username = "MCLOUD\\akumar"
    password = random_password.akumar_password.result
  })
}
