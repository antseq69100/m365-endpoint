# Troubleshooting - Greenshot

## Symptoms observed
- Startup error related to `Greenshot.ini`
- Previous version not replaced cleanly
- Multiple uninstall files present (`unins000.exe`, `unins001.exe`)
- Mixed installation folder content between old and new versions
- Intune reporting delay or inconsistent device install status

## Likely causes
- In-place upgrade over an existing version
- Application still running during upgrade
- Leftover files in `Program Files`
- Detection rule too broad or not reliable enough
- Overlap between old package logic and new package logic
- PSADT files blocked by Windows after extraction from downloaded content

## Selected solution
- Move to a PSADT-based package
- Uninstall the previous version before reinstalling
- Remove leftover installation folders
- Install the new version silently
- Use a custom registry key for Intune detection

## Verification steps after installation

### Check the registry key
```powershell
reg query "HKLM\SOFTWARE\ITLYON\Apps\Greenshot" /v Version
```

### Check the installed binary version
```powershell
([System.Diagnostics.FileVersionInfo]::GetVersionInfo("C:\Program Files\Greenshot\Greenshot.exe")).FileVersion
```

### Check Intune Management Extension logs
```text
C:\ProgramData\Microsoft\IntuneManagementExtension\Logs
```

### Check PSADT logs
```text
C:\Windows\Logs\Software
```

## PSADT module blocked issue
During manual testing, the package failed while importing PSADT with an error related to:

```text
PSADT.ClientServer.Server.dll
0x80131515
```

### Cause
PSADT files extracted from downloaded content were blocked by Windows.

### Fix
Unblock all files in the package folder before packaging:

```powershell
Get-ChildItem "C:\Packages\Greenshot" -Recurse | Unblock-File
```

### Required follow-up actions
1. Retest the script locally
2. Rebuild the `.intunewin`
3. Reupload the application in Intune

## Important notes
- Do not place `Greenshot.ini` inside `Program Files`
- Use `greenshot-defaults.ini` only if needed
- Rebuild the `.intunewin` after every script change
- Validate first on a pilot machine
- Prefer 64-bit PowerShell in Intune commands through `Sysnative`
