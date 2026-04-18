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

## Incident rencontré avec PSADT
Lors du test manuel du package, le script échouait au chargement du module PSADT avec une erreur liée à :

```text
PSADT.ClientServer.Server.dll
0x80131515
```

### Cause
Les fichiers PSADT extraits depuis une archive téléchargée étaient bloqués par Windows (Mark of the Web).

### Correctif
Débloquer tous les fichiers du dossier avant de packager :

```powershell
Get-ChildItem "C:\Packages\Greenshot" -Recurse | Unblock-File
```

### Conséquence
Après déblocage, il faut :
1. retester le script localement
2. recréer le fichier `.intunewin`
3. réuploader l'application dans Intune
