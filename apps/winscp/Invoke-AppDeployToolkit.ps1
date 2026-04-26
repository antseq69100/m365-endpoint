<#
===============================================================================
PSADT - WinSCP deployment
Author : Anthony Sequeira

Purpose :
- Install WinSCP silently from MSI
- Uninstall WinSCP cleanly
- Repair WinSCP if needed
- Keep a simple and reliable package for Intune Win32

Notes :
- Designed for machine-wide deployment
- MSI must be stored in .\Files\
===============================================================================
#>

[CmdletBinding()]
param(
    [ValidateSet('Install','Uninstall','Repair')]
    [string]$DeploymentType = 'Install',

    [ValidateSet('Interactive','Silent','NonInteractive')]
    [string]$DeployMode = 'Silent'
)

$ErrorActionPreference = 'Stop'
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition

# =====================================================================
# IMPORT PSADT MODULE
# =====================================================================

$PSADTModulePath = Join-Path $ScriptRoot 'PSAppDeployToolkit\PSAppDeployToolkit.psd1'

if (-not (Test-Path $PSADTModulePath)) {
    throw "PSADT module not found: $PSADTModulePath"
}

Import-Module $PSADTModulePath -Force

# =====================================================================
# APPLICATION VARIABLES
# =====================================================================

$CompanyName = 'ITLYON'
$AppName     = 'WinSCP'
$MsiFile     = 'WinSCP-6.5.6.msi'
$MsiPath     = Join-Path $ScriptRoot "Files\$MsiFile"

$LogFolder = Join-Path $env:ProgramData "$CompanyName\Logs\$AppName"
if (-not (Test-Path $LogFolder)) {
    New-Item -Path $LogFolder -ItemType Directory -Force | Out-Null
}

$InstallLog   = Join-Path $LogFolder 'Install.log'
$UninstallLog = Join-Path $LogFolder 'Uninstall.log'
$RepairLog    = Join-Path $LogFolder 'Repair.log'

# =====================================================================
# FUNCTIONS
# =====================================================================

function Write-LocalLog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    $TimeStamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $Line = "[$TimeStamp] $Message"
    Add-Content -Path (Join-Path $LogFolder 'Deploy-Application.log') -Value $Line
}

function Stop-AppProcess {
    Write-LocalLog "Checking if $AppName is running."

    Get-Process -Name 'WinSCP' -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue

    Start-Sleep -Seconds 2
}

function Test-AppInstalled {
    $ExePath = "${env:ProgramFiles(x86)}\WinSCP\WinSCP.exe"
    return (Test-Path $ExePath)
}

function Invoke-MsiAction {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Install','Uninstall','Repair')]
        [string]$Action,

        [Parameter(Mandatory = $true)]
        [string]$LogPath
    )

    if (-not (Test-Path $MsiPath)) {
        throw "MSI not found: $MsiPath"
    }

    switch ($Action) {
        'Install' {
            $Args = @(
                '/i'
                $MsiPath
                '/qn'
                '/norestart'
                '/L*v'
                $LogPath
            )
        }

        'Uninstall' {
            $Args = @(
                '/x'
                $MsiPath
                '/qn'
                '/norestart'
                '/L*v'
                $LogPath
            )
        }

        'Repair' {
            $Args = @(
                '/fa'
                $MsiPath
                '/qn'
                '/norestart'
                '/L*v'
                $LogPath
            )
        }
    }

    Write-LocalLog "Starting MSI action: $Action"
    Write-LocalLog "MSI Path: $MsiPath"
    Write-LocalLog "MSI Log: $LogPath"

    $Process = Start-Process -FilePath 'msiexec.exe' -ArgumentList $Args -Wait -PassThru -WindowStyle Hidden

    Write-LocalLog "msiexec.exe finished with exit code: $($Process.ExitCode)"

    if ($Process.ExitCode -notin @(0,3010,1641)) {
        throw "MSI action failed. ExitCode: $($Process.ExitCode). Check MSI log: $LogPath"
    }

    return $Process.ExitCode
}

# =====================================================================
# MAIN
# =====================================================================

try {
    Write-LocalLog "============================================================"
    Write-LocalLog "Starting deployment. Type: $DeploymentType / Mode: $DeployMode"
    Write-LocalLog "Script root: $ScriptRoot"

    switch ($DeploymentType) {

        'Install' {
            Stop-AppProcess
            $ExitCode = Invoke-MsiAction -Action Install -LogPath $InstallLog

            if (-not (Test-AppInstalled)) {
                throw "$AppName installation completed but WinSCP.exe was not found in Program Files (x86)."
            }

            Write-LocalLog "$AppName installation successful."
            exit $ExitCode
        }

        'Uninstall' {
            Stop-AppProcess
            $ExitCode = Invoke-MsiAction -Action Uninstall -LogPath $UninstallLog

            Write-LocalLog "$AppName uninstall completed."
            exit $ExitCode
        }

        'Repair' {
            Stop-AppProcess
            $ExitCode = Invoke-MsiAction -Action Repair -LogPath $RepairLog

            if (-not (Test-AppInstalled)) {
                throw "$AppName repair completed but WinSCP.exe was not found in Program Files (x86)."
            }

            Write-LocalLog "$AppName repair successful."
            exit $ExitCode
        }
    }
}
catch {
    $ErrorMessage = $_.Exception.Message
    Write-LocalLog "ERROR: $ErrorMessage"
    throw
}
