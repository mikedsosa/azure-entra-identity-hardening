data "azuread_client_config" "current" {}

# Exclusion group for emergency-access (break-glass) accounts.
# Every Conditional Access policy in this project excludes this group so a
# CA misconfiguration can never lock the tenant out completely.
resource "azuread_group" "break_glass_exclusion" {
  display_name     = "${local.name}-ca-exclude-breakglass"
  description      = "Emergency-access accounts excluded from Conditional Access. Membership changes must alert (see docs/runbook.md)."
  security_enabled = true
  members          = var.break_glass_user_object_ids
  owners           = [data.azuread_client_config.current.object_id]

  # Role-assignable groups can only be managed by Privileged Role Admins /
  # Global Admins, which protects membership from lower-privileged admins.
  assignable_to_role = true
}

# Security operators: receive ELIGIBLE (not standing) access through PIM.
resource "azuread_group" "security_operators" {
  display_name       = "${local.name}-pim-security-operators"
  description        = "Eligible for least-privilege security roles via PIM. No standing admin access."
  security_enabled   = true
  assignable_to_role = true
  owners             = [data.azuread_client_config.current.object_id]
}

# Lab operators: receive a narrowly scoped custom Azure role.
resource "azuread_group" "lab_vm_operators" {
  display_name     = "${local.name}-rbac-vm-operators"
  description      = "Granted the custom VM operator role at resource-group scope only."
  security_enabled = true
  owners           = [data.azuread_client_config.current.object_id]
}
