---
name: Windows EXE Recon
description: Safely analyze an unknown Windows .exe, document its behavior, and plan an independent reimplementation without copying its code or assets.
metadata:
  opencode/autoinvoke: true
---

# Windows EXE Recon

Use this skill when the user wants to understand, document, compare, or
independently reimplement a Windows executable (`.exe`, and by extension
`.dll`, `.sys`, or another PE file). It is a workflow for authorized,
defensive, clean-room analysis.

## Contract

- Analyze only software the user owns or is explicitly authorized to test.
- Treat every unknown binary as potentially malicious.
- Do **not** execute an unknown binary on the host. Execute only inside an
  isolated VM or sandbox with a snapshot and no access to real credentials.
- Do **not** bypass DRM, licensing, authentication, activation, anti-cheat, or
  other technical protection measures. Document behavior; do not defeat it.
- Do **not** copy source code, decompiled code, assets, icons, logos, text, or
  branding into a reconstruction. Reimplement behavior independently.
- Ask before installing tools, enabling network access, running the target, or
  publishing results.
- Redact secrets, tokens, personal data, and customer data from evidence.
- If malware is suspected, stop normal analysis and use a dedicated malware
  analysis VM. Share hashes, not live samples, unless the user explicitly
  approves a safe channel.

## Inputs

Collect these before deep work:

1. Target path and file hash.
2. Where the file came from and what authorization exists.
3. Analysis goal: inventory, behavior map, file format, protocol, security
   review, interoperability, or clean-room reimplementation.
4. Constraints: offline only, no installs, time budget, VM availability,
   allowed tools, and whether execution is permitted.
5. Desired deliverable: short report, full report, JSON inventory, or
   implementation plan.

If authorization or execution permission is unclear, stop and ask.

## Workflow

### 0. Intake

- Record the exact path, size, timestamps, SHA-256, and signature status.
- Confirm whether the target may be executed and in which environment.
- Take a VM snapshot before execution.
- Create an analysis workspace with `scripts/New-AnalysisWorkspace.ps1`.

### 1. Static triage

- Run `scripts/Get-ExeTriage.ps1` and store the JSON under `01-static/`.
- Review PE type, machine, subsystem, sections, entropy, imports, exports,
  resources, signature, version information, and overlay.
- Run `scripts/Get-StringSignals.ps1` and review URLs, paths, registry keys,
  IPC names, commands, configuration files, and error messages.
- Identify the likely runtime: native C/C++, .NET, Go, Rust, Delphi, Electron,
  Python bundle, Java launcher, or a packed/obfuscated binary.
- Read `references/static-triage.md` for interpretation guidance.

### 2. Environment and dependencies

- List bundled DLLs, runtimes, configuration files, and data directories.
- Check whether the binary expects a service, driver, COM registration, or
  installer-created state.
- Prefer portable, read-only inspection. Do not install the target on the host.
- If the target is an installer, analyze its payload and installation changes
  in a VM; snapshot before and after.

### 3. Deep static analysis

- Use Ghidra when available. Follow `references/ghidra.md`.
- Start from entry points, imports, strings cross-references, and error text.
- Name functions and data structures as understanding improves.
- Focus on behavior and interfaces, not on reproducing the original code.
- Record evidence with addresses, function names, and short summaries.
- Do not paste large decompiled bodies into reports.

### 4. Dynamic analysis in a VM

- Follow `references/dynamic-analysis.md`.
- Capture process, file, registry, service, task, and network activity.
- Exercise documented CLI flags and UI paths, one variable at a time.
- Record inputs, outputs, side effects, errors, and state changes.
- Compare before/after snapshots and keep a timeline.
- Stop if the target attempts destructive actions, credential access, or
  network propagation outside the lab.

### 5. Behavior map

Produce a behavior matrix:

| Area | Questions |
|---|---|
| Entry points | GUI, CLI, service, COM, file association, protocol handler |
| Inputs | Files, arguments, registry, environment, IPC, network |
| Outputs | Files, stdout/stderr, UI, registry, logs, network |
| State | Config locations, caches, recent files, locks, migrations |
| Formats | Magic bytes, versioning, endianness, compression, encryption |
| Errors | User-facing messages, exit codes, retry behavior |
| Security | Trust boundaries, secrets, update channel, permissions |

Mark each finding as observed, inferred, or unknown.

### 6. Independent reconstruction plan

- Describe behavior and interfaces, not copied implementation.
- Choose a clean architecture and document compatibility requirements.
- List fixtures needed to validate behavior.
- Define a test matrix covering normal, boundary, corrupt, and permission cases.
- Keep original assets out of the new project unless the user has rights and
  explicitly asks to reuse them.

### 7. Report

Use `templates/report.md` and the guidance in `references/reporting.md`.
Include:

- executive summary;
- target identity and hashes;
- authorization and scope;
- environment;
- static findings;
- dynamic findings;
- behavior map;
- formats and protocols;
- security observations;
- unknowns and confidence;
- independent implementation plan;
- evidence index.

## Output layout

Use this structure under the analysis workspace:

```text
00-intake/      authorization, hashes, scope
01-static/      PE inventory, strings, signatures, resources
02-dynamic/     VM notes, Procmon/network captures, before/after snapshots
03-ghidra/      project notes, function map, decompiler summaries
04-report/      report and diagrams
evidence/       redacted screenshots, logs, and artifacts
```

## Tool selection

Prefer tools already installed. Ask before installing anything. The full
requirements, application list, and official upstream repositories are in
`references/requirements-and-tooling.md`.

- PowerShell 5.1+ for orchestration and PE triage.
- Sysinternals: Sigcheck, Process Explorer, Procmon, Autoruns, TCPView.
- Ghidra for static reversing and decompilation.
- Wireshark, Fiddler, or mitmproxy for network observation.
- x64dbg or WinDbg for authorized debugging.
- 7-Zip for archive/installer inspection.
- Python with `pefile`, `capstone`, or `yara` only if already available or the
  user approves installing them.

## Safety gates

Stop and ask the user before:

- executing an unknown binary outside a VM;
- enabling network access from the analysis VM;
- installing software;
- uploading a sample to a public service;
- publishing a report that contains customer data or secrets;
- performing any action that could affect production systems.

## Definition of done

- Hashes, signature, and provenance recorded.
- Static inventory captured and interpreted.
- Execution environment documented.
- Behavior map covers entry points, inputs, outputs, state, and errors.
- Findings distinguish observed, inferred, and unknown.
- Report is reproducible from the evidence.
- No code, assets, or branding from the target were copied into the
  reconstruction plan.

## Supporting files

- `references/safety-and-scope.md`
- `references/static-triage.md`
- `references/ghidra.md`
- `references/dynamic-analysis.md`
- `references/reporting.md`
- `references/requirements-and-tooling.md`
- `templates/report.md`
- `scripts/New-AnalysisWorkspace.ps1`
- `scripts/Get-ExeTriage.ps1`
- `scripts/Get-StringSignals.ps1`
- `scripts/Invoke-GhidraHeadless.ps1`
