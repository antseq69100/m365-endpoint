# Génère une chaîne aléatoire de longueur définie
function New-RandomPart {
    param(
        [int]$Length = 7
    )

    # Jeu de caractères autorisés :
    # lettres minuscules + chiffres (sans caractères ambigus)
    $chars = 'abcdefghijkmnpqrstuvwxyz23456789'.ToCharArray()

    return (-join (1..$Length | ForEach-Object { $chars | Get-Random }))
}

# Génère un Display Name :
# Z + 7 caractères aléatoires
function New-DisplayName {
    return "Z" + (New-RandomPart -Length 7)
}

# Génère la partie locale du UPN :
# 8 caractères aléatoires
function New-UPNLocal {
    return New-RandomPart -Length 8
}

# Nombre total de comptes à générer
$count = 15

# Génération des résultats
$result = foreach ($i in 1..$count) {

    do {
        $displayName = New-DisplayName
        $upnLocal    = New-UPNLocal
    }
    while ($displayName.Substring(1).ToLower() -eq $upnLocal.ToLower())

    [PSCustomObject]@{
        DisplayName = $displayName
        UPN_Local   = $upnLocal
    }
}

# Affichage tableau
$result | Format-Table -AutoSize