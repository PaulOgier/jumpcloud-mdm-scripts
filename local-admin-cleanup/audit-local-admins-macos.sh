#!/bin/bash
# Audit local accounts, admin rights, Secure Token and FileVault on a Mac.
# Read-only: reports only, changes nothing.
#
# Run as a JumpCloud Command (Type: Mac, run as root), or inline. Line 1 prints
# the hostname so per-device Results are attributable.
#
# Reading the output:
#  - ADMIN=yes + TOKEN=DISABLED on a FileVault Mac is NOT a usable admin. It
#    cannot unlock the disk at pre-boot, so it is no use as break-glass and no
#    use for recovery after you delete something.
#  - Never delete the last account with TOKEN=ENABLED. Cross-check the
#    "FileVault-enabled users" list at the bottom before any account goes on a
#    kill list.
#  - Whether an account is a bound JumpCloud user (console-managed) or an orphan
#    (delete only by pushed Command) is NOT decidable on the device. Join this
#    output to the bindings from the JumpCloud API: /api/v2/systems/{id}/users.
#  - UID < 500 accounts are hidden from the login window. They are included here
#    deliberately: a hidden admin is exactly what an audit must not miss.

echo "=== $(scutil --get ComputerName) ==="
echo "serial: $(ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformSerialNumber/{print $4}')"

admins=" $(dscl . -read /Groups/admin GroupMembership 2>/dev/null | cut -d' ' -f2-) "

echo "--- Local accounts (uid >= 400, so hidden admins are caught) ---"
printf '%-20s %-6s %-6s %-7s %-9s %s\n' USER UID ADMIN HIDDEN TOKEN HOME
dscl . -list /Users UniqueID | awk '$2 >= 400 {print $1, $2}' | while read -r u uid; do
  case "$admins" in *" $u "*) adm=yes ;; *) adm=no ;; esac
  hid=$(dscl . -read "/Users/$u" IsHidden 2>/dev/null | awk '{print $2}')
  [ "$uid" -lt 500 ] && hid=1
  tok=$(sysadminctl -secureTokenStatus "$u" 2>&1 | grep -o 'ENABLED\|DISABLED' | head -1)
  home=$(dscl . -read "/Users/$u" NFSHomeDirectory 2>/dev/null | cut -d' ' -f2-)
  printf '%-20s %-6s %-6s %-7s %-9s %s\n' "$u" "$uid" "$adm" "${hid:-0}" "${tok:-unknown}" "$home"
done

echo "--- FileVault-enabled users (these can unlock at pre-boot) ---"
fdesetup list 2>/dev/null || echo "(FileVault off, or status not readable)"
