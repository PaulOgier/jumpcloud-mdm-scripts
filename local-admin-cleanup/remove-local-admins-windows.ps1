# Remove named stale local accounts on Windows (and their profile dirs).
# Read-only until you edit $Targets: run the audit script FIRST and only list
# accounts you have eyeballed as dead. Never delete by pattern.
#
# EDIT THIS — put the exact account names to delete inside the quotes, comma-separated.
# One target:   $Targets = @('oldadmin1')
# Several:      $Targets = @('oldadmin1','oldadmin2','tempadmin')
# @(...) is a PowerShell array; each name in its own 'single quotes', comma-separated.
# The loop below handles any count.
$Targets = @('audittest')

foreach ($u in $Targets) {
  if (-not (Get-LocalUser -Name $u -ErrorAction SilentlyContinue)) { Write-Output "SKIP $u (absent)"; continue }
  try {
    $sid = (Get-LocalUser -Name $u).SID.Value
    Remove-LocalUser -Name $u
    # Remove the profile dir too (best-effort).
    Get-CimInstance Win32_UserProfile | Where-Object { $_.SID -eq $sid } | Remove-CimInstance -ErrorAction SilentlyContinue
    Write-Output "DELETED $u"
  } catch { Write-Output "FAILED $u : $_" }
}
