# Handoff — feature/code-cleanup

Branch `feature/code-cleanup`, cut from `main` at `51edec7`. **Uncommitted**:
commit and push it before the build server can pull it. Delete this file
before merging to `main`.

Nothing has been built or deployed from this branch. `terraform validate`
could not run on the Windows workstation (Norton TLS scanning breaks the
provider plugin handshake), so the first `terraform init` / `plan` on the
build server is the first real validation.

## What changed

**Terraform — comments only, plus variable wiring. No resource arguments,
names or addresses changed.** Verified by diffing every `.tf` against
`HEAD` with comments and whitespace stripped; the only logic differences:

- `01-directory/directory.tf`: `name` and `short_name` now read
  `var.ad_domain_name` / `var.netbios` (same defaults as the old literals).
- `02-servers/linux.tf`, `windows.tf`: `domain_fqdn` / `computers_ou` now read
  `var.ad_domain_name` / `var.computers_ou` (same defaults).
- `directory_id` variable moved from `workspaces.tf` to `variables.tf`;
  unused `netbios` variable dropped from `02-servers`.

Expected: `terraform plan` against an existing deployment shows **no
changes**. A diff there means something above is wrong.

**Shell scripts** — all now `set -euo pipefail`, header comments rewritten.

- `apply.sh`: strict mode from line 1 (was set after the env check); fails
  with a clear error if the directory ID lookup comes back empty.
- `destroy.sh`: shebang moved to line 1 (it was on line 2, so it was not a
  shebang); secret deletes are a loop that warns instead of aborting when a
  secret is already gone, so a re-run after a partial destroy completes.
- `brand.sh`: emoji comments removed; JSON built from one branding block;
  temp file cleaned by `trap`; CLI errors now print instead of going to
  `/dev/null`. Failure is still non-fatal, as before.
- `validate.sh`, `check_env.sh`: strict mode, same output.

**User data** — ported to the cleaned-up pattern from `aws-active-directory`.

- `userdata.sh` (Linux): strict mode with an ERR trap; **installs `jq`**,
  which the old script used but never installed; join is skipped if already
  joined; sudoers file written once with mode 440. Logs moved from
  `/tmp/join.log` to `/root/userdata.log` and `/root/join.log`.
- `userdata.ps1` (Windows): idempotent create-and-catch for groups and
  users; reboots only when this run did the join. RDP grant now targets
  `MCLOUD\mcloud-users` (was the unqualified name, silently ignored on
  failure) and stays non-fatal so a failure can't skip the join reboot.

`make_diagram.py`: import moved to the top. SVG output byte-identical.

## Verify on the build server

1. `./apply.sh` completes and `validate.sh` prints the registration code and
   both private hostnames.
2. Linux: `/root/userdata.log` ends in `user-data complete`; `realm list`
   shows the domain; `id rpatel` shows `mcloud-users` and `india`.
3. Windows: `C:\ProgramData\userdata.log` shows the four users created and
   no RDP warning; RDP as `MCLOUD\rpatel` from the WorkSpace works.
4. WorkSpaces client shows the `@MikesCloudSolutions` branding.
5. `./destroy.sh` completes; run it a second time and it should still exit
   cleanly through to the `01-directory` destroy.

## Decided — the servers stay

The `AWS_Workspaces_V3` video is built around the WorkSpace as the only way
into a private VPC: the demo RDPs to `windows-ad-instance` and SSHes to
`linux-ad-instance` from inside the WorkSpace, as `rpatel`. Both instances,
and the four users the Windows one creates, are the demo's payoff. Do not
remove them.
