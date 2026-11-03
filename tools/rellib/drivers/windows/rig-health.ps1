# SPDX-License-Identifier: Apache-2.0
<#
  Read-only health facts of the Windows rig sessions (rig.py health()): one line "RIG <json>" per
  session. Runs as BT over SSH, no admin: the scheduled task (exists, enabled, state, last run and its
  result), its user (enabled, locked, password expiry, its own Modify grant on the work dir), the user's
  "Log on as a batch job" right (the LSA answers a lookup of one account's rights without admin) and the
  session's queue. Changes nothing.
  -Sessions 1,5 checks those; none checks every EpicWalletRig<k> task on the box.
#>
param([int[]]$Sessions = @())
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Continue'

Add-Type -TypeDefinition @'
using System; using System.Runtime.InteropServices; using System.Security.Principal;
public static class RigLsa {
  [StructLayout(LayoutKind.Sequential)] struct U { public ushort Len; public ushort Max; public IntPtr Buf; }
  [StructLayout(LayoutKind.Sequential)] struct O { public int Length; public IntPtr R; public IntPtr N; public int A; public IntPtr S; public IntPtr Q; }
  [DllImport("advapi32.dll")] static extern uint LsaOpenPolicy(IntPtr s, ref O o, int acc, out IntPtr h);
  [DllImport("advapi32.dll")] static extern uint LsaEnumerateAccountRights(IntPtr h, byte[] sid, out IntPtr r, out uint c);
  [DllImport("advapi32.dll")] static extern uint LsaClose(IntPtr h);
  [DllImport("advapi32.dll")] static extern int LsaNtStatusToWinError(uint s);
  // the account's own rights; "" when it has none (ERROR_FILE_NOT_FOUND), "ERR <n>" when the LSA refuses
  public static string Rights(string sidStr) {
    var sid = new SecurityIdentifier(sidStr); var b = new byte[sid.BinaryLength]; sid.GetBinaryForm(b, 0);
    var o = new O(); IntPtr h; uint st = LsaOpenPolicy(IntPtr.Zero, ref o, 0x800, out h);
    if (st != 0) return "ERR " + LsaNtStatusToWinError(st);
    try {
      IntPtr r; uint c; st = LsaEnumerateAccountRights(h, b, out r, out c);
      if (st != 0) { int e = LsaNtStatusToWinError(st); return e == 2 ? "" : "ERR " + e; }
      string s = ""; int sz = Marshal.SizeOf(typeof(U));
      for (int i = 0; i < c; i++) { var u = (U)Marshal.PtrToStructure(new IntPtr(r.ToInt64() + i * sz), typeof(U)); s += Marshal.PtrToStringUni(u.Buf, u.Len / 2) + " "; }
      return s.Trim();
    } finally { LsaClose(h); }
  }
}
'@

function Iso($t) { if ($t -and $t.Year -gt 2000) { $t.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ') } else { $null } }

$tasks = @(Get-ScheduledTask -TaskName 'EpicWalletRig*' -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -match '^EpicWalletRig[2-9]?$' })
if (-not $Sessions) { $Sessions = @($tasks | ForEach-Object { if ($_.TaskName -eq 'EpicWalletRig') { 1 } else { [int]$_.TaskName.Substring(13) } } | Sort-Object) }
$admins = (New-Object Security.Principal.SecurityIdentifier 'S-1-5-32-544').Translate([Security.Principal.NTAccount]).Value.Split('\')[1]
$adminPaths = @(([ADSI]"WinNT://./$admins,group").psbase.Invoke('Members') | ForEach-Object { $_.GetType().InvokeMember('AdsPath', 'GetProperty', $null, $_, $null) })
# rights every local user holds through a group: Everyone, Authenticated Users, Users (whose members include Authenticated Users)
$common = @('S-1-1-0', 'S-1-5-11', 'S-1-5-32-545') | ForEach-Object { [RigLsa]::Rights($_) }

foreach ($k in $Sessions) {
  $name = if ($k -eq 1) { 'EpicWalletRig' } else { "EpicWalletRig$k" }
  $work = if ($k -eq 1) { 'C:\EpicRig' } else { "C:\EpicRig$k" }
  $r = [ordered]@{ session = $k; task = $name; work = $work; exists = $false }
  $t = $tasks | Where-Object { $_.TaskName -eq $name } | Select-Object -First 1
  if ($t) {
    $i = Get-ScheduledTaskInfo -TaskName $name
    $r.exists = $true
    $r.enabled = [bool]$t.Settings.Enabled
    $r.state = "$($t.State)"
    $r.logon = "$($t.Principal.LogonType)"
    $r.last_result = [int64]$i.LastTaskResult
    $r.last_run = Iso $i.LastRunTime
    $r.next_run = Iso $i.NextRunTime
    $uid = "$($t.Principal.UserId)"
    $sid = $null
    try { $sid = (New-Object Security.Principal.SecurityIdentifier $uid).Value } catch {
      try { $sid = (New-Object Security.Principal.NTAccount $uid).Translate([Security.Principal.SecurityIdentifier]).Value } catch {} }
    $r.sid = $sid
    $u = if ($sid) { Get-LocalUser -SID $sid -ErrorAction SilentlyContinue }
    if ($u) {
      $r.user = $u.Name
      $r.account_enabled = [bool]$u.Enabled
      $r.password_expires = Iso $u.PasswordExpires
      $r.account_expires = Iso $u.AccountExpires
      $wa = Get-CimInstance Win32_UserAccount -Filter "LocalAccount=True AND SID='$sid'" -ErrorAction SilentlyContinue
      $r.locked = [bool]$wa.Lockout
      $own = [RigLsa]::Rights($sid)
      $isAdmin = [bool]($adminPaths | Where-Object { $_ -match "/$([regex]::Escape($u.Name))$" })
      $all = @($own) + $common + $(if ($isAdmin) { [RigLsa]::Rights('S-1-5-32-544') } else { @() })
      $r.rights_error = (@($all | Where-Object { $_ -like 'ERR *' }) -join '; ')
      $words = ($all -join ' ') -split '\s+'
      $r.batch_right = $words -contains 'SeBatchLogonRight'
      $r.batch_denied = $words -contains 'SeDenyBatchLogonRight'
      $r.profile = Test-Path -LiteralPath "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$sid"
      # the user's own Modify grant on its work dir (setup-test-user.ps1 gives one; null when the folder is missing)
      $acl = Get-Acl -LiteralPath $work -ErrorAction SilentlyContinue
      if ($acl) {
        $r.work_grant = [bool]($acl.Access | Where-Object { $_.AccessControlType -eq 'Allow' -and -not $_.IsInherited -and
          ($_.FileSystemRights -band [Security.AccessControl.FileSystemRights]::Modify) -eq [Security.AccessControl.FileSystemRights]::Modify -and
          $(try { $_.IdentityReference.Translate([Security.Principal.SecurityIdentifier]).Value -eq $sid } catch { $false }) })
      }
    } else { $r.user = $uid }
  }
  $q = Join-Path $work 'queue'
  $waiting = @(Get-ChildItem -LiteralPath $q -Filter '*.json' -File -ErrorAction SilentlyContinue)
  $r.queued = $waiting.Count
  $r.oldest_queued = Iso (($waiting | Sort-Object LastWriteTime | Select-Object -First 1).LastWriteTime)
  $r.running_jobs = @(Get-ChildItem -LiteralPath (Join-Path $q 'done') -Filter '*.running.json' -File -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-4) }).Count
  $r.now = Iso (Get-Date)
  'RIG ' + ($r | ConvertTo-Json -Compress)
}
