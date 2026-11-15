[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Target,

    [Parameter(Mandatory = $true)]
    [string]$ProjectDir,

    [Parameter(Mandatory = $true)]
    [string]$ProjectName,

    [string]$GhidraHome = "",

    [int]$AnalysisTimeoutSeconds = 600,

    [switch]$NoAnalysis,

    [switch]$Force,

    [string]$ScriptPath = "",

    [string]$PostScript = ""
)

$ErrorActionPreference = "Stop"

$targetPath = (Resolve-Path -LiteralPath $Target).Path
if (-not [System.IO.Path]::IsPathRooted($ProjectDir)) {
    $ProjectDir = Join-Path (Get-Location).Path $ProjectDir
}
if (-not (Test-Path -LiteralPath $ProjectDir)) {
    New-Item -ItemType Directory -Path $ProjectDir | Out-Null
}

function Find-AnalyzeHeadless {
    param([string]$GhidraRoot)

    if (-not [string]::IsNullOrWhiteSpace($GhidraRoot)) {
        $candidate = Join-Path $GhidraRoot "support\analyzeHeadless.bat"
        if (Test-Path -LiteralPath $candidate) { return $candidate }
    }

    $command = Get-Command "analyzeHeadless.bat" -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }

    $roots = @($env:ProgramFiles, ${env:ProgramFiles(x86)}, "C:\Tools", "C:\ghidra") |
        Where-Object { $_ -and (Test-Path -LiteralPath $_) }
    foreach ($root in $roots) {
        $candidates = Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like "ghidra*" } |
            ForEach-Object { Join-Path $_.FullName "support\analyzeHeadless.bat" }
        foreach ($candidate in $candidates) {
            if (Test-Path -LiteralPath $candidate) { return $candidate }
        }
    }

    return $null
}

$analyze = Find-AnalyzeHeadless -GhidraRoot $GhidraHome
if (-not $analyze) {
    throw "analyzeHeadless.bat not found. Pass -GhidraHome or add Ghidra support/ to PATH."
}

$logDir = Join-Path $ProjectDir "logs"
if (-not (Test-Path -LiteralPath $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logPath = Join-Path $logDir ("ghidra-{0}.log" -f $stamp)

$arguments = @(
    $ProjectDir,
    $ProjectName,
    "-import",
    $targetPath,
    "-analysisTimeoutPerFile",
    "$AnalysisTimeoutSeconds"
)

if ($NoAnalysis) { $arguments += "-noanalysis" }
if ($Force) { $arguments += "-overwrite" }
if (-not [string]::IsNullOrWhiteSpace($ScriptPath)) {
    $arguments += "-scriptPath"
    $arguments += $ScriptPath
}
if (-not [string]::IsNullOrWhiteSpace($PostScript)) {
    $arguments += "-postScript"
    $arguments += $PostScript
}

Write-Host "Ghidra: $analyze"
Write-Host "Project: $ProjectDir / $ProjectName"
Write-Host "Target: $targetPath"
Write-Host "Log: $logPath"

& $analyze @arguments 2>&1 | Tee-Object -FilePath $logPath
$exitCode = $LASTEXITCODE

if ($exitCode -ne 0) {
    throw "Ghidra headless exited with code $exitCode. See $logPath"
}

[pscustomobject]@{
    Ghidra = $analyze
    ProjectDir = $ProjectDir
    ProjectName = $ProjectName
    Target = $targetPath
    Log = $logPath
    ExitCode = $exitCode
} | Format-List
