# Helpers are separate so setup can be tested without touching an installed game.
function Assert-Package([string]$Root) {
    foreach ($line in Get-Content -LiteralPath (Join-Path $Root 'SHA256SUMS.txt')) {
        $parts=$line -split '  ',2
        if ($parts.Count -ne 2 -or $parts[0] -notmatch '^[a-fA-F0-9]{64}$') { throw 'Malformed package manifest.' }
        $file=Get-ContainedPath $Root $parts[1]
        if ((Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -ne $parts[0]) { throw "Package verification failed: $($parts[1])" }
    }
}
function Get-ContainedPath([string]$Root,[string]$Relative) {
    $base=[IO.Path]::GetFullPath($Root).TrimEnd('\','/')+[IO.Path]::DirectorySeparatorChar
    $file=[IO.Path]::GetFullPath((Join-Path $base $Relative))
    if ([IO.Path]::IsPathRooted($Relative) -or !$file.StartsWith($base,[StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe archive/package path.' }
    return $file
}
function Get-VerifiedDownload($Dependency,[string]$Cache) {
    if (([Uri]$Dependency.Url).Scheme -ne 'https') { throw 'Downloads must use HTTPS.' }
    New-Item -ItemType Directory -Path $Cache -Force | Out-Null
    $file=Get-ContainedPath $Cache $Dependency.File
    if ((Test-Path -LiteralPath $file) -and (Get-FileHash -LiteralPath $file -Algorithm $Dependency.Algorithm).Hash -eq $Dependency.Hash) { return $file }
    $temporary=$file+'.partial'
    Write-Host "Downloading $($Dependency.File)..."
    try {
        Invoke-WebRequest -UseBasicParsing -Uri $Dependency.Url -OutFile $temporary -UserAgent 'UltrakillCraft-Setup/1.0'
        if ((Get-FileHash -LiteralPath $temporary -Algorithm $Dependency.Algorithm).Hash -ne $Dependency.Hash) { throw "Download verification failed: $($Dependency.File). Nothing from this download was installed." }
        Move-Item -LiteralPath $temporary -Destination $file -Force
    } finally { if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force } }
    return $file
}
function Expand-CheckedZip([string]$Archive,[string]$Destination) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip=[IO.Compression.ZipFile]::OpenRead($Archive)
    try {
        # Validate ALL entries before extracting any.
        foreach ($entry in $zip.Entries) { $null=Get-ContainedPath $Destination $entry.FullName }
        foreach ($entry in $zip.Entries) {
            $target=Get-ContainedPath $Destination $entry.FullName
            if (!$entry.Name) { New-Item -ItemType Directory -Path $target -Force | Out-Null; continue }
            New-Item -ItemType Directory -Path (Split-Path $target) -Force | Out-Null
            [IO.Compression.ZipFileExtensions]::ExtractToFile($entry,$target,$true)
        }
    } finally { $zip.Dispose() }
}
function Export-ReShade64([string]$Installer,[string]$Destination) {
    # Official ReShade setup carries a ZIP at a 512-byte boundary (v6.8.0).
    # Extract its x64 module only; do not execute the installer or download shader packs.
    Add-Type -AssemblyName System.IO.Compression
    $bytes=[IO.File]::ReadAllBytes($Installer)
    $offset=-1
    for ($i=0; $i -lt $bytes.Length-30; $i+=512) {
        if ($bytes[$i] -eq 80 -and $bytes[$i+1] -eq 75 -and $bytes[$i+2] -eq 3 -and $bytes[$i+3] -eq 4 -and $bytes[$i+4] -ne 0) { $offset=$i; break }
    }
    if ($offset -lt 0) { throw 'ReShade archive layout was not recognized.' }
    $stream=New-Object IO.MemoryStream
    $stream.Write($bytes,$offset,$bytes.Length-$offset); $stream.Position=0
    $zip=New-Object IO.Compression.ZipArchive($stream,[IO.Compression.ZipArchiveMode]::Read,$false)
    try {
        $entry=$zip.GetEntry('ReShade64.dll')
        if (!$entry) { throw 'Verified ReShade package lacks its x64 module.' }
        $inputStream=$entry.Open(); $outputStream=[IO.File]::Create($Destination)
        try { $inputStream.CopyTo($outputStream) } finally { $inputStream.Dispose(); $outputStream.Dispose() }
    } finally { $zip.Dispose(); $stream.Dispose() }
}
function Copy-WithBackup([string]$Source,[string]$Destination,[string]$Backup) {
    if (Test-Path -LiteralPath $Destination) {
        if ((Get-FileHash -LiteralPath $Source -Algorithm SHA256).Hash -eq (Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash) { return }
        New-Item -ItemType Directory -Path (Split-Path $Backup) -Force | Out-Null
        Copy-Item -LiteralPath $Destination -Destination $Backup -Force
    }
    New-Item -ItemType Directory -Path (Split-Path $Destination) -Force | Out-Null
    Copy-Item -LiteralPath $Source -Destination $Destination -Force
}
function New-CraftShortcut([string]$Directory,[string]$LaunchPath,[string]$GameDir) {
    $shell=New-Object -ComObject WScript.Shell
    $link=$shell.CreateShortcut((Join-Path $Directory 'Ultrakill Craft.lnk'))
    $link.TargetPath=$env:ComSpec; $link.Arguments='/d /c ""'+$LaunchPath+'""'
    $link.WorkingDirectory=Split-Path $LaunchPath
    $link.IconLocation=(Join-Path $GameDir 'ULTRAKILL.exe')+',0'; $link.Save()
}
function Set-CraftProfile([string]$ProfileFile,[string]$MinecraftDir,[string]$JavaExe,[string]$Backup) {
    $data=Get-Content -LiteralPath $ProfileFile -Raw | ConvertFrom-Json
    if (!$data.profiles) { throw 'Launcher profiles are not initialized. Open the official Minecraft Launcher once and close it.' }
    $profile=[PSCustomObject]@{
        name='Ultrakill Craft'; type='custom'; gameDir=$MinecraftDir
        lastVersionId='fabric-loader-0.19.5-26.3'; javaDir=$JavaExe
        javaArgs='-Xms512M -Xmx3G --enable-native-access=ALL-UNNAMED'
        resolution=@{width=1280;height=720}
    }
    $data.profiles | Add-Member -NotePropertyName 'ultrakill-craft' -NotePropertyValue $profile -Force
    $data | Add-Member -NotePropertyName 'selectedProfile' -NotePropertyValue 'ultrakill-craft' -Force
    $temporary=$ProfileFile+'.ultrakillcraft.tmp'
    try {
        [IO.File]::WriteAllText($temporary,($data | ConvertTo-Json -Depth 100),(New-Object Text.UTF8Encoding($false)))
        Copy-WithBackup $temporary $ProfileFile $Backup
    } finally { if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary } }
}
function Find-Ultrakill {
    $roots=New-Object 'System.Collections.Generic.List[string]'
    foreach ($key in @('HKCU:\Software\Valve\Steam','HKLM:\SOFTWARE\WOW6432Node\Valve\Steam')) {
        $properties=Get-ItemProperty -LiteralPath $key -ErrorAction SilentlyContinue
        if ($properties.SteamPath) { $roots.Add($properties.SteamPath) }
        if ($properties.InstallPath) { $roots.Add($properties.InstallPath) }
    }
    foreach ($root in @($roots.ToArray())) {
        $vdf=Join-Path $root 'steamapps/libraryfolders.vdf'
        if (Test-Path -LiteralPath $vdf) {
            foreach ($match in [regex]::Matches((Get-Content -LiteralPath $vdf -Raw),'"path"\s+"([^"]+)"')) { $roots.Add($match.Groups[1].Value.Replace('\\','\')) }
        }
    }
    foreach ($root in $roots) {
        $candidate=Join-Path $root 'steamapps/common/ULTRAKILL'
        if (Test-Path -LiteralPath (Join-Path $candidate 'ULTRAKILL.exe')) { return [IO.Path]::GetFullPath($candidate) }
    }
    return $null
}
