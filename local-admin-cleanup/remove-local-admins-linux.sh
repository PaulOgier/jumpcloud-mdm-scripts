#!/bin/bash
# Remove named stale local accounts on Linux (with home dirs).
# Run the audit script first and set TARGETS to accounts you have verified are dead.
# Never delete by pattern; only named accounts you have eyeballed.
TARGETS="oldadmin1 oldadmin2"   # EDIT THIS
for u in $TARGETS; do
  id "$u" >/dev/null 2>&1 || { echo "SKIP $u (absent)"; continue; }
  pkill -KILL -u "$u" 2>/dev/null
  userdel -r "$u" && echo "DELETED $u (with home)" || echo "FAILED $u"
done
