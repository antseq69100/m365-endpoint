# ==========================================================
# Script Name : PS - Set Dark Mode Default
# Purpose     : Configure le mode sombre (Dark Mode)
#               pour Windows et les applications utilisateur.
#
# Platform    : Windows
# Execution   : Intune Platform Script
#
# Author      : Anthony Sequeira
# ==========================================================


# ----------------------------------------------------------
# Chemin du registre contenant les paramètres du thème
# HKCU = configuration spécifique à l'utilisateur connecté
# ----------------------------------------------------------
$path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"


# ----------------------------------------------------------
# Vérifie si la clé registre existe
# Si elle n'existe pas, elle est créée automatiquement
# ----------------------------------------------------------
If (!(Test-Path $path)) {

    Write-Output "Registry path not found. Creating key..."

    New-Item -Path $path -Force | Out-Null
}


# ----------------------------------------------------------
# Active le mode sombre pour l'interface Windows
#
# Valeurs possibles :
# 1 = Light Mode
# 0 = Dark Mode
# ----------------------------------------------------------
Write-Output "Applying dark mode for Windows UI..."

Set-ItemProperty -Path $path -Name "SystemUsesLightTheme" -Value 0 -Type DWord


# ----------------------------------------------------------
# Active le mode sombre pour les applications
#
# Valeurs possibles :
# 1 = Light Mode
# 0 = Dark Mode
# ----------------------------------------------------------
Write-Output "Applying dark mode for applications..."

Set-ItemProperty -Path $path -Name "AppsUseLightTheme" -Value 0 -Type DWord


# ----------------------------------------------------------
# Redémarre Explorer pour appliquer immédiatement le thème
# Sans cette étape, le changement peut nécessiter une
# déconnexion / reconnexion utilisateur.
# ----------------------------------------------------------
Write-Output "Restarting Windows Explorer to apply theme..."

Stop-Process -Name explorer -Force


# ----------------------------------------------------------
# Fin du script
# exit 0 indique que l'exécution s'est terminée correctement
# ----------------------------------------------------------
Write-Output "Dark mode configuration applied successfully."

exit 0