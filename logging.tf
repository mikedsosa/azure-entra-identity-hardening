resource "azurerm_log_analytics_workspace" "identity" {
  name                = "log-${local.name}-identity"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  daily_quota_gb      = var.log_daily_quota_gb

  # Force Entra ID (RBAC) auth for queries/ingestion; no shared keys.
  local_authentication_enabled = false

  tags = var.tags
}

# Tenant-level Entra diagnostic setting -> Log Analytics.
# Creating this requires at least Security Administrator in Entra plus
# write access to the workspace. Sign-in log export requires Entra ID P1/P2.
resource "azurerm_monitor_aad_diagnostic_setting" "entra_to_law" {
  count = var.enable_entra_log_export ? 1 : 0

  name                       = "${local.name}-entra-to-law"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.identity.id

  dynamic "enabled_log" {
    for_each = toset(var.entra_log_categories)
    content {
      category = enabled_log.value
    }
  }
}

resource "azurerm_monitor_action_group" "identity_alerts" {
  count = var.alert_email == "" ? 0 : 1

  name                = "ag-${local.name}-identity"
  resource_group_name = azurerm_resource_group.lab.name
  short_name          = "idalerts"
  tags                = var.tags

  email_receiver {
    name                    = "identity-oncall"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }
}

# Alert on ANY sign-in by a break-glass account. These accounts should only
# ever be used in an emergency, so every sign-in deserves a human look.
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "break_glass_signin" {
  count = var.enable_entra_log_export && length(var.break_glass_user_object_ids) > 0 ? 1 : 0

  name                = "alert-${local.name}-breakglass-signin"
  display_name        = "Break-glass account sign-in"
  description         = "Fires on any interactive or non-interactive sign-in by an emergency-access account. Follow docs/runbook.md."
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  scopes              = [azurerm_log_analytics_workspace.identity.id]
  severity            = 1

  evaluation_frequency = "PT5M"
  window_duration      = "PT5M"

  # The diagnostic setting creates the tables; skip validation so the first
  # apply works before any data has arrived.
  skip_query_validation = true

  criteria {
    query = <<-KQL
      let breakGlass = dynamic(${jsonencode(var.break_glass_user_object_ids)});
      union isfuzzy=true SigninLogs, AADNonInteractiveUserSignInLogs
      | where UserId in (breakGlass)
      | project TimeGenerated, UserPrincipalName, UserId, IPAddress, AppDisplayName, ResultType
    KQL

    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 0

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  dynamic "action" {
    for_each = var.alert_email == "" ? [] : [1]
    content {
      action_groups = [azurerm_monitor_action_group.identity_alerts[0].id]
    }
  }

  tags = var.tags

  depends_on = [azurerm_monitor_aad_diagnostic_setting.entra_to_law]
}
