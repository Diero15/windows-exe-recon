[CmdletBinding()]
param(
    [switch]$Project,
    [string]$TargetDir = "",
    [switch]$Force,
    [switch]$Uninstall,
    [string]$Ref = "",
    [switch]$NoDownload
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
} catch { }

$repo = "Diero15/windows-exe-recon"
$skillId = "windows-exe-recon"

if ($Project) {
    $target = Join-Path (Get-Location).Path ".opencode\skills\$skillId"
} elseif (-not [string]::IsNullOrWhiteSpace($TargetDir)) {
    $target = [System.IO.Path]::GetFullPath($TargetDir)
} else {
    $homeDir = $env:USERPROFILE
    if ([string]::IsNullOrWhiteSpace($homeDir)) { $homeDir = $HOME }
    $target = Join-Path $homeDir ".config\opencode\skills\$skillId"
}

if ($Uninstall) {
    if (Test-Path -LiteralPath $target) {
        Remove-Item -LiteralPath $target -Recurse -Force
        Write-Host "Removed skill: $target"
    } else {
        Write-Host "Skill is not installed at: $target"
    }
    return
}

$scriptDir = $PSScriptRoot
$localSkill = $false
if (-not [string]::IsNullOrWhiteSpace($scriptDir) -and [string]::IsNullOrWhiteSpace($Ref)) {
    $localSkill = Test-Path -LiteralPath (Join-Path $scriptDir "SKILL.md")
}

$temp = $null
try {
    if ($localSkill) {
        $source = $scriptDir
        Write-Host "Source: local folder $source"
    } else {
        if ($NoDownload) {
            throw "No local SKILL.md found and -NoDownload was set."
        }

        $temp = Join-Path $env:TEMP ("windows-exe-recon-" + [guid]::NewGuid().ToString("N"))
        New-Item -ItemType Directory -Path $temp | Out-Null
        $zip = Join-Path $temp "skill.zip"

        $urls = @()
        if (-not [string]::IsNullOrWhiteSpace($Ref)) {
            $urls += "https://github.com/$repo/archive/refs/tags/$Ref.zip"
            $urls += "https://github.com/$repo/archive/refs/heads/$Ref.zip"
        }
        $urls += "https://github.com/$repo/releases/latest/download/$skillId.zip"
        $urls += "https://github.com/$repo/archive/refs/heads/main.zip"

        $downloaded = $false
        $lastError = $null
        foreach ($url in $urls) {
            try {
                Write-Host "Downloading: $url"
                Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $zip
                if ((Get-Item -LiteralPath $zip).Length -gt 0) {
                    $downloaded = $true
                    break
                }
            } catch {
                $lastError = $_.Exception.Message
            }
        }
        if (-not $downloaded) {
            throw "Could not download the skill package. Last error: $lastError"
        }

        $extract = Join-Path $temp "extract"
        New-Item -ItemType Directory -Path $extract | Out-Null
        Expand-Archive -LiteralPath $zip -DestinationPath $extract -Force
        $skillFile = Get-ChildItem -LiteralPath $extract -Recurse -File -Filter "SKILL.md" | Select-Object -First 1
        if (-not $skillFile) {
            throw "Downloaded package does not contain SKILL.md."
        }
        $source = $skillFile.Directory.FullName
        Write-Host "Source: downloaded package"
    }

    if (Test-Path -LiteralPath $target) {
        if (-not $Force) {
            throw "Target already exists: $target. Use -Force to update it."
        }
        Remove-Item -LiteralPath $target -Recurse -Force
    }
    New-Item -ItemType Directory -Path $target -Force | Out-Null

    $exclude = @(
        ".git", ".github", "ci", "download", "dist", "node_modules",
        "install.ps1", "install.cmd", "package.ps1"
    )
    Get-ChildItem -LiteralPath $source -Force |
        Where-Object { $_.Name -notin $exclude -and $_.Name -notlike "*.zip" } |
        ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination $target -Recurse -Force
        }

    if (-not (Test-Path -LiteralPath (Join-Path $target "SKILL.md"))) {
        throw "Installation failed: SKILL.md was not copied to $target"
    }

    Write-Host ""
    Write-Host "Installed: $target"
    Write-Host "Skill ID:  $skillId"
    Write-Host "Load it:   @$skillId"
    Write-Host ""
    Write-Host "OpenCode watches skill folders; no restart is normally required."
} finally {
    if ($temp -and (Test-Path -LiteralPath $temp)) {
        Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
    }
}
