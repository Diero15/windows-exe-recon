# Releasing

## Automated GitHub release

The workflow template lives at `ci/release.yml`. It is not active until it is
copied to `.github/workflows/release.yml`.

1. Copy `ci/release.yml` to `.github/workflows/release.yml` using the GitHub
   web editor, or with a token that has the `workflow` scope.
2. Commit and push.
3. Create and push a version tag:

```powershell
git tag -a v1.0.0 -m "Windows EXE Recon v1.0.0"
git push origin v1.0.0
```

The workflow builds `windows-exe-recon.zip` and creates a GitHub release with
the ZIP attached.

## Manual release

Build the ZIP locally:

```powershell
.\package.ps1
```

Create the release with GitHub CLI:

```powershell
gh release create v1.0.0 .\dist\windows-exe-recon.zip `
  --title "Windows EXE Recon v1.0.0" `
  --notes-file RELEASE_NOTES.md
```

Or create the release from the GitHub web UI and upload
`dist/windows-exe-recon.zip`.

## Downloadable source ZIP

Even without a GitHub Release, a tagged source ZIP is downloadable:

```text
https://github.com/Diero15/windows-exe-recon/archive/refs/tags/v1.0.0.zip
```

Extract it and double-click `install.cmd`.
