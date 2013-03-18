#!/bin/bash

. GPiBE.conf

IMAGE_ARCHIVE_FILE="cache/${RPI_IMAGE_SRC_URL##*/}"
IMAGE_FILE="${IMAGE_ARCHIVE_FILE%%.*}.img"
MNT="tools/mnt-pi-img.sh"
GPI_IMAGE="images/gs5-rpi.img"

cd $(dirname $(readlink -f $0))

[ ! -d ./cache ] && mkdir -p ./cache
[ ! -d ./chroot ] && mkdir -p ./chroot
[ ! -d ./images ] && mkdir -p ./images

# Download Image
[ ! -e "${IMAGE_ARCHIVE_FILE}" ] && wget "${RPI_IMAGE_SRC_URL}" -O "${IMAGE_FILE}"
[ ! -e "${IMAGE_FILE}" ] && unzip "${IMAGE_ARCHIVE_FILE}"
[ ! -e "${GPI_IMAGE}" ] && cp "${IMAGE_FILE}" "${GPI_IMAGE}"

# Mount
${MNT} "${GPI_IMAGE}" chroot
mkdir -p chroot/be
mount -o bind ./ chroot/be

# Shrink image
chroot chroot apt-get --yes purge $(cat /be/package-lists/dpkg.cleanup)
chroot chroot rm -rf /usr/lib/xorg/modules/linux /usr/lib/xorg/modules/extensions /usr/lib/xorg/modules /usr/lib/xorg
chroot chroot apt-get --yes autoremove
chroot chroot apt-get --yes autoclean
chroot chroot apt-get --yes clean

# umount
${MNT} -u chroot

cd - 2>&1>/dev/null
