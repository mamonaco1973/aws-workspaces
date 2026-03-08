# ================================================================================
# Active Directory Administrator Credentials
# --------------------------------------------------------------------------------
# Generates a strong password for the AD Administrator account and stores the
# credentials securely in AWS Secrets Manager.
#
# Key Points
# - Passwords are randomly generated using the random_password provider.
# - Credentials are stored as JSON in AWS Secrets Manager.
# - Secret deletion is allowed for easy teardown of demo environments.
# ================================================================================

# ------------------------------------------------------------------------------
# Generate random password for the AD Administrator
# ------------------------------------------------------------------------------
resource "random_password" "admin_password" {
  length           = 24     # Password length
  special          = true   # Enable special characters
  override_special = "!@#$%"# Restrict allowed special characters
}

# ------------------------------------------------------------------------------
# Secrets Manager secret for AD Administrator credentials
# ------------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "admin_secret" {
  name        = "admin_ad_credentials_ws"  # Secret name
  description = "AD Admin Credentials"     # Secret description

  lifecycle {
    prevent_destroy = false                # Allow secret deletion
  }
}

# ------------------------------------------------------------------------------
# Store AD Administrator credentials in Secrets Manager
# ------------------------------------------------------------------------------
resource "aws_secretsmanager_secret_version" "admin_secret_version" {
  secret_id = aws_secretsmanager_secret.admin_secret.id

  secret_string = jsonencode({
    username = "MCLOUD\\Admin"
    password = random_password.admin_password.result
  })
}

# ================================================================================
# Active Directory Test Users
# --------------------------------------------------------------------------------
# Generates passwords and stores credentials for several demo AD users.
#
# Users
# - John Smith
# - Emily Davis
# - Raj Patel
# - Amit Kumar
#
# Each user receives:
# - Random 24 character password
# - Dedicated Secrets Manager secret
# - JSON credential object (username/password)
# ================================================================================


# ================================================================================
# User: John Smith
# ================================================================================

# ------------------------------------------------------------------------------
# Generate password for John Smith
# ------------------------------------------------------------------------------
resource "random_password" "jsmith_password" {
  length           = 24
  special          = true
  override_special = "!@#$%"
}

# ------------------------------------------------------------------------------
# Secrets Manager secret for John Smith
# ------------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "jsmith_secret" {
  name        = "jsmith_ad_credentials_ws"
  description = "John Smith AD Credentials"

  lifecycle {
    prevent_destroy = false
  }
}

# ------------------------------------------------------------------------------
# Store John Smith credentials
# ------------------------------------------------------------------------------
resource "aws_secretsmanager_secret_version" "jsmith_secret_version" {
  secret_id = aws_secretsmanager_secret.jsmith_secret.id

  secret_string = jsonencode({
    username = "MCLOUD\\jsmith"
    password = random_password.jsmith_password.result
  })
}


# ================================================================================
# User: Emily Davis
# ================================================================================

# ------------------------------------------------------------------------------
# Generate password for Emily Davis
# ------------------------------------------------------------------------------
resource "random_password" "edavis_password" {
  length           = 24
  special          = true
  override_special = "!@#$%"
}

# ------------------------------------------------------------------------------
# Secrets Manager secret for Emily Davis
# ------------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "edavis_secret" {
  name        = "edavis_ad_credentials_ws"
  description = "Emily Davis AD Credentials"

  lifecycle {
    prevent_destroy = false
  }
}

# ------------------------------------------------------------------------------
# Store Emily Davis credentials
# ------------------------------------------------------------------------------
resource "aws_secretsmanager_secret_version" "edavis_secret_version" {
  secret_id = aws_secretsmanager_secret.edavis_secret.id

  secret_string = jsonencode({
    username = "MCLOUD\\edavis"
    password = random_password.edavis_password.result
  })
}


# ================================================================================
# User: Raj Patel
# ================================================================================

# ------------------------------------------------------------------------------
# Generate password for Raj Patel
# ------------------------------------------------------------------------------
resource "random_password" "rpatel_password" {
  length           = 24
  special          = true
  override_special = "!@#$%"
}

# ------------------------------------------------------------------------------
# Secrets Manager secret for Raj Patel
# ------------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "rpatel_secret" {
  name        = "rpatel_ad_credentials_ws"
  description = "Raj Patel AD Credentials"

  lifecycle {
    prevent_destroy = false
  }
}

# ------------------------------------------------------------------------------
# Store Raj Patel credentials
# ------------------------------------------------------------------------------
resource "aws_secretsmanager_secret_version" "rpatel_secret_version" {
  secret_id = aws_secretsmanager_secret.rpatel_secret.id

  secret_string = jsonencode({
    username = "MCLOUD\\rpatel"
    password = random_password.rpatel_password.result
  })
}


# ================================================================================
# User: Amit Kumar
# ================================================================================

# ------------------------------------------------------------------------------
# Generate password for Amit Kumar
# ------------------------------------------------------------------------------
resource "random_password" "akumar_password" {
  length           = 24
  special          = true
  override_special = "!@#$%"
}

# ------------------------------------------------------------------------------
# Secrets Manager secret for Amit Kumar
# ------------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "akumar_secret" {
  name        = "akumar_ad_credentials_ws"
  description = "Amit Kumar AD Credentials"

  lifecycle {
    prevent_destroy = false
  }
}

# ------------------------------------------------------------------------------
# Store Amit Kumar credentials
# ------------------------------------------------------------------------------
resource "aws_secretsmanager_secret_version" "akumar_secret_version" {
  secret_id = aws_secretsmanager_secret.akumar_secret.id

  secret_string = jsonencode({
    username = "MCLOUD\\akumar"
    password = random_password.akumar_password.result
  })
}