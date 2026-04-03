############################################################
# Script : Liste des utilisateurs membres d’un groupe AD
# filtrés par appartenance à une OU spécifiquehttps://github.com/antseq69100/m365-endpoint/tree/main/scripts
#
# Auteur  : Anthony Sequeira
# Usage   : Audit sécurité / contrôle accès / nettoyage groupes
# Version : 1.4
#
# Description :
# Ce script permet d’identifier quels utilisateurs d’un groupe
# Active Directory appartiennent à une OU spécifique.
#
# Fonctionnalités :
# - Saisie interactive du groupe AD
# - Saisie interactive de l’OU
# - Choix interactif du mode d’affichage console
# - Choix interactif du mode d’export fichier
# - Création automatique du dossier d’export si inexistant
# - Contrôle des saisies utilisateur
# - Gestion d’erreurs propre
#
# Pré-requis :
# - Module ActiveDirectory installé (RSAT ou serveur AD)
# - Droits lecture Active Directory
############################################################


############################################################
# Chargement du module Active Directory
############################################################

if (-not (Get-Module -ListAvailable -Name ActiveDirectory))
{
    Write-Host ""
    Write-Host "Le module ActiveDirectory n'est pas installé sur cette machine." -ForegroundColor Red
    Write-Host "Installe RSAT ou exécute ce script depuis un serveur AD." -ForegroundColor Yellow
    Write-Host ""
    Pause
    return
}

Import-Module ActiveDirectory


############################################################
# FONCTIONS
############################################################

function Show-Section
{
    param (
        [string]$Title
    )

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor DarkCyan
    Write-Host ("   {0}" -f $Title) -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor DarkCyan
    Write-Host ""
}

function Read-NonEmptyInput
{
    param (
        [string]$PromptMessage
    )

    do
    {
        $Value = Read-Host $PromptMessage

        if ([string]::IsNullOrWhiteSpace($Value))
        {
            Write-Host "Valeur invalide. Merci de renseigner une valeur non vide." -ForegroundColor Red
        }

    } while ([string]::IsNullOrWhiteSpace($Value))

    return $Value
}

function Read-Choice
{
    param (
        [string]$PromptMessage,
        [string[]]$AllowedValues
    )

    do
    {
        $Value = Read-Host $PromptMessage

        if ($AllowedValues -notcontains $Value)
        {
            Write-Host ("Choix invalide. Valeurs autorisées : {0}" -f ($AllowedValues -join ", ")) -ForegroundColor Red
        }

    } while ($AllowedValues -notcontains $Value)

    return $Value
}

function Write-UserFull
{
    param (
        [object]$User
    )

    $EnabledColor = if ($User.Enabled) { "Green" } else { "Red" }

    Write-Host ("Name              : {0}" -f $User.Name) -ForegroundColor White
    Write-Host ("SamAccountName    : {0}" -f $User.SamAccountName) -ForegroundColor Gray
    Write-Host -NoNewline "Enabled           : "
    Write-Host $User.Enabled -ForegroundColor $EnabledColor
    Write-Host ("DistinguishedName : {0}" -f $User.DistinguishedName) -ForegroundColor DarkGray
    Write-Host ""
}

function Write-UserShort
{
    param (
        [object]$User
    )

    $EnabledColor = if ($User.Enabled) { "Green" } else { "Red" }

    Write-Host ("Name    : {0}" -f $User.Name) -ForegroundColor White
    Write-Host -NoNewline "Enabled : "
    Write-Host $User.Enabled -ForegroundColor $EnabledColor
    Write-Host ""
}

function Build-ExportContent
{
    param (
        [object[]]$Users,
        [string]$Mode
    )

    $Content = foreach ($User in $Users)
    {
        switch ($Mode)
        {
            "1"
            {
@"
Name              : $($User.Name)
SamAccountName    : $($User.SamAccountName)
Enabled           : $($User.Enabled)
DistinguishedName : $($User.DistinguishedName)

"@
            }

            "2"
            {
@"
Name    : $($User.Name)
Enabled : $($User.Enabled)

"@
            }
        }
    }

    return $Content
}


############################################################
# INTRODUCTION
############################################################

Show-Section -Title "Audit des utilisateurs d'un groupe AD par OU"

Write-Host "Bienvenue dans le script d'audit Active Directory." -ForegroundColor White
Write-Host "Ce script permet de rechercher les utilisateurs membres d'un groupe" -ForegroundColor White
Write-Host "et présents dans une OU précise." -ForegroundColor White
Write-Host ""
Write-Host "Conseil :" -ForegroundColor Yellow
Write-Host "- Le DN d'OU doit être saisi au format complet" -ForegroundColor Gray
Write-Host '  Exemple : OU=Utilisateurs,OU=Paris,DC=entreprise,DC=local' -ForegroundColor DarkGray
Write-Host ""
Write-Host "- Les sous-OU de cette OU seront incluses automatiquement" -ForegroundColor Gray
Write-Host ""


############################################################
# SAISIE INTERACTIVE
############################################################

Show-Section -Title "Saisie des paramètres"

$GroupName = Read-NonEmptyInput -PromptMessage "Nom du groupe AD à analyser"
$SearchOU  = Read-NonEmptyInput -PromptMessage "DN complet de l'OU à filtrer"

Write-Host ""
Write-Host "Choix du mode d'affichage console :" -ForegroundColor Yellow
Write-Host "1 - Full  : Name / SamAccountName / Enabled / DistinguishedName" -ForegroundColor Gray
Write-Host "2 - Short : Name / Enabled" -ForegroundColor Gray
$DisplayMode = Read-Choice -PromptMessage "Entre 1 ou 2" -AllowedValues @("1","2")

Write-Host ""
Write-Host "Souhaites-tu exporter les résultats dans un fichier ?" -ForegroundColor Yellow
Write-Host "1 - Oui" -ForegroundColor Gray
Write-Host "2 - Non" -ForegroundColor Gray
$EnableExportChoice = Read-Choice -PromptMessage "Entre 1 ou 2" -AllowedValues @("1","2")

$EnableExport = $EnableExportChoice -eq "1"

$ExportMode = $null
$ExportFolder = $null
$ExportFileName = $null

if ($EnableExport)
{
    Write-Host ""
    Write-Host "Choix du mode d'export fichier :" -ForegroundColor Yellow
    Write-Host "1 - Full  : Name / SamAccountName / Enabled / DistinguishedName" -ForegroundColor Gray
    Write-Host "2 - Short : Name / Enabled" -ForegroundColor Gray
    $ExportMode = Read-Choice -PromptMessage "Entre 1 ou 2" -AllowedValues @("1","2")

    Write-Host ""
    Write-Host "Exemple de dossier : C:\Temp\AuditAD" -ForegroundColor DarkGray
    $ExportFolder = Read-NonEmptyInput -PromptMessage "Chemin complet du dossier d'export"

    Write-Host ""
    Write-Host "Exemple de nom de fichier : Audit_Groupe_AD.txt" -ForegroundColor DarkGray
    $ExportFileName = Read-NonEmptyInput -PromptMessage "Nom du fichier d'export"
}


############################################################
# LECTURE DU GROUPE
############################################################

Show-Section -Title "Lecture des membres du groupe"

Write-Host ("Groupe analysé : {0}" -f $GroupName) -ForegroundColor Yellow
Write-Host ("OU filtrée     : {0}" -f $SearchOU) -ForegroundColor Yellow
Write-Host ""

try
{
    $GroupMembers = Get-ADGroupMember -Identity $GroupName -Recursive -ErrorAction Stop |
        Where-Object { $_.objectClass -eq "user" }
}
catch
{
    Write-Host "Erreur lors de la lecture du groupe AD." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor DarkYellow
    Pause
    return
}


############################################################
# FILTRAGE DES UTILISATEURS
############################################################

Show-Section -Title "Filtrage des utilisateurs"

$FilteredUsers = @()

foreach ($Member in $GroupMembers)
{
    try
    {
        $User = Get-ADUser $Member.SamAccountName -Properties DistinguishedName, Enabled -ErrorAction Stop

        if ($User.DistinguishedName -like "*$SearchOU*")
        {
            $FilteredUsers += $User
        }
    }
    catch
    {
        Write-Host ("Impossible de lire l'utilisateur : {0}" -f $Member.SamAccountName) -ForegroundColor DarkYellow
    }
}

$FilteredUsers = $FilteredUsers | Sort-Object SamAccountName -Unique


############################################################
# AFFICHAGE DES RÉSULTATS
############################################################

Show-Section -Title "Résultats"

if (-not $FilteredUsers -or $FilteredUsers.Count -eq 0)
{
    Write-Host "Aucun utilisateur trouvé dans le groupe et l'OU spécifiée." -ForegroundColor Red
}
else
{
    Write-Host ("Nombre d'utilisateurs trouvés : {0}" -f $FilteredUsers.Count) -ForegroundColor Green
    Write-Host ""

    foreach ($User in $FilteredUsers)
    {
        switch ($DisplayMode)
        {
            "1" { Write-UserFull -User $User }
            "2" { Write-UserShort -User $User }
        }
    }
}


############################################################
# EXPORT FICHIER
############################################################

if ($EnableExport)
{
    Show-Section -Title "Export des résultats"

    try
    {
        ############################################################
        # Vérification et création sécurisée du dossier d’export
        ############################################################

        if (-not (Test-Path -Path $ExportFolder))
        {
            Write-Host "Le dossier d'export n'existe pas." -ForegroundColor Yellow
            Write-Host "Création automatique en cours..." -ForegroundColor Yellow

            New-Item `
                -Path $ExportFolder `
                -ItemType Directory `
                -Force `
                -ErrorAction Stop | Out-Null

            Write-Host ("Dossier créé avec succès : {0}" -f $ExportFolder) -ForegroundColor Green
            Write-Host ""
        }
        else
        {
            Write-Host ("Le dossier existe déjà : {0}" -f $ExportFolder) -ForegroundColor DarkGray
            Write-Host ""
        }

        ############################################################
        # Construction du chemin du fichier d’export
        ############################################################

        $ExportPath = Join-Path -Path $ExportFolder -ChildPath $ExportFileName

        ############################################################
        # Génération du contenu selon le mode choisi
        ############################################################

        $ExportContent = Build-ExportContent -Users $FilteredUsers -Mode $ExportMode

        ############################################################
        # Écriture dans le fichier
        ############################################################

        $ExportContent | Out-File -FilePath $ExportPath -Encoding UTF8 -ErrorAction Stop

        Write-Host "Export terminé avec succès." -ForegroundColor Green
        Write-Host ("Fichier créé : {0}" -f $ExportPath) -ForegroundColor Yellow
    }
    catch
    {
        Write-Host "Erreur lors de l'export." -ForegroundColor Red
        Write-Host "Vérifie le chemin, les droits, ou le nom du fichier." -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor DarkYellow
    }
}


############################################################
# FIN
############################################################

Show-Section -Title "Fin du script"
Write-Host "Traitement terminé." -ForegroundColor Green
Write-Host ""
Pause
