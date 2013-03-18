#!/bin/bash -e

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
	rm -f images/*
fi

# Download Image
if [[ ! -e "${IMAGE_ARCHIVE_FILE}" && ! -e "${IMAGE_FILE}" && ! -e "${GPI_IMAGE}" ]]; then
	echo -e "GPiBE: Downloading Raspbian base image ..."
	wget "${RPI_IMAGE_SRC_URL}" -O "${IMAGE_ARCHIVE_FILE}"
fi
[ ! -e "${IMAGE_FILE}" ]; unzip "${IMAGE_ARCHIVE_FILE}" -d "${IMAGE_ARCHIVE_FILE%%/*}"
if [ ! -e "${GPI_IMAGE}" ]; then
	echo -e "GPiBE: Creating working image copy ..."
	cp -f "${IMAGE_FILE}" "${GPI_IMAGE}"
fi

# Mount
echo -e "GPiBE: Mounting image ..."
${MNT} "${GPI_IMAGE}" chroot
[ ! -d chroot/be ] && mkdir -p chroot/be
echo -e "GPiBE: Mounting Build Environment ..."
mount -o bind ./ chroot/be

# Shrink image
echo -e "GPiBE: Removing abundant packages to shrink image ..."
export LC_ALL=C
chroot chroot apt-get --yes purge $(cat package-lists/dpkg.cleanup)
chroot chroot rm -rf /usr/lib/xorg/modules/linux /usr/lib/xorg/modules/extensions /usr/lib/xorg/modules /usr/lib/xorg
chroot chroot apt-get --yes autoremove
chroot chroot apt-get --yes autoclean
chroot chroot apt-get --yes clean

# umount
echo -e "GPiBE: Unmounting image ..."
${MNT} -u chroot

cd - 2>&1>/dev/null
