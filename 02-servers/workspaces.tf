# ==============================================================================
# Amazon WorkSpaces — register the managed directory with WorkSpaces and give
# its Admin user a Windows desktop, the lab's only way into the private VPC
# ==============================================================================

data "aws_directory_service_directory" "mcloud" {
  directory_id = var.directory_id
}

# ------------------------------------------------------------------------------
# Service role — WorkSpaces acts on the VPC and directory through a role
# with these two managed policies
# ------------------------------------------------------------------------------

resource "aws_iam_role" "workspaces_default" {
  name = "workspaces_DefaultRole_${local.build_suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "workspaces.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "workspaces_service_access" {
  role       = aws_iam_role.workspaces_default.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonWorkSpacesServiceAccess"
}

# Backs the self-service actions enabled on the directory below.
resource "aws_iam_role_policy_attachment" "workspaces_self_service" {
  role       = aws_iam_role.workspaces_default.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonWorkSpacesSelfServiceAccess"
}

# ------------------------------------------------------------------------------
# Directory registration — produces the registration code users type into
# the client. Self-service lets a user resize, rebuild or restart their own
# WorkSpace from the client without an admin.
# ------------------------------------------------------------------------------

resource "aws_workspaces_directory" "registered_directory" {
  directory_id = data.aws_directory_service_directory.mcloud.id

  self_service_permissions {
    change_compute_type  = true
    increase_volume_size = true
    rebuild_workspace    = true
    restart_workspace    = true
    switch_running_mode  = true
  }

  # Every client type, including the browser, so the demo works anywhere.
  workspace_access_properties {
    device_type_android    = "ALLOW"
    device_type_chromeos   = "ALLOW"
    device_type_ios        = "ALLOW"
    device_type_linux      = "ALLOW"
    device_type_osx        = "ALLOW"
    device_type_web        = "ALLOW"
    device_type_windows    = "ALLOW"
    device_type_zeroclient = "ALLOW"
  }

  # The role must exist with its policies before registration, and nothing
  # else in this resource references it.
  depends_on = [
    aws_iam_role.workspaces_default,
    aws_iam_role_policy_attachment.workspaces_service_access,
    aws_iam_role_policy_attachment.workspaces_self_service
  ]
}

# ------------------------------------------------------------------------------
# Bundle — hard-coded Amazon-owned Windows bundle: Standard with Windows
# (Server 2025 based), WorkSpaces Streaming Protocol (WSP). Amazon offers no
# Value-size bundle on Server 2022 or later, so the WorkSpace is STANDARD.
# If AWS retires it, find a current one with:
#   aws workspaces describe-workspace-bundles --owner AMAZON
# ------------------------------------------------------------------------------

data "aws_workspaces_bundle" "windows_standard_bundle" {
  bundle_id = "wsb-82dpmqfgh"
}

# Optional Linux desktop for a second user; the bundle ID may be stale.
# data "aws_workspaces_bundle" "redhat_standard_bundle" {
#   bundle_id = "wsb-8wthbqzhx"
# }

# ------------------------------------------------------------------------------
# Admin's WorkSpace — AUTO_STOP bills hourly and stops after an idle hour,
# far cheaper than ALWAYS_ON for a lab that sits unused most of the time
# ------------------------------------------------------------------------------

resource "aws_workspaces_workspace" "admin_workspace_win" {
  directory_id = aws_workspaces_directory.registered_directory.directory_id
  user_name    = "Admin"
  bundle_id    = data.aws_workspaces_bundle.windows_standard_bundle.id

  workspace_properties {
    compute_type_name                         = "STANDARD"
    root_volume_size_gib                      = 80
    user_volume_size_gib                      = 50
    running_mode                              = "AUTO_STOP"
    running_mode_auto_stop_timeout_in_minutes = 60
  }

  tags = {
    Name = "Admin WorkSpace"
  }

  depends_on = [
    aws_workspaces_directory.registered_directory
  ]
}

# Optional: a Red Hat WorkSpace for rpatel. Uncomment with the bundle above.
#resource "aws_workspaces_workspace" "rpatel_workspace_redhat" {
#  directory_id = aws_workspaces_directory.registered_directory.directory_id
#  user_name    = "rpatel"
#  bundle_id    = data.aws_workspaces_bundle.redhat_standard_bundle.id
#
#  workspace_properties {
#    compute_type_name                         = "STANDARD"
#    root_volume_size_gib                      = 80
#    user_volume_size_gib                      = 50
#    running_mode                              = "AUTO_STOP"
#    running_mode_auto_stop_timeout_in_minutes = 60
#  }
#
#  tags = {
#    Name = "rpatel workspace"
#  }
#
#  depends_on = [
#    aws_workspaces_workspace.admin_workspace_win
#  ]
#}
