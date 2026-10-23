# Baseline Conditional Access policies.
#
# All policies:
#   * default to report-only (var.ca_policy_state) so nothing is enforced
#     until you have reviewed the sign-in logs;
#   * exclude the break-glass group;
#   * follow the naming pattern CAxxx-<scope>-<control>.
#
# Requires Microsoft Entra ID P1 (P2 for the risk-based policies).

data "azuread_authentication_strength_policy" "phishing_resistant" {
  display_name = "Phishing-resistant MFA"
}

# CA001: Require MFA for all users on all cloud apps.
resource "azuread_conditional_access_policy" "ca001_all_users_mfa" {
  display_name = "CA001-AllUsers-RequireMFA"
  state        = var.ca_policy_state

  conditions {
    client_app_types = ["all"]

    applications {
      included_applications = ["All"]
    }

    users {
      included_users  = ["All"]
      excluded_groups = local.ca_excluded_groups
    }
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["mfa"]
  }
}

# CA002: Block legacy authentication (Exchange ActiveSync + other legacy
# clients such as POP, IMAP, SMTP AUTH). Legacy protocols cannot do MFA.
resource "azuread_conditional_access_policy" "ca002_block_legacy_auth" {
  display_name = "CA002-AllUsers-BlockLegacyAuth"
  state        = var.ca_policy_state

  conditions {
    client_app_types = ["exchangeActiveSync", "other"]

    applications {
      included_applications = ["All"]
    }

    users {
      included_users  = ["All"]
      excluded_groups = local.ca_excluded_groups
    }
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["block"]
  }
}

# CA003: Privileged admin roles must use phishing-resistant MFA, re-auth
# every 4 hours, and never keep a persistent browser session.
resource "azuread_conditional_access_policy" "ca003_admins_phishing_resistant" {
  display_name = "CA003-Admins-RequirePhishingResistantMFA"
  state        = var.ca_policy_state

  conditions {
    client_app_types = ["all"]

    applications {
      included_applications = ["All"]
    }

    users {
      included_roles  = local.privileged_admin_role_ids
      excluded_groups = local.ca_excluded_groups
    }
  }

  grant_controls {
    operator                          = "OR"
    authentication_strength_policy_id = data.azuread_authentication_strength_policy.phishing_resistant.id
  }

  session_controls {
    sign_in_frequency        = 4
    sign_in_frequency_period = "hours"
    persistent_browser_mode  = "never"
  }
}

# CA004: Require MFA for Azure management (portal, CLI, PowerShell, ARM).
resource "azuread_conditional_access_policy" "ca004_azure_management_mfa" {
  display_name = "CA004-AllUsers-AzureManagement-RequireMFA"
  state        = var.ca_policy_state

  conditions {
    client_app_types = ["all"]

    applications {
      included_applications = [local.azure_management_app_id]
    }

    users {
      included_users  = ["All"]
      excluded_groups = local.ca_excluded_groups
    }
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["mfa"]
  }
}

# CA005: Block device code flow, a common phishing vector. Add exclusions
# only for documented, business-justified devices (e.g. meeting-room kits).
resource "azuread_conditional_access_policy" "ca005_block_device_code_flow" {
  display_name = "CA005-AllUsers-BlockDeviceCodeFlow"
  state        = var.ca_policy_state

  conditions {
    client_app_types                     = ["all"]
    authentication_flow_transfer_methods = ["deviceCodeFlow"]

    applications {
      included_applications = ["All"]
    }

    users {
      included_users  = ["All"]
      excluded_groups = local.ca_excluded_groups
    }
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["block"]
  }
}

# CA006 / CA007: Risk-based policies (Entra ID P2 / ID Protection).
resource "azuread_conditional_access_policy" "ca006_signin_risk_mfa" {
  count = var.enable_risk_based_policies ? 1 : 0

  display_name = "CA006-AllUsers-SignInRiskMediumHigh-RequireMFA"
  state        = var.ca_policy_state

  conditions {
    client_app_types    = ["all"]
    sign_in_risk_levels = ["medium", "high"]

    applications {
      included_applications = ["All"]
    }

    users {
      included_users  = ["All"]
      excluded_groups = local.ca_excluded_groups
    }
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["mfa"]
  }

  session_controls {
    sign_in_frequency_interval = "everyTime"
  }
}

resource "azuread_conditional_access_policy" "ca007_user_risk_password_change" {
  count = var.enable_risk_based_policies ? 1 : 0

  display_name = "CA007-AllUsers-UserRiskHigh-RequirePasswordChange"
  state        = var.ca_policy_state

  conditions {
    client_app_types = ["all"]
    user_risk_levels = ["high"]

    applications {
      included_applications = ["All"]
    }

    users {
      included_users  = ["All"]
      excluded_groups = local.ca_excluded_groups
    }
  }

  grant_controls {
    operator          = "AND"
    built_in_controls = ["mfa", "passwordChange"]
  }

  session_controls {
    sign_in_frequency_interval = "everyTime"
  }
}
