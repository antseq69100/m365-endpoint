# =====================================================================
# Script Name  : Universal Win32 Uninstall Script (EXE + MSI)
# Author       : Anthony Sequeira
# Version      : 1.0
# Date         : 2026-02-28
#
# Usage        : Microsoft Intune / SYSTEM context / Win32 remediation
#
# Description  :
# Ce script permet de désinstaller automatiquement une application
# détectée dans le registre Windows (32-bit et 64-bit) à partir d’un
# pattern de nom (wildcard supporté).
#
# Compatible :
# - MSI uninstall
# - EXE uninstall (QuietUninstallString prioritaire)
# - Fallback silent switches génériques si nécessaire
#
# Sécurité / Compatibilité :
# - Force l’exécution en PowerShell 64-bit si lancé en 32-bit
# - Log ASCII compatible Intune IME
# - Fonctionne en contexte SYSTEM
# - Supporte environnements multilingues
#
# Log file :
# C:\Temp\Uninstall-App.log
#
# Exemple :
# $software = "*Focusrite*"
#
# Cas d’usage typiques :
# - Intune Remediation scripts
# - Win32 uninstall helper
# - Remédiation logicielle automatique
# =====================================================================



# ---------------------------------------------------------------------
# FORCE EXECUTION POWERSHELL 64-BIT
# (Intune IME exécute souvent en 32-bit par défaut)
# ---------------------------------------------------------------------
if ([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess) {

    # Relance automatiquement le script dans PowerShell 64-bit
    $ps64 = "$env:WINDIR\SysNative\WindowsPowerShell\v1.0\powershell.exe"

    Start-Process -FilePath $ps64 `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" `
        -Wait

    exit
}



# =====================================================================
# CONFIGURATION SECTION
# =====================================================================

# Pattern logiciel recherché (wildcards autorisés)
# Exemple : "*Focusrite*", "*GoXLR*", "*Zoom*"
$software = "*Focusrite*"


# Chemin dossier log
$logFolder = "C:\Temp"

# Chemin fichier log final
$logFile   = Join-Path $logFolder "Uninstall-App.log"



# =====================================================================
# CREATE LOG DIRECTORY IF MISSING
# =====================================================================

# Création du dossier si absent
if (!(Test-Path $logFolder)) {

    New-Item `
        -Path $logFolder `
        -ItemType Directory `
        -Force | Out-Null
}



# =====================================================================
# ASCII SANITIZER FUNCTION
#
# Objectif :
# Nettoyer accents et caractères Unicode problématiques pour garantir
# compatibilité lecture logs Intune / Notepad / CMD / pipelines SIEM
# =====================================================================

function Convert-ToAsciiSafe {

    param([string]$Text)

    if ([string]::IsNullOrEmpty($Text)) {
        return $Text
    }

    # Normalisation Unicode
    $norm = $Text.Normalize([Text.NormalizationForm]::FormD)

    $sb = New-Object System.Text.StringBuilder

    foreach ($ch in $norm.ToCharArray()) {

        $uc = [Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch)

        if ($uc -ne [Globalization.UnicodeCategory]::NonSpacingMark) {

            [void]$sb.Append($ch)

        }
    }

    # Reconstruction string sans accents
    $noAccents = $sb.ToString().Normalize([Text.NormalizationForm]::FormC)

    # Filtrage ASCII uniquement
    return ($noAccents -replace '[^\x20-\x7E]', '?')
}



# =====================================================================
# LOGGING FUNCTION
#
# Garantit :
# - timestamp précis
# - ASCII safe
# - compatible Intune IME parsing
# =====================================================================

function Write-Log {

    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    $safe = Convert-ToAsciiSafe $Message

    $line = "$time - $safe"

    $line | Out-File `
        -FilePath $logFile `
        -Append `
        -Encoding ASCII
}



# =====================================================================
# DEBUG ENVIRONMENT INFORMATION
#
# Très utile en troubleshooting Intune / SYSTEM context
# =====================================================================

Write-Log "=== SCRIPT VERSION: 2026-02-28-FOCUSRITE-V5-ASCII-SAFE ==="

Write-Log ("PS Version: " + $PSVersionTable.PSVersion)

Write-Log ("64-bit Process: " + [Environment]::Is64BitProcess)

Write-Log ("64-bit OS: " + [Environment]::Is64BitOperatingSystem)



# Identification du contexte sécurité courant
try {

    $wid = [System.Security.Principal.WindowsIdentity]::GetCurrent()

    Write-Log ("UserSID: " + $wid.User.Value)

    Write-Log ("EnvUser: " + $env:USERNAME)

    Write-Log ("EnvDomain: " + $env:USERDOMAIN)

}
catch {

    Write-Log ("User info error: " + $_.Exception.Message)

}



Write-Log ("Host: " + $host.Name)

Write-Log "==== Uninstall start ===="



# =====================================================================
# REGISTRY PATHS SCAN LIST
#
# Scan :
# - applications 64-bit
# - applications 32-bit (WOW6432Node)
# =====================================================================

$paths = @(

    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",

    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"

)



# =====================================================================
# OPTIONAL SOFTWARE INVENTORY SNAPSHOT
#
# Dump partiel utile pour debug détection Intune
# =====================================================================

try {

    $dump = @()

    foreach ($path in $paths) {

        Get-ItemProperty $path -ErrorAction SilentlyContinue |

        ForEach-Object {

            if ($_.DisplayName) {

                $dump += $_.DisplayName

            }
        }
    }

    $first50 = ($dump | Select-Object -First 50) -join " | "

    Write-Log ("Apps detected (first 50): " + $first50)

}
catch {

    Write-Log ("Error dumping DisplayName: " + $_.Exception.Message)

}



# =====================================================================
# MAIN UNINSTALL ENGINE
# =====================================================================

$found = $false



foreach ($path in $paths) {

    Get-ItemProperty $path -ErrorAction SilentlyContinue |

    ForEach-Object {

        if ($_.DisplayName -and $_.DisplayName -like $software) {

            $found = $true

            Write-Log ("Found: " + $_.DisplayName)



            try {

                # Priorité QuietUninstallString si disponible
                $uninstallString = $_.QuietUninstallString

                if (-not $uninstallString) {

                    $uninstallString = $_.UninstallString

                }



                if (-not $uninstallString) {

                    Write-Log "No uninstall command found"

                    return
                }



                Write-Log ("Raw command: " + $uninstallString)



                # =====================================================
                # MSI UNINSTALL HANDLER
                # =====================================================

                if ($uninstallString -match "(?i)msiexec") {

                    Write-Log "Detected type: MSI"



                    # Conversion install -> uninstall si nécessaire
                    $fixed = $uninstallString -replace "(?i)\s/I\s", " /X "

                    $fixed = $fixed -replace "(?i)\s/I", " /X"



                    $cmd = "$fixed /qn /norestart"



                    Write-Log ("Run: " + $cmd)



                    Start-Process "cmd.exe" `
                        -ArgumentList "/c $cmd" `
                        -Wait `
                        -NoNewWindow
                }

                else {

                    # =====================================================
                    # EXE UNINSTALL HANDLER
                    # =====================================================

                    Write-Log "Detected type: EXE"



                    if ($_.QuietUninstallString) {

                        Write-Log ("Run quiet: " + $uninstallString)



                        Start-Process "cmd.exe" `
                            -ArgumentList "/c $uninstallString" `
                            -Wait `
                            -NoNewWindow
                    }

                    else {

                        # fallback switches silencieux génériques
                        $cmd = "$uninstallString /SILENT /VERYSILENT /SUPPRESSMSGBOXES /NORESTART"



                        Write-Log ("Run generic silent: " + $cmd)



                        Start-Process "cmd.exe" `
                            -ArgumentList "/c $cmd" `
                            -Wait `
                            -NoNewWindow
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
# SOFTWARE NOT FOUND HANDLER
# =====================================================================

if (-not $found) {

    Write-Log ("No app found matching: " + $software)

}



Write-Log "==== Script end ===="
