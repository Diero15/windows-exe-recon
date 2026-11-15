[CmdletBinding()]
param(
    [string]$OutDir = "dist"
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
if (-not [System.IO.Path]::IsPathRooted($OutDir)) {
    $OutDir = Join-Path $root $OutDir
}
if (-not (Test-Path -LiteralPath $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir | Out-Null
}

$zip = Join-Path $OutDir "windows-exe-recon.zip"
if (Test-Path -LiteralPath $zip) {
    Remove-Item -LiteralPath $zip -Force
}

$exclude = @(".git", ".github", "ci", "download", "dist", "package.ps1")
$items = Get-ChildItem -LiteralPath $root -Force |
    Where-Object { $_.Name -notin $exclude -and $_.Name -notlike "*.zip" } |
    Select-Object -ExpandProperty FullName

if (-not $items) {
    throw "Nothing to package."
}

Compress-Archive -Path $items -DestinationPath $zip -Force
Write-Host "Created: $zip"
Get-Item -LiteralPath $zip | Select-Object FullName, Length | Format-List
