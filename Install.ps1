[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory=$true)][string]$GameDir,
    [string]$MinecraftDir=(Join-Path $env:LOCALAPPDATA 'UltrakillCraft/minecraft-instance')
)
$ErrorActionPreference='Stop'
$gameTarget=[IO.Path]::GetFullPath($GameDir)
$mcTarget=[IO.Path]::GetFullPath($MinecraftDir)
if (!(Test-Path -LiteralPath (Join-Path $gameTarget 'ULTRAKILL.exe'))) { throw 'GameDir must be your ULTRAKILL install.' }
if (!(Test-Path -LiteralPath (Join-Path $gameTarget 'BepInEx/core/BepInEx.dll'))) { throw 'Install BepInEx 5 x64 first.' }
if (!(Test-Path -LiteralPath (Join-Path $gameTarget 'dxgi.dll'))) { throw 'Install full-add-on ReShade for DirectX 11 first.' }
if ((-not $WhatIfPreference) -and (Get-Process ULTRAKILL -ErrorAction SilentlyContinue)) { throw 'Close ULTRAKILL normally before installation. Also close the isolated Minecraft client.' }
$duplicate=Join-Path $gameTarget 'BepInEx/plugins/Minekill.dll'
if (Test-Path -LiteralPath $duplicate) { throw 'A duplicate root Minekill.dll exists; remove/relocate it before installing.' }
foreach ($line in Get-Content -LiteralPath (Join-Path $PSScriptRoot 'SHA256SUMS.txt')) {
    $parts=$line -split '  ',2
    if ($parts.Count -ne 2) { throw 'Malformed package hash manifest.' }
    $source=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot $parts[1]))
    if (!$source.StartsWith([IO.Path]::GetFullPath($PSScriptRoot)+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw 'Invalid package path.' }
    if ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ne $parts[0]) { throw "Package verification failed: $($parts[1])" }
}
$backupTarget=Join-Path $gameTarget ('UltrakillCraft-backups/'+(Get-Date -Format 'yyyyMMdd-HHmmss'))
function Install-File([string]$source,[string]$destination,[string]$backupName) {
    if ($PSCmdlet.ShouldProcess($destination,'Back up existing file and install Ultrakill Craft')) {
        if (Test-Path -LiteralPath $destination) {
            $saved=Join-Path $backupTarget $backupName
            New-Item -ItemType Directory -Path (Split-Path $saved) -Force | Out-Null
            Copy-Item -LiteralPath $destination -Destination $saved
        }
        New-Item -ItemType Directory -Path (Split-Path $destination) -Force | Out-Null
        Copy-Item -LiteralPath $source -Destination $destination -Force
    }
}
foreach ($file in Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'ULTRAKILL') -File -Recurse) {
    $relative=$file.FullName.Substring((Join-Path $PSScriptRoot 'ULTRAKILL').Length+1)
    Install-File $file.FullName (Join-Path $gameTarget $relative) ('ULTRAKILL/'+$relative)
}
Install-File (Join-Path $PSScriptRoot 'Minecraft/mods/ultrakill-craft-0.1.0.jar') (Join-Path $mcTarget 'mods/ultrakill-craft-0.1.0.jar') 'Minecraft/mods/ultrakill-craft-0.1.0.jar'
$configTarget=Join-Path $gameTarget 'BepInEx/config/local.minekill.overlay.cfg'
if ($PSCmdlet.ShouldProcess($configTarget,'Back up config and set isolated Minecraft directory')) {
    if (Test-Path -LiteralPath $configTarget) {
        New-Item -ItemType Directory -Path $backupTarget -Force | Out-Null
        Copy-Item -LiteralPath $configTarget -Destination (Join-Path $backupTarget 'local.minekill.overlay.cfg')
    }
    New-Item -ItemType Directory -Path (Split-Path $configTarget) -Force | Out-Null
    $config=if (Test-Path -LiteralPath $configTarget) { Get-Content -LiteralPath $configTarget -Raw } else { '' }
    $section=[regex]::Match($config,'(?ms)^\[Paths\][^\r\n]*\r?\n(?:(?!^\[).)*')
    if ($section.Success) {
        $updated=$section.Value
        if ($updated -match '(?m)^MinecraftInstanceDirectory\s*=') {
            $updated=[regex]::Replace($updated,'(?m)^MinecraftInstanceDirectory\s*=[^\r\n]*',[Text.RegularExpressions.MatchEvaluator]{ param($match) "MinecraftInstanceDirectory = $mcTarget" })
        } else { $updated+="`r`nMinecraftInstanceDirectory = $mcTarget`r`n" }
        $config=$config.Substring(0,$section.Index)+$updated+$config.Substring($section.Index+$section.Length)
    } else { $config+="`r`n[Paths]`r`nMinecraftInstanceDirectory = $mcTarget`r`n" }
    [IO.File]::WriteAllText($configTarget,$config,(New-Object Text.UTF8Encoding($false)))
}
Write-Output 'Package verified. Installation steps completed (or previewed with -WhatIf). Start your isolated Minecraft profile, then ULTRAKILL.'

