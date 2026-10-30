# SPDX-License-Identifier: Apache-2.0
# G4 update trust, Windows: one command to the rig agent (agent.ps1), from the build machine over SSH as the rig user.
# Writes <run>\cmd\<seq>.json, waits for <run>\res\<seq>.json, prints it and removes it.
#   rpc.ps1 <run> <seq> <base64 JSON command> [timeout s]
param([string]$Run, [string]$Seq, [string]$B64, [int]$TimeoutS = 120)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
if (-not $Run.StartsWith('C:\EpicRig\trust\', [StringComparison]::OrdinalIgnoreCase)) { throw "run folder $Run is not under C:\EpicRig\trust" }
$json = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($B64))
$cmd = Join-Path $Run "cmd\$Seq.json"
$res = Join-Path $Run "res\$Seq.json"
$tmp = "$cmd.tmp"
New-Item -ItemType Directory -Force (Join-Path $Run 'cmd'), (Join-Path $Run 'res') | Out-Null
Set-Content -LiteralPath $tmp -Value $json -Encoding utf8 -NoNewline
Move-Item -LiteralPath $tmp -Destination $cmd -Force
$end = (Get-Date).AddSeconds($TimeoutS)
while (-not (Test-Path -LiteralPath $res)) {
  if ((Get-Date) -gt $end) {
    if (Test-Path -LiteralPath $cmd) { Remove-Item -LiteralPath $cmd -Force -ErrorAction SilentlyContinue; '{"ok":false,"error":"agent did not take the command (not running?)"}' }
    else { '{"ok":false,"error":"agent took the command but did not answer in time"}' }
    exit 0
  }
  Start-Sleep -Milliseconds 100
}
Get-Content -Raw -LiteralPath $res
Remove-Item -LiteralPath $res -Force -ErrorAction SilentlyContinue
