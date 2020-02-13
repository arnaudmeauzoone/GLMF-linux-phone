#!/bin/sh

export PATH=/usr/bin:/bin:/usr/sbin:/sbin
echo $PATH

# On monte une arborescence Linux minimale (proc, sys et dev)
# Pour que le système fonctionne
mount -t proc -o nodev,noexec,nosuid proc /proc
mount -t sysfs -o nodev,noexec,nosuid sysfs /sys
mount -t devtmpfs none /dev

# /dev/pts est important pour que telnet fonctionne
mkdir -p /dev/pts
mount -t devpts devpts /dev/pts

# Évite que les messages du noyau ne
# "polluent" l'écran
echo 0 > /proc/sys/kernel/printk

# On configure le framebuffer
_mode="$(cat /sys/class/graphics/fb0/modes)"
echo "Configuration du framebuffer mode: $_mode"
echo "$_mode" > /sys/class/graphics/fb0/mode

# Obligatoire pour rafraîchir le framebuffer
# voir https://github.com/AsteroidOS/msm-fb-refresher
/usr/sbin/msm-fb-refresher --loop &

# mode 16 bits par pixel et on s’assure que la
# taille est la bonne 1440x2560 pour un Samsung Galaxy S7
echo 16 > /sys/class/graphics/fb0/bits_per_pixel
echo 1440,2560 > /sys/class/graphics/fb0/virtual_size

# Réinitialisation du framebuffer
echo 1 > /sys/class/graphics/fb0/blank
echo 0 > /sys/class/graphics/fb0/blank

# Réinitialisation de la console pour passer sur le framebuffer
# à partir de là, vous devriez voir les lignes de boot sur votre écran
echo 0 > /sys/class/vtconsole/vtcon1/bind
echo 1 > /sys/class/vtconsole/vtcon1/bind

echo "Initialisation de la console"

# Mise en place de la fonction d'un lien
# Ethernet virtuel via android_usb
SYS=/sys/class/android_usb/android0
printf "%s" "0" >"$SYS/enable"
printf "%s" "18D1" >"$SYS/idVendor"
printf "%s" "D001" >"$SYS/idProduct"
printf "%s" "rndis" >"$SYS/functions"
printf "%s" "1" >"$SYS/enable"

echo "USB ethernet via android_usb"

# Les paramètres réseau
TELNET_PORT=23
IP=172.16.42.1

# On configure l'interface réseau.
# Ici rndis0 car créé via android_usb
ifconfig rndis0 "$IP" 2>/dev/null

# On démarre le daemond telnet
# Permet d'avoir un shell sur le périphérique
# via l'ordinateur
busybox telnetd -b "${IP}:${TELNET_PORT}" -l /bin/bash

gzip -c -d image.ppm.gz >/tmp/splash.ppm # On prépare l’image splash.

UUID=049f2dc1-360d-4302-a067-f41fd5f11c8e # Remplacez cet UUID par le votre.
# Fonction permettant de trouver la partition root
root_partition() {
	DEVICE="$(blkid | grep $UUID | cut -d ":" -f 1)"
	echo "$DEVICE"
}

# On attend que la carte SD/clé USB soit détectée
while [ -z "$(root_partition)" ]; do
	fbsplash -s /tmp/splash.ppm # on affiche l’image splash (si on le souhaite).
	sleep 0.1 # évite la surchauffe.
done

partition="$(find_root_partition)" #
mount -t ext4 -o ro "$partition" /sysroot # Si sysroot n’existe pas crée le avec mkdir

echo "Systeme de fichier monté"

killall telnetd mdev msm-fb-refresher 2>/dev/null # On tue tous les process pour laisser un système complètement propre.
# On démonte tous les points de montages
umount /proc
umount /sys
umount /dev/pts
umount /dev

# Le pivot
exec switch_root /sysroot /sbin/init

# Normalement on ne doit jamais arriver ici.
# On affiche une erreur si le pivot n’a pas fonctionné.
while true; do
	sleep 1
	echo "Erreur dans l'initramfs"
done
