# Troubleshooting

## Application installs but is not detected
Check that Intune detection is configured against:

`HKEY_CURRENT_USER\SOFTWARE\YourCompany\Apps\Greenshot`

and not `HKEY_LOCAL_MACHINE`.

Verify locally:

```powershell
reg query "HKCU\SOFTWARE\YourCompany\Apps\Greenshot" /v Version
```

## Application is installed in the wrong path
This package is designed for a user-context deployment and copies Greenshot to:

`%LocalAppData%\Programs\Greenshot`

Verify locally:

```powershell
Get-ChildItem "$env:LocalAppData\Programs\Greenshot"
```

Do not use `Program Files` as the expected path for this package.

## Detection rule is incorrect
Use the following Intune detection rule:

- Rule type: Registry
- Key path: `HKEY_CURRENT_USER\SOFTWARE\YourCompany\Apps\Greenshot`
- Value name: `Version`
- Detection method: String comparison
- Operator: Equals
- Value: `1.3.315`

## Wrong install context
This package must be configured in Intune with:

- **Install behavior** = `User`

If the deployment is configured in System context, installation and detection will not align correctly.

## Browser or unwanted UI opens during install
This issue was observed with the standard EXE installer approach.

The retained solution is based on the portable ZIP package, which avoids the installer post-actions and provides a cleaner silent deployment.

## Validate installation command

```text
%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -NoProfile -File .\Invoke-AppDeployToolkit.ps1 -DeploymentType Install -DeployMode Silent
```

## Validate uninstall command

```text
%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -NoProfile -File .\Invoke-AppDeployToolkit.ps1 -DeploymentType Uninstall -DeployMode Silent
```

## Validate installed version

```powershell
([System.Diagnostics.FileVersionInfo]::GetVersionInfo("$env:LocalAppData\Programs\Greenshot\Greenshot.exe")).FileVersion
```

Expected normalized version:

`1.3.315`

## Validate startup registration

```powershell
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v Greenshot
```

## Conflict with previous package
If an older Greenshot package was previously assigned, make sure:
- it is removed from the same target scope
- it is renamed as legacy or old
- it does not still enforce an outdated detection method or installer-based deployment model
