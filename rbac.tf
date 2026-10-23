resource "azurerm_resource_group" "lab" {
  name     = "rg-${local.name}-identity"
  location = var.location
  tags     = var.tags
}

# Least-privilege custom Azure role: operate (not create/delete/reconfigure)
# virtual machines. Assignable ONLY at the lab resource group.
resource "azurerm_role_definition" "vm_operator" {
  name        = "${local.name} Lab VM Operator"
  scope       = azurerm_resource_group.lab.id
  description = "Read, start, restart, and deallocate VMs. Cannot create, delete, resize, or run commands on VMs."

  permissions {
    actions = [
      "Microsoft.Resources/subscriptions/resourceGroups/read",
      "Microsoft.Compute/virtualMachines/read",
      "Microsoft.Compute/virtualMachines/instanceView/read",
      "Microsoft.Compute/virtualMachines/start/action",
      "Microsoft.Compute/virtualMachines/restart/action",
      "Microsoft.Compute/virtualMachines/deallocate/action",
    ]
    not_actions = []
  }

  assignable_scopes = [azurerm_resource_group.lab.id]
}

# Built-in role, narrowly scoped: security operators can READ the identity
# log workspace (to investigate) but cannot change it.
resource "azurerm_role_assignment" "secops_log_reader" {
  scope                = azurerm_log_analytics_workspace.identity.id
  role_definition_name = "Log Analytics Reader"
  principal_id         = azuread_group.security_operators.object_id
  principal_type       = "Group"
  description          = "Read-only access to identity logs for investigations."
}
