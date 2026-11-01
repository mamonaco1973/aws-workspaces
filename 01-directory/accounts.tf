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

# Regular users get memorable passwords, <word>-<6 digits> (e.g.
# orange-123456), easy to type when you sign in during the demo. Lowercase,
# a digit and "-" meet the directory's complexity rule (3 of 4 classes).
locals {
  regular_users = ["jsmith", "edavis", "rpatel", "akumar"]

  memorable_words = [
    "bright", "simple", "orange", "window", "little", "people", "friend",
    "yellow", "animal", "family", "circle", "moment", "summer", "button",
    "planet", "rocket", "silver", "forest", "stream", "butter", "castle",
    "wonder", "gentle", "driver", "coffee"
  ]

  user_passwords = {
    for u in local.regular_users :
    u => "${random_shuffle.word[u].result[0]}-${random_integer.num[u].result}"
  }
}

resource "random_shuffle" "word" {
  for_each     = toset(local.regular_users)
  input        = local.memorable_words
  result_count = 1
}

resource "random_integer" "num" {
  for_each = toset(local.regular_users)
  min      = 100000
  max      = 999999
}

# John Smith
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
    password = local.user_passwords["jsmith"]
  })
}

# Emily Davis
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
    password = local.user_passwords["edavis"]
  })
}

# Raj Patel
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
    password = local.user_passwords["rpatel"]
  })
}

# Amit Kumar
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
    password = local.user_passwords["akumar"]
  })
}
