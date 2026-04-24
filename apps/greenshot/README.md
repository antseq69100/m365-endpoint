# Greenshot - Intune Win32 package

## Overview

This package deploys Greenshot through PSAppDeployToolkit for managed Windows devices.

It is designed for:
- Microsoft Intune Win32 deployment
- Silent user-context installation
- Silent uninstall
- Cleanup of previous application leftovers
- Custom registry marker for Intune detection
- Simple logging for troubleshooting

## Application details

| Property | Value |
|---|---|
| Application | Greenshot |
| Vendor | Greenshot |
| Package type | Win32 app |
| Installer type | Portable extracted package |
| Wrapper | PSAppDeployToolkit |
| Install context | User |

## Source package

Use the extracted contents of:

`Greenshot-PORTABLE-1.3.315-RELEASE.zip`

Do not package the ZIP file itself.

Do not use the standard Greenshot EXE installer for this deployment model.

## Package structure

    apps/greenshot/
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
        │   ├── Greenshot/
        │   │   ├── Greenshot.exe
        │   │   ├── Greenshot.Base.dll
        │   │   ├── Greenshot.Editor.dll
        │   │   ├── Languages/
        │   │   ├── Plugins/
        │   │   └── ...
        │   └── greenshot-defaults.ini
        ├── PSAppDeployToolkit/
        ├── PSAppDeployToolkitExtensions/
        ├── Strings/
        ├── SupportFiles/
        ├── Invoke-AppDeployToolkit.exe
        └── Invoke-AppDeployToolkit.ps1

## Recommended Intune configuration

### Install behavior

`User`

### Install command

See: [`install-command.txt`](./install-command.txt)

### Uninstall command

See: [`uninstall-command.txt`](./uninstall-command.txt)

### Detection rule

See: [`detection-rule.md`](./detection-rule.md)

## Logging

Typical log files are written to:

`C:\Temp\Install-App.log`  
`C:\Temp\Uninstall-App.log`

Additional Intune troubleshooting logs:

`C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\`

## Build process

1. Copy the PSAppDeployToolkit template into `package-layout`
2. Copy the extracted Greenshot portable files into `package-layout/Files/Greenshot/`
3. Copy `greenshot-defaults.ini` into `package-layout/Files/`
4. Replace `package-layout/Invoke-AppDeployToolkit.ps1` with the Greenshot deployment script
5. Build the `.intunewin` package from `package-layout`

See: [`build-package.txt`](./build-package.txt)

## Detection model

This package uses a custom registry marker for Intune detection.

Expected detection marker:

`HKLM\SOFTWARE\ITLYON\Apps\Greenshot`

Value:

`Version = 1.3.315`

See: [`detection-rule.md`](./detection-rule.md)

## Troubleshooting

See: [`troubleshooting.md`](./troubleshooting.md)

## Notes

- This package is based on the extracted portable Greenshot package.
- Do not package the ZIP file directly.
- Do not use the standard EXE installer for this deployment model.
- The package writes a custom registry marker for Intune detection.
- `greenshot-defaults.ini` can be used to apply default settings.

## Status

Validated as a working baseline for Greenshot deployment with Intune Win32 and PSAppDeployToolkit.
