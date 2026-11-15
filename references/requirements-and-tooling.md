# Requirements, applications, and upstream projects

This page lists what the skill needs, what it can use, and which official
projects the guidance refers to. Nothing here is bundled or installed
automatically.

## Minimum setup

| Requirement | Required | Notes |
|---|---:|---|
| OpenCode V2 | Yes | Hosts the skill and loads `SKILL.md`. |
| Windows 10 or 11 | Yes for the PowerShell scripts | The workflow is PE-centric; static analysis can be done on Windows. |
| Windows PowerShell 5.1+ or PowerShell 7+ | Yes | Scripts are tested with Windows PowerShell 5.1; PowerShell 7+ is supported. |
| Authorization to analyze the target | Yes | Owner or explicit permission. |
| Isolated VM or sandbox | Yes for execution | Snapshot before running an unknown binary; no real credentials. |
| Git | Recommended | Clone and update the skill repository. |
| Disk space | 1-5 GB recommended | Evidence, logs, VM snapshots, and Ghidra projects. |

## Recommended lab

| Component | Why |
|---|---|
| Disposable Windows VM | Safe execution and rollback. |
| Host-only or controlled NAT network | Observe traffic without exposing the host. |
| Fake user profile | Avoid real credentials and personal data. |
| Snapshot | Revert after every execution session. |
| Separate evidence directory | Keep hashes, logs, and screenshots reproducible. |

## Applications

| Application | Role | When | Required |
|---|---|---|---|
| [OpenCode](https://opencode.ai) | Agent host and skill loader | Always | Yes |
| [PowerShell](https://github.com/PowerShell/PowerShell) | Orchestration and PE triage | Always | Yes |
| [Git](https://git-scm.com) | Clone and update the skill | Install/update | Recommended |
| [Ghidra](https://github.com/NationalSecurityAgency/ghidra) | Static analysis and decompilation | Deep static work | Optional |
| [Sysinternals](https://learn.microsoft.com/sysinternals/) | Procmon, Process Explorer, Sigcheck, Autoruns, TCPView | Dynamic triage | Optional |
| [Wireshark](https://www.wireshark.org/) | Network capture and protocol inspection | Network behavior | Optional |
| [7-Zip](https://www.7-zip.org/) | Installer and archive inspection | Packed payloads | Optional |
| [x64dbg](https://github.com/x64dbg/x64dbg) | User-mode debugging | Authorized debugging | Optional |
| [WinDbg](https://learn.microsoft.com/windows-hardware/drivers/debugger/) | Kernel and user-mode debugging | Drivers or crash analysis | Optional |
| [Python](https://www.python.org/) | Automation and small parsers | Repetitive analysis | Optional |
| [pefile](https://github.com/erocarrera/pefile) | PE parsing in Python | Custom inventories | Optional |
| [Capstone](https://github.com/capstone-engine/capstone) | Disassembly in Python | Custom analysis | Optional |
| [YARA](https://github.com/VirusTotal/yara) | Rule-based scanning | Classification and hunting | Optional |
| [Detect It Easy](https://github.com/horsicq/Detect-It-Easy) | Packer and compiler detection | Static triage | Optional |
| [HxD](https://mh-nexus.de/en/hxd/) | Hex editor | Format inspection | Optional |

## Upstream repositories

These are the official projects and documentation sites referenced by the
skill. The skill does not vendor their code, and their licenses remain their
own.

| Project | Official source | Used for |
|---|---|---|
| OpenCode | <https://opencode.ai> · <https://opencode.ai/v2/docs/> | Skill runtime and format |
| Ghidra | <https://github.com/NationalSecurityAgency/ghidra> | Disassembly and decompilation |
| Sysinternals | <https://learn.microsoft.com/sysinternals/> | Process, file, registry, and network observation |
| Wireshark | <https://gitlab.com/wireshark/wireshark> · <https://www.wireshark.org/> | Packet capture |
| 7-Zip | <https://www.7-zip.org/> | Archive extraction |
| x64dbg | <https://github.com/x64dbg/x64dbg> | Debugging |
| WinDbg | <https://learn.microsoft.com/windows-hardware/drivers/debugger/> | Debugging |
| pefile | <https://github.com/erocarrera/pefile> | PE parsing |
| Capstone | <https://github.com/capstone-engine/capstone> | Disassembly |
| YARA | <https://github.com/VirusTotal/yara> | Rule scanning |
| Detect It Easy | <https://github.com/horsicq/Detect-It-Easy> | Packer detection |
| HxD | <https://mh-nexus.de/en/hxd/> | Hex editing |

## What is not required

- No cloud account or API key for static triage.
- No network access for the PowerShell scripts.
- No specific product, vendor, or file format.
- No bundled target binaries or third-party code.

## Installation policy

The skill never installs tools automatically. If a task needs an application
that is not present, the agent must ask the user before installing it. Prefer
portable tools and versions already approved by the user.

## Safety notes

- Ghidra, debuggers, and Procmon can expose sensitive data. Use a lab VM.
- Wireshark captures may contain credentials or personal data. Redact them.
- YARA rules and Python packages should come from trusted sources.
- Verify download hashes and signatures when possible.
- Keep the analysis VM isolated from production networks.
