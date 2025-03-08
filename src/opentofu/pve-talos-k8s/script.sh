#!/usr/bin/env bash

#$1 = nom de l'image
#$2 = version de Talos
#$3 = schematic id de Talos

pve_iso_path="/var/lib/vz/template/iso"
image_name=$1.$2.img
talos_version=$2
talos_schematic_id=$3

#Cette vérification est faite pour éviter de télécharger le fichier si il existe déjà, ce qui permet de gagner du temps et surtout de la bande passante
if [[ -f "$pve_iso_path/$image_name" ]]; then
    echo "$1 existe déjà"
else
    raw_filename="talos-nocloud-amd64.raw"
    echo "Installation si nécessaire du package xz-utils qui permet de décompresser les fichiers .xz"
    sudo apt-get install xz-utils -y

    echo "Téléchargement du fichier image Talos Linux"
    curl -o $raw_filename.xz  https://factory.talos.dev/image/$talos_schematic_id/$talos_version/nocloud-amd64.raw.xz

    echo "Décompression du fichier image Talos Linux"
    xz -d $raw_filename.xz

    echo "Déplacement du fichier raw dans le dossier des fichiers iso de proxmox"
    mv $raw_filename $pve_iso_path/$image_name

    echo "Suppression du script dont on a plus besoin"
    rm script.sh
fi
