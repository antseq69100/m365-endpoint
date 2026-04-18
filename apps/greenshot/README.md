# Greenshot - Intune Win32 + PSADT

## Objectif
Déployer Greenshot via Intune en package Win32 avec PSAppDeployToolkit, avec une installation silencieuse, une désinstallation propre et une détection fiable.

## Version cible
`1.3.315`

## Méthode retenue
- Package Win32 Intune
- Script PSADT
- Installation en contexte **System**
- Détection via **clé registre custom**
- Test d'abord sur machine pilote

## Détection Intune
- **Type** : Registry
- **Key path** : `HKEY_LOCAL_MACHINE\SOFTWARE\ITLYON\Apps\Greenshot`
- **Value name** : `Version`
- **Detection method** : String comparison
- **Operator** : Equals
- **Value** : `1.3.315`

## Commandes Intune

### Installation
Voir : [`install-command.txt`](./install-command.txt)

### Désinstallation
Voir : [`uninstall-command.txt`](./uninstall-command.txt)

## Fichiers de documentation
- [`detection-rule.md`](./detection-rule.md)
- [`troubleshooting.md`](./troubleshooting.md)

## Points d'attention
- Ne pas pousser `Greenshot.ini` dans `Program Files`
- Utiliser éventuellement `greenshot-defaults.ini`
- Recréer le `.intunewin` à chaque modification du script
- Vérifier la clé registre après installation

## Vérification post-déploiement

### Vérifier la clé registre

```powershell
reg query "HKLM\SOFTWARE\ITLYON\Apps\Greenshot" /v Version
```

### Vérifier la version du binaire

```powershell
([System.Diagnostics.FileVersionInfo]::GetVersionInfo("C:\Program Files\Greenshot\Greenshot.exe")).FileVersion
```

## Retour d'expérience
Un ancien mode de mise à jour par-dessus l'existant provoquait :
- des reliquats dans le dossier d'installation
- des désinstalleurs multiples
- des erreurs liées à `Greenshot.ini`

Le passage à PSADT a été retenu pour mieux contrôler :
- la désinstallation
- le nettoyage
- la réinstallation
- la détection Intune
