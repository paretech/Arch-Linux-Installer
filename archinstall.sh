#!/bin/bash -v

HOSTNAME="apollo"
USERNAME="paretech"
TIMEZONE="US/Eastern"
LANGUAGE="en_US.UTF-8"
DRIVE=/dev/sda
MOUNT_PATH=/mnt

# Test to see if operating in a chrooted environment. See 
# http://unix.stackexchange.com/questions/14345/how-do-i-tell-im-running-in-a-chroot
# for more information.
if [ "$(stat -c %d:%i /)" == "$(stat -c %d:%i /proc/1/root/.)" ]; then ### Not chrooted ###
    
# prepare disk
sgdisk --zap-all ${DRIVE}
sgdisk --set-alignment=2048 ${DRIVE}
sgdisk --clear ${DRIVE}

# create partitions
sgdisk -n 1:0:+250M -t 1:8300 -c 1:"Boot" ${DRIVE} # partition 1 (Boot)
sgdisk -n 2:0:+2G   -t 2:8200 -c 2:"Swap" ${DRIVE} # partition 2 (Swap)
sgdisk -n 3:0:0     -t 3:8300 -c 3:"Arch" ${DRIVE} # partition 3 (Arch)

# format partitions
mkfs.ext4 ${DRIVE}1
mkswap    ${DRIVE}2
mkfs.ext4 ${DRIVE}3

# mount partitions
mount ${DRIVE}3 ${MOUNT_PATH}
mkdir ${MOUNT_PATH}/boot && mount ${DRIVE}1 ${MOUNT_PATH}/boot
swapon ${DRIVE}2

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
if [ "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/.)" ];

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
#mkinitcpio -p linux

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

### User Configuration ###

# install and configure sudoers
# http://unix.stackexchange.com/questions/79338/programatically-use-visudo-to-edit-sudoers
pacman --noconfirm -S sudo
#cp /etc/sudoers /tmp/sudoers.edit
#sed -i "s/#\s*\(%wheel\s*ALL=(ALL)\s*ALL.*$\)/\1/" /tmp/sudoers.edit
#sed -i "s/#\s*\(%sudo\s*ALL=(ALL)\s*ALL.*$\)/\1/" /tmp/sudoers.edit
#visudo -qcsf /tmp/sudoers.edit && cat /tmp/sudoers.edit > /etc/sudoers

# change root password
passwd
fi ### END chroot check ###