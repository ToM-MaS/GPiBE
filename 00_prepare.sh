#!/bin/bash

. GPiBE.conf

IMAGE_ARCHIVE_FILE="cache/${RPI_IMAGE_SRC_URL##*/}"
IMAGE_FILE="${IMAGE_ARCHIVE_FILE%%.*}.img"
MNT="tools/mnt-pi-img.sh"
GPI_IMAGE="images/gs5-rpi.img"

cd $(dirname $(readlink -f $0))

[ ! -d cache ] && mkdir cache
[ ! -d chroot ] && mkdir chroot
if [ ! -d ./images ]; then
	mkdir images
else
	rm images/*
fi

# Download Image
[[ ! -e "${IMAGE_ARCHIVE_FILE}" && ! -e "${IMAGE_FILE}" && ! -e "${GPI_IMAGE}" ]] && wget "${RPI_IMAGE_SRC_URL}" -O "${IMAGE_ARCHIVE_FILE}"
[ ! -e "${IMAGE_FILE}" ] && unzip "${IMAGE_ARCHIVE_FILE}" -d "${IMAGE_ARCHIVE_FILE%%/*}"
[ ! -e "${GPI_IMAGE}" ] && cp "${IMAGE_FILE}" "${GPI_IMAGE}"

# Mount
${MNT} "${GPI_IMAGE}" chroot
[ ! -d chroot/be ] && mkdir -p chroot/be
mount -o bind ./ chroot/be

# Shrink image
chroot chroot apt-get --yes purge $(cat package-lists/dpkg.cleanup)
chroot chroot rm -rf /usr/lib/xorg/modules/linux /usr/lib/xorg/modules/extensions /usr/lib/xorg/modules /usr/lib/xorg
chroot chroot apt-get --yes autoremove
chroot chroot apt-get --yes autoclean
chroot chroot apt-get --yes clean

# umount
${MNT} -u chroot

cd - 2>&1>/dev/null
