# Detection rule

## Recommended detection rule

Use a file detection rule.

### Settings

- Rule type: File
- Path: `%ProgramFiles(x86)%\WinSCP`
- File or folder: `WinSCP.exe`
- Detection method: File or folder exists
- Associated with a 32-bit app on 64-bit clients: No

## Why this rule

WinSCP is expected to be installed here:

`C:\Program Files (x86)\WinSCP`

This rule is simple, readable, and easy to troubleshoot.

## Validation

After installation, confirm that this file exists:

`C:\Program Files (x86)\WinSCP\WinSCP.exe`
