# =====================================================================
# Universal Win32 Uninstall Script (EXE + MSI) - Intune/SYSTEM friendly
# Fix: NO weird characters in logs (ASCII-only output + sanitize)
# Log file: C:\Temp\Uninstall-App.log
# =====================================================================

# ---------------------------------------------------------------------
# FORCE POWERSHELL 64-BIT IF LAUNCHED IN 32-BIT (common with Intune IME)
# ---------------------------------------------------------------------
if ([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess) {
    $ps64 = "$env:WINDIR\SysNative\WindowsPowerShell\v1.0\powershell.exe"
    Start-Process -FilePath $ps64 `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" `
        -Wait
    exit
}

# =====================================================================
# CONFIG
# =====================================================================

# Software name pattern (wildcards allowed): *Focusrite*, *GoXLR*, etc.
$software = "*Focusrite*"

# Log path
$logFolder = "C:\Temp"
$logFile   = Join-Path $logFolder "Uninstall-App.log"

# =====================================================================
# CREATE LOG FOLDER IF NEEDED
# =====================================================================
if (!(Test-Path $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
}

# =====================================================================
# ASCII SANITIZER (remove accents + replace non-ASCII)
# =====================================================================
function Convert-ToAsciiSafe {
    param([string]$Text)

    if ([string]::IsNullOrEmpty($Text)) { return $Text }

    # Remove diacritics (accents)
    $norm = $Text.Normalize([Text.NormalizationForm]::FormD)
    $sb = New-Object System.Text.StringBuilder
    foreach ($ch in $norm.ToCharArray()) {
        $uc = [Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch)
        if ($uc -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$sb.Append($ch)
        }
    }
    $noAccents = $sb.ToString().Normalize([Text.NormalizationForm]::FormC)

    # Keep only ASCII printable chars
    return ($noAccents -replace '[^\x20-\x7E]', '?')
}

# =====================================================================
# LOG FUNCTION (FORCE ASCII LOG OUTPUT)
# =====================================================================
function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $safe = Convert-ToAsciiSafe $Message
    $line = "$time - $safe"

    # ASCII is readable everywhere (Intune/IME/cmd/notepad/etc.)
    $line | Out-File -FilePath $logFile -Append -Encoding ASCII
}

# =====================================================================
# DEBUG INFO (useful in Intune)
# =====================================================================
Write-Log "=== SCRIPT VERSION: 2026-02-28-FOCUSRITE-V5-ASCII-SAFE ==="
Write-Log ("PS Version: " + $PSVersionTable.PSVersion)
Write-Log ("64-bit Process: " + [Environment]::Is64BitProcess)
Write-Log ("64-bit OS: " + [Environment]::Is64BitOperatingSystem)

# Avoid logging localized names like 'autorite nt\systeme' with accents
try {
    $wid = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    Write-Log ("UserSID: " + $wid.User.Value)       # e.g. S-1-5-18
    Write-Log ("EnvUser: " + $env:USERNAME)         # e.g. SYSTEM
    Write-Log ("EnvDomain: " + $env:USERDOMAIN)     # e.g. NT AUTHORITY
} catch {
    Write-Log ("User info error: " + $_.Exception.Message)
}

Write-Log ("Host: " + $host.Name)
Write-Log "==== Uninstall start ===="

# =====================================================================
# REGISTRY PATHS TO SCAN
# =====================================================================
$paths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

# =====================================================================
# OPTIONAL APP DUMP (DEBUG)
# =====================================================================
try {
    $dump = @()
    foreach ($path in $paths) {
        Get-ItemProperty $path -ErrorAction SilentlyContinue | ForEach-Object {
            if ($_.DisplayName) { $dump += $_.DisplayName }
        }
    }
    $first50 = ($dump | Select-Object -First 50) -join " | "
    Write-Log ("Apps detected (first 50): " + $first50)
} catch {
    Write-Log ("Error dumping DisplayName: " + $_.Exception.Message)
}

# =====================================================================
# MAIN UNINSTALL LOGIC
# =====================================================================
$found = $false

foreach ($path in $paths) {

    Get-ItemProperty $path -ErrorAction SilentlyContinue | ForEach-Object {

        if ($_.DisplayName -and $_.DisplayName -like $software) {

            $found = $true
            Write-Log ("Found: " + $_.DisplayName)

            try {
                $uninstallString = $_.QuietUninstallString
                if (-not $uninstallString) { $uninstallString = $_.UninstallString }

                if (-not $uninstallString) {
                    Write-Log "No uninstall command found"
                    return
                }

                Write-Log ("Raw command: " + $uninstallString)

                # -----------------------------------------------------
                # MSI CASE
                # -----------------------------------------------------
                if ($uninstallString -match "(?i)msiexec") {

                    Write-Log "Detected type: MSI"

                    # Try to convert /I to /X (uninstall)
                    $fixed = $uninstallString -replace "(?i)\s/I\s", " /X "
                    $fixed = $fixed -replace "(?i)\s/I", " /X"

                    # Ensure silent flags
                    $cmd = "$fixed /qn /norestart"
                    Write-Log ("Run: " + $cmd)

                    Start-Process "cmd.exe" -ArgumentList "/c $cmd" -Wait -NoNewWindow
                }
                else {
                    # -----------------------------------------------------
                    # EXE CASE
                    # -----------------------------------------------------
                    Write-Log "Detected type: EXE"

                    if ($_.QuietUninstallString) {
                        Write-Log ("Run quiet: " + $uninstallString)
                        Start-Process "cmd.exe" -ArgumentList "/c $uninstallString" -Wait -NoNewWindow
                    }
                    else {
                        $cmd = "$uninstallString /SILENT /VERYSILENT /SUPPRESSMSGBOXES /NORESTART"
                        Write-Log ("Run generic silent: " + $cmd)
                        Start-Process "cmd.exe" -ArgumentList "/c $cmd" -Wait -NoNewWindow
                    }
                }

                Write-Log "Uninstall finished"
            }
            catch {
                Write-Log ("Uninstall error: " + $_.Exception.Message)
            }
        }
    }
}

# =====================================================================
# NOT FOUND
# =====================================================================
if (-not $found) {
    Write-Log ("No app found matching: " + $software)
}

Write-Log "==== Script end ===="