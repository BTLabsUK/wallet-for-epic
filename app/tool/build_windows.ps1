# Builds the Windows release and zips it. Run from anywhere in PowerShell 7 on Windows.
#
# Needs: Flutter 3.47.5 (default C:\Users\<you>\flutter), rustup (LEPIC's rust-toolchain.toml
# picks the Rust version), Visual Studio 2022 Build Tools with the C++ workload, CMake and Git.
# -Lepic is a LEPIC repository holding the commit in ..\tools\lepic.rev, -LepicFlutter the
# lepic-flutter repository (package:lepic) holding the commit in ..\tools\lepic-flutter.rev, whose
# own lepic.rev must equal tools\lepic.rev. As tools/lepic.sh does on Linux, the script clones them
# into app\third_party\lepic and app\third_party\lepic-flutter at those commits and builds
# lepic_ffi.dll from the first into the second's native\ with
# `cargo xtask mobile --package --target x86_64-pc-windows-msvc --out <binding>\native`;
# package:lepic's build hook then bundles the DLL next to epic_wallet.exe.
#
# Output: build\epic_wallet-windows-x64-<version>.zip, a portable folder with epic_wallet.exe.
param(
    [string]$Flutter = "$env:USERPROFILE\flutter\bin",
    [string]$Lepic = (Join-Path $PSScriptRoot '..\..\..\lepic'),
    [string]$LepicFlutter = (Join-Path $PSScriptRoot '..\..\..\lepic-flutter')
)
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)

# rustup's shims first, so LEPIC's rust-toolchain.toml wins over any standalone Rust on PATH.
$env:Path = @($Flutter, "$env:USERPROFILE\.cargo\bin", $env:Path) -join ';'
foreach ($tool in 'flutter', 'rustup', 'cargo', 'cmake', 'git') {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) { throw "$tool not found on PATH" }
}

$rev = (Get-Content ..\tools\lepic.rev -Raw).Trim()
$clone = 'third_party\lepic'
if (-not (Test-Path "$clone\.git")) {
    git clone --quiet --no-checkout $Lepic $clone
    if ($LASTEXITCODE) { throw "could not clone LEPIC from $Lepic" }
}
git -C $clone fetch --quiet $Lepic '+refs/heads/*:refs/remotes/source/*'
if ($LASTEXITCODE) { throw "could not fetch LEPIC from $Lepic" }
git -C $clone checkout --quiet --detach $rev
if ($LASTEXITCODE) { throw "LEPIC $rev is not in $Lepic" }
if (git -C $clone status --porcelain --untracked-files=no) {
    throw "$clone has local changes; it must match the pin exactly"
}
Write-Output "LEPIC at $(git -C $clone log --oneline -1)"

$bindingRev = (Get-Content ..\tools\lepic-flutter.rev -Raw).Trim()
$binding = 'third_party\lepic-flutter'
if (-not (Test-Path "$binding\.git")) {
    git clone --quiet --no-checkout $LepicFlutter $binding
    if ($LASTEXITCODE) { throw "could not clone lepic-flutter from $LepicFlutter" }
}
git -C $binding fetch --quiet $LepicFlutter '+refs/heads/*:refs/remotes/source/*'
if ($LASTEXITCODE) { throw "could not fetch lepic-flutter from $LepicFlutter" }
git -C $binding checkout --quiet --detach $bindingRev
if ($LASTEXITCODE) { throw "lepic-flutter $bindingRev is not in $LepicFlutter" }
if (git -C $binding status --porcelain --untracked-files=no) {
    throw "$binding has local changes; it must match the pin exactly"
}
$bindingPin = (Get-Content "$binding\lepic.rev" -Raw).Trim()
if ($bindingPin -ne $rev) {
    throw "tools\lepic.rev ($rev) differs from the LEPIC pin of lepic-flutter $bindingRev ($bindingPin)"
}
Write-Output "lepic-flutter at $(git -C $binding log --oneline -1)"

# One target directory per clone: a shared one bakes the wrong paths into xtask.
Remove-Item Env:CARGO_TARGET_DIR -ErrorAction SilentlyContinue
$native = Join-Path (Resolve-Path $binding).Path 'native'
Push-Location $clone
try {
    cargo xtask mobile --package --target x86_64-pc-windows-msvc --out $native
    if ($LASTEXITCODE) { throw 'LEPIC build failed' }
} finally {
    Pop-Location
}

flutter --version
if ($LASTEXITCODE) { throw 'flutter failed' }
flutter pub get
if ($LASTEXITCODE) { throw 'pub get failed' }
flutter build windows --release
if ($LASTEXITCODE) { throw 'flutter build windows failed' }

$version = (Select-String -Path pubspec.yaml -Pattern '^version:\s*(\S+)').Matches[0].Groups[1].Value -replace '\+', '-'
$bundle = 'build\windows\x64\runner\Release'
# A configure that failed once (for example on NuGet) caches C:\Program Files\epic_wallet as the
# install prefix, and later builds install there, leaving only the exe here. Refuse that bundle.
foreach ($file in 'epic_wallet.exe', 'flutter_windows.dll', 'lepic_ffi.dll', 'data\icudtl.dat') {
    if (-not (Test-Path "$bundle\$file")) {
        throw "$bundle\$file is missing. Delete build\windows and build again."
    }
}
$zip = "build\epic_wallet-windows-x64-$version.zip"
Remove-Item $zip -ErrorAction SilentlyContinue
Compress-Archive -Path "$bundle\*" -DestinationPath $zip
Write-Output "Wrote $((Resolve-Path $zip).Path)"
