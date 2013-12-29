HOSTNAME="apollo"
USERNAME="mpare"
TIMEZONE="US/Eastern"
LANGUAGE=
DRIVE=/dev/sda
MOUNT_PATH=/mnt

# prepare disk
sgdisk --zap-all ${DRIVE}
sgdisk --set-alignment=2048 ${DRIVE}
sgdisk --clear ${DRIVE}

# create partitions
sgdisk -n 1:0:+250M -t 1:8300 -c 1:"Boot" ${DRIVE} # partition 1 (Boot)
sgdisk -n 2:0:+2G   -t 2:8200 -c 2:"Arch" ${DRIVE} # partition 2 (Swap)
sgdisk -n 3:0:0     -t 3:8300 -c 3:"Arch" ${DRIVE} # partition 3 (Arch)

# format partitions
mkfs.ext4 ${DRIVE}1
mkswap    ${DRIVE}2
mkfs.ext4 ${DRIVE}3

# mount partitions
mount ${DRIVE}3 ${MOUNT_PATH}

mkdir ${MOUNT_PATH}/boot
mount ${DRIVE}1 ${MOUNT_PATH}/boot

swapon ${DRIVE}2


# install base system
pacstrap ${MOUNT_PATH} base base-devel

# generate file system table
genfstab -p ${MOUNT_PATH} >> ${MOUNT_PATH}/etc/fstab

chmod a+rx archroot.sh

cp archroot.sh ${MOUNT_PATH}

arch-chroot ${MOUNT_PATH} ./archroot.sh

