#!/bin/bash

# Motivateur Agressif N°1 Obligatoire non Négociable: MANON

# add -h option to display help
if [ "$1" = "-h" ]; then
    printf "\033[1;33m"
    echo "------------------------------------------"
    printf "\033[0m"
    printf "Il est possible d'executer MANON avec la commande bash <nom_du_script> DELAI_ANALYSE\n"
    printf "Avec DELAI_ANALYSE: délai en secondes entre chaque analyse du projet (optionnel, par défaut 15s)\n"
    printf "ℹ️ Le script s'ajoutera automatiquement au gitignore\n"
    printf "\033[1;33m"
    echo "------------------------------------------"
    printf "\033[0m"
    exit 0
fi

# $1 argument optionnel: délai entre chaque analyse
DELAI_ANALYSE=${1:-15} # Temps entre chaque analyse

SEUIL_FICHIER_ALERT=5 # Nombre de fichiers non commités avant alerte
SEUIL_FICHIERS_MAX=$(($SEUIL_FICHIER_ALERT+2)) # Nombre de fichiers non commités avant arrêt

PLATFORM=$(uname -s)

function send_notification {
    title=$1
    message=$2
    # Si on est sur macOS, on envoie une notification
    if [ $PLATFORM = "Darwin" ]; then
        osascript -e "display notification \"$message\" with title \"$title\""
    else [ $PLATEFORM = "Windows_NT" ]
        powershell -Command "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show('$message', '$title')"
    fi
}

# Vérifier que git est installé
if ! [ -x "$(command -v git)" ]; then
  echo "Error: git n'est pas installé." >&2
  exit 1
fi

# Ajouter le script au gitignore
if ! grep -q "$0" .gitignore; then
    echo "$0" >> .gitignore
    git add .gitignore
    git commit .gitignore -m "Ajout du script bash au gitignore"
    printf "Ajout du script bash au gitignore\n"
fi

printf "Démarrage de Manon, analyse toutes les $DELAI_ANALYSE secondes\n"

while sleep $DELAI_ANALYSE; do 
    FICHIER_MODIF=$(git status --porcelain | grep -cE "^(M| M)")
    if [ $FICHIER_MODIF -ge $SEUIL_FICHIER_ALERT ]; then
        printf "\033[1;31m" # Changer la couleur du texte en rouge
        if [ $FICHIER_MODIF -ge $SEUIL_FICHIERS_MAX ]; then
            send_notification "❌ Dommage" "Le maximum de lignes modifiées est atteint, suppression des fichiers modifiés en cours !"
            printf "❌ Maximum de lignes modifiées atteint, on arrête tout !\n"
            git status --porcelain | grep -E "^(M| M)" | cut -c4- | xargs -I{} printf "Suppression de {}\n"
            git reset --hard
        else
            send_notification "⚠️ Attention" "Le seuil de lignes modifiées est bientot atteint !"
            printf "⚠️ Le seuil de lignes modifiées est bientot atteint !\n"
        fi
        printf "\033[0m" # Remettre la couleur du texte par défaut
        printf "Total fichiers non commitées: $FICHIER_MODIF\n"
    fi
done