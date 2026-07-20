# Audit local accounts and Administrators-group members on Windows.
# Read-only: reports only, changes nothing.
#
# Run as a JumpCloud Command (Type: Windows, PowerShell, run as SYSTEM), or
# inline. Line 1 prints the hostname so per-device Results are attributable.
#
# Reading the output:
#  - RID is the tail of the account SID. RID 500 is the built-in Administrator,
#    disabled by default on Win10/11 - judge it by Enabled, not by its name,
#    which can be renamed or localised.
#  - Whether an account is a bound JumpCloud user (console-managed) or an orphan
#    (delete only by pushed Command) is NOT decidable on the device. Join this
#    output to the bindings from the JumpCloud API: /api/v2/systems/{id}/users.

Write-Output "=== $env:COMPUTERNAME ==="
Write-Output "serial: $((Get-CimInstance Win32_BIOS).SerialNumber)"

$adminSids = @(Get-LocalGroupMember -Group 'Administrators' -ErrorAction SilentlyContinue |
                 ForEach-Object { $_.SID.Value })

Write-Output "--- Local accounts ---"
Get-LocalUser | ForEach-Object {
  [pscustomobject]@{
    Name      = $_.Name
    Enabled   = $_.Enabled
    Admin     = if ($adminSids -contains $_.SID.Value) { 'yes' } else { 'no' }
    RID       = ($_.SID.Value -split '-')[-1]
    LastLogon = $_.LastLogon
  }
} | Format-Table -Auto | Out-String

# Domain/Entra members of Administrators have no matching Get-LocalUser record,
# so list the group separately as well or they go unseen.
Write-Output "--- Administrators group members (all, incl. non-local) ---"
Get-LocalGroupMember -Group 'Administrators' -ErrorAction SilentlyContinue |
  Select-Object Name, ObjectClass, PrincipalSource | Format-Table -Auto | Out-String
