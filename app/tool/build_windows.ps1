# Builds the Windows release and zips it. Run from app\ in PowerShell 7 on Windows.
#
# Needs: Flutter 3.47.5 (default C:\Users\<you>\flutter), rustup (the Rust 1.89.0 pin in
# rust\rust-toolchain.toml applies only through rustup), Visual Studio 2022 Build Tools with the
# C++ workload, CMake, and Strawberry Perl with its NASM for the vendored OpenSSL and aws-lc.
# ..\playground\src\epic-wallet and ..\playground\src\randomx-rust must exist (`pg sync`).
#
# Output: build\epic_wallet-windows-x64-<version>.zip, a portable folder with epic_wallet.exe.
param(
    [string]$Flutter = "$env:USERPROFILE\flutter\bin",
    [string]$Strawberry = 'C:\Strawberry'
)
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)

# rustup's shims first, so rust-toolchain.toml wins over any standalone Rust on PATH. Strawberry
# Perl before Git's, because OpenSSL's Configure fails under Git's MSYS perl.
$env:Path = @(
    $Flutter,
    "$env:USERPROFILE\.cargo\bin",
    "$Strawberry\perl\bin",
    "$Strawberry\c\bin",
    $env:Path
) -join ';'

foreach ($tool in 'flutter', 'rustup', 'cmake', 'perl', 'nasm') {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) { throw "$tool not found on PATH" }
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
foreach ($file in 'flutter_windows.dll', 'epic_wallet_core.dll', 'data\icudtl.dat') {
    if (-not (Test-Path "$bundle\$file")) {
        throw "$bundle\$file is missing. Delete build\windows and build again."
    }
}
$zip = "build\epic_wallet-windows-x64-$version.zip"
Remove-Item $zip -ErrorAction SilentlyContinue
Compress-Archive -Path "$bundle\*" -DestinationPath $zip
Write-Output "Wrote $((Resolve-Path $zip).Path)"
