# Static triage

Static triage answers: what kind of file is this, what does it depend on, and
where should deeper analysis start? It never executes the target.

## Identity

Record:

- full path, size, creation and write times;
- SHA-256, SHA-1, and MD5;
- Authenticode status, signer, and timestamp;
- version resource: description, company, product, versions, original filename;
- PE machine, subsystem, characteristics, and linker version;
- whether the file is signed but the signature is invalid or expired.

PowerShell:

```powershell
Get-FileHash -LiteralPath .\app.exe -Algorithm SHA256
Get-AuthenticodeSignature -LiteralPath .\app.exe | Format-List *
(Get-Item .\app.exe).VersionInfo | Format-List *
```

## PE structure

Check:

- `MZ` and `PE\0\0` signatures;
- machine: x86, x64, ARM, ARM64;
- subsystem: GUI, console, native, EFI;
- entry point, image base, section alignment, file alignment;
- section names, virtual/raw sizes, raw pointers, characteristics;
- section entropy;
- overlay size after the last raw section;
- data directories: export, import, resource, exception, security, relocation,
  debug, TLS, IAT, delay import, CLR;
- debug directory and PDB path;
- Rich header, manifest, and requested execution level.

Interpretation hints:

| Observation | Possible meaning |
|---|---|
| High entropy in code/data sections | Packed, compressed, or encrypted |
| Very few imports | Statically linked, packed, or runtime-resolved |
| Imports for `LoadLibrary`/`GetProcAddress` | Dynamic API resolution |
| CLR directory present | .NET assembly |
| `Go build ID` / Go section names | Go binary |
| Rust panic strings | Rust binary |
| Delphi/C++Builder imports | Delphi/C++Builder binary |
| Large overlay | Installer payload, archive, or appended data |
| TLS callbacks | Code may run before the entry point |

## Imports

Group imports by behavior:

- process and thread creation;
- files, directories, and memory mapping;
- registry and services;
- networking and HTTP;
- cryptography and hashing;
- COM, RPC, named pipes, and shared memory;
- UI, shell, and file associations;
- debugging, anti-debugging, and virtualization checks;
- update and installer APIs.

Do not treat a suspicious import as proof of malicious behavior. Correlate it
with strings, cross-references, and dynamic evidence.

## Exports

Exports matter for DLLs and plugin hosts:

- exported names and ordinals;
- forwarded exports;
- calling convention hints;
- exported data or service entry points.

## Strings

Collect ASCII and UTF-16LE strings. Prioritize:

- URLs, domains, user agents, and proxy settings;
- file paths, extensions, and configuration names;
- registry keys and services;
- named pipes and IPC endpoints;
- command lines and shell execution;
- error messages and log formats;
- version numbers and update endpoints;
- license, activation, and account-related text (document only);
- SQL queries and embedded file signatures.

Use `scripts/Get-StringSignals.ps1`. Review the full string set manually when
the signal list is too small or too noisy.

## Resources and manifests

- Icons, dialogs, menus, string tables, and version resources reveal UI shape.
- Manifests reveal requested privileges, DPI awareness, and side-by-side
  dependencies.
- Embedded archives, cabinets, or PE files require extraction in a VM.

## Framework detection

- .NET: CLR directory, `mscoree.dll`, managed metadata.
- Go: Go build ID, `runtime.` symbols, large static binary.
- Rust: panic strings, `std::` symbols, `.rdata` patterns.
- Delphi: `SysUtils`, `Classes`, Borland-specific imports.
- Electron: `resources/app.asar`, Chromium files, Node runtime.
- Python bundle: `python3*.dll`, `PyInstaller`, `_MEIPASS`.
- Java: `jvm.dll`, JAR resources, launcher stubs.
- Packed: high entropy, small import table, unpacking stub, anomalous sections.

## Artifacts to save

```text
01-static/
  triage.json
  triage.txt
  strings-signals.txt
  imports.txt
  exports.txt
  sections.csv
  signature.txt
  manifest.xml
  resources/
```

## Do not

- Do not run the target to "see what it does" during static triage.
- Do not upload the sample to a public scanner without approval.
- Do not assume a signed binary is safe.
- Do not assume an unsigned binary is malicious.
