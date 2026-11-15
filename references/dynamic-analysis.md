# Dynamic analysis in a VM

Dynamic analysis is optional and requires explicit permission. The goal is to
observe behavior, not to attack systems.

## Lab setup

- Use a disposable Windows VM.
- Take a snapshot before installing or running anything.
- Disable shared folders, clipboard sharing, and drag-and-drop when possible.
- Use a fake user account with no real credentials.
- Keep the VM on host-only or controlled NAT networking.
- Record the VM image, Windows build, and tool versions.
- Revert the snapshot after the session.

## Baseline

Capture before execution:

- running processes and services;
- scheduled tasks;
- Run/RunOnce keys;
- installed programs;
- listening ports;
- files in target directories;
- relevant registry keys.

Use built-in PowerShell or your own snapshot script. Keep JSON snapshots under
`02-dynamic/before/`.

## Execution

Run one scenario at a time:

1. No arguments.
2. `/?`, `-h`, `--help`.
3. Documented CLI flags.
4. Open a sample file.
5. Save/export.
6. Invalid or corrupt input.
7. Permission-denied path.
8. Offline and online modes.
9. Install/uninstall, only in a disposable VM.

For each scenario record:

- command line and working directory;
- exit code;
- visible UI changes;
- files created, modified, or deleted;
- registry changes;
- services, tasks, or drivers created;
- network connections and payloads;
- crashes, hangs, or retries.

## Tools

### Process Monitor

Filter:

- `Process Name is <target>.exe`;
- exclude `Result is SUCCESS` when looking for failures;
- include `Operation is Process Profiling` only when needed;
- include registry, file system, process/thread, and network events.

Save the PML and a filtered CSV. Do not attach huge raw logs to the report.

### Process Explorer

- process tree and child processes;
- loaded DLLs and signed/unsigned status;
- handles and environment;
- command lines;
- integrity level.

### API Monitor or debugger

Use only when authorized. Focus on:

- file and registry APIs;
- process creation;
- network APIs;
- cryptography APIs;
- COM and RPC;
- UI automation.

Do not use debugging to bypass protections.

### Network

- Capture DNS, TCP, UDP, and TLS metadata.
- Decrypt only traffic you are authorized to inspect.
- Record endpoints, methods, headers, and payload shapes.
- Redact tokens and personal data.

## After execution

Capture after snapshots and compare:

- new or changed files;
- new or changed registry keys;
- new services, tasks, or drivers;
- new listening ports;
- new user accounts or permissions;
- outbound connections.

## Behavior matrix

| Scenario | Input | Output | Side effects | Evidence |
|---|---|---|---|---|
| Launch | none | window/console | config created | `02-dynamic/run-01.md` |
| Help | `--help` | usage text | none | `02-dynamic/run-02.md` |
| Open file | sample | parsed view | recent file | `02-dynamic/run-03.md` |
| Invalid file | corrupt | error | log entry | `02-dynamic/run-04.md` |

## Stop conditions

- Destructive file or registry operations outside the workspace.
- Attempts to access credentials, browser profiles, or personal data.
- Network propagation or exploitation attempts.
- Kernel driver installation without explicit approval.
- Security or antivirus tampering.
