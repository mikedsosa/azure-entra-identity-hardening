locals {
  name = var.prefix

  # Microsoft Entra built-in role TEMPLATE IDs. These GUIDs are the same in
  # every tenant. Source (verified 2026-10):
  # https://learn.microsoft.com/entra/identity/role-based-access-control/permissions-reference
  entra_role_template_ids = {
    "Global Administrator"                    = "62e90394-69f5-4237-9190-012177145e10"
    "Privileged Role Administrator"           = "e8611ab8-c189-46e8-94e1-60213ab1f814"
    "Security Administrator"                  = "194ae4cb-b126-40b2-bd5b-6091b380977d"
    "Conditional Access Administrator"        = "b1be1c3e-b65d-4f19-8427-f6fa0d97feb9"
    "User Administrator"                      = "fe930be7-5e62-47db-91af-98c3a49a38b1"
    "Privileged Authentication Administrator" = "7be44c8a-adaf-4e2a-84d6-ab2649e08a13"
    "Application Administrator"               = "9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3"
    "Security Reader"                         = "5d6b6bb7-de71-4623-b4af-96380a352509"
    "Security Operator"                       = "5f2222b1-57c3-48ba-8ad5-d4759f1fde6f"
    "Global Reader"                           = "f2ef992c-3afb-46b9-b7cf-a126ee74c451"
  }

  # Roles treated as "privileged admin" for the admin-protection policy.
  privileged_admin_roles = [
    "Global Administrator",
    "Privileged Role Administrator",
    "Security Administrator",
    "Conditional Access Administrator",
    "User Administrator",
    "Privileged Authentication Administrator",
    "Application Administrator",
  ]

  privileged_admin_role_ids = [for r in local.privileged_admin_roles : local.entra_role_template_ids[r]]

  # Windows Azure Service Management API (Azure portal, CLI, PowerShell, ARM).
  azure_management_app_id = "797f4846-ba00-4fd7-ba43-dac1f8f63013"

  # Every policy excludes the break-glass group.
  ca_excluded_groups = [azuread_group.break_glass_exclusion.object_id]
}
