# =====================================================================
# Universal Win32 Install Script (EXE/MSI) - Intune / SYSTEM friendly
# Author  : Anthony Sequeira
# Version : 1.0.3
# Purpose : Install EXE or MSI applications through Microsoft Intune
# Log file: C:\Temp\Install-App.log
# =====================================================================


# =====================================================================
# HOW TO USE THIS SCRIPT WITH MICROSOFT INTUNE (WIN32 APP)
# =====================================================================

<#
STEP 1 — Folder structure before packaging

Example:

AppFolder
│
├── Install-App.ps1
└── Setup.exe   (or Setup.msi)


STEP 2 — Create IntuneWin package

Run:

IntuneWinAppUtil.exe -c AppFolder -s Install-App.ps1 -o OutputFolder


STEP 3 — Install command (Intune)

powershell.exe -ExecutionPolicy Bypass -File .\Install-App.ps1


STEP 4 — Uninstall command (example)

powershell.exe -ExecutionPolicy Bypass -File .\Uninstall-App.ps1


STEP 5 — Detection rule recommendation

Use ONE of these:

Option A (recommended)
Registry detection:
HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\<AppKey>

Option B
DisplayName equals:
Example:
Focusrite Control

Option C
File detection:
C:\Program Files\AppFolder\App.exe


STEP 6 — Common EXE silent install switches

NSIS installers:
    /S

Inno Setup:
    /VERYSILENT /SUPPRESSMSGBOXES /NORESTART

InstallShield:
    /s

MSI wrapper:
    /s /v"/qn"

Microsoft installers:
    /quiet /norestart


STEP 7 — Where logs are stored

C:\Temp\Install-App.log


STEP 8 — Version tracking

Always increment:

$ScriptVersion = "1.0.X"

Example:

1.0.0 = initial release
1.0.1 = logging improved
1.0.2 = Logitech G HUB hardening
1.0.3 = logging folder creation hardened
#>


# =====================================================================
# SCRIPT METADATA VARIABLES
# =====================================================================

$ScriptVersion = "1.0.3"
$ScriptAuthor  = "Anthony Sequeira"


# =====================================================================
# FORCE POWERSHELL 64-BIT IF SCRIPT STARTS IN 32-BIT CONTEXT
# =====================================================================

if ([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess)
{
    $ps64 = "$env:WINDIR\SysNative\WindowsPowerShell\v1.0\powershell.exe"

    $proc = Start-Process `
        -FilePath $ps64 `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" `
        -Wait `
        -PassThru

    exit $proc.ExitCode
}


# =====================================================================
# CONFIGURATION SECTION (EDIT THIS PER APPLICATION)
# =====================================================================

# Friendly application name (for logging only)
$appName = "Logitech G Hub"

# Installer filename inside the package
$installerFile = "lghub_installer.exe"

# Installer type:
# Supported values:
# EXE
# MSI
$installerType = "EXE"

# Silent install arguments
# Example values:
# /S
# /quiet
# /VERYSILENT /SUPPRESSMSGBOXES /NORESTART
$installArgs = "--silent"

# Optional DisplayName detection pattern
# Used only to skip install if already present
$expectedDisplayName = "*Logitech G HUB*"

# Logitech G HUB post-install validation path
$expectedFilePath = "C:\Program Files\LGHUB\lghub.exe"

# Logitech G HUB related processes to stop before install
$processNamesToStop = @(
    "lghub",
    "lghub_agent",
    "lghub_updater",
    "logi_crashpad_handler"
)


# =====================================================================
# LOGGING CONFIGURATION
# =====================================================================

$logFolder = "C:\Temp"
$logFile   = Join-Path $logFolder "Install-App.log"


# =====================================================================
# CREATE LOG FOLDER IF NEEDED
# =====================================================================

try
{
    if (!(Test-Path $logFolder))
    {
        New-Item -Path $logFolder -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }
}
catch
{
    Write-Output ("Failed to create log folder: " + $logFolder + " | " + $_.Exception.Message)
    exit 1
}


# =====================================================================
# ASCII LOG SANITIZER FUNCTION
# =====================================================================

function Convert-ToAsciiSafe
{
    param([string]$Text)

    if ([string]::IsNullOrEmpty($Text))
    {
        return $Text
    }

    $norm = $Text.Normalize([Text.NormalizationForm]::FormD)

    $sb = New-Object System.Text.StringBuilder

    foreach ($ch in $norm.ToCharArray())
    {
        $uc = [Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch)

        if ($uc -ne [Globalization.UnicodeCategory]::NonSpacingMark)
        {
            [void]$sb.Append($ch)
        }
    }

    $noAccents = $sb.ToString().Normalize([Text.NormalizationForm]::FormC)

    return ($noAccents -replace '[^\x20-\x7E]', '?')
}


# =====================================================================
# LOG FUNCTION
# =====================================================================

function Write-Log
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    try
    {
        $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        $safe = Convert-ToAsciiSafe $Message

        $line = "$time - $safe"

        $line | Out-File -FilePath $logFile -Append -Encoding ASCII -ErrorAction Stop
    }
    catch
    {
        Write-Output ("Log write failed: " + $_.Exception.Message)
    }
}


# =====================================================================
# DETECTION HELPER FUNCTION
# =====================================================================

function Test-AppInstalled
{
    param(
        [string]$NamePattern
    )

    $paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($path in $paths)
    {
        $apps = Get-ItemProperty $path -ErrorAction SilentlyContinue

        foreach ($app in $apps)
        {
            if ($app.DisplayName -and $app.DisplayName -like $NamePattern)
            {
                return $true
            }
        }
    }

    return $false
}


# =====================================================================
# FILE DETECTION HELPER FUNCTION
# =====================================================================

function Test-AppInstalledByFile
{
    param(
        [string]$FilePath
    )

    if ([string]::IsNullOrWhiteSpace($FilePath))
    {
        return $false
    }

    return (Test-Path $FilePath)
}


# =====================================================================
# PROCESS STOP HELPER FUNCTION
# =====================================================================

function Stop-AppProcesses
{
    param(
        [string[]]$ProcessNames
    )

    foreach ($processName in $ProcessNames)
    {
        try
        {
            $foundProcesses = Get-Process -Name $processName -ErrorAction SilentlyContinue

            if ($foundProcesses)
            {
                foreach ($proc in $foundProcesses)
                {
                    Write-Log ("Stopping process: " + $proc.ProcessName + " (PID: " + $proc.Id + ")")
                    Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
                }
            }
            else
            {
                Write-Log ("Process not running: " + $processName)
            }
        }
        catch
        {
            Write-Log ("Error while stopping process " + $processName + ": " + $_.Exception.Message)
        }
    }
}


# =====================================================================
# DEBUG / TROUBLESHOOTING INFORMATION
# =====================================================================

Write-Log "====================================================="
Write-Log "Script start"
Write-Log ("Script version: " + $ScriptVersion)
Write-Log ("Script author: " + $ScriptAuthor)
Write-Log ("Application name: " + $appName)
Write-Log ("Installer file: " + $installerFile)
Write-Log ("Installer type: " + $installerType)
Write-Log ("Install arguments: " + $installArgs)
Write-Log ("Expected DisplayName: " + $expectedDisplayName)
Write-Log ("Expected file path: " + $expectedFilePath)
Write-Log ("PowerShell version: " + $PSVersionTable.PSVersion.ToString())
Write-Log ("64-bit process: " + [Environment]::Is64BitProcess)
Write-Log ("64-bit OS: " + [Environment]::Is64BitOperatingSystem)


try
{
    $wid = [System.Security.Principal.WindowsIdentity]::GetCurrent()

    Write-Log ("User SID: " + $wid.User.Value)
    Write-Log ("Env USERNAME: " + $env:USERNAME)
    Write-Log ("Env USERDOMAIN: " + $env:USERDOMAIN)
}
catch
{
    Write-Log ("User context detection error: " + $_.Exception.Message)
}


# =====================================================================
# RESOLVE INSTALLER PATH
# =====================================================================

$scriptRoot = Split-Path -Parent $PSCommandPath

$installerPath = Join-Path $scriptRoot $installerFile

Write-Log ("Resolved installer path: " + $installerPath)


if (!(Test-Path $installerPath))
{
    Write-Log ("Installer not found: " + $installerPath)

    exit 1
}


# =====================================================================
# OPTIONAL PRE-INSTALL CHECK
# =====================================================================

if ($expectedFilePath -and (Test-AppInstalledByFile -FilePath $expectedFilePath))
{
    Write-Log ("Application already installed (file detection successful)")

    exit 0
}

if ($expectedDisplayName -and (Test-AppInstalled -NamePattern $expectedDisplayName))
{
    Write-Log ("Application appears installed by DisplayName, but file not found - continuing install for repair/recovery")
}


# =====================================================================
# PRE-INSTALL PROCESS CLEANUP
# =====================================================================

Write-Log "Starting pre-install process cleanup"

Stop-AppProcesses -ProcessNames $processNamesToStop

Start-Sleep -Seconds 3


# =====================================================================
# INSTALL EXECUTION
# =====================================================================

try
{
    if ($installerType -eq "MSI")
    {
        Write-Log "Installer type detected: MSI"

        $arguments = "/i `"$installerPath`" /qn /norestart"

        $process = Start-Process `
            -FilePath "msiexec.exe" `
            -ArgumentList $arguments `
            -Wait `
            -PassThru `
            -NoNewWindow
    }

    elseif ($installerType -eq "EXE")
    {
        Write-Log "Installer type detected: EXE"
        Write-Log ("Running EXE: " + $installerPath)
        Write-Log ("With arguments: " + $installArgs)

        if ([string]::IsNullOrWhiteSpace($installArgs))
        {
            $process = Start-Process `
                -FilePath $installerPath `
                -Wait `
                -PassThru `
                -NoNewWindow
        }
        else
        {
            $process = Start-Process `
                -FilePath $installerPath `
                -ArgumentList $installArgs `
                -Wait `
                -PassThru `
                -NoNewWindow
        }
    }

    else
    {
        Write-Log "Unsupported installer type"

        exit 1
    }


    Write-Log ("Installer exit code: " + $process.ExitCode)


    if ($process.ExitCode -in @(0,1641,3010))
    {
        Write-Log "Installer returned a success code"
    }

    else
    {
        Write-Log "Installation failed"

        exit $process.ExitCode
    }
}

catch
{
    Write-Log ("Installation error: " + $_.Exception.Message)

    exit 1
}


# =====================================================================
# POST-INSTALL VALIDATION
# =====================================================================

Start-Sleep -Seconds 10

if ($expectedFilePath -and (Test-AppInstalledByFile -FilePath $expectedFilePath))
{
    Write-Log "Post-install validation successful"
    Write-Log "Installation successful"

    exit $process.ExitCode
}
else
{
    Write-Log ("Post-install validation failed: file not found at " + $expectedFilePath)

    exit 1
}


Write-Log "Script end"
