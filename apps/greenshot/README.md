# Greenshot - Intune Win32 + PSADT

## Objective
Deploy Greenshot through Intune as a Win32 app using PSAppDeployToolkit, with silent installation, clean uninstallation, and reliable detection.

## Target version
`1.3.315`

## Selected approach
- Intune Win32 package
- PSADT script
- Installation in **System** context
- Detection through a **custom registry key**
- Initial validation on a pilot machine

## Intune detection rule
- **Type**: Registry
- **Key path**: `HKEY_LOCAL_MACHINE\SOFTWARE\ITLYON\Apps\Greenshot`
- **Value name**: `Version`
- **Detection method**: String comparison
- **Operator**: Equals
- **Value**: `1.3.315`

## Intune commands

### Install
See: [`install-command.txt`](./install-command.txt)

Command used:
```text
%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -NoProfile -File .\Invoke-AppDeployToolkit.ps1 -DeploymentType Install -DeployMode Silent
```

### Uninstall
See: [`uninstall-command.txt`](./uninstall-command.txt)

Command used:
```text
%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -NoProfile -File .\Invoke-AppDeployToolkit.ps1 -DeploymentType Uninstall -DeployMode Silent
```

## Documentation files
- [`detection-rule.md`](./detection-rule.md)
- [`troubleshooting.md`](./troubleshooting.md)

## Important notes
- Do not place `Greenshot.ini` inside `Program Files`
- Use `greenshot-defaults.ini` only if a default configuration is needed
- Rebuild the `.intunewin` package after any script change
- Verify the registry key after installation
- Unblock PSADT files after extraction if the content comes from an Internet download
- Rebuild the `.intunewin` package after running `Unblock-File`

## Post-deployment checks

### Check the registry key
```powershell
reg query "HKLM\SOFTWARE\ITLYON\Apps\Greenshot" /v Version
```

### Check the installed binary version
```powershell
([System.Diagnostics.FileVersionInfo]::GetVersionInfo("C:\Program Files\Greenshot\Greenshot.exe")).FileVersion
```

## Package preparation
Before generating the `.intunewin`, unblock PSADT files if needed:

```powershell
Get-ChildItem "C:\Packages\Greenshot" -Recurse | Unblock-File
```

Then rebuild the `.intunewin` package.

## Lessons learned
A previous upgrade approach that installed over the existing version caused:
- leftover files in the installation folder
- multiple uninstallers
- `Greenshot.ini` related errors

Using PSADT was selected to better control:
- uninstallation
- cleanup
- reinstallation
- Intune detection

An additional issue was identified during local testing:
- the PSADT module could be blocked by Windows after extraction from downloaded content
- this prevented module import and therefore package execution
- the fix was to unblock the files and then rebuild the `.intunewin`
