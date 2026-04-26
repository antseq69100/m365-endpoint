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

```powershell
$MsiFile = 'WinSCP-6.5.6.msi'
