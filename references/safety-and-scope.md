# Safety and scope

## Authorization

Before opening the target, confirm:

- who owns the binary;
- why the analysis is allowed;
- whether execution is permitted;
- whether network access is permitted;
- whether results may be published.

If any answer is unclear, pause and ask. A hash and a filename are not proof of
authorization.

## Isolation model

| Activity | Host | Isolated VM |
|---|---:|---:|
| Hash, strings, PE headers | Allowed | Allowed |
| Signature and version metadata | Allowed | Allowed |
| Ghidra static analysis | Allowed | Allowed |
| Executing an unknown binary | **No** | Required |
| Network observation | **No** | Required |
| Installer execution | **No** | Required |
| Kernel driver loading | **No** | Required, disposable VM |

- Take a VM snapshot before execution.
- Disable shared folders, clipboard sharing, and drag-and-drop when possible.
- Use a fake user profile and no real credentials.
- Keep the VM off production networks. Use host-only or controlled NAT.
- Revert the snapshot after analysis.

## Malware handling

If the target shows signs of malware:

- stop interactive exploration;
- preserve the VM state and hashes;
- use a dedicated malware analysis environment;
- do not upload live samples to public services without approval;
- share hashes and behavioral indicators, not raw samples;
- never run the sample on the host or a production network.

## Prohibited actions

- Defeating DRM, licensing, activation, authentication, or anti-cheat.
- Reusing copied code, assets, icons, logos, or text in a reconstruction.
- Credential dumping, persistence, lateral movement, or destructive testing.
- Publishing customer data, secrets, or private paths.
- Installing tools or exposing network services without approval.

## Data handling

- Redact secrets, tokens, session identifiers, and personal data.
- Keep evidence in the analysis workspace.
- Prefer screenshots and short excerpts over full memory dumps.
- Record hashes and provenance for every artifact.
- Do not commit target binaries to this repository.

## Stop conditions

Stop and ask the user if:

- the binary attempts to modify the boot sector, drivers, or security settings;
- the binary contacts unexpected external hosts;
- the binary attempts credential access or privilege escalation;
- the analysis requires installing a kernel driver;
- the evidence contains customer data or secrets;
- the requested next step would affect a real system.
