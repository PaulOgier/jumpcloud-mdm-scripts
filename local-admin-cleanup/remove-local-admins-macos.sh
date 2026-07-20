#!/bin/bash
# Remove named stale local admin/user accounts on a Mac.
# Run the audit script first and set TARGETS to accounts you have verified are dead.
# Never delete by pattern; only named accounts you have eyeballed.
#
# Safety before running:
#  - Confirm a working admin (the managed user) remains on the machine.
#  - FileVault: ensure another enabled FileVault user exists (fdesetup list).
#  - Secure Token: confirm the surviving admin holds one
#    (sysadminctl -secureTokenStatus <user>).

# EDIT THIS: exact account short-name(s) to remove, space-separated.
TARGETS="oldadmin1 oldadmin2"

# Safety: never delete the currently-logged-in console user.
CONSOLE_USER="$(stat -f%Su /dev/console)"
for u in $TARGETS; do
  if [ "$u" = "$CONSOLE_USER" ]; then echo "SKIP $u (logged in)"; continue; fi
  if ! id "$u" >/dev/null 2>&1; then echo "SKIP $u (not present)"; continue; fi
  # -secure archives+erases home; use -keepHome instead to preserve the folder.
  sysadminctl -deleteUser "$u" -secure && echo "DELETED $u" || echo "FAILED $u"
done
# Fallback if sysadminctl can't (rare): dscl . -delete /Users/<name> ; rm -rf /Users/<name>
