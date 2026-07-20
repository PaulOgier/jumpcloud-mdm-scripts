# JumpCloud MDM scripts

Practical, field-tested scripts for managing a cross-platform (macOS, Windows,
Linux) fleet with **JumpCloud**: the small, boring automation the console does
not give you out of the box. Every script is written to run as a JumpCloud
**Command**, prints its results per-device so they collate cleanly, and carries
its safety rules in the comments.

No client data, no secrets, no hard-coded account names. Adapt the target lists
and API host to your own environment.

## Contents

- **[`local-admin-cleanup/`](local-admin-cleanup/)**: audit and remove stale
  local administrator accounts across the fleet after an MDM migration. Six
  scripts (audit + remove, per platform), an audit-first workflow, and the
  JumpCloud gotchas (PowerShell command type, break-glass admins, FileVault
  Secure Token, pulling results from the API).

More to come.

## Conventions

- **Audit before you change anything.** Every destructive script has a read-only
  audit counterpart. Run the audit, read it, decide, then act.
- **Named targets only.** Removal scripts never match by pattern. You list the
  exact accounts, and they ship pointed at a placeholder that does nothing.
- **Per-device output.** Line 1 of each script prints the hostname/serial so
  JumpCloud Command Results are attributable machine by machine.

## Licence

MIT. See [`LICENSE`](LICENSE). Maintained by [Outsource House](https://osh.co.za).
