# Greenshot - Intune Win32 deployment with PSAppDeployToolkit (Portable ZIP)

## Objective
Deploy Greenshot 1.3.315 through Microsoft Intune as a Win32 app using PSAppDeployToolkit and the portable ZIP package, with a fully silent user-context deployment, clean removal, and reliable detection.

## Target version
`1.3.315`

## Chosen method
- Intune Win32 package
- PSAppDeployToolkit (PSADT)
- Deployment in **User** context
- Source based on the **portable ZIP package**
- Files copied to `%LocalAppData%\Programs\Greenshot`
- Detection through a custom **HKCU** registry marker
- Optional startup registration through `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`
- Pilot validation before wider deployment

## Prerequisites

- PSAppDeployToolkit 4.1.x (tested with 4.1.8)
- Greenshot-PORTABLE-1.3.315-RELEASE.zip
- Microsoft Win32 Content Prep Tool (IntuneWinAppUtil.exe)

## Download sources

- PSAppDeployToolkit: official PSADT documentation / GitHub releases
- Greenshot portable package: official Greenshot downloads / version history
- IntuneWinAppUtil.exe: official Microsoft Intune Win32 packaging documentation

## Source package
Use the extracted contents of:

`Greenshot-PORTABLE-1.3.315-RELEASE.zip`

Do not package the ZIP file itself.  
Do not use the standard Greenshot EXE installer for this deployment model.

```md
## Notes

- The WinSCP package uses the official MSI installer.
- The MSI file must be placed in `package-layout/Files/`.
- No extracted application subfolder is required in `Files/`.

## Package structure

```text
apps/winscp/
├── .gitignore
├── Invoke-AppDeployToolkit.ps1
├── README.md
├── build-package.txt
├── detection-rule.md
├── install-command.txt
├── troubleshooting.md
├── uninstall-command.txt
└── package-layout/
    ├── Assets/
    ├── Config/
    ├── Files/
    │   ├── Add Setup Files Here.txt
    │   └── WinSCP-6.5.6.msi
    ├── PSAppDeployToolkit/
    ├── PSAppDeployToolkitExtensions/
    ├── Strings/
    ├── SupportFiles/
    ├── Invoke-AppDeployToolkit.exe
    └── Invoke-AppDeployToolkit.ps1

## Intune configuration

### Install behavior
`User`

### Installation command
See: [`install-command.txt`](./install-command.txt)

### Uninstall command
See: [`uninstall-command.txt`](./uninstall-command.txt)

### Detection rule
See: [`detection-rule.md`](./detection-rule.md)

## Post-deployment validation

### Verify registry marker

```powershell
reg query "HKCU\SOFTWARE\YourCompany\Apps\Greenshot" /v Version
```

### Verify installed files

```powershell
Get-ChildItem "$env:LocalAppData\Programs\Greenshot"
```

### Verify executable version

```powershell
([System.Diagnostics.FileVersionInfo]::GetVersionInfo("$env:LocalAppData\Programs\Greenshot\Greenshot.exe")).FileVersion
```

### Verify startup registration

```powershell
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v Greenshot
```

## Important notes
- Do not use the standard Greenshot EXE installer in this package
- Do not keep HKLM-based detection from the previous deployment model
- Do not validate the app through `Program Files` paths for this package
- Rebuild the `.intunewin` package after every script change
- Keep pilot assignments isolated from the old EXE-based package

## Documentation files
- [`detection-rule.md`](./detection-rule.md)
- [`troubleshooting.md`](./troubleshooting.md)
- [`install-command.txt`](./install-command.txt)
- [`uninstall-command.txt`](./uninstall-command.txt)

## Lessons learned
The original EXE-based deployment model caused several issues:
- browser opening at the end of setup
- inconsistent silent behavior
- unreliable alignment between install context and detection logic
- confusion between machine-wide and user-based installation paths

The portable ZIP + PSADT model was retained because it provides:
- a fully controlled file copy deployment
- clean user-context installation
- reliable HKCU-based detection
- no dependency on the Greenshot installer UI behavior
