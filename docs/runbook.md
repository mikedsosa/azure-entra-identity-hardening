# Identity Incident Runbooks

These are lab runbooks, written to show the response process. **None of them
has been exercised yet.** Run each as a tabletop or lab drill, and record the
date, who took part, and what changed in the *Exercise log* at the bottom.

Roles used below:
- **Responder**: on-call security engineer (eligible for Security Operator / Security Administrator through PIM)
- **Incident lead**: owns decisions and communication
- **Approver**: second person for break-glass use

---

## 1. Risky sign-in (user)

**Trigger:** ID Protection risk detection, CA006/CA007 report-only hit, or an
alert from `queries/risky-signins.kql`.

| Step | Action | Where |
|---|---|---|
| 1 | Activate least-privilege role through PIM (Security Operator) with incident ticket as justification | My roles → Activate |
| 2 | Triage: risk level, detection type (unfamiliar location, anonymous IP, leaked credentials, AiTM), IP, app, CA result, MFA result | Entra → ID Protection → Risky sign-ins; `risky-signins.kql` |
| 3 | Contact the user out-of-band (phone/known chat, not the email that may be compromised). Was it them? | — |
| 4a | **Confirmed safe:** mark *Confirm sign-in safe* and document why | ID Protection |
| 4b | **Compromised or unsure:** revoke sessions (`az rest --method post --url https://graph.microsoft.com/v1.0/users/<id>/revokeSignInSessions`), reset password, require MFA re-registration, mark *Confirm compromised* | Entra / Graph |
| 5 | Scope: what did the session touch? Mailbox rules, OAuth consents, MFA method changes, file access in the window | AuditLogs, `privileged-role-changes.kql`, M365 audit |
| 6 | Hunt for the same IP / user agent across other users | SigninLogs |
| 7 | Close: lessons learned, tune policy (e.g. move user to passkeys) | Ticket |

## 2. Compromised administrator

**Trigger:** suspicious privileged activity in AuditLogs, high user risk on an
admin account, unexpected CA policy change, or a tip from the admin.

**Severity: critical. Page the incident lead immediately.**

| Step | Action | Notes |
|---|---|---|
| 1 | **Contain identity:** disable the account, revoke sessions, remove from all role-assignable groups and PIM eligibility | Use a different admin. If the attacker is GA and fighting back, go to runbook 3 |
| 2 | **Check persistence:** new users, new admins, new app registrations / credentials on service principals, new federation/domain settings, changes to CA policies or the exclusion group, new PIM settings | `privileged-role-changes.kql`, AuditLogs, Entra → Enterprise apps |
| 3 | **Restore the control plane:** run `terraform plan` to see drift from the known-good CA/PIM config, then `apply` to restore it | IaC is the source of truth |
| 4 | **Azure scope:** review Azure Activity Log for role assignments, resource deletions, Key Vault access, diagnostic setting changes | Azure Monitor |
| 5 | **Eradicate:** remove attacker-created objects, rotate secrets the admin could read, re-register admin with new FIDO2 key | — |
| 6 | **Recover:** re-enable account only after re-issuing credentials and confirming device is clean | — |
| 7 | **Notify:** follow your organization's incident and legal notification process | — |
| 8 | **Post-incident:** why did the admin hold standing access? Was CA003 enforced? Update threat model | — |

## 3. Break-glass (emergency access)

### Setup (one-time, manual, before `terraform apply`)

1. Create **two** cloud-only accounts on the `*.onmicrosoft.com` domain (not
   federated, not synced), e.g. `ea-01@<tenant>.onmicrosoft.com`.
2. Assign **Global Administrator** permanently (active, not eligible) so PIM
   outages can't block them.
3. Register a **FIDO2 security key** (or passkey) per account. Store each key
   in a separate physical safe with sign-out log. Two-person rule for access.
4. Don't tie the accounts to a single person's phone or email.
5. Put both object IDs into `break_glass_user_object_ids`. Terraform adds them
   to the exclusion group that every CA policy excludes.
6. Set `alert_email` so every break-glass sign-in notifies the security team.

### When to use

Only when normal admin access is unavailable, for example a CA
misconfiguration locking out admins, an MFA or federation outage, or every
other Global Admin being compromised or unavailable.

### Procedure

| Step | Action |
|---|---|
| 1 | Incident lead approves use. Record who, when, why |
| 2 | Two people retrieve the key. Sign in from a known-clean device |
| 3 | Perform the minimum fix (e.g. set the broken CA policy to report-only, or `terraform apply` a known-good config) |
| 4 | Sign out. Return the key to the safe |
| 5 | Confirm the break-glass alert fired. If it did **not**, treat the alerting gap as a finding |
| 6 | Review AuditLogs for everything the account did. Attach to the incident |
| 7 | Within 24h: rotate/re-register the key if it left controlled custody |

### Quarterly test

Sign in with each account, confirm access and the alert, sign out, and log the
test below.

---

## Exercise log

| Date | Runbook | Type (tabletop / lab) | Participants | Findings / changes |
|---|---|---|---|---|
| _not yet run_ | | | | |
