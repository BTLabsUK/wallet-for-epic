# Builds the Windows installer, epic-wallet-<version>-windows-x64-setup.exe, in one go. Run in
# PowerShell 7 (pwsh -NoProfile -File) on Windows, in a session without a window: nothing is started.
#
# Needs what build_windows.ps1 needs (Flutter, rustup, VS 2022 Build Tools, CMake, Git) plus
# Inno Setup 6 (ISCC.exe; installed per user by `innosetup-6.x.exe /VERYSILENT /CURRENTUSER`).
# -Source is the repository checkout (default: this script's repository). -Lepic is a LEPIC
# repository holding the commit in tools\lepic.rev. -LepicCache optionally names an earlier
# <checkout>\app\third_party\lepic to copy first, so unchanged Rust crates are not rebuilt.
#
# Steps: LEPIC at the pin -> lepic_ffi.dll with a static CRT (RUSTFLAGS crt-static) ->
# flutter build windows --release (version from pubspec.yaml) -> checks (VersionInfo, storage
# prefix) -> VC runtime DLLs next to epic_wallet.exe -> Inno Setup -> .exe and .exe.sha256 in -OutDir.
param(
    [string]$Source = (Join-Path $PSScriptRoot '..\..'),
    [Parameter(Mandatory)][string]$Lepic,
    [string]$LepicCache,
    [string]$OutDir,
    [string]$Flutter = "$env:USERPROFILE\flutter\bin",
    [string]$Iscc = "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe",
    # The built-in node's epic.exe (optional), bundled as bin\epic.exe next to epic_wallet.exe.
    [string]$NodeBin
)
$ErrorActionPreference = 'Stop'
$Source = (Resolve-Path $Source).Path
$app = Join-Path $Source 'app'
if (-not $OutDir) { $OutDir = Join-Path $app 'build\installer' }
New-Item -ItemType Directory -Force $OutDir | Out-Null
$OutDir = (Resolve-Path $OutDir).Path
$env:Path = @($Flutter, "$env:USERPROFILE\.cargo\bin", $env:Path) -join ';'
foreach ($tool in 'flutter', 'rustup', 'cargo', 'cmake', 'git') {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) { throw "$tool not found on PATH" }
}
if (-not (Test-Path $Iscc)) { throw "ISCC.exe not found at $Iscc (install Inno Setup 6)" }

function Step($m) { Write-Output "`n== $m" }

# --- LEPIC at the pin
Step 'LEPIC'
$rev = (Get-Content (Join-Path $Source 'tools\lepic.rev') -Raw).Trim()
$clone = Join-Path $app 'third_party\lepic'
if ($LepicCache -and -not (Test-Path $clone)) {
    New-Item -ItemType Directory -Force (Split-Path $clone) | Out-Null
    robocopy $LepicCache $clone /E /NFL /NDL /NJH /NJS /NP | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "copying $LepicCache failed" }
}
if (-not (Test-Path "$clone\.git")) {
    git clone --quiet --no-checkout $Lepic $clone
    if ($LASTEXITCODE) { throw "could not clone LEPIC from $Lepic" }
}
git -C $clone fetch --quiet $Lepic '+refs/heads/*:refs/remotes/source/*'
if ($LASTEXITCODE) { throw "could not fetch LEPIC from $Lepic" }
git -C $clone checkout --quiet --detach $rev
if ($LASTEXITCODE) { throw "LEPIC $rev is not in $Lepic" }
if (git -C $clone status --porcelain --untracked-files=no) { throw "$clone has local changes" }
Write-Output "LEPIC at $(git -C $clone log --oneline -1)"

# --- lepic_ffi.dll, static CRT: the target needs no VC runtime or UCRT DLLs of its own
Step 'lepic_ffi.dll (static CRT)'
Remove-Item Env:CARGO_TARGET_DIR -ErrorAction SilentlyContinue
$env:RUSTFLAGS = '-C target-feature=+crt-static'
Push-Location $clone
try {
    cargo xtask mobile --package --target x86_64-pc-windows-msvc
    if ($LASTEXITCODE) { throw 'LEPIC build failed' }
} finally { Pop-Location; Remove-Item Env:RUSTFLAGS }
$ffi = Get-ChildItem $clone -Recurse -Filter lepic_ffi.dll | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$dumpbin = Get-ChildItem "${env:ProgramFiles(x86)}\Microsoft Visual Studio" -Recurse -Filter dumpbin.exe -ErrorAction SilentlyContinue |
    Where-Object FullName -like '*Hostx64\x64*' | Select-Object -First 1
if ($dumpbin -and $ffi) {
    $deps = & $dumpbin.FullName /dependents $ffi.FullName | Where-Object { $_ -match '\.dll\s*$' } | ForEach-Object { $_.Trim() }
    Write-Output "lepic_ffi.dll ($($ffi.FullName)) depends on: $($deps -join ', ')"
    $crt = $deps | Where-Object { $_ -match '^(vcruntime|msvcp|api-ms-win-crt|ucrtbase)' }
    if ($crt) { throw "lepic_ffi.dll still needs the C runtime: $($crt -join ', ')" }
}

# --- Flutter
Step 'flutter build windows'
$ver = (Select-String -Path (Join-Path $app 'pubspec.yaml') -Pattern '^version:\s*(\d+\.\d+\.\d+)\+(\d+)').Matches[0].Groups
$name = $ver[1].Value; $number = $ver[2].Value
Set-Location $app
flutter pub get
if ($LASTEXITCODE) { throw 'pub get failed' }
flutter build windows --release --target lib/main_desktop.dart --build-name $name --build-number $number
if ($LASTEXITCODE) { throw 'flutter build windows failed' }
$rel = Join-Path $app 'build\windows\x64\runner\Release'
# A failed configure leaves only the exe here (install prefix pointed elsewhere): refuse that.
foreach ($f in 'epic_wallet.exe', 'flutter_windows.dll', 'lepic_ffi.dll', 'data\icudtl.dat', 'flutter_secure_storage_windows_plugin.dll') {
    if (-not (Test-Path "$rel\$f")) { throw "$rel\$f is missing. Delete build\windows and build again." }
}

Step 'checks'
$info = (Get-Item "$rel\epic_wallet.exe").VersionInfo
Write-Output "ProductName=$($info.ProductName) CompanyName=$($info.CompanyName) ProductVersion=$($info.ProductVersion) FileVersion=$($info.FileVersion)"
if ($info.ProductName -ne 'EpicWallet' -or $info.CompanyName -ne 'com.blacktyger' -or $info.ProductVersion -notlike "$name*") {
    throw 'epic_wallet.exe VersionInfo is not EpicWallet / com.blacktyger / version'
}
$text = [Text.Encoding]::ASCII.GetString([IO.File]::ReadAllBytes("$rel\flutter_secure_storage_windows_plugin.dll"))
if (-not $text.Contains('EpicWallet_VGhp')) { throw 'secure-storage prefix EpicWallet_ missing' }
if ($text.Contains('epic_wallet_VGhp') -or $text.Contains('epic_wallet_lepic_VGhp') -or $text.Contains('epic_wallet_desktop_ui_VGhp')) {
    throw 'an old secure-storage prefix is still in the plugin'
}
Write-Output 'secure-storage prefix: EpicWallet_ only'

# --- VC runtime next to the exe (the Flutter engine and plugins link it dynamically)
Step 'VC runtime'
foreach ($d in 'msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll') {
    Copy-Item "$env:SystemRoot\System32\$d" $rel -Force
    Write-Output "bundled $d $((Get-Item "$rel\$d").VersionInfo.FileVersion)"
}

if ($NodeBin) {
    New-Item -ItemType Directory -Force "$rel\bin" | Out-Null
    Copy-Item $NodeBin "$rel\bin\epic.exe" -Force
    Write-Output "bundled bin\epic.exe $((Get-FileHash "$rel\bin\epic.exe" -Algorithm SHA256).Hash.ToLower())"
}

# --- installer
Step 'Inno Setup'
$iss = Join-Path $app 'windows\installer\epic_wallet.iss'
& $Iscc /Qp "/DSourceDir=$rel" "/DOutputDir=$OutDir" "/DAppVersion=$name" $iss
if ($LASTEXITCODE) { throw 'ISCC failed' }
$setup = Join-Path $OutDir "epic-wallet-$name-windows-x64-setup.exe"
$hash = (Get-FileHash $setup -Algorithm SHA256).Hash.ToLower()
"$hash  $(Split-Path $setup -Leaf)" | Set-Content -Encoding ascii "$setup.sha256"
Write-Output "Wrote $setup ($((Get-Item $setup).Length) bytes) sha256 $hash"
