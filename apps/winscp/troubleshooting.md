# Troubleshooting

## Common log locations

### Intune Management Extension

`C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\`

Main files:
- `AppWorkload.log`
- `AppActionProcessor.log`
- `IntuneManagementExtension.log`
- `AgentExecutor.log`

### Local package logs

`C:\ProgramData\ITLYON\Logs\WinSCP\`

Files:
- `Deploy-Application.log`
- `Install.log`
- `Uninstall.log`
- `Repair.log`

## Common checks

### 1. Verify the MSI exists in the package

Expected location:

`Files\WinSCP-6.5.6.msi`

### 2. Verify the script variable matches the exact MSI name

In `Invoke-AppDeployToolkit.ps1`:

    $MsiFile = 'WinSCP-6.5.6.msi'

### 3. Verify installation result

Expected executable:

`C:\Program Files (x86)\WinSCP\WinSCP.exe`

### 4. Verify Intune install command

`%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -NoProfile -File .\Invoke-AppDeployToolkit.ps1 -DeploymentType Install -DeployMode Silent`

### 5. Verify Intune uninstall command

`%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -NoProfile -File .\Invoke-AppDeployToolkit.ps1 -DeploymentType Uninstall -DeployMode Silent`

## Typical failure causes

- MSI file missing from `Files`
- Wrong MSI file name in script
- Wrong detection rule
- Package rebuilt from the wrong source folder
- Old package still assigned in Intune

## Recommended validation process

1. Test locally from the package folder
2. Confirm WinSCP is installed
3. Confirm detection path exists
4. Build `.intunewin`
5. Upload to Intune
6. Test on one device before broad assignment
