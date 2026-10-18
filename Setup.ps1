[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$GameDir,
    [string]$SetupDir=(Join-Path $env:USERPROFILE 'Games/Ultrakill Craft'),
    [string]$MinecraftDir=(Join-Path $SetupDir 'minecraft-instance'),
    [string]$LauncherDir=(Join-Path $env:APPDATA '.minecraft'),
    [switch]$NoShortcut
)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Setup.Core.ps1')
Assert-Package $PSScriptRoot
if (![Environment]::Is64BitOperatingSystem -or ![Environment]::Is64BitProcess) { throw 'Run setup with 64-bit Windows PowerShell on Windows x64.' }
if (!$GameDir) { $GameDir=Find-Ultrakill }
if (!$GameDir -and !$WhatIfPreference) { $GameDir=(Read-Host 'ULTRAKILL was not found. Paste its Steam install folder').Trim('"') }
if (!$GameDir -or !(Test-Path -LiteralPath (Join-Path $GameDir 'ULTRAKILL.exe'))) { throw 'Install ULTRAKILL in Steam first, or supply -GameDir with its install folder.' }
$GameDir=[IO.Path]::GetFullPath($GameDir)
$MinecraftDir=[IO.Path]::GetFullPath($MinecraftDir)
$SetupDir=[IO.Path]::GetFullPath($SetupDir)
$LauncherDir=[IO.Path]::GetFullPath($LauncherDir)
foreach ($directory in @($SetupDir,$MinecraftDir)) {
    foreach ($appData in @($env:LOCALAPPDATA,$env:APPDATA)) {
        if ($directory -eq $appData -or $directory.StartsWith($appData.TrimEnd('\')+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Choose a Games or Documents folder outside AppData so the Microsoft Store Minecraft Launcher can see Java and the mod files.' }
    }
}
$profileFiles=@('launcher_profiles.json','launcher_profiles_microsoft_store.json' | ForEach-Object { Join-Path $LauncherDir $_ } | Where-Object { Test-Path -LiteralPath $_ })
if (!$profileFiles.Count) { throw 'Install/open the official Minecraft Launcher, sign in, then close it and run setup again. Get it at https://www.minecraft.net/download. The games must already be installed.' }
foreach ($profileFile in $profileFiles) {
    $profileData=Get-Content -LiteralPath $profileFile -Raw | ConvertFrom-Json
    if (!$profileData.profiles) { throw 'Open the official Minecraft Launcher once, then close it and retry.' }
    $existing=$profileData.profiles.'ultrakill-craft'
    if ($existing.gameDir -and [IO.Path]::GetFullPath($existing.gameDir) -ne $MinecraftDir) { throw "The existing Ultrakill Craft profile uses $($existing.gameDir). To keep its worlds, use -MinecraftDir with that folder outside AppData. If moving an old AppData instance, move the whole instance folder and update its launcher profile gameDir first. No installed files were changed." }
}
if (Test-Path -LiteralPath (Join-Path $GameDir 'BepInEx/plugins/Minekill.dll')) { throw 'An older duplicate Minekill.dll exists directly under BepInEx/plugins. Remove or relocate it first.' }
Write-Host "ULTRAKILL: $GameDir"
Write-Host "Minecraft profile directory: $MinecraftDir"
Write-Host 'Setup installs Java 25, BepInEx 5, full-add-on ReShade 6.8, Fabric and Fabric API.'
Write-Host 'Replaced files and launcher profiles will be backed up. Existing worlds are kept.'
if (!$PSCmdlet.ShouldProcess($GameDir,'Install dependencies, mod, Minecraft profile and desktop shortcut')) { return }
if (Get-Process -Name ULTRAKILL,java,javaw,MinecraftLauncher -ErrorAction SilentlyContinue) { throw 'Close ULTRAKILL, Minecraft, its launcher and other Java apps normally before setup, then try again.' }
# Check write access before downloading or changing any game files.
$probe=Join-Path $GameDir ([IO.Path]::GetRandomFileName())
try { $handle=[IO.File]::Create($probe,1,[IO.FileOptions]::DeleteOnClose); $handle.Dispose() }
catch { throw 'This ULTRAKILL folder is not writable. Run Setup.cmd as administrator using your own Windows account, or install Steam games in a writable folder.' }
[Net.ServicePointManager]::SecurityProtocol=[Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
$ProgressPreference='SilentlyContinue'
$dependencies=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Setup.Dependencies.json') -Raw | ConvertFrom-Json
$cache=Join-Path $SetupDir 'downloads'
$files=@{}
# Finish every download/hash check before touching installed game/profile files.
foreach ($property in $dependencies.PSObject.Properties) { $files[$property.Name]=Get-VerifiedDownload $property.Value $cache }
$stamp=(Get-Date -Format 'yyyyMMdd-HHmmss')+'-'+[Guid]::NewGuid().ToString('N').Substring(0,6)
$stage=Join-Path $SetupDir ('staging/'+$stamp)
New-Item -ItemType Directory -Path $stage -Force | Out-Null
Expand-CheckedZip $files.Java (Join-Path $stage 'java')
Expand-CheckedZip $files.BepInEx (Join-Path $stage 'bepinex')
Export-ReShade64 $files.ReShade (Join-Path $stage 'dxgi.dll')
$javaCandidates=@(Get-ChildItem -LiteralPath (Join-Path $stage 'java') -Filter javaw.exe -File -Recurse)
if ($javaCandidates.Count -ne 1) { throw 'Java archive layout was not recognized.' }
$javaRelative=$javaCandidates[0].FullName.Substring((Join-Path $stage 'java').Length+1)
$javaRoot=Join-Path $SetupDir 'runtime/java25'
$javaExe=Join-Path $javaRoot $javaRelative
$backup=Join-Path $SetupDir ('backups/'+$stamp)
# Back up dependency files as well as mod files. Re-running setup is supported.
foreach ($pair in @(@('java',$javaRoot,'runtime'),@('bepinex',$GameDir,'ULTRAKILL'))) {
    $sourceRoot=Join-Path $stage $pair[0]
    foreach ($file in Get-ChildItem -LiteralPath $sourceRoot -File -Recurse) {
        $relative=$file.FullName.Substring($sourceRoot.Length+1)
        Copy-WithBackup $file.FullName (Get-ContainedPath $pair[1] $relative) (Get-ContainedPath $backup ($pair[2]+'/'+$relative))
    }
}
Copy-WithBackup (Join-Path $stage 'dxgi.dll') (Join-Path $GameDir 'dxgi.dll') (Join-Path $backup 'ULTRAKILL/dxgi.dll')
$version='fabric-loader-0.19.5-26.3'
Copy-WithBackup (Join-Path $PSScriptRoot 'Minecraft/fabric-version.json') (Join-Path $LauncherDir "versions/$version/$version.json") (Join-Path $backup 'Minecraft/fabric-profile.json')
Copy-WithBackup (Join-Path $PSScriptRoot 'Minecraft/vanilla-version.json') (Join-Path $LauncherDir 'versions/26.3/26.3.json') (Join-Path $backup 'Minecraft/vanilla-profile.json')
Copy-WithBackup $files.FabricAPI (Join-Path $MinecraftDir 'mods/fabric-api-0.161.0+26.3.jar') (Join-Path $backup 'Minecraft/fabric-api.jar')
& (Join-Path $PSScriptRoot 'Install.ps1') -GameDir $GameDir -MinecraftDir $MinecraftDir
foreach ($profileFile in $profileFiles) { Set-CraftProfile $profileFile $MinecraftDir $javaExe (Join-Path $backup ('Minecraft/'+[IO.Path]::GetFileName($profileFile))) }
$launchPath=Join-Path $SetupDir 'Launch Ultrakill Craft.cmd'
$launcher=(Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Minecraft Launcher' -ErrorAction SilentlyContinue).InstallLocation
$launcherExe=if ($launcher) { Join-Path $launcher 'MinecraftLauncher.exe' } else { Join-Path ${env:ProgramFiles(x86)} 'Minecraft Launcher/MinecraftLauncher.exe' }
$launcherLine=if (Test-Path -LiteralPath $launcherExe) { 'start "" "'+$launcherExe.Replace('%','%%')+'"' } else { 'start "" explorer.exe "shell:AppsFolder\Microsoft.4297127D64EC6_8wekyb3d8bbwe!Minecraft"' }
[IO.File]::WriteAllText($launchPath,(@('@echo off','chcp 65001 >nul',$launcherLine,'start "" "steam://rungameid/1229490"','exit /b') -join "`r`n")+"`r`n",(New-Object Text.UTF8Encoding($false)))
if (!$NoShortcut) {
    New-CraftShortcut ([Environment]::GetFolderPath('Desktop')) $launchPath $GameDir
}
Write-Host ''
Write-Host 'Setup complete!' -ForegroundColor Green
if ($NoShortcut) { Write-Host "Launch file: $launchPath" } else { Write-Host 'Use the Ultrakill Craft desktop shortcut.' }
Write-Host 'In Minecraft Launcher select Ultrakill Craft and press Play. Keep Minecraft open and unminimized.'
Write-Host "Backups: $backup"
Write-Host 'The official launcher downloads Minecraft and Fabric libraries when you press Play.'
