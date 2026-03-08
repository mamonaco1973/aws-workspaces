# ================================================================================
# Unique Deployment Identifier
# --------------------------------------------------------------------------------
# Generates a unique identifier used to prevent naming collisions across
# multiple Terraform deployments.
#
# Key Points
# - Generated once per Terraform state.
# - Used as a suffix for IAM resource names.
# - Ensures globally unique IAM names.
# ================================================================================

resource "random_id" "build_id" {
  byte_length = 3
}

locals {
  build_suffix = random_id.build_id.hex
}


# ================================================================================
# EC2 Secrets Manager Access Role
# --------------------------------------------------------------------------------
# Role assumed by EC2 instances that require access to AWS Secrets Manager.
# ================================================================================

resource "aws_iam_role" "ec2_secrets_role" {
  name = "tf-ec2-secrets-role-${local.build_suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}


# ================================================================================
# EC2 Systems Manager Role
# --------------------------------------------------------------------------------
# Role allowing EC2 instances to interact with AWS Systems Manager.
# ================================================================================

resource "aws_iam_role" "ec2_ssm_role" {
  name = "tf-ec2-ssm-role-${local.build_suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}


# ================================================================================
# Secrets Manager Access Policy
# --------------------------------------------------------------------------------
# Grants EC2 instances permission to retrieve secrets from AWS Secrets Manager.
# ================================================================================

resource "aws_iam_policy" "secrets_policy" {
  name        = "tf-secrets-read-policy-${local.build_suffix}"
  description = "allow ec2 instances to read specific secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [

      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets"
        ]
        Resource = [
          data.aws_secretsmanager_secret.admin_secret.arn,
          data.aws_secretsmanager_secret.jsmith_secret.arn,
          data.aws_secretsmanager_secret.edavis_secret.arn,
          data.aws_secretsmanager_secret.rpatel_secret.arn,
          data.aws_secretsmanager_secret.akumar_secret.arn
        ]
      },

      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeIamInstanceProfileAssociations",
          "ec2:DisassociateIamInstanceProfile",
          "ec2:ReplaceIamInstanceProfileAssociation"
        ]
        Resource = "*"
      },

      {
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = aws_iam_role.ec2_ssm_role.arn
      }
    ]
  })
}


# ================================================================================
# IAM Instance Profiles
# --------------------------------------------------------------------------------
# Instance profiles allow EC2 instances to assume IAM roles.
# ================================================================================

resource "aws_iam_instance_profile" "ec2_secrets_profile" {
  name = "tf-ec2-secrets-profile-${local.build_suffix}"
  role = aws_iam_role.ec2_secrets_role.name
}

resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "tf-ec2-ssm-profile-${local.build_suffix}"
  role = aws_iam_role.ec2_ssm_role.name
}