[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [string]$OutDir = "",

    [int]$MinLength = 4,

    [int]$MaxSignals = 3000,

    [switch]$IncludeAll
)

$ErrorActionPreference = "Stop"

function Write-Utf8NoBom {
    param([string]$FilePath, [string]$Text)
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($FilePath, $Text, $encoding)
}

$targetPath = (Resolve-Path -LiteralPath $Path).Path
$item = Get-Item -LiteralPath $targetPath
if ([string]::IsNullOrWhiteSpace($OutDir)) {
    $OutDir = $item.DirectoryName
} elseif (-not [System.IO.Path]::IsPathRooted($OutDir)) {
    $OutDir = Join-Path (Get-Location).Path $OutDir
}
if (-not (Test-Path -LiteralPath $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir | Out-Null
}

if ($item.Length -gt 512MB) {
    throw "File is larger than 512 MB. Extract or trim it before string analysis."
}

$bytes = [System.IO.File]::ReadAllBytes($targetPath)
$latin1 = [System.Text.Encoding]::GetEncoding(28591).GetString($bytes)
$unicode = [System.Text.Encoding]::Unicode.GetString($bytes)

$regex = [regex]("[ -~]{" + $MinLength + ",}")
$all = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
foreach ($match in $regex.Matches($latin1)) {
    if ($match.Value.Length -le 1000) { [void]$all.Add($match.Value) }
}
foreach ($match in $regex.Matches($unicode)) {
    if ($match.Value.Length -le 1000) { [void]$all.Add($match.Value) }
}

$keywords = @(
    "http://", "https://", "ftp://", "ws://", "wss://",
    "api", "token", "secret", "password", "passwd", "credential",
    "license", "activation", "activate", "serial", "subscription",
    "update", "upgrade", "version", "channel", "feed",
    "config", "settings", "preferences", "profile",
    ".json", ".xml", ".ini", ".yaml", ".yml", ".toml", ".db", ".sqlite",
    "appdata", "programdata", "temp", "tmp", "cache", "logs",
    "hkcu", "hklm", "currentversion", "runonce", "services",
    "pipe", "namedpipe", "shared memory", "mutex",
    "cmd.exe", "powershell", "wscript", "cscript", "rundll32", "regsvr32",
    "createprocess", "shellexecute", "winexec",
    "socket", "connect", "proxy", "user-agent", "authorization",
    "error", "failed", "failure", "denied", "timeout", "retry",
    "debug", "trace", "warning", "exception"
)

$signals = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
$urls = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
$paths = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
$registry = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
$pipes = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)

$urlRegex = [regex]'https?://[^\s"''<>]+'
$pathRegex = [regex]'[A-Za-z]:\\[^\s"''<>|]+'
$regRegex = [regex]'(?i)\b(?:HKCU|HKLM|HKCR|HKU|HKCC)\\[^\s"''<>]+'
$pipeRegex = [regex]'(?i)\\\\\.\\pipe\\[^\s"''<>]+'

foreach ($s in $all) {
    foreach ($m in $urlRegex.Matches($s)) { if ($m.Value.Length -le 500) { [void]$urls.Add($m.Value) } }
    foreach ($m in $pathRegex.Matches($s)) { if ($m.Value.Length -le 500) { [void]$paths.Add($m.Value) } }
    foreach ($m in $regRegex.Matches($s)) { if ($m.Value.Length -le 500) { [void]$registry.Add($m.Value) } }
    foreach ($m in $pipeRegex.Matches($s)) { if ($m.Value.Length -le 500) { [void]$pipes.Add($m.Value) } }

    $lower = $s.ToLowerInvariant()
    foreach ($keyword in $keywords) {
        if ($lower.Contains($keyword)) {
            if ($signals.Count -lt $MaxSignals) { [void]$signals.Add($s) }
            break
        }
    }
}

$signalList = @($signals) | Sort-Object
$urlList = @($urls) | Sort-Object
$pathList = @($paths) | Sort-Object
$regList = @($registry) | Sort-Object
$pipeList = @($pipes) | Sort-Object

$summary = @()
$summary += "# String signals"
$summary += ""
$summary += "Target: $targetPath"
$summary += "Strings scanned: $($all.Count)"
$summary += "Signals: $($signalList.Count)"
$summary += "URLs: $($urlList.Count)"
$summary += "Paths: $($pathList.Count)"
$summary += "Registry keys: $($regList.Count)"
$summary += "Named pipes: $($pipeList.Count)"
$summary += ""
$summary += "## URLs"
$summary += $urlList
$summary += ""
$summary += "## Filesystem paths"
$summary += $pathList
$summary += ""
$summary += "## Registry keys"
$summary += $regList
$summary += ""
$summary += "## Named pipes"
$summary += $pipeList
$summary += ""
$summary += "## Signals"
$summary += $signalList

Write-Utf8NoBom -FilePath (Join-Path $OutDir "strings-signals.txt") -Text (($summary -join [Environment]::NewLine) + [Environment]::NewLine)

if ($IncludeAll) {
    $allList = @($all) | Sort-Object
    if ($allList.Count -gt 50000) { $allList = $allList[0..49999] }
    $allText = @("# All strings", "", "Target: $targetPath", "") + $allList
    Write-Utf8NoBom -FilePath (Join-Path $OutDir "strings-all.txt") -Text (($allText -join [Environment]::NewLine) + [Environment]::NewLine)
}

[pscustomobject]@{
    Target = $targetPath
    Strings = $all.Count
    Signals = $signalList.Count
    URLs = $urlList.Count
    Paths = $pathList.Count
    Registry = $regList.Count
    Pipes = $pipeList.Count
    OutDir = $OutDir
} | Format-List
