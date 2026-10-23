variable "tenant_id" {
  description = "Microsoft Entra tenant ID (GUID) of the LAB tenant you deploy into."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.tenant_id))
    error_message = "tenant_id must be a GUID."
  }
}

variable "subscription_id" {
  description = "Azure subscription ID (GUID) used for the Log Analytics workspace and Azure RBAC examples."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.subscription_id))
    error_message = "subscription_id must be a GUID."
  }
}

variable "prefix" {
  description = "Short prefix for resource and object names."
  type        = string
  default     = "idlab"

  validation {
    condition     = can(regex("^[a-z0-9]{2,10}$", var.prefix))
    error_message = "prefix must be 2-10 lowercase letters or digits."
  }
}

variable "location" {
  description = "Azure region for the resource group and Log Analytics workspace."
  type        = string
  default     = "eastus2"
}

variable "tags" {
  description = "Tags applied to Azure resources."
  type        = map(string)
  default = {
    project = "entra-identity-hardening"
    env     = "lab"
  }
}

# --- Conditional Access -------------------------------------------------------

variable "ca_policy_state" {
  description = <<-EOT
    State for all baseline Conditional Access policies. Start in report-only
    ("enabledForReportingButNotEnforced"), review the sign-in logs / CA insights
    workbook, then switch to "enabled" deliberately.
  EOT
  type        = string
  default     = "enabledForReportingButNotEnforced"

  validation {
    condition     = contains(["enabled", "disabled", "enabledForReportingButNotEnforced"], var.ca_policy_state)
    error_message = "ca_policy_state must be enabled, disabled, or enabledForReportingButNotEnforced."
  }
}

variable "break_glass_user_object_ids" {
  description = <<-EOT
    Object IDs of the emergency-access (break-glass) accounts. They are added
    to an exclusion group that every policy in this project excludes. Create
    the accounts manually (see docs/runbook.md); this project does not create
    them so their credentials never pass through Terraform state.
  EOT
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for id in var.break_glass_user_object_ids : can(regex("^[0-9a-fA-F-]{36}$", id))])
    error_message = "Each break-glass object ID must be a GUID."
  }
}

variable "enable_risk_based_policies" {
  description = "Create sign-in-risk and user-risk policies. Requires Microsoft Entra ID P2 (ID Protection)."
  type        = bool
  default     = false
}

# --- Privileged Identity Management --------------------------------------------

variable "enable_pim" {
  description = "Create PIM eligible assignments (Entra role + Azure resource role). Requires Microsoft Entra ID P2 or Entra ID Governance."
  type        = bool
  default     = false
}

variable "pim_eligible_entra_role" {
  description = "Display name of the Entra built-in role the security-operators group is ELIGIBLE for via PIM."
  type        = string
  default     = "Security Reader"

  validation {
    condition     = contains(["Security Reader", "Security Operator", "Security Administrator", "Global Reader"], var.pim_eligible_entra_role)
    error_message = "Keep the lab least-privilege: choose Security Reader, Security Operator, Security Administrator, or Global Reader."
  }
}

variable "pim_azure_eligibility_days" {
  description = "How long the Azure resource PIM eligibility lasts before it expires."
  type        = number
  default     = 30
}

# --- Logging -------------------------------------------------------------------

variable "enable_entra_log_export" {
  description = "Export Entra sign-in/audit logs to Log Analytics. Sign-in log export requires Entra ID P1 or P2."
  type        = bool
  default     = true
}

variable "entra_log_categories" {
  description = "Entra diagnostic log categories to export. Risk categories need Entra ID P2 to produce data."
  type        = list(string)
  default = [
    "AuditLogs",
    "SignInLogs",
    "NonInteractiveUserSignInLogs",
    "ServicePrincipalSignInLogs",
    "ManagedIdentitySignInLogs",
    "RiskyUsers",
    "UserRiskEvents",
  ]
}

variable "log_retention_days" {
  description = "Log Analytics retention in days (30-730)."
  type        = number
  default     = 30

  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "log_retention_days must be between 30 and 730."
  }
}

variable "log_daily_quota_gb" {
  description = "Daily ingestion cap (GB) to keep lab costs bounded. -1 means unlimited."
  type        = number
  default     = 1
}

variable "alert_email" {
  description = "Optional email address for the break-glass sign-in alert. Leave empty to create the alert without a notification target."
  type        = string
  default     = ""
  sensitive   = true
}
