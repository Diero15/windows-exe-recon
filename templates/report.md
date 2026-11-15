# Analysis report: <target name>

## Executive summary

<What the binary appears to be, its main behavior, and the confidence level.>

## Target identity

| Field | Value |
|---|---|
| Path | `<path>` |
| SHA-256 | `<hash>` |
| Size | `<bytes>` |
| Signature | `<status / signer>` |
| Version | `<file version>` |
| Build timestamp | `<PE timestamp>` |
| Analysis date | `<date>` |

## Authorization and scope

- Source and owner: `<...>`
- Authorization: `<...>`
- Execution allowed: `<yes/no, where>`
- Network allowed: `<yes/no, where>`
- Publication allowed: `<yes/no>`

## Environment

- Host/VM: `<...>`
- Windows build: `<...>`
- Tools: `<Ghidra version, Procmon version, ...>`
- Network mode: `<offline/host-only/NAT>`

## Static findings

### PE summary

<Machine, subsystem, sections, entropy, overlay, packer hints.>

### Imports and exports

<Grouped by subsystem; only the relevant entries.>

### Strings and resources

<URLs, paths, registry keys, IPC names, commands, errors.>

### Framework and runtime

<Native, .NET, Go, Rust, Delphi, Electron, Python, Java, packed.>

## Dynamic findings

| Scenario | Input | Observed behavior | Side effects | Evidence |
|---|---|---|---|---|
| Launch | none | `<...>` | `<...>` | `<path>` |
| Help | `--help` | `<...>` | `<...>` | `<path>` |
| Open file | `<fixture>` | `<...>` | `<...>` | `<path>` |

## Behavior map

### Entry points

<GUI, CLI, service, COM, file association, protocol handler.>

### Inputs

<Files, arguments, registry, environment, IPC, network.>

### Outputs

<Files, UI, stdout/stderr, logs, registry, network.>

### State and configuration

<Paths, formats, locks, migrations, recent files.>

### File formats and protocols

<Magic bytes, versions, lengths, endianness, checksums, encryption.>

### Errors and edge cases

<Exit codes, messages, retries, partial writes.>

## Security observations

<Trust boundaries, secrets, update verification, permissions. Document only;
do not bypass protections.>

## Unknowns

- `<question>` — next experiment: `<...>`
- `<question>` — next experiment: `<...>`

## Independent implementation plan

- Scope and compatibility goals: `<...>`
- Architecture: `<...>`
- Fixtures and tests: `<...>`
- Deliberate differences: `<...>`

## Evidence index

```text
00-intake/...
01-static/...
02-dynamic/...
03-ghidra/...
evidence/...
```
