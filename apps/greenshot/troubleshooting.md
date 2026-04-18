# Troubleshooting

## App installs but is not detected
Check that Intune detection is configured against:

`HKEY_CURRENT_USER\SOFTWARE\ITLYON\Apps\Greenshot`

and not `HKEY_LOCAL_MACHINE`.

Verify locally:

```powershell
reg query "HKCU\SOFTWARE\ITLYON\Apps\Greenshot" /v Version
```

## App is detected nowhere on disk
Check the user profile path:

```powershell
Get-ChildItem "$env:LocalAppData\Programs\Greenshot"
```

This package does not install Greenshot into `Program Files`.

## Wrong install context
This package must be configured in Intune with:

- **Install behavior** = `User`

If the app is deployed in System context, the user-based installation logic and HKCU detection will not align correctly.

## Old package interference
Make sure the old EXE-based Greenshot package is no longer assigned to the same pilot target.

## Command validation

### Install command

```text
%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -NoProfile -File .\Invoke-AppDeployToolkit.ps1 -DeploymentType Install -DeployMode Silent
```

### Uninstall command

```text
%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -NoProfile -File .\Invoke-AppDeployToolkit.ps1 -DeploymentType Uninstall -DeployMode Silent
```

## Version validation
Check the executable version:

```powershell
([System.Diagnostics.FileVersionInfo]::GetVersionInfo("$env:LocalAppData\Programs\Greenshot\Greenshot.exe")).FileVersion
```

Expected normalized version for detection:

`1.3.315`
