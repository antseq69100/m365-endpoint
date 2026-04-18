# Greenshot - Intune Win32 + PSADT

## Objectif
Déployer Greenshot via Intune avec PSAppDeployToolkit en installation silencieuse, avec détection par clé registre custom.

## Version cible
1.3.315

## Méthode
- Package Win32 Intune
- Script PSADT
- Détection registre custom
- Installation en contexte System

## Fichiers
- `psadt/Invoke-AppDeployToolkit.ps1`
- `intune/detection-rule.md`
- `intune/install-command.txt`
- `intune/uninstall-command.txt`
- `notes/troubleshooting.md`

## Détection Intune
- Type : Registry
- Key path : `HKEY_LOCAL_MACHINE\SOFTWARE\ITLYON\Apps\Greenshot`
- Value name : `Version`
- Method : String comparison
- Operator : Equals
- Value : `1.3.315`

## Commande d'installation
`%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -NoProfile -File .\Invoke-AppDeployToolkit.ps1 -DeploymentType Install -DeployMode Silent`

## Commande de désinstallation
`%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -NoProfile -File .\Invoke-AppDeployToolkit.ps1 -DeploymentType Uninstall -DeployMode Silent`

## Points d'attention
- Ne pas pousser `Greenshot.ini` dans Program Files
- Utiliser éventuellement `greenshot-defaults.ini`
- Recréer le `.intunewin` à chaque modification du script
- Vérifier la clé registre après installation

## Vérifications post-déploiement
```powershell
reg query "HKLM\SOFTWARE\ITLYON\Apps\Greenshot" /v Version
