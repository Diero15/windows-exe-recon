# Windows EXE Recon v1.0.0

A portable OpenCode skill for authorized, defensive analysis of Windows
executables: static triage, Ghidra guidance, VM-based dynamic observation,
behavior mapping, and an independent reimplementation plan.

## Install from the ZIP

If the release asset `windows-exe-recon.zip` is attached, download it.
Otherwise download the tagged source ZIP:

```text
https://github.com/Diero15/windows-exe-recon/archive/refs/tags/v1.0.0.zip
```

1. Extract the ZIP.
2. Double-click `install.cmd`.

The installer copies the skill to:

```text
%USERPROFILE%\.config\opencode\skills\windows-exe-recon
```

## Install with PowerShell

```powershell
irm https://raw.githubusercontent.com/Diero15/windows-exe-recon/main/install.ps1 | iex
```

Or, from the extracted ZIP:

```powershell
.\install.ps1
```

Project-local install:

```powershell
.\install.ps1 -Project
```

Update an existing install:

```powershell
.\install.ps1 -Force
```

Uninstall:

```powershell
.\install.ps1 -Uninstall
```

## Use

```text
Use @windows-exe-recon to analyze C:\Samples\app.exe.
Do not execute it on the host. Start with static triage.
```

## Safety

Analyze only software you own or are authorized to test. Execute unknown
binaries only in an isolated VM. Do not bypass DRM, licensing, authentication,
activation, or anti-cheat. Do not copy code, assets, icons, logos, or text.
