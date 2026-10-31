# ==============================================================================
# Provider — us-east-1, because WorkSpaces is not offered in us-east-2 where
# the parent Active Directory lab runs
# ==============================================================================

provider "aws" {
  region = "us-east-1"
}
