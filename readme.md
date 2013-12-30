## Description ##
Quick script to install Arch Linux as a VirtualBox Guest OS. This script will partition and format drive, install the base Arch Linux, install and configure syslinux as the bootloader, install and configure the VirtualBox Guest Additions, some basic user configuration, install the x windows environment, install the awesome windows manager "Awesome", and probably a few other items.

## Instructions ##
1. Boot the Arch install CD
2. Download archinstall.sh
    wget -O - http://tinyurl.com/aigist | tar xv
3. chmod a+rx archinstall.sh