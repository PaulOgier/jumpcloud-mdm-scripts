# Audit and remove local admin accounts fleet-wide with JumpCloud

Six small scripts to find and clean up stale **local administrator accounts**
across a Mac, Windows and Linux fleet, driven from **JumpCloud Commands**. They
exist to solve one recurring MDM problem: after an MDM migration (Jamf to
JumpCloud, an old RMM to a new one, or an on-prem AD to cloud identity) every
machine is left carrying leftover local admins: `jamfadmin`, an old build
account, a technician's throwaway. Those accounts are invisible from the
identity console because nothing binds them to a managed user, and each one is a
standing local-privilege foothold.

The pattern here is **audit first, eyeball the results, then delete named
accounts only**. Nothing deletes by pattern, and nothing runs a removal until
you have looked at the audit output and decided.

## The scripts

| Platform | Audit (read-only) | Remove (edit before running) |
|----------|-------------------|------------------------------|
| macOS    | `audit-local-admins-macos.sh`   | `remove-local-admins-macos.sh`   |
| Windows  | `audit-local-admins-windows.ps1`| `remove-local-admins-windows.ps1`|
| Linux    | `audit-local-admins-linux.sh`   | `remove-local-admins-linux.sh`   |

The audit scripts change nothing. The remove scripts are read-only until you
edit the target list at the top. They ship pointed at a placeholder name that
does not exist, so a blind run does nothing.

## How to run them from JumpCloud

These are built to run as **JumpCloud Commands**, not by hand in a terminal. A
terminal only tells you about the one machine you are sitting at; the whole
point is a fleet-wide picture and a fleet-wide kill list. Use a terminal only to
spot-check a single pilot device.

1. **Commands > New Command.**
2. **Mac / Linux:** command type `Mac` or `Linux`, and set **Run As: root**.
   Paste the script body in.
3. **Windows:** command type `Windows`, and **tick the "Windows PowerShell"
   checkbox** at the top of the editor. This is the most common mistake. If you
   leave it unticked the command runs under `cmd.exe`, every PowerShell line
   errors as *"not recognized"*, and it looks like the script is broken when it
   simply never ran as PowerShell.
4. Scope it to a device group, or to a single pilot machine first.
5. Run it, then read the results (see below).

### Getting the output back

The JumpCloud agent runs the command as root (macOS/Linux) or SYSTEM (Windows),
captures **stdout, stderr and the exit code**, and posts it to the console under
**Commands > (your command) > Results**, one row per device. The scripts need no
callback URL or API key. Printing to stdout is the whole contract. That is why
line 1 of every script prints the hostname/serial: results are per-device and
otherwise unattributable.

At 30 to 40 devices, clicking through one Results pane per machine is miserable.
Pull them all at once from the API instead:

```bash
# needs a JumpCloud API key with command-results read
curl -s -H "x-api-key: $JC_API_KEY" \
  "https://console.jumpcloud.com/api/commandresults?limit=100" \
  | jq -r '.results[] | [.system, .exitCode, (.response.data.output)] | @tsv'
```

Then grep one JSON blob instead of clicking 40 panes. (Note: very long command
output may be truncated in the console, so keep the audit output compact.)

## Tips, traps and safety

These are the things that bite you in the field. Read them before you delete
anything.

- **Never delete the last usable admin on a box.** The removal only ever touches
  the exact names you list, but you still have to confirm a working managed
  admin survives on every target. Stand up **one managed break-glass admin**
  (a single JumpCloud admin user bound to every machine, password in your vault)
  and confirm it is green on each box *before* any delete runs.
- **A machine showing in the JumpCloud console does not mean the local account
  is managed.** JumpCloud manages *bound users*, not every local account on a
  device it can see. Judge each account by whether it is a bound JumpCloud user
  on that system, not by the machine being listed. Orphaned accounts (no bound
  JumpCloud user) can only be removed by a **pushed delete Command**. The
  console cannot touch them directly. That is exactly why these scripts exist.
- **macOS FileVault + Secure Token is the real trap.** An account can show
  `ADMIN=yes` but `TOKEN=DISABLED`; on a FileVault Mac that account cannot unlock
  the disk at pre-boot, so it is useless as break-glass and useless for recovery.
  The macOS audit reports Secure Token and the FileVault-enabled user list for
  exactly this reason, so **never delete the last Secure-Token holder.**
- **Apple Silicon + FileVault, creating accounts:** `sysadminctl -addUser` fails
  with **error 5402** (root is not the volume owner). Seed a break-glass account
  through the GUI or with `-adminUser <token-holder>` instead. Deletes are
  unaffected. Only creation hits this.
- **Hidden admins.** The macOS audit deliberately includes UID < 500 accounts
  (hidden from the login window). A hidden admin is exactly what an audit must
  not miss.
- **Do a pilot first.** Run the audit on one machine, then the remove on one
  machine you can physically reach, before you scope either to a group.

## Why these are safe to publish

Read-only audits, named-target-only deletes, an explicit break-glass rule, and
no hard-coded account names or secrets. Adapt the target lists and API host to
your own environment.
