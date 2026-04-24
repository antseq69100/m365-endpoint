# WinSCP - Intune Win32 package

## Overview

This package deploys the official WinSCP MSI through PSAppDeployToolkit for managed Windows devices.

It is designed for:
- Microsoft Intune Win32 deployment
- Silent machine-wide installation
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
| Install context | System |
| Architecture | x86 app installed on x64 Windows in Program Files (x86) |

## Repository structure

```text
apps/winscp/
├── package-layout/
├── .gitignore
├── Invoke-AppDeployToolkit.ps1
├── README.md
├── build-package.txt
├── detection-rule.md
├── install-command.txt
├── troubleshooting.md
└── uninstall-command.txt
