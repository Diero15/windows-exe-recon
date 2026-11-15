[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [string]$OutFile = "",

    [switch]$Json
)

$ErrorActionPreference = "Stop"

function Write-Utf8NoBom {
    param([string]$FilePath, [string]$Text)
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($FilePath, $Text, $encoding)
}

function Get-Entropy {
    param([byte[]]$Bytes)
    if (-not $Bytes -or $Bytes.Length -eq 0) { return 0.0 }
    $counts = New-Object 'int[]' 256
    foreach ($b in $Bytes) { $counts[$b]++ }
    $length = [double]$Bytes.Length
    $entropy = 0.0
    foreach ($count in $counts) {
        if ($count -gt 0) {
            $p = $count / $length
            $entropy -= $p * [Math]::Log($p, 2)
        }
    }
    return [Math]::Round($entropy, 4)
}

$targetPath = (Resolve-Path -LiteralPath $Path).Path
$item = Get-Item -LiteralPath $targetPath
$fs = [System.IO.File]::Open($targetPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
$br = New-Object System.IO.BinaryReader($fs)

$sections = @()
$dataDirs = @()
$sizeOfHeaders = 0
$is64 = $false

function Rva-ToOffset {
    param([uint32]$Rva)
    if ($Rva -eq 0) { return $null }
    if ($sizeOfHeaders -gt 0 -and $Rva -lt $sizeOfHeaders) { return [int64]$Rva }
    foreach ($s in $sections) {
        $span = [Math]::Max([uint32]$s.VirtualSize, [uint32]$s.SizeOfRawData)
        if ($Rva -ge $s.VirtualAddress -and $Rva -lt ($s.VirtualAddress + $span)) {
            return [int64]$s.PointerToRawData + ([int64]$Rva - [int64]$s.VirtualAddress)
        }
    }
    return $null
}

function Read-AsciiZAt {
    param([uint32]$Rva, [int]$MaxLength = 512)
    $offset = Rva-ToOffset -Rva $Rva
    if ($null -eq $offset -or $offset -lt 0 -or $offset -ge $fs.Length) { return $null }
    $old = $fs.Position
    try {
        $fs.Position = $offset
        $bytes = New-Object 'System.Collections.Generic.List[byte]'
        while ($fs.Position -lt $fs.Length -and $bytes.Count -lt $MaxLength) {
            $b = $br.ReadByte()
            if ($b -eq 0) { break }
            $bytes.Add($b)
        }
        return [System.Text.Encoding]::ASCII.GetString($bytes.ToArray())
    } finally {
        $fs.Position = $old
    }
}

try {
    $fs.Position = 0
    if ($br.ReadUInt16() -ne 0x5A4D) { throw "Missing MZ signature" }
    $fs.Position = 0x3C
    $peOffset = $br.ReadUInt32()
    $fs.Position = $peOffset
    if ($br.ReadUInt32() -ne 0x00004550) { throw "Missing PE signature" }

    $machine = $br.ReadUInt16()
    $numberOfSections = $br.ReadUInt16()
    $timeDateStamp = $br.ReadUInt32()
    $pointerToSymbolTable = $br.ReadUInt32()
    $numberOfSymbols = $br.ReadUInt32()
    $sizeOfOptionalHeader = $br.ReadUInt16()
    $characteristics = $br.ReadUInt16()
    $optionalOffset = $fs.Position

    $magic = $br.ReadUInt16()
    $is64 = ($magic -eq 0x20B)
    $majorLinkerVersion = $br.ReadByte()
    $minorLinkerVersion = $br.ReadByte()
    $sizeOfCode = $br.ReadUInt32()
    $sizeOfInitializedData = $br.ReadUInt32()
    $sizeOfUninitializedData = $br.ReadUInt32()
    $addressOfEntryPoint = $br.ReadUInt32()
    $baseOfCode = $br.ReadUInt32()
    $baseOfData = 0
    if ($is64) {
        $imageBase = $br.ReadUInt64()
    } else {
        $baseOfData = $br.ReadUInt32()
        $imageBase = [uint64]$br.ReadUInt32()
    }

    $sectionAlignment = $br.ReadUInt32()
    $fileAlignment = $br.ReadUInt32()
    $majorOSVersion = $br.ReadUInt16()
    $minorOSVersion = $br.ReadUInt16()
    $majorImageVersion = $br.ReadUInt16()
    $minorImageVersion = $br.ReadUInt16()
    $majorSubsystemVersion = $br.ReadUInt16()
    $minorSubsystemVersion = $br.ReadUInt16()
    $win32VersionValue = $br.ReadUInt32()
    $sizeOfImage = $br.ReadUInt32()
    $sizeOfHeaders = $br.ReadUInt32()
    $checkSum = $br.ReadUInt32()
    $subsystem = $br.ReadUInt16()
    $dllCharacteristics = $br.ReadUInt16()

    if ($is64) {
        $sizeOfStackReserve = $br.ReadUInt64()
        $sizeOfStackCommit = $br.ReadUInt64()
        $sizeOfHeapReserve = $br.ReadUInt64()
        $sizeOfHeapCommit = $br.ReadUInt64()
    } else {
        $sizeOfStackReserve = [uint64]$br.ReadUInt32()
        $sizeOfStackCommit = [uint64]$br.ReadUInt32()
        $sizeOfHeapReserve = [uint64]$br.ReadUInt32()
        $sizeOfHeapCommit = [uint64]$br.ReadUInt32()
    }

    $loaderFlags = $br.ReadUInt32()
    $numberOfRvaAndSizes = $br.ReadUInt32()

    $dirNames = @(
        "Export", "Import", "Resource", "Exception", "Security", "Relocation",
        "Debug", "Architecture", "GlobalPtr", "TLS", "LoadConfig", "BoundImport",
        "IAT", "DelayImport", "CLR", "Reserved"
    )
    $directoryCount = [Math]::Min(16, [int]$numberOfRvaAndSizes)
    for ($i = 0; $i -lt $directoryCount; $i++) {
        $rva = $br.ReadUInt32()
        $size = $br.ReadUInt32()
        $dataDirs += [pscustomobject]@{
            index = $i
            name = $dirNames[$i]
            rva = $rva
            size = $size
        }
    }

    $fs.Position = $optionalOffset + $sizeOfOptionalHeader
    for ($i = 0; $i -lt $numberOfSections; $i++) {
        $nameBytes = $br.ReadBytes(8)
        $sectionName = [System.Text.Encoding]::ASCII.GetString($nameBytes).TrimEnd([char]0)
        $virtualSize = $br.ReadUInt32()
        $virtualAddress = $br.ReadUInt32()
        $sizeOfRawData = $br.ReadUInt32()
        $pointerToRawData = $br.ReadUInt32()
        $pointerToRelocations = $br.ReadUInt32()
        $pointerToLineNumbers = $br.ReadUInt32()
        $numberOfRelocations = $br.ReadUInt16()
        $numberOfLineNumbers = $br.ReadUInt16()
        $sectionCharacteristics = $br.ReadUInt32()

        $entropy = 0.0
        if ($sizeOfRawData -gt 0 -and $pointerToRawData -lt $fs.Length) {
            $readSize = [Math]::Min([int64]$sizeOfRawData, [int64](16MB))
            $readSize = [Math]::Min($readSize, [int64]($fs.Length - $pointerToRawData))
            if ($readSize -gt 0) {
                $old = $fs.Position
                $fs.Position = $pointerToRawData
                $raw = $br.ReadBytes([int]$readSize)
                $entropy = Get-Entropy -Bytes $raw
                $fs.Position = $old
            }
        }

        $sections += [pscustomobject]@{
            name = $sectionName
            virtualSize = $virtualSize
            virtualAddress = $virtualAddress
            sizeOfRawData = $sizeOfRawData
            pointerToRawData = $pointerToRawData
            characteristics = $sectionCharacteristics
            entropy = $entropy
        }
    }

    $imports = @()
    $exports = @()
    $importError = $null
    $exportError = $null

    try {
        $importDir = $dataDirs | Where-Object { $_.name -eq "Import" } | Select-Object -First 1
        if ($importDir -and $importDir.rva -ne 0) {
            $descriptorOffset = Rva-ToOffset -Rva $importDir.rva
            if ($null -ne $descriptorOffset) {
                $thunkSize = 4
                if ($is64) { $thunkSize = 8 }
                for ($d = 0; $d -lt 256; $d++) {
                    $fs.Position = $descriptorOffset + ($d * 20)
                    $originalFirstThunk = $br.ReadUInt32()
                    $timeStamp = $br.ReadUInt32()
                    $forwarderChain = $br.ReadUInt32()
                    $nameRva = $br.ReadUInt32()
                    $firstThunk = $br.ReadUInt32()
                    if ($originalFirstThunk -eq 0 -and $timeStamp -eq 0 -and $forwarderChain -eq 0 -and $nameRva -eq 0 -and $firstThunk -eq 0) { break }

                    $dllName = Read-AsciiZAt -Rva $nameRva
                    $functions = @()
                    $thunkRva = $originalFirstThunk
                    if ($thunkRva -eq 0) { $thunkRva = $firstThunk }
                    $thunkOffset = Rva-ToOffset -Rva $thunkRva
                    if ($null -ne $thunkOffset) {
                        for ($t = 0; $t -lt 2000; $t++) {
                            $fs.Position = $thunkOffset + ($t * $thunkSize)
                            if ($is64) {
                                $value = $br.ReadUInt64()
                                if ($value -eq 0) { break }
                                $ordinalFlag = [uint64]::Parse("8000000000000000", [System.Globalization.NumberStyles]::HexNumber)
                                if (($value -band $ordinalFlag) -ne 0) {
                                    $functions += ("Ordinal_" + ($value -band 0xFFFF))
                                } else {
                                    $nameOffset = Read-AsciiZAt -Rva ([uint32]($value -band 0x7FFFFFFF) + 2)
                                    if ($nameOffset) { $functions += $nameOffset }
                                }
                            } else {
                                $value = [uint64]$br.ReadUInt32()
                                if ($value -eq 0) { break }
                                $ordinalFlag = [uint64]::Parse("80000000", [System.Globalization.NumberStyles]::HexNumber)
                                if (($value -band $ordinalFlag) -ne 0) {
                                    $functions += ("Ordinal_" + ($value -band 0xFFFF))
                                } else {
                                    $nameOffset = Read-AsciiZAt -Rva ([uint32]($value -band 0x7FFFFFFF) + 2)
                                    if ($nameOffset) { $functions += $nameOffset }
                                }
                            }
                        }
                    }
                    $imports += [pscustomobject]@{
                        dll = $dllName
                        functions = $functions
                    }
                }
            }
        }
    } catch {
        $importError = "$($_.Exception.Message)"
    }

    try {
        $exportDir = $dataDirs | Where-Object { $_.name -eq "Export" } | Select-Object -First 1
        if ($exportDir -and $exportDir.rva -ne 0) {
            $exportOffset = Rva-ToOffset -Rva $exportDir.rva
            if ($null -ne $exportOffset) {
                $fs.Position = $exportOffset
                $exportCharacteristics = $br.ReadUInt32()
                $exportTimeDateStamp = $br.ReadUInt32()
                $exportMajor = $br.ReadUInt16()
                $exportMinor = $br.ReadUInt16()
                $exportNameRva = $br.ReadUInt32()
                $exportBase = $br.ReadUInt32()
                $numberOfFunctions = $br.ReadUInt32()
                $numberOfNames = $br.ReadUInt32()
                $addressOfFunctions = $br.ReadUInt32()
                $addressOfNames = $br.ReadUInt32()
                $addressOfNameOrdinals = $br.ReadUInt32()

                $namesOffset = Rva-ToOffset -Rva $addressOfNames
                $ordinalsOffset = Rva-ToOffset -Rva $addressOfNameOrdinals
                if ($null -ne $namesOffset) {
                    $count = [Math]::Min(5000, [int]$numberOfNames)
                    for ($i = 0; $i -lt $count; $i++) {
                        $fs.Position = $namesOffset + ($i * 4)
                        $nameRva = $br.ReadUInt32()
                        $name = Read-AsciiZAt -Rva $nameRva
                        if (-not $name) { continue }
                        $ordinal = $null
                        if ($null -ne $ordinalsOffset) {
                            $old = $fs.Position
                            $fs.Position = $ordinalsOffset + ($i * 2)
                            $ordinal = [uint32]$br.ReadUInt16() + $exportBase
                            $fs.Position = $old
                        }
                        $exports += [pscustomobject]@{ name = $name; ordinal = $ordinal }
                    }
                }
            }
        }
    } catch {
        $exportError = "$($_.Exception.Message)"
    }

    $maxRawEnd = [int64]$sizeOfHeaders
    foreach ($s in $sections) {
        $end = [int64]$s.pointerToRawData + [int64]$s.sizeOfRawData
        if ($end -gt $maxRawEnd) { $maxRawEnd = $end }
    }
    $overlay = [Math]::Max([int64]0, [int64]$fs.Length - $maxRawEnd)

    $machineName = switch ($machine) {
        0x014C { "x86" }
        0x8664 { "x64" }
        0x01C0 { "ARM" }
        0xAA64 { "ARM64" }
        0x0200 { "IA64" }
        default { ("0x{0:X4}" -f $machine) }
    }
    $subsystemName = switch ($subsystem) {
        1 { "Native" }
        2 { "GUI" }
        3 { "Console" }
        5 { "OS/2" }
        7 { "POSIX" }
        9 { "Windows CE" }
        10 { "EFI Application" }
        11 { "EFI Boot Service Driver" }
        12 { "EFI Runtime Driver" }
        13 { "EFI ROM" }
        16 { "Xbox" }
        17 { "Windows Boot" }
        default { ("0x{0:X4}" -f $subsystem) }
    }
    $dllFlags = @()
    if (($dllCharacteristics -band 0x0020) -ne 0) { $dllFlags += "HIGH_ENTROPY_VA" }
    if (($dllCharacteristics -band 0x0040) -ne 0) { $dllFlags += "DYNAMIC_BASE" }
    if (($dllCharacteristics -band 0x0100) -ne 0) { $dllFlags += "NX_COMPAT" }
    if (($dllCharacteristics -band 0x0400) -ne 0) { $dllFlags += "NO_SEH" }
    if (($dllCharacteristics -band 0x0800) -ne 0) { $dllFlags += "NO_BIND" }
    if (($dllCharacteristics -band 0x1000) -ne 0) { $dllFlags += "APPCONTAINER" }
    if (($dllCharacteristics -band 0x2000) -ne 0) { $dllFlags += "WDM_DRIVER" }
    if (($dllCharacteristics -band 0x4000) -ne 0) { $dllFlags += "GUARD_CF" }
    if (($dllCharacteristics -band 0x8000) -ne 0) { $dllFlags += "TERMINAL_SERVER_AWARE" }

    $highEntropy = @($sections | Where-Object { $_.entropy -ge 7.2 })
    $importDllCount = @($imports).Count
    $isDotNet = (($dataDirs | Where-Object { $_.name -eq "CLR" } | Select-Object -First 1).rva -ne 0)
    $hasTls = (($dataDirs | Where-Object { $_.name -eq "TLS" } | Select-Object -First 1).rva -ne 0)
    $hasDebug = (($dataDirs | Where-Object { $_.name -eq "Debug" } | Select-Object -First 1).rva -ne 0)
    $hasResources = (($dataDirs | Where-Object { $_.name -eq "Resource" } | Select-Object -First 1).rva -ne 0)
    $packedHint = ($highEntropy.Count -gt 0 -and $importDllCount -le 5)

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
        }
    } catch {
        $version = [ordered]@{ error = "$($_.Exception.Message)" }
    }

    $sha256 = (Get-FileHash -LiteralPath $targetPath -Algorithm SHA256).Hash
    $sha1 = (Get-FileHash -LiteralPath $targetPath -Algorithm SHA1).Hash
    $md5 = (Get-FileHash -LiteralPath $targetPath -Algorithm MD5).Hash

    $result = [ordered]@{
        generatedAt = (Get-Date).ToString("o")
        target = [ordered]@{
            path = $targetPath
            name = $item.Name
            sizeBytes = $item.Length
            createdUtc = $item.CreationTimeUtc.ToString("o")
            modifiedUtc = $item.LastWriteTimeUtc.ToString("o")
        }
        hashes = [ordered]@{ sha256 = $sha256; sha1 = $sha1; md5 = $md5 }
        signature = $signature
        version = $version
        pe = [ordered]@{
            peOffset = $peOffset
            machine = $machine
            machineName = $machineName
            numberOfSections = $numberOfSections
            timeDateStamp = $timeDateStamp
            timeDateUtc = ([DateTimeOffset]::FromUnixTimeSeconds($timeDateStamp)).UtcDateTime.ToString("o")
            characteristics = ("0x{0:X4}" -f $characteristics)
            magic = ("0x{0:X4}" -f $magic)
            is64Bit = $is64
            linkerVersion = "$majorLinkerVersion.$minorLinkerVersion"
            addressOfEntryPoint = ("0x{0:X8}" -f $addressOfEntryPoint)
            imageBase = ("0x{0:X}" -f $imageBase)
            sectionAlignment = $sectionAlignment
            fileAlignment = $fileAlignment
            sizeOfImage = $sizeOfImage
            sizeOfHeaders = $sizeOfHeaders
            checkSum = ("0x{0:X8}" -f $checkSum)
            subsystem = $subsystem
            subsystemName = $subsystemName
            dllCharacteristics = ("0x{0:X4}" -f $dllCharacteristics)
            dllCharacteristicsFlags = $dllFlags
            osVersion = "$majorOSVersion.$minorOSVersion"
            imageVersion = "$majorImageVersion.$minorImageVersion"
            subsystemVersion = "$majorSubsystemVersion.$minorSubsystemVersion"
            overlayBytes = $overlay
            isDotNet = $isDotNet
            hasTlsCallbacks = $hasTls
            hasDebugDirectory = $hasDebug
            hasResources = $hasResources
        }
        sections = $sections
        directories = $dataDirs
        imports = $imports
        exports = $exports
        hints = [ordered]@{
            highEntropySections = @($highEntropy | ForEach-Object { $_.name })
            importDllCount = $importDllCount
            packedSuspicion = $packedHint
            importError = $importError
            exportError = $exportError
        }
    }

    $jsonText = $result | ConvertTo-Json -Depth 10
    if (-not [string]::IsNullOrWhiteSpace($OutFile)) {
        if (-not [System.IO.Path]::IsPathRooted($OutFile)) {
            $OutFile = Join-Path (Get-Location).Path $OutFile
        }
        $parent = Split-Path -Parent $OutFile
        if ($parent -and -not (Test-Path -LiteralPath $parent)) {
            New-Item -ItemType Directory -Path $parent | Out-Null
        }
        Write-Utf8NoBom -FilePath $OutFile -Text ($jsonText + [Environment]::NewLine)
    }

    if ($Json) {
        $jsonText
    } else {
        Write-Output ("Target: {0}" -f $targetPath)
        Write-Output ("SHA-256: {0}" -f $sha256)
        Write-Output ("Size: {0} bytes" -f $item.Length)
        Write-Output ("Machine: {0} ({1})" -f $machineName, ("0x{0:X4}" -f $machine))
        Write-Output ("Subsystem: {0}" -f $subsystemName)
        Write-Output ("Sections: {0}" -f $numberOfSections)
        Write-Output ("Imports: {0} DLL(s)" -f $importDllCount)
        Write-Output ("Exports: {0}" -f @($exports).Count)
        Write-Output ("Overlay: {0} bytes" -f $overlay)
        Write-Output ("High entropy: {0}" -f (($highEntropy | ForEach-Object { $_.name }) -join ", "))
        Write-Output ("Signature: {0}" -f $signature.status)
        Write-Output ("Packed hint: {0}" -f $packedHint)
        if ($OutFile) { Write-Output ("JSON: {0}" -f $OutFile) }
    }
} finally {
    $br.Close()
    $fs.Close()
}
