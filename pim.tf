# Privileged Identity Management (PIM) examples.
# Requires Microsoft Entra ID P2 (or Entra ID Governance). Disabled by
# default; set enable_pim = true in your tfvars once the license is active.

# Entra role: the security-operators group is ELIGIBLE (must activate,
# time-bound, audited) rather than permanently assigned.
resource "azuread_directory_role_eligibility_schedule_request" "security_operators" {
  count = var.enable_pim ? 1 : 0

  role_definition_id = local.entra_role_template_ids[var.pim_eligible_entra_role]
  principal_id       = azuread_group.security_operators.object_id
  directory_scope_id = "/"
  justification      = "Lab: eligible-only access for security operators (no standing privilege)."
}

# Azure resource role: VM operators are ELIGIBLE for the custom role on the
# lab resource group only, and the eligibility itself expires.
resource "azurerm_pim_eligible_role_assignment" "vm_operators" {
  count = var.enable_pim ? 1 : 0

  scope              = azurerm_resource_group.lab.id
  role_definition_id = azurerm_role_definition.vm_operator.role_definition_resource_id
  principal_id       = azuread_group.lab_vm_operators.object_id
  justification      = "Lab: time-bound eligibility for VM start/stop on the lab RG."

  schedule {
    expiration {
      duration_days = var.pim_azure_eligibility_days
    }
  }
}
