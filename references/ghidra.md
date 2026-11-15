# Ghidra workflow

Use Ghidra for static understanding when available. The objective is a behavior
map and clean-room specification, not a complete source reconstruction.

## Prepare

- Confirm the target hash and copy it into the isolated analysis workspace.
- Create a Ghidra project per target and per analysis date.
- Keep the original binary read-only.
- Use a shared project only when the user approves.

## Headless import

```powershell
.\scripts\Invoke-GhidraHeadless.ps1 `
  -Target C:\Samples\app.exe `
  -ProjectDir .\analysis-app\03-ghidra `
  -ProjectName app-recon
```

The wrapper calls:

```text
analyzeHeadless <projectDir> <projectName> -import <target>
```

Add `-NoAnalysis` for a fast import, then analyze interactively. Add
`-ScriptPath` and `-PostScript` for custom export scripts.

## Entry points

Start with:

- `entry`;
- `WinMain`, `wWinMain`, `main`, `wmain`;
- `DllMain` for DLLs;
- TLS callbacks;
- service entry points (`ServiceMain`, `HandlerEx`);
- COM exports (`DllGetClassObject`, `DllRegisterServer`);
- runtime initialization for .NET, Go, Rust, or Delphi.

Follow the imports and strings that match the user's goal.

## Triage order

1. List imported functions and group them by subsystem.
2. Find strings that expose features, paths, URLs, and errors.
3. Follow cross-references from high-value strings.
4. Identify command-line parsing and configuration loading.
5. Identify file formats, serialization, and validation.
6. Identify IPC, network protocols, and update mechanisms.
7. Identify security boundaries and privilege requirements.
8. Rename functions and data as understanding improves.

## Naming and comments

Use names that describe behavior, not guessed original names:

```text
parse_config_file
read_license_blob
start_update_check
encode_request_body
```

Add comments with:

- observed input and output;
- evidence address;
- confidence level;
- open questions.

## Decompiler hygiene

- Do not paste large decompiled functions into reports.
- Summarize control flow and data structures.
- Keep short excerpts only when they prove a specific behavior.
- Record the function address and the build hash with every excerpt.
- Avoid copying source-like code into a reconstruction repository.

## Formats and protocols

When reversing a file format or protocol:

- locate magic bytes and version fields;
- identify integer widths and endianness;
- identify length prefixes and checksums;
- build a minimal writer/reader in a separate test harness;
- validate with round-trip fixtures;
- document unknown fields explicitly.

## Security review

Document, but do not defeat:

- license and activation checks;
- signature verification;
- anti-debugging and anti-VM checks;
- update signature checks;
- permission boundaries;
- credential storage.

Classify each as observed, inferred, or unknown.

## Evidence to keep

```text
03-ghidra/
  project-notes.md
  function-map.csv
  string-xrefs.md
  format-notes.md
  protocol-notes.md
  decompiler-summaries/
```

## Stop conditions

- The binary is packed and unpacking would require running it outside a VM.
- The analysis requires defeating a protection mechanism.
- The target contains credentials or customer data.
- The next step would modify a real system.
