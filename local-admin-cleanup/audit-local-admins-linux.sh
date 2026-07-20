#!/bin/bash
# Audit human accounts (uid>=1000) and sudo/admin group members on Linux.
# Read-only: lists accounts and admins. Changes nothing.
echo "=== $(hostname) ==="
echo "--- Human accounts (uid>=1000) ---"
awk -F: '$3>=1000 && $3<65534 {print $1"  (uid="$3")"}' /etc/passwd
echo "--- sudo/admin group members ---"
getent group sudo; getent group admin 2>/dev/null; getent group wheel 2>/dev/null
