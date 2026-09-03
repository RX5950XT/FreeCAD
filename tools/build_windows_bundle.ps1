# FreeCAD Windows Installer Builder
# Based on package/rattler-build/windows/create_bundle.sh

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$condaEnv = Resolve-Path (Join-Path $repoRoot ".pixi/envs/default")
$bundleDir = Join-Path $repoRoot "FreeCAD_Windows"
$binDir = Join-Path $bundleDir "bin"
$installerDir = Join-Path $repoRoot "package/WindowsInstaller"
$installerScript = Join-Path $installerDir "FreeCAD-installer.nsi"
$sslPatchPath = Join-Path $repoRoot "package/rattler-build/windows/ssl-patch.py"
$nsisTempDir = Join-Path $repoRoot ".nsis_tmp"
$nsProcessArchive = Join-Path $repoRoot ".NsProcess.zip"

function Get-NsisCompilerPath {
    $candidates = @(
        (Get-Command "makensis.exe" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue),
        "C:\Program Files (x86)\NSIS\makensis.exe",
        "C:\Program Files\NSIS\makensis.exe"
    ) | Where-Object { $_ -and (Test-Path $_) }

    if (-not $candidates) {
        throw "找不到 makensis.exe。請先安裝 NSIS。"
    }

    return @($candidates)[0]
}

function Get-SevenZipPath {
    $candidates = @(
        (Get-Command "7z.exe" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue),
        "C:\Program Files\7-Zip\7z.exe"
    ) | Where-Object { $_ -and (Test-Path $_) }

    if (-not $candidates) {
        throw "找不到 7z.exe。請先安裝 7-Zip。"
    }

    return @($candidates)[0]
}

function Prepare-NsisCompiler {
    $makensis = Get-NsisCompilerPath
    $sevenZip = Get-SevenZipPath

    if (Test-Path $nsisTempDir) {
        Remove-Item -Recurse -Force $nsisTempDir
    }

    Copy-Item -Recurse -Force (Split-Path $makensis -Parent) $nsisTempDir

    Invoke-WebRequest -Uri "https://nsis.sourceforge.io/mediawiki/images/1/18/NsProcess.zip" -OutFile $nsProcessArchive
    $hash = (Get-FileHash -Algorithm SHA256 $nsProcessArchive).Hash.ToLower()
    if ($hash -ne "fc19fc66a5219a233570fafd5daeb0c9b85387b379f6df5ac8898159a57c5944") {
        throw "NsProcess 下載雜湊不符。"
    }

    & $sevenZip x $nsProcessArchive "-o$nsisTempDir" -y | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "NsProcess 解壓失敗。"
    }

    Move-Item -Force (Join-Path $nsisTempDir "Plugin/nsProcess.dll") (Join-Path $nsisTempDir "Plugins/x86-ansi/nsProcess.dll")
    Move-Item -Force (Join-Path $nsisTempDir "Plugin/nsProcessW.dll") (Join-Path $nsisTempDir "Plugins/x86-unicode/nsProcess.dll")

    return (Join-Path $nsisTempDir "makensis.exe")
}

function Get-InstallerFileName {
    $freecadCmd = Join-Path $condaEnv "Library/bin/freecadcmd.exe"
    if (-not (Test-Path $freecadCmd)) {
        throw "找不到 freecadcmd.exe：$freecadCmd"
    }

    if ($env:BUILD_TAG) {
        return "FreeCAD-TW_$($env:BUILD_TAG)-Windows-x86_64-installer.exe"
    }

    # 以建置時間當版本：每次產出的檔名都不同，也不會跟原版 FreeCAD 的安裝檔混淆
    return "FreeCAD-TW_$(Get-Date -Format 'yyyyMMdd-HHmm')-Windows-x86_64-installer.exe"
}

if (Test-Path $bundleDir) {
    Remove-Item -Recurse -Force $bundleDir
}

Write-Host "=== Step 1: Creating bundle directory structure ===" -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path $binDir | Out-Null
New-Item -ItemType Directory -Force -Path "$bundleDir/share" | Out-Null
New-Item -ItemType Directory -Force -Path "$bundleDir/data" | Out-Null
New-Item -ItemType Directory -Force -Path "$bundleDir/Ext" | Out-Null
New-Item -ItemType Directory -Force -Path "$bundleDir/lib" | Out-Null
New-Item -ItemType Directory -Force -Path "$bundleDir/Mod" | Out-Null
New-Item -ItemType Directory -Force -Path "$bundleDir/doc" | Out-Null

Write-Host "=== Step 2: Copying Python runtime ===" -ForegroundColor Cyan
Copy-Item -Recurse -Force "$condaEnv/DLLs" "$binDir/DLLs"
Copy-Item -Recurse -Force "$condaEnv/Lib" "$binDir/Lib"
if (Test-Path "$condaEnv/Scripts") {
    Copy-Item -Recurse -Force "$condaEnv/Scripts" "$binDir/Scripts"
}
Copy-Item -Force "$condaEnv/python*.dll" "$binDir/"
Copy-Item -Force "$condaEnv/msvc*.dll" "$binDir/" -ErrorAction SilentlyContinue
Copy-Item -Force "$condaEnv/ucrt*.dll" "$binDir/" -ErrorAction SilentlyContinue

Write-Host "=== Step 3: Copying executables ===" -ForegroundColor Cyan
$exes = @("ccx.exe", "gmsh.exe", "dot.exe", "unflatten.exe")
foreach ($exe in $exes) {
    $src = "$condaEnv/Library/bin/$exe"
    if (Test-Path $src) {
        Copy-Item -Force $src "$binDir/"
        Write-Host "  Copied $exe"
    }
}
# mingw-w64 binaries
if (Test-Path "$condaEnv/Library/mingw-w64/bin") {
    Copy-Item -Force "$condaEnv/Library/mingw-w64/bin/*" "$binDir/"
}

Write-Host "=== Step 4: Copying resources and dependencies ===" -ForegroundColor Cyan
Copy-Item -Recurse -Force "$condaEnv/Library/share/*" "$bundleDir/share/" -ErrorAction SilentlyContinue
Copy-Item -Force "$condaEnv/Library/bin/*.dll" "$binDir/"

Write-Host "=== Step 5: Copying FreeCAD build ===" -ForegroundColor Cyan
Copy-Item -Force "$condaEnv/Library/bin/freecad*" "$binDir/" -ErrorAction SilentlyContinue
Copy-Item -Force "$condaEnv/Library/bin/FreeCAD*" "$binDir/"
Copy-Item -Recurse -Force "$condaEnv/Library/data/*" "$bundleDir/data/" -ErrorAction SilentlyContinue
Copy-Item -Recurse -Force "$condaEnv/Library/Ext/*" "$bundleDir/Ext/" -ErrorAction SilentlyContinue
Copy-Item -Recurse -Force "$condaEnv/Library/lib/*" "$bundleDir/lib/" -ErrorAction SilentlyContinue
Copy-Item -Recurse -Force "$condaEnv/Library/Mod/*" "$bundleDir/Mod/" -ErrorAction SilentlyContinue

Write-Host "=== Step 6: Copying documentation ===" -ForegroundColor Cyan
$docs = @("ThirdPartyLibraries.html", "LICENSE.html")
foreach ($doc in $docs) {
    $src = "$condaEnv/Library/doc/$doc"
    if (Test-Path $src) {
        Copy-Item -Force $src "$bundleDir/doc/"
    }
}

Write-Host "=== Step 7: Cleaning up unnecessary files ===" -ForegroundColor Cyan
Get-ChildItem -Path $bundleDir -Recurse -Filter "*.a" | Remove-Item -Force
Get-ChildItem -Path $bundleDir -Recurse -Filter "*.lib" | Remove-Item -Force
Get-ChildItem -Path $bundleDir -Recurse -Filter "*arm*.exe" | Remove-Item -Force -ErrorAction SilentlyContinue

Write-Host "=== Step 8: Applying SSL patch ===" -ForegroundColor Cyan
$sslOrig = "$binDir/Lib/ssl.py"
if (Test-Path $sslOrig) {
    Move-Item -Force $sslOrig "$binDir/Lib/.ssl-orig.py"
    Copy-Item -Force $sslPatchPath "$sslOrig"
    Write-Host "  SSL patch applied"
}

Write-Host "=== Step 9: Creating qt6.conf ===" -ForegroundColor Cyan
"[Paths]" | Out-File -FilePath "$binDir/qt6.conf" -Encoding utf8
"Prefix = ../lib/qt6" | Out-File -FilePath "$binDir/qt6.conf" -Append -Encoding utf8

Write-Host "=== Step 10: Generating packages.txt ===" -ForegroundColor Cyan
& pixi list -e default | Out-File -FilePath "$bundleDir/packages.txt" -Encoding utf8
"`nLIST OF PACKAGES:" | Out-File -FilePath "$bundleDir/packages.txt" -Append -Encoding utf8

Write-Host "=== Step 11: Building NSIS installer ===" -ForegroundColor Cyan
$makensis = Prepare-NsisCompiler
$installerName = Get-InstallerFileName
$installerPath = Join-Path $repoRoot $installerName
$checksumPath = "$installerPath-SHA256.txt"

if (Test-Path $installerPath) {
    Remove-Item -Force $installerPath
}
if (Test-Path $checksumPath) {
    Remove-Item -Force $checksumPath
}

Push-Location $installerDir
try {
    & $makensis `
        "/DExeFile=$installerName" `
        "/DFILES_FREECAD=$bundleDir" `
        "/XSetCompressor /FINAL lzma" `
        $installerScript

    if ($LASTEXITCODE -ne 0) {
        throw "NSIS installer 建置失敗。"
    }
} finally {
    Pop-Location
}

$builtInstaller = Join-Path $installerDir $installerName
if (-not (Test-Path $builtInstaller)) {
    throw "找不到建置完成的 installer：$builtInstaller"
}

Move-Item -Force $builtInstaller $installerPath
$hash = Get-FileHash -Algorithm SHA256 $installerPath
"$($hash.Hash.ToLower()) *$installerName" | Out-File -FilePath $checksumPath -Encoding ascii

Write-Host "=== Installer created at: $installerPath ===" -ForegroundColor Green
Write-Host "SHA256 saved at: $checksumPath" -ForegroundColor Green
Write-Host "Bundle size: $([math]::Round((Get-ChildItem $bundleDir -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB, 2)) MB" -ForegroundColor Green

if (Test-Path $nsisTempDir) {
    Remove-Item -Recurse -Force $nsisTempDir
}
if (Test-Path $nsProcessArchive) {
    Remove-Item -Force $nsProcessArchive
}
