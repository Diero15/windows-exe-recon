[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Target,

    [string]$Out = "",

    [switch]$CopyTarget,

    [switch]$Force
)

$ErrorActionPreference = "Stop"

function Write-Utf8NoBom {
    param([string]$Path, [string]$Text)
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Text, $encoding)
}

$targetPath = (Resolve-Path -LiteralPath $Target).Path
if (-not (Test-Path -LiteralPath $targetPath -PathType Leaf)) {
    throw "Target not found: $targetPath"
}

$baseName = [System.IO.Path]::GetFileNameWithoutExtension($targetPath)
if ([string]::IsNullOrWhiteSpace($Out)) {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $Out = Join-Path (Get-Location).Path ("analysis-{0}-{1}" -f $baseName, $stamp)
} elseif (-not [System.IO.Path]::IsPathRooted($Out)) {
    $Out = Join-Path (Get-Location).Path $Out
}

if (Test-Path -LiteralPath $Out) {
    if (-not $Force) {
        throw "Output already exists: $Out. Use -Force to add to it."
    }
} else {
    New-Item -ItemType Directory -Path $Out | Out-Null
}

$dirs = @("00-intake", "01-static", "02-dynamic", "03-ghidra", "04-report", "evidence")
foreach ($dir in $dirs) {
    $path = Join-Path $Out $dir
    if (-not (Test-Path -LiteralPath $path)) {
        New-Item -ItemType Directory -Path $path | Out-Null
    }
}

$item = Get-Item -LiteralPath $targetPath
$hash = Get-FileHash -LiteralPath $targetPath -Algorithm SHA256
$hash1 = Get-FileHash -LiteralPath $targetPath -Algorithm SHA1
$hash5 = Get-FileHash -LiteralPath $targetPath -Algorithm MD5

$signature = $null
try {
    $sig = Get-AuthenticodeSignature -LiteralPath $targetPath
    $signature = [ordered]@{
        status = "$($sig.Status)"
        statusMessage = "$($sig.StatusMessage)"
        signer = if ($sig.SignerCertificate) { $sig.SignerCertificate.Subject } else { $null }
        issuer = if ($sig.SignerCertificate) { $sig.SignerCertificate.Issuer } else { $null }
    }
} catch {
    $signature = [ordered]@{ status = "Unavailable"; error = "$($_.Exception.Message)" }
}

$version = $null
try {
    $vi = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($targetPath)
    $version = [ordered]@{
        fileDescription = $vi.FileDescription
        companyName = $vi.CompanyName
        productName = $vi.ProductName
        fileVersion = $vi.FileVersion
        productVersion = $vi.ProductVersion
        originalFilename = $vi.OriginalFilename
        internalName = $vi.InternalName
        legalCopyright = $vi.LegalCopyright
        comments = $vi.Comments
        isDebug = $vi.IsDebug
        isPatched = $vi.IsPatched
        isPreRelease = $vi.IsPreRelease
        isSpecialBuild = $vi.IsSpecialBuild
    }
} catch {
    $version = [ordered]@{ error = "$($_.Exception.Message)" }
}

$meta = [ordered]@{
    createdAt = (Get-Date).ToString("o")
    target = [ordered]@{
        path = $targetPath
        name = $item.Name
        extension = $item.Extension
        sizeBytes = $item.Length
        createdUtc = $item.CreationTimeUtc.ToString("o")
        modifiedUtc = $item.LastWriteTimeUtc.ToString("o")
        attributes = "$($item.Attributes)"
    }
    hashes = [ordered]@{
        sha256 = $hash.Hash
        sha1 = $hash1.Hash
        md5 = $hash5.Hash
    }
    signature = $signature
    version = $version
    authorization = [ordered]@{
        owner = ""
        source = ""
        executionAllowed = $false
        networkAllowed = $false
        publicationAllowed = $false
        notes = ""
    }
}

$metaJson = $meta | ConvertTo-Json -Depth 8
Write-Utf8NoBom -Path (Join-Path $Out "00-intake\target.json") -Text $metaJson

$hashes = @(
    "$($hash.Hash)  $targetPath",
    "$($hash1.Hash)  $targetPath",
    "$($hash5.Hash)  $targetPath"
) -join [Environment]::NewLine
Write-Utf8NoBom -Path (Join-Path $Out "00-intake\hashes.txt") -Text ($hashes + [Environment]::NewLine)

if ($CopyTarget) {
    Copy-Item -LiteralPath $targetPath -Destination (Join-Path $Out "evidence\target.bin") -Force
}

$readme = @"
# Analysis workspace

Target: $targetPath
SHA-256: $($hash.Hash)
Created: $((Get-Date).ToString("o"))

## Layout

- 00-intake: authorization, hashes, scope
- 01-static: PE inventory, strings, signatures, resources
- 02-dynamic: VM notes, Procmon/network captures, snapshots
- 03-ghidra: project notes, function map, decompiler summaries
- 04-report: final report and diagrams
- evidence: redacted screenshots, logs, and artifacts

## Safety

- Do not execute unknown binaries on the host.
- Use an isolated VM with a snapshot and no real credentials.
- Redact secrets and personal data.
- Do not commit target binaries to source control.

## Next steps

1. Complete `00-intake/target.json` with authorization and scope.
2. Run `Get-ExeTriage.ps1` and save JSON under `01-static`.
3. Run `Get-StringSignals.ps1` under `01-static`.
4. Use Ghidra only after static triage.
5. Execute only in the VM, with permission.
"@
Write-Utf8NoBom -Path (Join-Path $Out "README.md") -Text $readme

[pscustomobject]@{
    Workspace = $Out
    Target = $targetPath
    Sha256 = $hash.Hash
    SizeBytes = $item.Length
} | Format-List
