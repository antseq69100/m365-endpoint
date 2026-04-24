# WinSCP - Intune Win32 package

## Overview

This package deploys the official WinSCP MSI through PSAppDeployToolkit for managed Windows devices.

It is designed for:
- Microsoft Intune Win32 deployment
- Silent installation
- Silent uninstall
- Basic repair support
- Simple logging for troubleshooting

## Application details

| Property | Value |
|---|---|
| Application | WinSCP |
| Vendor | Martin Prikryl |
| Package type | Win32 app |
| Installer type | MSI |
| Wrapper | PSAppDeployToolkit |

## Source package

Use the official MSI installer:

`WinSCP-6.5.6.msi`

Place the MSI file in:

`package-layout/Files/`

Do not create an extracted application subfolder in `Files/`.

## Package structure

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

## Recommended Intune configuration

### Install behavior

`System`

### Install command

See: [`install-command.txt`](./install-command.txt)

### Uninstall command

See: [`uninstall-command.txt`](./uninstall-command.txt)

### Detection rule

See: [`detection-rule.md`](./detection-rule.md)

## Logging

Local logs are written to:

`C:\ProgramData\ITLYON\Logs\WinSCP\`

Main log files:
- `Deploy-Application.log`
- `Install.log`
- `Uninstall.log`
- `Repair.log`

## Build process

1. Copy the PSAppDeployToolkit template into `package-layout`
2. Copy the MSI file into `package-layout/Files/`
3. Replace `package-layout/Invoke-AppDeployToolkit.ps1` with the WinSCP deployment script
4. Build the `.intunewin` package from `package-layout`

See: [`build-package.txt`](./build-package.txt)

## Troubleshooting

See: [`troubleshooting.md`](./troubleshooting.md)

## Notes

- This package uses the official WinSCP MSI installer.
- The MSI file must be placed in `package-layout/Files/`.
- No extracted application subfolder is required in `Files/`.
- Update the MSI file name in `Invoke-AppDeployToolkit.ps1` when packaging a new version.

## Status

Validated as a working baseline for WinSCP deployment with Intune Win32 and PSAppDeployToolkit.
