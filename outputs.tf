output "conditional_access_policy_ids" {
  description = "Object IDs of the baseline Conditional Access policies."
  value = merge(
    {
      ca001 = azuread_conditional_access_policy.ca001_all_users_mfa.id
      ca002 = azuread_conditional_access_policy.ca002_block_legacy_auth.id
      ca003 = azuread_conditional_access_policy.ca003_admins_phishing_resistant.id
      ca004 = azuread_conditional_access_policy.ca004_azure_management_mfa.id
      ca005 = azuread_conditional_access_policy.ca005_block_device_code_flow.id
    },
    var.enable_risk_based_policies ? {
      ca006 = azuread_conditional_access_policy.ca006_signin_risk_mfa[0].id
      ca007 = azuread_conditional_access_policy.ca007_user_risk_password_change[0].id
    } : {}
  )
}

output "ca_policy_state" {
  description = "State applied to every baseline policy."
  value       = var.ca_policy_state
}

output "break_glass_exclusion_group_id" {
  description = "Object ID of the break-glass exclusion group."
  value       = azuread_group.break_glass_exclusion.object_id
}

output "security_operators_group_id" {
  description = "Object ID of the PIM-eligible security operators group."
  value       = azuread_group.security_operators.object_id
}

output "log_analytics_workspace_id" {
  description = "Resource ID of the identity Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.identity.id
}

output "custom_role_id" {
  description = "Resource ID of the custom least-privilege VM operator role."
  value       = azurerm_role_definition.vm_operator.role_definition_resource_id
}
