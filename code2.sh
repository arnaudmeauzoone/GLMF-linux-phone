#!/bin/bash

# Les variables de boot.img
var_flash_offset_base="0x10000000"
var_flash_offset_kernel="0x00008000"
var_flash_offset_ramdisk="0x01000000"
var_flash_offset_second="0x00f00000"
var_flash_offset_tags="0x00000100"
var_flash_pagesize="2048"

# On crée l'initramfs
cd initramfs/
find . | cpio --create --format='newc' | gzip > ../myinitramfs.img
cd ..

# Création du fichier boot.img
$HOME/mkbootimg/mkbootimg \
--kernel "$HOME/kernel/arch/arm64/boot/Image" \
--ramdisk "myinitramfs.img" \
--base "${var_flash_offset_base}" \
--second_offset "${var_flash_offset_second}" \
--cmdline "${var_kernel_cmdline}" \
--kernel_offset "${var_flash_offset_kernel}" \
--ramdisk_offset "${var_flash_offset_ramdisk}" \
--tags_offset "${var_flash_offset_tags}" \
--pagesize "${var_flash_pagesize}"  \
--dt "dtb.img" \
-o "boot.img"
