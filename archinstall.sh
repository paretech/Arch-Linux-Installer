#!/bin/bash

HOSTNAME="apollo"
USERNAME="paretech"
TIMEZONE="US/Eastern"
LANGUAGE="en_US.UTF-8"

# To determine DRIVE, inspect output of
# $ lsblk
DRIVE=/dev/sda
MOUNT_PATH=/mnt
USERSHELL=/bin/bash

# Test to see if operating in a chrooted environment. See
# http://unix.stackexchange.com/questions/14345/how-do-i-tell-im-running-in-a-chroot
# for more information.
if [ "$(stat -c %d:%i /)" == "$(stat -c %d:%i /proc/1/root/.)" ]; then ### Not chrooted ###

# prepare disk
sgdisk --zap-all ${DRIVE}
sgdisk --set-alignment=2048 ${DRIVE}
sgdisk --clear ${DRIVE}

# Common Partitions Types
#   8300 Linux filesystem
#   8200 linux swap
#   fd00 linux raid
#   ef02 BIOS boot
#
# For more use 'sgdisk -L'.

# create partitions
sgdisk --new=1:0:+500M --typecode=1:ef00 --change-name=1:"EFI System Partition" ${DRIVE} # partition 1 (EFI)
sgdisk --new=2:0:+250M --typecode=2:8300 --change-name=2:"Boot" ${DRIVE} # partition 2 (Boot)
sgdisk --new=3:0:+2G   --typecode=3:8200 --change-name=3:"Swap" ${DRIVE} # partition 3 (Swap)
sgdisk --new=4:0:0     --typecode=4:8300 --change-name=4:"root" ${DRIVE} # partition 4 (Arch)

# format partitions
mkfs.fat -F32 ${DRIVE}1
mkfs.ext4 ${DRIVE}2
mkswap    ${DRIVE}3
mkfs.ext4 ${DRIVE}4

# mount partitions
mount ${DRIVE}4 ${MOUNT_PATH}
mkdir ${MOUNT_PATH}/boot && mount ${DRIVE}2 ${MOUNT_PATH}/boot
swapon ${DRIVE}3

# install base system
pacstrap ${MOUNT_PATH} base base-devel

# generate file system table
genfstab -p ${MOUNT_PATH} >> ${MOUNT_PATH}/etc/fstab

# prepare chroot script
cp ${0} ${MOUNT_PATH}

# change root
arch-chroot ${MOUNT_PATH} ${0}

# unmount drives
umount -R ${MOUNT_PATH}

# restart into new arch env
reboot
fi ### END chroot check ###

# Test to see if operating in a chrooted environment. See
# http://unix.stackexchange.com/questions/14345/how-do-i-tell-im-running-in-a-chroot
# for more information.
if [ "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/.)" ]; then

# Configure Hostname
echo ${HOSTNAME} > /etc/hostname
sed -i "s/localhost\.localdomain/${HOSTNAME}/g" /etc/hosts

# configure locale
sed -i "s/^#\(${LANGUAGE}.*\)$/\1/" "/etc/locale.gen";
locale-gen
echo LANG=${LANGUAGE} > /etc/locale.conf
export LANG=${LANGUAGE}
cat > /etc/vconsole.conf <<VCONSOLECONF
KEYMAP=${KEYMAP}
FONT=${FONT}
FONT_MAP=
VCONSOLECONF

# configure time
ln -s /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
echo ${TIMEZONE} >> /etc/timezone

# Install and Configure Bootloader
pacman --noconfirm -S syslinux gdisk
syslinux-install_update -iam

# Generate Ram Disk
# Don't need this as the initial ramdisk is created during linux install
# mkinitcpio -p linux

# setup network
systemctl enable dhcpcd

# setup virtualbox addons
pacman --noconfirm -S virtualbox-guest-utils
echo vboxguest >> /etc/modules-load.d/virtualbox.conf
echo vboxsf >> /etc/modules-load.d/virtualbox.conf
echo vboxvideo >> /etc/modules-load.d/virtualbox.conf
modprobe -a vboxguest vboxsf vboxvideo
systemctl enable vboxservice
mkdir /media && chgrp vboxsf /media

# X Windows System
pacman --noconfirm -S xorg-server xorg-server-utils xorg-xinit xterm ttf-dejavu awesome

### User Configuration ###

# install and configure sudoers
pacman --noconfirm -S sudo
cp /etc/sudoers /tmp/sudoers.edit
# sed -i "s/#\s*\(%wheel\s*ALL=(ALL)\s*ALL.*$\)/\1/" /tmp/sudoers.edit
sed -i "s/#\s*\(%sudo\s*ALL=(ALL)\s*ALL.*$\)/\1/" /tmp/sudoers.edit
visudo -qcsf /tmp/sudoers.edit && cat /tmp/sudoers.edit > /etc/sudoers && groupadd sudo

# change root password
echo "Changing Root password:"
passwd

# create new user
echo "Set new user, ${USERNAME}, password:"
useradd -m -g users -G optical,storage,power,sudo,vboxsf -s ${USERSHELL} ${USERNAME}
passwd ${USERNAME}

# new usuer config x
echo /usr/bin/VBoxClient-all >> /home/${USERNAME}/.xinitrc
echo "exec awesome" >> /home/${USERNAME}/.xinitrc
fi ### END chroot check ###
