# SPDX-License-Identifier: Apache-2.0
# Installs or upgrades the btsign Windows service (docs/RELEASING.md, "Signer"). Run as a local
# Administrator from a staging folder that holds (tools/signer/windows/stage.sh makes it):
#   python-<ver>-embed-amd64.zip   the embeddable Python (sigstore-verified when staged)
#   wheels\*.whl + requirements-windows.txt   cryptography, jsonschema, segno (hash-pinned)
#   apksigner.jar                  from Android build-tools (pinned in btsign.toml)
#   app\                           tools/signer (btsign.py, btsign\, vendor\, selftest\)
#
# First run: makes the local account btsigner (random password, never shown or stored by this
# script; Windows keeps it as the service's LSA secret), gives it "log on as a service" and
# denies it interactive, remote-desktop and network logons, installs C:\Program Files\btsign,
# makes C:\ProgramData\btsign readable and writable by btsigner alone (inheritance off, no
# Administrators, no SYSTEM), registers the service (delayed automatic start, restart on
# failure) and a firewall rule for the tailnet port from 100.64.0.0/10 only, and starts it.
# Later runs (service already there): stop, replace the program files, start. They never touch
# the account's password: resetting it would make DPAPI lose the store (the bundle restores it).
param(
  [Parameter(Mandatory = $true)][string]$Stage,
  [Parameter(Mandatory = $true)][string]$Listen,
  [string]$BotUrl = "",
  [string]$Java = "",
  [int]$Port = 8797,
  [int]$AdminPort = 8796
)
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$Account = "btsigner"
$Prog = Join-Path $env:ProgramFiles "btsign"
$Data = Join-Path $env:ProgramData "btsign"
$Svc = "btsign"

$id = [Security.Principal.WindowsIdentity]::GetCurrent()
if (-not ([Security.Principal.WindowsPrincipal]$id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  throw "run as a local Administrator"
}
if (-not ($Listen -match '^100\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])\.\d{1,3}\.\d{1,3}$')) {
  throw "-Listen must be this machine's tailnet (100.64.0.0/10) address"
}
if (-not $Java) {
  $Java = (Get-Command java.exe -ErrorAction Stop).Source
}

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class BtsignLsa {
  [StructLayout(LayoutKind.Sequential)] struct LSA_UNICODE_STRING { public ushort Length; public ushort MaximumLength; public IntPtr Buffer; }
  [StructLayout(LayoutKind.Sequential)] struct LSA_OBJECT_ATTRIBUTES { public int Length; public IntPtr RootDirectory; public IntPtr ObjectName; public uint Attributes; public IntPtr SecurityDescriptor; public IntPtr SecurityQualityOfService; }
  [DllImport("advapi32.dll")] static extern uint LsaOpenPolicy(IntPtr SystemName, ref LSA_OBJECT_ATTRIBUTES attrs, uint access, out IntPtr handle);
  [DllImport("advapi32.dll")] static extern uint LsaAddAccountRights(IntPtr handle, byte[] sid, LSA_UNICODE_STRING[] rights, uint count);
  [DllImport("advapi32.dll")] static extern uint LsaClose(IntPtr handle);
  [DllImport("advapi32.dll")] static extern int LsaNtStatusToWinError(uint status);
  public static void Add(byte[] sid, string right) {
    var attrs = new LSA_OBJECT_ATTRIBUTES();
    IntPtr h;
    uint st = LsaOpenPolicy(IntPtr.Zero, ref attrs, 0x00000800 | 0x00000010, out h);
    if (st != 0) throw new Exception("LsaOpenPolicy: " + LsaNtStatusToWinError(st));
    try {
      var s = new LSA_UNICODE_STRING();
      s.Buffer = Marshal.StringToHGlobalUni(right);
      s.Length = (ushort)(right.Length * 2); s.MaximumLength = (ushort)(s.Length + 2);
      st = LsaAddAccountRights(h, sid, new[] { s }, 1);
      Marshal.FreeHGlobal(s.Buffer);
      if (st != 0) throw new Exception("LsaAddAccountRights " + right + ": " + LsaNtStatusToWinError(st));
    } finally { LsaClose(h); }
  }
}
"@

function New-Password {
  $bytes = New-Object byte[] 36
  [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
  # Base64 plus a fixed tail that satisfies any complexity policy.
  return [Convert]::ToBase64String($bytes) + "aA1!"
}

function Install-Program {
  Write-Host "program files: $Prog"
  if (Test-Path $Prog) {
    foreach ($d in "python", "lib", "app") {
      $p = Join-Path $Prog $d
      if (Test-Path $p) { Remove-Item -LiteralPath $p -Recurse -Force }
    }
  } else {
    New-Item -ItemType Directory -Path $Prog | Out-Null
  }
  $zip = Get-ChildItem -LiteralPath $Stage -Filter "python-*-embed-amd64.zip" | Select-Object -First 1
  Expand-Archive -LiteralPath $zip.FullName -DestinationPath (Join-Path $Prog "python")
  $pth = Get-ChildItem -LiteralPath (Join-Path $Prog "python") -Filter "python3*._pth" | Select-Object -First 1
  $zipName = (Get-ChildItem -LiteralPath (Join-Path $Prog "python") -Filter "python3*.zip" | Select-Object -First 1).Name
  # Isolated: the stdlib zip, the pinned packages and the signer's code; no site, no user paths.
  Set-Content -LiteralPath $pth.FullName -Encoding ascii -Value @($zipName, ".", "..\lib", "..\app")
  $py = (Get-Command python.exe -ErrorAction Stop).Source
  & $py -m pip install --quiet --no-index --no-deps --require-hashes --only-binary=:all: `
      --find-links (Join-Path $Stage "wheels") -r (Join-Path $Stage "requirements-windows.txt") `
      --target (Join-Path $Prog "lib") --python-version 3.14 --platform win_amd64 --implementation cp
  if ($LASTEXITCODE -ne 0) { throw "pip install failed" }
  Copy-Item -LiteralPath (Join-Path $Stage "app") -Destination (Join-Path $Prog "app") -Recurse
  Copy-Item -LiteralPath (Join-Path $Stage "apksigner.jar") -Destination (Join-Path $Prog "apksigner.jar") -Force
  $jarSha = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $Prog "apksigner.jar")).Hash.ToLower()
  $want = (Get-Content -LiteralPath (Join-Path $Stage "apksigner.jar.sha256") -Raw).Trim().Split(" ")[0]
  if ($jarSha -ne $want) { throw "apksigner.jar SHA-256 $jarSha is not the staged pin $want" }
  $javaBin = Split-Path $Java
  $cfg = @(
    "# btsign settings (not secret). Written by install.ps1.",
    "listen = `"$Listen`"",
    "port = $Port",
    "admin_port = $AdminPort",
    "bot_url = `"$BotUrl`"",
    "java = '$Java'",
    "jarsigner = '$(Join-Path $javaBin "jarsigner.exe")'",
    "keytool = '$(Join-Path $javaBin "keytool.exe")'",
    "apksigner_jar = '$(Join-Path $Prog "apksigner.jar")'",
    "apksigner_jar_sha256 = `"$jarSha`"",
    "# The schemes the release APKs carry (apksigner verify -v of the published 26.10.24 APK).",
    "apk_schemes = { v1 = false, v2 = true, v3 = false, v4 = false }"
  )
  Set-Content -LiteralPath (Join-Path $Prog "btsign.toml") -Encoding ascii -Value $cfg
  # pip --target moves files out of the caller's temp folder with the caller's own ACL: give every
  # program file the folder's inherited ACL (Users read), or btsigner cannot import them.
  & icacls.exe $Prog /reset /T /Q | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "icacls reset of $Prog failed" }
}

function Lock-Data([string]$sidText) {
  if (-not (Test-Path $Data)) { New-Item -ItemType Directory -Path $Data | Out-Null }
  # btsigner alone: its own full-control entry, owner, then every inherited entry dropped
  # (Administrators and SYSTEM included). An Administrator can still take ownership: the limit
  # docs/RELEASING.md states.
  & icacls.exe $Data /grant:r "*${sidText}:(OI)(CI)F" | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "icacls grant failed" }
  & icacls.exe $Data /setowner "*$sidText" | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "icacls setowner failed" }
  & icacls.exe $Data /inheritance:r | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "icacls inheritance failed" }
  Write-Host "data folder: $Data (ACL: $Account only)"
}

$existing = Get-Service -Name $Svc -ErrorAction SilentlyContinue
if ($existing) {
  Write-Host "upgrading: the service exists; the account and its password are left alone"
  if ($existing.Status -ne "Stopped") { Stop-Service -Name $Svc; (Get-Service $Svc).WaitForStatus("Stopped", "00:00:30") }
  Install-Program
  Start-Service -Name $Svc
  Write-Host "service ${Svc}: $((Get-Service $Svc).Status)"
  exit 0
}

if (Get-LocalUser -Name $Account -ErrorAction SilentlyContinue) {
  throw "account $Account exists but the service does not: refusing to reset its password (that would lose DPAPI data). Remove the account by hand if the store is not needed."
}
$plain = New-Password
$secure = ConvertTo-SecureString $plain -AsPlainText -Force
New-LocalUser -Name $Account -Password $secure -PasswordNeverExpires -UserMayNotChangePassword `
  -AccountNeverExpires -Description "BT Labs release signer service (btsign)" | Out-Null
Add-LocalGroupMember -SID S-1-5-32-545 -Member $Account   # Users
$sidText = (Get-LocalUser -Name $Account).SID.Value
$sidObj = New-Object Security.Principal.SecurityIdentifier($sidText)
$sidBytes = New-Object byte[] ($sidObj.BinaryLength)
$sidObj.GetBinaryForm($sidBytes, 0)
foreach ($r in "SeServiceLogonRight", "SeDenyInteractiveLogonRight", "SeDenyRemoteInteractiveLogonRight", "SeDenyNetworkLogonRight") {
  [BtsignLsa]::Add($sidBytes, $r)
}
# Not on the sign-in screen.
$ul = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList"
if (-not (Test-Path $ul)) { New-Item -Path $ul -Force | Out-Null }
New-ItemProperty -Path $ul -Name $Account -Value 0 -PropertyType DWord -Force | Out-Null

Install-Program
Lock-Data $sidText

$bin = "`"$(Join-Path $Prog 'python\python.exe')`" `"$(Join-Path $Prog 'app\btsign.py')`" service --data `"$Data`" --config `"$(Join-Path $Prog 'btsign.toml')`""
$cred = New-Object Management.Automation.PSCredential(".\$Account", $secure)
New-Service -Name $Svc -BinaryPathName $bin -DisplayName "BT Labs release signer (btsign)" `
  -Description "Signs Epic Wallet releases after the owner's TOTP approval (docs/RELEASING.md, Signer)." `
  -StartupType Automatic -Credential $cred | Out-Null
$plain = $null; $secure = $null; $cred = $null
& sc.exe config $Svc start= delayed-auto | Out-Null
& sc.exe failure $Svc reset= 86400 actions= restart/60000/restart/60000/restart/300000 | Out-Null

$rule = "btsign signer (tailnet)"
Get-NetFirewallRule -DisplayName $rule -ErrorAction SilentlyContinue | Remove-NetFirewallRule
New-NetFirewallRule -DisplayName $rule -Direction Inbound -Action Allow -Protocol TCP -LocalPort $Port `
  -LocalAddress $Listen -RemoteAddress "100.64.0.0/10" -Program (Join-Path $Prog "python\python.exe") | Out-Null

Start-Service -Name $Svc
(Get-Service $Svc).WaitForStatus("Running", "00:00:45")
Write-Host "service ${Svc}: $((Get-Service $Svc).Status) as .\$Account"
