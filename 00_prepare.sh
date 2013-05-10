#!/bin/bash -e

. GPiBE.conf

set -e

IMAGE_ARCHIVE_FILE="cache/${RPI_IMAGE_SRC_URL##*/}"
IMAGE_FILE="${IMAGE_ARCHIVE_FILE%%.*}.img"
MNT="tools/mnt-pi-img.sh"
GPI_IMAGE="cache/gs5-rpi-tmpl.img"

cd $(dirname $(readlink -f $0))

[ ! -d cache ] && mkdir cache
[ ! -d chroot ] && mkdir chroot

# Download Image
if [[ ! -e "${IMAGE_ARCHIVE_FILE}" && ! -e "${IMAGE_FILE}" && ! -e "${GPI_IMAGE}" ]]; then
	echo -e "GPiBE: Downloading Raspbian base image ..."
	wget "${RPI_IMAGE_SRC_URL}" -O "${IMAGE_ARCHIVE_FILE}"

  SHA1SUM="`sha1sum ${RPI_IMAGE_SHA1} | cut -d " " -f1`"
  if [ x"${RPI_IMAGE_SHA1}" == x"${SHA1SUM}" ]  
	  rm -f "${GPI_IMAGE}"
  else
    echo "ERROR: SHA1 checksum error (${SHA1SUM} != ${RPI_IMAGE_SHA1})"
    exit 1
  fi
fi
if [ ! -e "${IMAGE_FILE}" ]; then
	unzip "${IMAGE_ARCHIVE_FILE}" -d "${IMAGE_ARCHIVE_FILE%%/*}"
	rm -f "${GPI_IMAGE}"
fi

# Working copy
if [ ! -e "${GPI_IMAGE}" ]; then
	echo -e "GPiBE: Creating working image copy ..."
	cp -f "${IMAGE_FILE}" "${GPI_IMAGE}"

	# Mount
	echo -e "GPiBE: Mounting image ..."
	sudo ${MNT} "${GPI_IMAGE}" chroot

	echo -e "GPiBE: Set Time Zone ...\n"
	sudo sh -c "echo ${TIMEZONE} > chroot/etc/timezone"
	sudo cp chroot/usr/share/zoneinfo/${TIMEZONE} chroot/etc/localtime

	echo -e "GPiBE: Set locale settings ...\n"
	sudo sh -c "echo \"LANG=en_US.UTF-8\" > chroot/etc/locale"
	sudo sh -c "echo \"de_DE ISO-8859-1\" > chroot/etc/locale.gen"
	sudo sh -c "echo \"de_DE.UTF-8 UTF-8\" >> chroot/etc/locale.gen"
	sudo sh -c "echo \"de_DE@euro ISO-8859-15\" >> chroot/etc/locale.gen"
	sudo sh -c "echo \"en_US ISO-8859-1\" >> chroot/etc/locale.gen"
	sudo sh -c "echo \"en_US.ISO-8859-15 ISO-8859-15\" >> chroot/etc/locale.gen"
	sudo sh -c "echo \"en_US.UTF-8 UTF-8\" >> chroot/etc/locale.gen"
	sudo chroot chroot locale-gen 2>&1 >/dev/null

	# Disable init-scripts
	sudo sh -c "echo \#\!/bin/sh > chroot/usr/sbin/policy-rc.d"
	sudo sh -c "echo 'exit 101' >> chroot/usr/sbin/policy-rc.d"
	sudo chmod 755 chroot/usr/sbin/policy-rc.d

	# Cleanup image
	echo -e "GPiBE: Removing abundant packages to shrink image ..."
	export DEBIAN_FRONTEND=noninteractive
	sudo chroot chroot apt-get -y -q --force-yes purge $(cat package-lists/dpkg.cleanup)
	sudo chroot chroot rm -rf /usr/lib/xorg/modules/linux /usr/lib/xorg/modules/extensions /usr/lib/xorg/modules /usr/lib/xorg /etc/polkit-1 /etc/skel/pistore.desktop
	sudo chroot chroot apt-get -y -q --force-yes autoremove
	sudo chroot chroot apt-get -y -q --force-yes autoclean
	sudo chroot chroot apt-get -y -q --force-yes clean

	sudo rm -f chroot/usr/sbin/policy-rc.d

	# umount
	echo -e "GPiBE: Unmounting image ..."
	sudo ${MNT} -u chroot

	# Resize image to 3.4GB
	truncate --size $((3400*1024*1024)) ${GPI_IMAGE}
	PART_START=$(/sbin/parted ${GPI_IMAGE} -ms unit s p | grep "^2" | cut -f 2 -d:)
	[ "$PART_START" ] || exit 1
	/sbin/fdisk ${GPI_IMAGE} <<EOF
p
d
2
n
p
2
$PART_START

p
w
EOF

	OFFSET_ROOT=`/sbin/sfdisk -uS -l "${GPI_IMAGE}" 2>/dev/null | grep img2 | awk '{print $2}'`
	OFFSET_ROOT=$((512*${OFFSET_ROOT}))
	LOOP_DEV="`sudo /sbin/losetup -f --show -o ${OFFSET_ROOT} ${GPI_IMAGE}`"

	sudo /sbin/e2fsck -f -y ${LOOP_DEV}
	sudo /sbin/resize2fs ${LOOP_DEV}
	sync
	sleep 3
	sudo /sbin/losetup -d ${LOOP_DEV}
fi

# write branch information to local file
[ x"${GIT_BRANCH}" != x"" ] && echo "${GIT_BRANCH}" > GPiBE_branch

cd - 2>&1>/dev/null
