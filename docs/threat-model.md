# Threat Model: Entra ID Identity Plane

Method: STRIDE per element, focused on the identity control plane. Ratings
are qualitative judgments for a mid-size tenant (**H**igh / **M**edium /
**L**ow likelihood × impact). They are not derived from measured data.

## Assets

| Asset | Why it matters |
|---|---|
| Privileged role holders (Global Admin, Privileged Role Admin, Security Admin, CA Admin) | Full or near-full tenant control |
| Conditional Access policy set | Central enforcement point. Tampering silently removes protection |
| Break-glass accounts | Bypass CA by design, so they're the highest-value credential |
| Tokens (access, refresh, PRT) | Usable without the password, so they can bypass MFA if stolen |
| Sign-in and audit logs | Evidence for detection and investigation |
| Terraform state and pipeline identity | Can reveal or rewrite the whole configuration |

## Entry points

Interactive sign-in (browser, desktop, mobile), legacy protocols (IMAP, POP,
SMTP AUTH, EAS), device code flow, OAuth consent, Azure management APIs
(portal, CLI, PowerShell), the IaC pipeline, and Microsoft support/partner
access.

## STRIDE analysis

| # | STRIDE | Threat | Example technique (MITRE ATT&CK) | Mitigation in this lab | Residual risk | L×I |
|---|---|---|---|---|---|---|
| S1 | Spoofing | Password spray / credential stuffing against users | T1110.003 Password Spraying | CA001 MFA, CA002 blocks legacy auth (no MFA possible there) | MFA fatigue / push bombing: use number matching + passkeys | M×H |
| S2 | Spoofing | Adversary-in-the-middle phishing steals session after MFA | T1557 AiTM, T1539 Steal Web Session Cookie | CA003 phishing-resistant MFA for admins. CA006 risk-based MFA (P2) | Standard users still on phishable MFA. Token protection and compliant device not in v1 | H×H |
| S3 | Spoofing | Device code phishing | T1566 Phishing, T1528 Steal Application Access Token | CA005 blocks device code flow | Exceptions must be tightly scoped | M×H |
| S4 | Spoofing | Break-glass credential stolen | T1078.004 Valid Accounts: Cloud | FIDO2 keys in physical safes, alert on every sign-in, quarterly test | Physical custody failures | L×H |
| T1 | Tampering | Attacker with CA Admin disables or edits policies | T1556 Modify Authentication Process | IaC is source of truth (drift shows in `plan`). Audit log export. PIM for CA Admin | Drift is only detected when someone runs `plan` (add a scheduled drift check) | M×H |
| T2 | Tampering | Adding an attacker account to the break-glass exclusion group | T1098 Account Manipulation | Role-assignable group (only Privileged Role Admin / GA can change it). Membership changes appear in AuditLogs | No dedicated alert on group change yet (see runbook, add one) | L×H |
| T3 | Tampering | Malicious change via IaC pipeline | T1195 Supply Chain Compromise | PR review, CI static checks, human-run apply, gitleaks | No branch protection configured yet (set on GitHub) | L×H |
| R1 | Repudiation | Admin denies making a privileged change | — | AuditLogs exported with retention. PIM activation requires justification | 30-day default retention is short for real investigations | M×M |
| I1 | Information disclosure | Terraform state or tfvars leaked | T1552 Unsecured Credentials | `.gitignore` for state/tfvars, gitleaks in CI, no secrets in code | Local state on laptop. Use remote backend with Entra auth | M×M |
| I2 | Information disclosure | Over-broad access to sign-in logs (PII) | T1530 Data from Cloud Storage | Log Analytics Reader only for security operators. Workspace local auth disabled | Workspace-level, not table-level, RBAC | L×M |
| D1 | Denial of service | Bad CA policy locks everyone out (self-inflicted) | — | Report-only first, What If testing, break-glass exclusion | Human error during promotion | M×H |
| D2 | Denial of service | Log ingestion cap reached, so detections go blind | T1562.008 Disable or Modify Cloud Logs | Daily cap is a lab cost control | Raise or remove the cap outside the lab | M×M |
| E1 | Elevation of privilege | Standing Global Admin compromised | T1078.004 | PIM eligibility, phishing-resistant MFA, 4h sign-in frequency | Lab still has whoever ran `apply` as GA. Reduce after setup | M×H |
| E2 | Elevation of privilege | Over-privileged Azure RBAC (Owner/Contributor everywhere) | T1098.003 Additional Cloud Roles | Custom role with 6 actions, RG-scoped, PIM eligibility that expires | Other subscriptions not covered | M×M |
| E3 | Elevation of privilege | Illicit OAuth consent grant | T1528 | Out of scope v1. Restrict user consent in tenant settings | Not mitigated by this repo | M×H |

## Top residual risks (what to do next)

1. **Phishable MFA for standard users** (S2). Roll out passkeys and an
   authentication-strength policy for all users, then token protection.
2. **No alert on CA policy or exclusion-group changes** (T1, T2). Add
   scheduled query alerts on `AuditLogs` for `Update conditional access
   policy` and group membership changes on the exclusion group.
3. **OAuth consent** (E3). Set user consent to verified publishers or admin
   consent workflow.
4. **Log retention** (R1). Raise retention or archive to storage for
   investigations that span months.

## Assumptions

- The tenant is a lab or a greenfield tenant with no on-premises AD sync. Hybrid
  identity would add AD DS, Entra Connect, and pass-through/federation threats.
- Only the identity plane is in scope. Network, endpoint, and data threats
  are covered in the companion reference architecture.
