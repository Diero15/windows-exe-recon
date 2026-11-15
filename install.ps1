[CmdletBinding()]
param(
    [string]$Source = "",

    [string]$Destination = "",

    [string]$Project = "",

    [switch]$Force,

    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"
$skillId = "windows-exe-recon"

if ([string]::IsNullOrWhiteSpace($Source)) {
    $Source = $PSScriptRoot
}

function Resolve-UserConfigRoot {
    if (-not [string]::IsNullOrWhiteSpace($env:XDG_CONFIG_HOME)) {
        return (Join-Path $env:XDG_CONFIG_HOME "opencode")
    }
    $profileRoot = $env:USERPROFILE
    if ([string]::IsNullOrWhiteSpace($profileRoot)) {
        $profileRoot = [Environment]::GetFolderPath("UserProfile")
    }
    return (Join-Path $profileRoot ".config\opencode")
}

if (-not [string]::IsNullOrWhiteSpace($Destination) -and -not [string]::IsNullOrWhiteSpace($Project)) {
    throw "Use -Destination or -Project, not both."
}

if ([string]::IsNullOrWhiteSpace($Destination)) {
    if (-not [string]::IsNullOrWhiteSpace($Project)) {
        $projectPath = (Resolve-Path -LiteralPath $Project).Path
        $Destination = Join-Path $projectPath ".opencode\skills\$skillId"
    } else {
        $Destination = Join-Path (Resolve-UserConfigRoot) "skills\$skillId"
    }
} elseif (-not [System.IO.Path]::IsPathRooted($Destination)) {
    $Destination = [System.IO.Path]::GetFullPath((Join-Path (Get-Location).Path $Destination))
}

if ($Uninstall) {
    if (Test-Path -LiteralPath $Destination) {
        Remove-Item -LiteralPath $Destination -Recurse -Force
        Write-Host "Removed: $Destination"
    } else {
        Write-Host "Nothing to remove: $Destination"
    }
    return
}

$sourcePath = (Resolve-Path -LiteralPath $Source).Path
if (-not (Test-Path -LiteralPath (Join-Path $sourcePath "SKILL.md"))) {
    throw "SKILL.md not found in source: $sourcePath"
}

if (Test-Path -LiteralPath $Destination) {
    if (-not $Force) {
        throw "Destination already exists: $Destination`nUse -Force to update/reinstall."
    }
    Remove-Item -LiteralPath $Destination -Recurse -Force
}

New-Item -ItemType Directory -Path $Destination -Force | Out-Null

$items = @(
    "SKILL.md",
    "README.md",
    "SECURITY.md",
    "LICENSE",
    ".gitignore",
    "install.ps1",
    "install.cmd",
    "references",
    "scripts",
    "templates"
)

foreach ($item in $items) {
    $sourceItem = Join-Path $sourcePath $item
    if (Test-Path -LiteralPath $sourceItem) {
        Copy-Item -LiteralPath $sourceItem -Destination $Destination -Recurse -Force
    }
}

$installedSkill = Join-Path $Destination "SKILL.md"
if (-not (Test-Path -LiteralPath $installedSkill)) {
    throw "Installation failed: $installedSkill not found."
}

Write-Host ""
Write-Host "Windows EXE Recon installed."
Write-Host "  Skill:       $Destination"
Write-Host "  Entry point: $installedSkill"
Write-Host ""
Write-Host "Use it in OpenCode with:"
Write-Host "  @windows-exe-recon"
Write-Host ""
Write-Host "If OpenCode does not show it immediately, run /reload."
