# =====================================================================
# Script Name  : Set-WindowsUserDarkMode.ps1
# Author       : Anthony Sequeira
# Version      : 1.0
# Date         : 2026-04-03
#
# Execution    : Microsoft Intune Platform Script
# Context      : USER (HKCU required)
#
# Description  :
# Configure le mode sombre Windows pour :
# - l’interface système
# - les applications compatibles
#
# Le script applique les paramètres dans le registre utilisateur
# actif (HKCU) puis redémarre Windows Explorer pour prise en compte
# immédiate sans nécessiter logout/login.
#
# Compatible :
# - Intune Platform Script (User context)
# - Remediation script (user phase)
# - Autopilot post-enrollment
#
# Registry Keys modified :
# HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize
#
# Values :
# SystemUsesLightTheme = 0
# AppsUseLightTheme    = 0
#
# Behaviour :
# Script idempotent → peut être relancé sans effet secondaire
#
# Exit Codes :
# 0 = Success
# 1 = Error
# =====================================================================



# =====================================================================
# VARIABLES
# =====================================================================

# Registry path contenant la configuration du thème utilisateur
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"



# =====================================================================
# ENSURE REGISTRY PATH EXISTS
# Création si absent (cas profils nouveaux utilisateurs / Autopilot)
# =====================================================================

if (!(Test-Path $registryPath)) {

    Write-Output "Registry path not found. Creating personalize key..."

    New-Item `
        -Path $registryPath `
        -Force | Out-Null
}



# =====================================================================
# APPLY DARK MODE FOR WINDOWS UI
#
# Value meanings :
# 1 = Light Mode
# 0 = Dark Mode
# =====================================================================

Write-Output "Applying Dark Mode to Windows system UI..."

Set-ItemProperty `
    -Path $registryPath `
    -Name "SystemUsesLightTheme" `
    -Value 0 `
    -Type DWord



# =====================================================================
# APPLY DARK MODE FOR APPLICATIONS
#
# Value meanings :
# 1 = Light Mode
# 0 = Dark Mode
# =====================================================================

Write-Output "Applying Dark Mode to applications..."

Set-ItemProperty `
    -Path $registryPath `
    -Name "AppsUseLightTheme" `
    -Value 0 `
    -Type DWord



# =====================================================================
# RESTART EXPLORER PROCESS
#
# Permet application immédiate du thème
# Sans restart explorer :
# changement visible uniquement après reconnexion utilisateur
#
# Safe behavior :
# restart uniquement si explorer.exe actif
# =====================================================================

Write-Output "Restarting Explorer process to apply theme immediately..."

$explorerProcess = Get-Process explorer -ErrorAction SilentlyContinue

if ($explorerProcess) {

    Stop-Process `
        -Name explorer `
        -Force
}



# =====================================================================
# SCRIPT COMPLETION
# =====================================================================

Write-Output "Dark Mode configuration applied successfully."

exit 0
