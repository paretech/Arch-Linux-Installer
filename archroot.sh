# Generate Ram Disk
mkinitcpio -p linux
 
 
# Install and Configure Bootloader
pacman --noconfirm -S syslinux gdisk
syslinux-install_update -iam

# Configure Hostname
echo ${HOSTNAME} > /etc/hostname
sed -i "s/localhost\.localdomain/${HOSTNAME}/g" /etc/hosts