# Run with Windows PowerShell 5.1; only temporary fixture folders are installed to.
[CmdletBinding()]
param([string]$DownloadCache)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Setup.Core.ps1')
function Assert($Condition,[string]$Message) { if (!$Condition) { throw $Message } }
Assert-Package $PSScriptRoot
$work=Join-Path (Split-Path $PSScriptRoot) ('Ultrakill Craft test '+[Guid]::NewGuid().ToString('N'))
$game=Join-Path $work 'Steam library/ULTRAKILL'
$launcher=Join-Path $work 'Minecraft launcher'
$setup=Join-Path $work 'Install with spaces'
$instance=Join-Path $setup 'minecraft-instance'
New-Item -ItemType Directory -Path $game,$launcher -Force | Out-Null
[IO.File]::WriteAllText((Join-Path $game 'ULTRAKILL.exe'),'fixture, never executed')
$original='{"profiles":{"keep":{"name":"Existing vanilla","gameDir":"C:\\fixture-world","javaArgs":"-Xmx2G"}},"settings":{"enableSnapshots":true}}'
foreach ($name in @('launcher_profiles.json','launcher_profiles_microsoft_store.json')) { [IO.File]::WriteAllText((Join-Path $launcher $name),$original) }
$powershell=Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'
$arguments=@('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $PSScriptRoot 'Setup.ps1'),'-GameDir',$game,'-LauncherDir',$launcher,'-SetupDir',$setup,'-NoShortcut')
function Run-Setup([string[]]$Extra=@(),[int]$Expected=0) {
    $ErrorActionPreference='Continue'
    $output=& $powershell @arguments @Extra 2>&1
    $ErrorActionPreference='Stop'
    Assert ($LASTEXITCODE -eq $Expected) ($output -join "`n")
    return ($output -join "`n")
}
$null=Run-Setup -Extra '-WhatIf'
Assert (!(Test-Path -LiteralPath $setup)) 'WhatIf wrote an installation folder.'
Assert ((Get-Content -LiteralPath (Join-Path $launcher 'launcher_profiles.json') -Raw) -eq $original) 'WhatIf changed profiles.'
$dependencies=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Setup.Dependencies.json') -Raw | ConvertFrom-Json
if ($DownloadCache) {
    New-Item -ItemType Directory -Path (Join-Path $setup 'downloads') -Force | Out-Null
    foreach ($dependency in $dependencies.PSObject.Properties.Value) {
        $source=Join-Path $DownloadCache $dependency.File
        if (Test-Path -LiteralPath $source) {
            Assert ((Get-FileHash -LiteralPath $source -Algorithm $dependency.Algorithm).Hash -eq $dependency.Hash) 'Fixture download cache failed verification.'
            Copy-Item -LiteralPath $source -Destination (Join-Path $setup 'downloads')
        }
    }
}
$null=Run-Setup
foreach ($name in @('launcher_profiles.json','launcher_profiles_microsoft_store.json')) {
    $data=Get-Content -LiteralPath (Join-Path $launcher $name) -Raw | ConvertFrom-Json
    Assert ($data.profiles.keep.name -eq 'Existing vanilla' -and $data.settings.enableSnapshots) 'Existing launcher data changed.'
    Assert ($data.profiles.'ultrakill-craft'.gameDir -eq $instance) 'The instance did not follow SetupDir.'
    Assert (Test-Path -LiteralPath $data.profiles.'ultrakill-craft'.javaDir) 'Private Java missing.'
    Assert ($data.profiles.'ultrakill-craft'.javaArgs -match '--enable-native-access=ALL-UNNAMED') 'Native access flag missing.'
}
foreach ($pair in @(@('fabric-version.json','fabric-loader-0.19.5-26.3'),@('vanilla-version.json','26.3'))) {
    $installed=Join-Path $launcher ('versions/'+$pair[1]+'/'+$pair[1]+'.json')
    Assert ((Get-FileHash -LiteralPath $installed).Hash -eq (Get-FileHash -LiteralPath (Join-Path $PSScriptRoot ('Minecraft/'+$pair[0]))).Hash) 'Pinned version metadata differs.'
}
foreach ($file in @('BepInEx/core/BepInEx.dll','BepInEx/plugins/Minekill/Minekill.dll','dxgi.dll','MinekillRenderer.dll','reshade-shaders/Shaders/MCPassthrough.fx')) {
    Assert (Test-Path -LiteralPath (Join-Path $game $file)) "Missing installed runtime: $file"
}
foreach ($file in @('ultrakill-craft-0.1.0.jar','fabric-api-0.161.0+26.3.jar')) { Assert (Test-Path -LiteralPath (Join-Path $instance ('mods/'+$file))) "Missing Minecraft mod: $file" }
$config=Join-Path $game 'BepInEx/config/local.minekill.overlay.cfg'
Assert ((Get-Content -LiteralPath $config -Raw).Contains("MinecraftInstanceDirectory = $instance")) 'Bridge points to the wrong instance.'
$world=Join-Path $instance 'saves/fixture-world'
New-Item -ItemType Directory -Path $world -Force | Out-Null
[IO.File]::WriteAllText((Join-Path $world 'keep.dat'),'keep my world')
[IO.File]::WriteAllText((Join-Path $instance 'options.txt'),'keep my settings')
[IO.File]::AppendAllText($config,"`r`n[Unrelated]`r`nKeep = true`r`n")
[IO.File]::WriteAllText((Join-Path $game 'dxgi.dll'),'old runtime fixture')
$null=Run-Setup
Assert ((Get-Content -LiteralPath (Join-Path $world 'keep.dat') -Raw) -eq 'keep my world') 'Repeat setup changed a world.'
Assert ((Get-Content -LiteralPath (Join-Path $instance 'options.txt') -Raw) -eq 'keep my settings') 'Repeat setup changed user settings.'
Assert ((Get-Content -LiteralPath $config -Raw).Contains('Keep = true')) 'Repeat setup dropped unrelated config.'
$saved=@(Get-ChildItem -LiteralPath (Join-Path $setup 'backups') -Filter dxgi.dll -File -Recurse)
Assert ($saved.Count -eq 1 -and (Get-Content -LiteralPath $saved[0].FullName -Raw) -eq 'old runtime fixture') 'Replaced runtime was not backed up.'
$profileBackups=@(Get-ChildItem -LiteralPath (Join-Path $setup 'backups') -Filter launcher_profiles.json -File -Recurse)
Assert (@($profileBackups | Where-Object { (Get-Content -LiteralPath $_.FullName -Raw) -eq $original }).Count -eq 1) 'Original profile backup missing.'
New-CraftShortcut $work (Join-Path $setup 'Launch Ultrakill Craft.cmd') $game
$shortcut=(New-Object -ComObject WScript.Shell).CreateShortcut((Join-Path $work 'Ultrakill Craft.lnk'))
Assert ($shortcut.Arguments -eq ('/d /c ""'+(Join-Path $setup 'Launch Ultrakill Craft.cmd')+'""')) 'Shortcut quoting failed.'
$null=Run-Setup -Extra @('-MinecraftDir',(Join-Path $work 'different instance')) -Expected 1
Assert (!(Test-Path -LiteralPath (Join-Path $work 'different instance'))) 'Profile conflict wrote a new instance.'
$null=Run-Setup -Extra @('-MinecraftDir',(Join-Path $env:LOCALAPPDATA 'UltrakillCraft-fixture-refused')) -Expected 1

# Check the actual CMD entry point, argument forwarding and failure exit code.
function Run-Cmd([string]$Command,[int]$Expected) {
    $info=New-Object Diagnostics.ProcessStartInfo
    $info.FileName=$env:ComSpec; $info.Arguments='/d /s /c '+$Command
    $info.UseShellExecute=$false; $info.CreateNoWindow=$true
    $info.RedirectStandardOutput=$true; $info.RedirectStandardError=$true
    $process=[Diagnostics.Process]::Start($info)
    try {
        $output=$process.StandardOutput.ReadToEnd()+$process.StandardError.ReadToEnd()
        $process.WaitForExit()
        Assert ($process.ExitCode -eq $Expected) $output
        return $output
    } finally { $process.Dispose() }
}
$cmdArguments='""'+(Join-Path $PSScriptRoot 'Setup.cmd')+'" -GameDir "'+$game+'" -LauncherDir "'+$launcher+'" -SetupDir "'+$setup+'" -NoShortcut -WhatIf <nul"'
$output=Run-Cmd $cmdArguments 0
Assert ($output -match 'What if:') 'Setup.cmd did not forward the preview arguments.'
$cmdArguments='""'+(Join-Path $PSScriptRoot 'Setup.cmd')+'" -GameDir "'+(Join-Path $work 'missing game')+'" <nul"'
$null=Run-Cmd $cmdArguments 1

$badArchive=Join-Path $work 'traversal.zip'
Add-Type -AssemblyName System.IO.Compression.FileSystem,System.IO.Compression
$zip=[IO.Compression.ZipFile]::Open($badArchive,[IO.Compression.ZipArchiveMode]::Create)
$null=$zip.CreateEntry('../outside.txt'); $zip.Dispose()
$refused=$false
try { Expand-CheckedZip $badArchive (Join-Path $work 'extract') } catch { $refused=$_.Exception.Message -match 'Unsafe' }
Assert $refused 'Archive traversal was accepted.'
Assert (!(Test-Path -LiteralPath (Join-Path $work 'extract'))) 'Unsafe archive was partially extracted.'

# Corrupt HTTPS responses must not replace a previously cached file.
function Invoke-WebRequest { param([switch]$UseBasicParsing,$Uri,$OutFile,$UserAgent) [IO.File]::WriteAllText($OutFile,'corrupt download') }
$cache=Join-Path $work 'corrupt-cache'
New-Item -ItemType Directory -Path $cache -Force | Out-Null
[IO.File]::WriteAllText((Join-Path $cache 'fixture.zip'),'previous cache')
$refused=$false
try { $null=Get-VerifiedDownload ([PSCustomObject]@{Url='https://example.invalid/fixture';File='fixture.zip';Algorithm='SHA256';Hash=('0'*64)}) $cache } catch { $refused=$_.Exception.Message -match 'verification failed' }
Assert $refused 'Corrupt download was accepted.'
Assert ((Get-Content -LiteralPath (Join-Path $cache 'fixture.zip') -Raw) -eq 'previous cache') 'Failed download replaced the cache.'
Assert (!(Test-Path -LiteralPath (Join-Path $cache 'fixture.zip.partial'))) 'Failed download left a partial file.'
Write-Host "PASS: clean/repeat setup, both profile formats, pinned Fabric/vanilla metadata, Java/loaders/mods, backups, worlds/settings, shortcut/CMD, WhatIf, profile conflicts, AppData refusal, ZIP traversal and corrupt downloads. Fixtures: $work"
