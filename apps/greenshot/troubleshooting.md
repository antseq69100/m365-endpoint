# Troubleshooting - Greenshot

## Symptômes rencontrés
- Erreur au démarrage liée à `Greenshot.ini`
- Ancienne version non remplacée proprement
- Présence de plusieurs fichiers de désinstallation (`unins000.exe`, `unins001.exe`)
- Dossier d'installation mélangé entre ancienne et nouvelle version
- Intune ne remonte pas immédiatement le bon état

## Causes probables
- Upgrade direct par-dessus une ancienne version
- Application encore en cours d'exécution pendant la mise à jour
- Reliquats dans `Program Files`
- Détection trop large ou non fiable
- Chevauchement entre ancien package et nouveau package

## Solution retenue
- Passage à un package PSADT
- Désinstallation de l'ancienne version avant réinstallation
- Nettoyage des dossiers restants
- Installation silencieuse de la nouvelle version
- Détection Intune via clé registre custom

## Vérifications après installation

### Vérifier la clé registre

```powershell
reg query "HKLM\SOFTWARE\ITLYON\Apps\Greenshot" /v Version
```

### Vérifier la version du binaire

```powershell
([System.Diagnostics.FileVersionInfo]::GetVersionInfo("C:\Program Files\Greenshot\Greenshot.exe")).FileVersion
```

### Vérifier les logs Intune

```text
C:\ProgramData\Microsoft\IntuneManagementExtension\Logs
```

### Vérifier les logs PSADT

```text
C:\Windows\Logs\Software
```

## Points d'attention
- Ne pas pousser `Greenshot.ini` dans `Program Files`
- Utiliser éventuellement `greenshot-defaults.ini`
- Recréer le `.intunewin` à chaque modification du script
- Tester d'abord sur une machine pilote
