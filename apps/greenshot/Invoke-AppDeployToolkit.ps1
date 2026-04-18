<#
===============================================================================
PSADT - Application deployment
Author : Anthony

Purpose :
- Remove previous Greenshot portable deployment
- Copy Greenshot portable files into the current user profile
- Validate installed version
- Create a registry marker for Intune detection
- Create startup entry and Start Menu shortcut
- Stay fully silent (no EXE installer, no browser)

Important notes :
- This version uses PSADT structure but deploys the PORTABLE ZIP content
- Install context must be USER in Intune
- Detection must use HKCU
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
# ENVIRONMENT / APPLICATION VARIABLES
# =====================================================================

$CompanyName   = 'YOURCOMPANY'
$AppName       = 'Greenshot'
$TargetVersion = '1.3.315'

# Portable source folder inside the package
$PortableSourceFolder = Join-Path $ScriptRoot 'Files\Greenshot'

# Optional defaults file
$DefaultsFile = Join-Path $ScriptRoot 'Files\greenshot-defaults.ini'

# Target install folder in current user profile
$InstallFolder = Join-Path $env:LocalAppData "Programs\$AppName"
$InstalledExe  = Join-Path $InstallFolder "$AppName.exe"

# Clean application name for registry usage
$AppRegName = $AppName -replace '[\\/:*?"<>| ]', ''

# Custom registry key used by Intune detection
$MarkerKey  = "HKCU:\SOFTWARE\$CompanyName\Apps\$AppRegName"
$MarkerName = 'Version'

# Run at logon key
$RunKey      = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$RunValue    = $AppName

# Start Menu shortcut
$StartMenuPrograms = Join-Path $env:AppData 'Microsoft\Windows\Start Menu\Programs'
$ShortcutPath      = Join-Path $StartMenuPrograms "$AppName.lnk"

# =====================================================================
# FUNCTIONS
# =====================================================================

function Stop-AppProcess {
    Get-Process -Name $AppName -ErrorAction SilentlyContinue |
        Stop-Process -Force -ErrorAction SilentlyContinue

    Start-Sleep -Seconds 2
}

function Convert-VersionForDetection {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version
    )

    $Match = [regex]::Match($Version, '\d+(\.\d+)+')
    if (-not $Match.Success) {
        return $Version
    }

    $Parts = $Match.Value.Split('.')
    if ($Parts.Count -ge 3) {
        return ($Parts[0..2] -join '.')
    }

    return $Match.Value
}

function Get-AppInstalledVersion {
    if (-not (Test-Path $InstalledExe)) {
        return $null
    }

    $RawVersion = ([System.Diagnostics.FileVersionInfo]::GetVersionInfo($InstalledExe)).FileVersion
    if (-not $RawVersion) {
        return $null
    }

    return (Convert-VersionForDetection -Version $RawVersion)
}

function Remove-AppFolder {
    if (Test-Path $InstallFolder) {
        Remove-Item -Path $InstallFolder -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Set-AppMarker {
    param(
        [Parameter(Mandatory = $true)]
        [string]$InstalledVersion
    )

    if (-not (Test-Path $MarkerKey)) {
        New-Item -Path $MarkerKey -Force | Out-Null
    }

    New-ItemProperty `
        -Path $MarkerKey `
        -Name $MarkerName `
        -Value $InstalledVersion `
        -PropertyType String `
        -Force | Out-Null
}

function Remove-AppMarker {
    if (Test-Path $MarkerKey) {
        Remove-Item -Path $MarkerKey -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Set-RunAtLogon {
    if (-not (Test-Path $RunKey)) {
        New-Item -Path $RunKey -Force | Out-Null
    }

    New-ItemProperty `
        -Path $RunKey `
        -Name $RunValue `
        -Value ('"{0}"' -f $InstalledExe) `
        -PropertyType String `
        -Force | Out-Null
}

function Remove-RunAtLogon {
    if (Test-Path $RunKey) {
        Remove-ItemProperty -Path $RunKey -Name $RunValue -ErrorAction SilentlyContinue
    }
}

function New-AppShortcut {
    if (-not (Test-Path $InstalledExe)) {
        return
    }

    if (-not (Test-Path $StartMenuPrograms)) {
        New-Item -Path $StartMenuPrograms -ItemType Directory -Force | Out-Null
    }

    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $InstalledExe
    $Shortcut.WorkingDirectory = $InstallFolder
    $Shortcut.IconLocation = "$InstalledExe,0"
    $Shortcut.Save()
}

function Remove-AppShortcut {
    if (Test-Path $ShortcutPath) {
        Remove-Item -Path $ShortcutPath -Force -ErrorAction SilentlyContinue
    }
}

function Install-AppDefaults {
    if (-not (Test-Path $DefaultsFile)) {
        return
    }

    if (-not (Test-Path $InstallFolder)) {
        return
    }

    Copy-Item `
        -Path $DefaultsFile `
        -Destination (Join-Path $InstallFolder 'greenshot-defaults.ini') `
        -Force
}

function Install-PortableApp {
    if (-not (Test-Path $PortableSourceFolder)) {
        throw "Portable source folder not found: $PortableSourceFolder"
    }

    if (-not (Test-Path (Join-Path $PortableSourceFolder "$AppName.exe"))) {
        throw "$AppName.exe not found in portable source folder: $PortableSourceFolder"
    }

    Stop-AppProcess
    Remove-AppFolder
    Remove-AppMarker
    Remove-RunAtLogon
    Remove-AppShortcut

    New-Item -Path $InstallFolder -ItemType Directory -Force | Out-Null

    Copy-Item `
        -Path (Join-Path $PortableSourceFolder '*') `
        -Destination $InstallFolder `
        -Recurse `
        -Force

    Start-Sleep -Seconds 2

    if (-not (Test-Path $InstalledExe)) {
        throw "$AppName.exe was not copied to $InstalledExe"
    }

    Install-AppDefaults

    $InstalledVersion = Get-AppInstalledVersion
    if (-not $InstalledVersion) {
        throw "Unable to read installed version of $AppName."
    }

    if ($InstalledVersion -ne $TargetVersion) {
        throw "Incorrect version detected. Expected: $TargetVersion / Installed: $InstalledVersion"
    }

    Set-RunAtLogon
    New-AppShortcut
    Set-AppMarker -InstalledVersion $InstalledVersion
}

# =====================================================================
# MAIN LOGIC
# =====================================================================

switch ($DeploymentType) {

    'Install' {
        Install-PortableApp
    }

    'Uninstall' {
        Stop-AppProcess
        Remove-AppFolder
        Remove-RunAtLogon
        Remove-AppShortcut
        Remove-AppMarker
    }

    'Repair' {
        Stop-AppProcess
        Remove-AppFolder
        Remove-RunAtLogon
        Remove-AppShortcut
        Remove-AppMarker

        Install-PortableApp
    }
}
