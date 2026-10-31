# ==============================================================================
# Name suffix — IAM names are account-global, so a random suffix lets this lab
# coexist with another copy of it (or the parent AD lab) in one account
# ==============================================================================

resource "random_id" "build_id" {
  byte_length = 3
}

locals {
  build_suffix = random_id.build_id.hex
}

# ==============================================================================
# Instance role — lets the two servers read the join and user passwords at
# boot instead of having them baked into user data
# ==============================================================================

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

# Scoped to this lab's five secrets only.
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
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_secrets_profile" {
  name = "tf-ec2-secrets-profile-${local.build_suffix}"
  role = aws_iam_role.ec2_secrets_role.name
}

resource "aws_iam_role_policy_attachment" "ec2_secrets_policy_attach" {
  role       = aws_iam_role.ec2_secrets_role.name
  policy_arn = aws_iam_policy.secrets_policy.arn
}

# Session Manager as a fallback way in, since neither server has a public IP.
resource "aws_iam_role_policy_attachment" "ec2_ssm_attach" {
  role       = aws_iam_role.ec2_secrets_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
