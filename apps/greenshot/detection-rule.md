# Detection rule

## Intune detection settings
- **Rule type**: Registry
- **Key path**: `HKEY_CURRENT_USER\SOFTWARE\YourCompany\Apps\Greenshot`
- **Value name**: `Version`
- **Detection method**: String comparison
- **Operator**: Equals
- **Value**: `1.3.315`
- **Associated with a 32-bit app on 64-bit clients**: No

## Why this detection rule
This package deploys Greenshot in **user context** from the portable ZIP package.

The application files are copied to:

`%LocalAppData%\Programs\Greenshot`

The deployment script then writes a custom registry marker in the current user hive:

`HKCU\SOFTWARE\YourCompany\Apps\Greenshot`

This registry marker is used as the authoritative Intune detection method.
