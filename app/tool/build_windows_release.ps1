# SPDX-License-Identifier: Apache-2.0
# Builds the Windows installer, bt-wallet-<version>[-notor]-windows-x64-setup.exe, in one go. Run in
# PowerShell 7 (pwsh -NoProfile -File) on Windows, in a session without a window: nothing is started.
# -Dist msstore builds the Microsoft Store package instead, bt-wallet-<version>-msstore-windows-x64.msix
# (https://docs.btlabs.uk/developers/build/variants/): no in-app updater, no Inno Setup, an unsigned MSIX that the Store signs.
#
# Needs what build_windows.ps1 needs (Flutter, rustup, VS 2022 Build Tools, CMake, Git) plus
# Inno Setup 6 (ISCC.exe; installed per user by `innosetup-6.x.exe /VERYSILENT /CURRENTUSER`).
# -Source is the repository checkout (default: this script's repository). -Lepic is a LEPIC
# repository holding the commit in tools\lepic.rev, -LepicFlutter the lepic-flutter repository
# (package:lepic) holding the commit in tools\lepic-flutter.rev, whose own lepic.rev must equal
# tools\lepic.rev. -LepicCache optionally names an earlier <checkout>\app\third_party\lepic to
# copy first, so unchanged Rust crates are not rebuilt. -CargoTarget names LEPIC's cargo target
# directory, outside the checkout and kept between builds (one per variant: two builds never share
# one), so a warm LEPIC build survives a new checkout.
#
# Steps: LEPIC and lepic-flutter at the pins -> lepic_ffi.dll with a static CRT (RUSTFLAGS
# crt-static), built from LEPIC into lepic-flutter\native ->
# flutter build windows --release (version from pubspec.yaml) -> checks (VersionInfo, storage
# prefix) -> VC runtime DLLs next to btwallet.exe -> Authenticode signature on btwallet.exe
# -> Inno Setup -> signature on the installer -> .exe and .exe.sha256 in -OutDir.
#
# Signing: the code-signing certificate stays in the signing machine's certificate store, never in
# the repository. -SignThumbprint (or WFE_SIGN_THUMBPRINT) names it by its SHA-1 thumbprint;
# signtool.exe from the Windows SDK signs with SHA-256 and an RFC 3161 timestamp. Without one
# the build goes on unsigned and says so, and SmartScreen warns on a first install.
param(
    [string]$Source = (Join-Path $PSScriptRoot '..\..'),
    [Parameter(Mandatory)][string]$Lepic,
    [Parameter(Mandatory)][string]$LepicFlutter,
    [string]$LepicCache,
    [string]$CargoTarget,
    [string]$OutDir,
    [string]$Flutter = "$env:USERPROFILE\flutter\bin",
    [string]$Iscc = "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe",
    # The built-in node's epic.exe (optional), bundled as bin\epic.exe next to btwallet.exe.
    # Default: $env:WFE_NODE_BIN_WIN; unset, with WFE_FETCH_INPUTS=1 (the hosted runner), the pinned
    # one (tools/build-inputs.json) is downloaded by tools/fetch-build-inputs.sh in Git Bash.
    [string]$NodeBin = $env:WFE_NODE_BIN_WIN,
    # The Tor bundle from tools/fetch-tor.sh win (tor.exe, LICENSE.tor.txt, VERSION), bundled as
    # bin\tor-bundle next to btwallet.exe. Without it the app shows Tor as not included.
    [string]$TorBundle,
    # The build without Tor (https://docs.btlabs.uk/developers/build/variants/): --dart-define=WFE_TOR=false, LEPIC without
    # its tor feature, no Tor bundle (-TorBundle is refused), -notor in the installer's name.
    [switch]$NoTor,
    # The commit shown beside the version in the app (WFE_BUILD_ID); default: $env:WFE_BUILD_ID,
    # else -Source's HEAD.
    [string]$BuildId = $env:WFE_BUILD_ID,
    # A rebuild of the same version (WFE_BUILD_TAG, e.g. r2); default: from the tag v<version>-rN
    # on -Source's HEAD.
    [string]$BuildTag,
    # The code-signing certificate's SHA-1 thumbprint in CurrentUser\My or LocalMachine\My.
    [string]$SignThumbprint = $env:WFE_SIGN_THUMBPRINT,
    [string]$SignTool,
    [string]$TimestampUrl = 'http://timestamp.digicert.com',
    # Where the build is distributed (https://docs.btlabs.uk/developers/build/variants/): web (our page: the installer) or
    # msstore (the Microsoft Store: an MSIX package, https://docs.btlabs.uk/developers/build/variants/).
    [ValidateSet('web', 'msstore')][string]$Dist = 'web',
    # The MSIX identity, as Partner Center shows it under Product management > Product identity.
    # The defaults are placeholders: the Store refuses a package whose identity is not the one it
    # gave the app. A test build signed with a test certificate names that certificate's subject.
    [string]$MsixName = 'BTLabs.BTWallet',
    [string]$MsixPublisher = 'CN=00000000-0000-0000-0000-000000000000',
    [string]$MsixPublisherDisplayName = 'BT Labs'
)
$ErrorActionPreference = 'Stop'
if ($NoTor -and $TorBundle) { throw '-NoTor builds without Tor: leave out -TorBundle' }
if ($Dist -eq 'msstore' -and $NoTor) { throw '-Dist msstore is the build with Tor (https://docs.btlabs.uk/developers/build/variants/)' }

# Signs $File with the certificate -SignThumbprint names, or says the build is unsigned.
function Sign-File([string]$File) {
    if (-not $SignThumbprint) {
        Write-Warning "not signed: $(Split-Path $File -Leaf) (no -SignThumbprint / WFE_SIGN_THUMBPRINT)"
        return
    }
    $tool = $SignTool
    if (-not $tool) {
        $tool = Get-ChildItem "${env:ProgramFiles(x86)}\Windows Kits\10\bin\*\x64\signtool.exe" -ErrorAction SilentlyContinue |
            Sort-Object FullName -Descending | Select-Object -First 1 -ExpandProperty FullName
    }
    if (-not $tool) { throw 'signtool.exe not found: install the Windows SDK or pass -SignTool' }
    & $tool sign /sha1 $SignThumbprint /fd SHA256 /tr $TimestampUrl /td SHA256 $File
    if ($LASTEXITCODE) { throw "signtool could not sign $File" }
    & $tool verify /pa $File
    if ($LASTEXITCODE) { throw "the signature of $File does not verify" }
}
$variant = if ($NoTor) { '-notor' } else { '' }
$torDefine = if ($NoTor) { 'false' } else { 'true' }
$Source = (Resolve-Path $Source).Path
$app = Join-Path $Source 'app'
if (-not $OutDir) { $OutDir = Join-Path $app 'build\installer' }
New-Item -ItemType Directory -Force $OutDir | Out-Null
$OutDir = (Resolve-Path $OutDir).Path
$env:Path = @($Flutter, "$env:USERPROFILE\.cargo\bin", $env:Path) -join ';'
foreach ($tool in 'flutter', 'rustup', 'cargo', 'cmake', 'git') {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) { throw "$tool not found on PATH" }
}
if ($Dist -eq 'msstore') {
    # MakeAppx and MakePri from the newest Windows SDK.
    $kit = Get-ChildItem "${env:ProgramFiles(x86)}\Windows Kits\10\bin\*\x64\makeappx.exe" -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending | Select-Object -First 1
    if (-not $kit) { throw 'makeappx.exe not found: install the Windows SDK' }
    $kit = Split-Path $kit.FullName
} elseif (-not (Test-Path $Iscc)) { throw "ISCC.exe not found at $Iscc (install Inno Setup 6)" }

function Step($m) { Write-Output "`n== $m" }

# --- LEPIC and lepic-flutter at the pins
Step 'LEPIC'
$rev = (Get-Content (Join-Path $Source 'tools\lepic.rev') -Raw).Trim()
$clone = Join-Path $app 'third_party\lepic'
# No -LepicCache: reuse the newest earlier build folder beside this one (…\wfe-rel\*\src) whose
# LEPIC is at the same pin and was built (a cargo target inside, or lepic.built beside it once the
# target is -CargoTarget), so an unchanged LEPIC is not compiled again: the copy keeps the sources'
# times, which cargo compares with its last build.
function Built($dir) { @("$dir\target", "$dir.built") | Where-Object { Test-Path $_ } | Select-Object -First 1 }
if (-not $LepicCache -and -not (Test-Path $clone)) {
    $builds = Split-Path (Split-Path (Resolve-Path $Source))
    $LepicCache = Get-ChildItem $builds -Directory -ErrorAction SilentlyContinue |
        ForEach-Object { Join-Path $_.FullName 'src\app\third_party\lepic' } |
        Where-Object { (Built $_) -and ((git -C $_ rev-parse HEAD 2>$null) -eq $rev) } |
        Sort-Object { (Get-Item (Built $_)).LastWriteTime } -Descending | Select-Object -First 1
    if ($LepicCache) { Write-Output "LEPIC cache: $LepicCache" }
}
if ($LepicCache -and -not (Test-Path $clone)) {
    New-Item -ItemType Directory -Force (Split-Path $clone) | Out-Null
    # With -CargoTarget the sources only: the build goes to that target, not one copied along.
    $skip = @(if ($CargoTarget) { '/XD'; "$LepicCache\target" })
    robocopy $LepicCache $clone /E /NFL /NDL /NJH /NJS /NP @skip | Out-Null
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

$bindingRev = (Get-Content (Join-Path $Source 'tools\lepic-flutter.rev') -Raw).Trim()
$binding = Join-Path $app 'third_party\lepic-flutter'
if (-not (Test-Path "$binding\.git")) {
    New-Item -ItemType Directory -Force (Split-Path $binding) | Out-Null
    git clone --quiet --no-checkout $LepicFlutter $binding
    if ($LASTEXITCODE) { throw "could not clone lepic-flutter from $LepicFlutter" }
}
git -C $binding fetch --quiet $LepicFlutter '+refs/heads/*:refs/remotes/source/*'
if ($LASTEXITCODE) { throw "could not fetch lepic-flutter from $LepicFlutter" }
git -C $binding checkout --quiet --detach $bindingRev
if ($LASTEXITCODE) { throw "lepic-flutter $bindingRev is not in $LepicFlutter" }
if (git -C $binding status --porcelain --untracked-files=no) { throw "$binding has local changes" }
$bindingPin = (Get-Content (Join-Path $binding 'lepic.rev') -Raw).Trim()
if ($bindingPin -ne $rev) {
    throw "tools\lepic.rev ($rev) differs from the LEPIC pin of lepic-flutter $bindingRev ($bindingPin)"
}
Write-Output "lepic-flutter at $(git -C $binding log --oneline -1)"

# --- lepic_ffi.dll, static CRT: the target needs no VC runtime or UCRT DLLs of its own
Step 'lepic_ffi.dll (static CRT)'
if ($CargoTarget) {
    New-Item -ItemType Directory -Force $CargoTarget | Out-Null
    $env:CARGO_TARGET_DIR = $CargoTarget
    Write-Output "cargo target: $CargoTarget"
} else { Remove-Item Env:CARGO_TARGET_DIR -ErrorAction SilentlyContinue }
$env:RUSTFLAGS = '-C target-feature=+crt-static'
Push-Location $clone
try {
    # xtask has the clone's path built in (CARGO_MANIFEST_DIR) and builds LEPIC there. A target
    # copied or kept from another clone would run the xtask built for that one, against that
    # clone's sources: build it again for this clone (seconds).
    cargo clean --quiet --package xtask
    if ($LASTEXITCODE) { throw 'cargo clean --package xtask failed' }
    # -NoTor: LEPIC without its tor feature, so lepic_ffi.dll carries no Tor code either.
    $lepicNoTor = @(if ($NoTor) { '--no-tor' })
    cargo xtask mobile --package --target x86_64-pc-windows-msvc @lepicNoTor --out (Join-Path $binding 'native')
    if ($LASTEXITCODE) { throw 'LEPIC build failed' }
    Set-Content -Path "$clone.built" -Value $rev
} finally { Pop-Location; Remove-Item Env:RUSTFLAGS; Remove-Item Env:CARGO_TARGET_DIR -ErrorAction SilentlyContinue }
$ffi = Get-ChildItem (Join-Path $binding 'native') -Recurse -Filter lepic_ffi.dll | Sort-Object LastWriteTime -Descending | Select-Object -First 1
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
# pubspec.yaml's YY.MM.patch (a test build adds -rcN) and its build number (https://docs.btlabs.uk/developers/releases/).
# The exe and the installer carry YY.MM.patch.0: the build number is Android's versionCode and
# does not fit a VERSIONINFO field (windows\runner\CMakeLists.txt leaves it out).
$ver = (Select-String -Path (Join-Path $app 'pubspec.yaml') -Pattern '^version:\s*((\d+)\.(\d+)\.(\d+)(?:-rc\d+)?)\+(\d+)').Matches[0].Groups
$name = $ver[1].Value; $number = $ver[5].Value
$fileVersion = "$($ver[2].Value).$($ver[3].Value).$($ver[4].Value).0"
Set-Location $app
flutter pub get
if ($LASTEXITCODE) { throw 'pub get failed' }
if (-not $BuildId) { $BuildId = (git -C $Source rev-parse --short=7 HEAD) }
if (-not $BuildTag) {
    foreach ($t in @(git -C $Source tag --points-at HEAD)) { if ($t -match '^v[\d.]+-(r\d+)$') { $BuildTag = $Matches[1] } }
}
Write-Output "build id: $BuildId $BuildTag"
flutter build windows --release --target lib/main_desktop.dart --build-name $name --build-number $number --dart-define=WFE_BUILD_ID=$BuildId --dart-define=WFE_BUILD_TAG=$BuildTag --dart-define=WFE_TOR=$torDefine --dart-define=WFE_DIST=$Dist
if ($LASTEXITCODE) { throw 'flutter build windows failed' }
$rel = Join-Path $app 'build\windows\x64\runner\Release'
# A failed configure leaves only the exe here (install prefix pointed elsewhere): refuse that.
foreach ($f in 'btwallet.exe', 'flutter_windows.dll', 'lepic_ffi.dll', 'data\icudtl.dat', 'flutter_secure_storage_windows_plugin.dll') {
    if (-not (Test-Path "$rel\$f")) { throw "$rel\$f is missing. Delete build\windows and build again." }
}

Step 'checks'
$info = (Get-Item "$rel\btwallet.exe").VersionInfo
Write-Output "ProductName=$($info.ProductName) CompanyName=$($info.CompanyName) ProductVersion=$($info.ProductVersion) FileVersion=$($info.FileVersion)"
if ($info.ProductName -ne 'BT Wallet' -or $info.CompanyName -ne 'BT Labs' -or $info.ProductVersion -ne $name) {
    throw 'btwallet.exe VersionInfo is not BT Wallet / BT Labs / version'
}
$numbers = "$($info.FileMajorPart).$($info.FileMinorPart).$($info.FileBuildPart).$($info.FilePrivatePart)"
if ($numbers -ne $fileVersion) { throw "btwallet.exe file version is $numbers, not $fileVersion" }
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

if (-not $NodeBin -and $env:WFE_FETCH_INPUTS -eq '1') {
    $bash = Get-Command bash -ErrorAction SilentlyContinue
    if (-not $bash) { throw 'WFE_FETCH_INPUTS=1 needs bash (Git Bash) on PATH' }
    $fetched = & $bash.Source (Join-Path $Source 'tools/fetch-build-inputs.sh') node windows (Join-Path $env:TEMP 'wfe-node-input') | Select-Object -Last 1
    if ($LASTEXITCODE -or -not $fetched) { throw 'tools/fetch-build-inputs.sh node windows failed' }
    $NodeBin = (& $bash.Source -c "cygpath -w '$fetched'") | Select-Object -Last 1
    Write-Output "node binary fetched: $NodeBin"
}
if ($NodeBin) {
    New-Item -ItemType Directory -Force "$rel\bin" | Out-Null
    Copy-Item $NodeBin "$rel\bin\epic.exe" -Force
    Write-Output "bundled bin\epic.exe $((Get-FileHash "$rel\bin\epic.exe" -Algorithm SHA256).Hash.ToLower())"
}

if ($TorBundle) {
    if (-not (Test-Path "$TorBundle\tor.exe")) { throw "$TorBundle\tor.exe is missing" }
    if (Test-Path "$rel\bin\tor-bundle") { Remove-Item -Recurse -Force "$rel\bin\tor-bundle" }
    New-Item -ItemType Directory -Force "$rel\bin\tor-bundle" | Out-Null
    Copy-Item "$TorBundle\*" "$rel\bin\tor-bundle" -Force
    Write-Output "bundled bin\tor-bundle: $((Get-Content "$rel\bin\tor-bundle\VERSION" -Raw).Trim()), tor.exe $((Get-FileHash "$rel\bin\tor-bundle\tor.exe" -Algorithm SHA256).Hash.ToLower())"
} else {
    # A Release folder of an earlier build with Tor must not lend its tor to this one.
    if (Test-Path "$rel\bin\tor-bundle") { Remove-Item -Recurse -Force "$rel\bin\tor-bundle" }
    if ($NoTor) { Write-Output 'no Tor: the build without Tor (WFE_TOR=false)' }
    else { Write-Output 'no -TorBundle: Tor shows as not included in this build' }
}

# --- signature on the app, then the installer that carries it
Step 'Authenticode'
Sign-File "$rel\btwallet.exe"

# --- the Microsoft Store package: the Release folder as it is, with the manifest and the logos
if ($Dist -eq 'msstore') {
    Step 'MSIX'
    $msixSrc = Join-Path $app 'windows\msix'
    $stage = Join-Path $app 'build\msix'
    $layout = Join-Path $stage 'layout'
    if (Test-Path $stage) { Remove-Item -Recurse -Force $stage }
    New-Item -ItemType Directory -Force $layout, "$stage\pri" | Out-Null
    robocopy $rel $layout /E /XF *.lib *.exp *.pdb *.ilk /NFL /NDL /NJH /NJS /NP | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "copying $rel failed" }
    Copy-Item (Join-Path $app 'assets\fonts\OFL-Montserrat.txt') "$layout\LICENSE.Montserrat.txt"
    Copy-Item -Recurse "$msixSrc\Assets" "$layout\Assets"
    Copy-Item -Recurse "$msixSrc\Assets" "$stage\pri\Assets"
    $manifest = (Get-Content "$msixSrc\AppxManifest.xml" -Raw).
        Replace('$IdentityName$', [Security.SecurityElement]::Escape($MsixName)).
        Replace('$Publisher$', [Security.SecurityElement]::Escape($MsixPublisher)).
        Replace('$PublisherDisplayName$', [Security.SecurityElement]::Escape($MsixPublisherDisplayName)).
        Replace('$Version$', $fileVersion)
    if ($manifest -match '\$[A-Za-z]+\$') { throw "AppxManifest.xml still has a field to fill: $($Matches[0])" }
    [IO.File]::WriteAllText("$layout\AppxManifest.xml", $manifest, (New-Object Text.UTF8Encoding $false))
    Copy-Item "$layout\AppxManifest.xml" "$stage\pri\AppxManifest.xml"
    # resources.pri indexes only the logos (their scale and targetsize variants), not the app's files.
    & "$kit\makepri.exe" createconfig /cf "$stage\priconfig.xml" /dq en-US /pv 10.0.0 /o | Out-Null
    if ($LASTEXITCODE) { throw 'makepri createconfig failed' }
    & "$kit\makepri.exe" new /pr "$stage\pri" /cf "$stage\priconfig.xml" /mn "$stage\pri\AppxManifest.xml" /of "$layout\resources.pri" /o | Out-Null
    if ($LASTEXITCODE) { throw 'makepri new failed' }
    foreach ($f in 'btwallet.exe', 'lepic_ffi.dll', 'bin\epic.exe', 'bin\tor-bundle\tor.exe', 'resources.pri') {
        if (-not (Test-Path "$layout\$f")) { throw "the package would miss $f (pass -NodeBin and -TorBundle)" }
    }
    $msix = Join-Path $OutDir "bt-wallet-$name-msstore-windows-x64.msix"
    & "$kit\makeappx.exe" pack /d $layout /p $msix /o /h SHA256
    if ($LASTEXITCODE) { throw 'makeappx pack failed' }
    $hash = (Get-FileHash $msix -Algorithm SHA256).Hash.ToLower()
    "$hash  $(Split-Path $msix -Leaf)" | Set-Content -Encoding ascii "$msix.sha256"
    Write-Output "Wrote $msix ($((Get-Item $msix).Length) bytes) sha256 $hash; identity $MsixName, $MsixPublisher; version $fileVersion; unsigned"
    return
}

# --- installer
Step 'Inno Setup'
$iss = Join-Path $app 'windows\installer\epic_wallet.iss'
& $Iscc /Qp "/DSourceDir=$rel" "/DOutputDir=$OutDir" "/DAppVersion=$name" "/DVariant=$variant" $iss
if ($LASTEXITCODE) { throw 'ISCC failed' }
$setup = Join-Path $OutDir "bt-wallet-$name$variant-windows-x64-setup.exe"
# Inno Setup pads the string FileVersion with spaces (and a NUL): compare the trimmed text.
$setupVersion = ((Get-Item $setup).VersionInfo.FileVersion -replace '[\s\x00]', '')
if ($setupVersion -ne $fileVersion) { throw "the installer's file version is $setupVersion, not $fileVersion" }
Sign-File $setup
# The packaging checks of the installer are app/tool/verify_windows_release.sh's (bash, python3),
# which also runs on a downloaded file. Here only when Git Bash is on PATH.
$bash = Get-Command bash -ErrorAction SilentlyContinue
if ($bash -and (Get-Command python3, python -ErrorAction SilentlyContinue)) {
    $env:WFE_VERSION = $name; $env:WFE_BUILD_ID = $BuildId; $env:WFE_TOR = $(if ($NoTor) { '0' } else { '1' })
    & $bash.Source (Join-Path $app 'tool/verify_windows_release.sh') ($setup -replace '\\', '/')
    $rc = $LASTEXITCODE
    Remove-Item Env:WFE_VERSION, Env:WFE_TOR
    if ($rc) { throw 'verify_windows_release.sh failed' }
} else { Write-Warning 'bash or python not found: tool/verify_windows_release.sh not run' }
$hash = (Get-FileHash $setup -Algorithm SHA256).Hash.ToLower()
"$hash  $(Split-Path $setup -Leaf)" | Set-Content -Encoding ascii "$setup.sha256"
Write-Output "Wrote $setup ($((Get-Item $setup).Length) bytes) sha256 $hash"
