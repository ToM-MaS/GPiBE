#!/bin/bash

. GPiBE.conf

cd $(dirname $(readlink -f $0))

[ -e  GPiBE_branch ] && GPI_BRANCH="`cat GPiBE_branch`" || GPI_BRANCH="master"

MNT="tools/mnt-pi-img.sh"
BUILDNAME="`date +%y%m%d%H%M`rpi"
[[ "${GPI_BRANCH}" != "master" ]] && BUILDNAME="${BUILDNAME}-${GPI_BRANCH}"
FILENAME="${GDFDL_FILE_PREFIX}_${BUILDNAME}"
GPI_IMAGE="images/${FILENAME}.img"
GPI_IMAGE_TMPL="cache/gs5-rpi-tmpl.img"

# Create image clone
if [ ! -e "${GPI_IMAGE_TMPL}" ]; then
	echo -e "FATAL ERROR: No image template prepared yet. Please run 00_prepare.sh first."
	exit 1
fi
echo -e "GPiBE: Cloning RaspberryPi image ..."
if [ ! -d "${GPI_IMAGE%%/*}" ]; then
	mkdir -p "${GPI_IMAGE%%/*}"
else
	rm -f "${GPI_IMAGE%%/*}/"*
fi
cp -f "${GPI_IMAGE_TMPL}" "${GPI_IMAGE}"

# Mount
echo -e "GPiBE: Mounting image ..."
sudo ${MNT} "${GPI_IMAGE}" chroot

# Check for existing upstream projects
if [ ! -d upstream/GBE ]; then
	echo -e "GPiBE: Cloning GBE ..."
	git clone -b master ${GBE_GIT_URL} upstream/GBE
fi
if [ -d upstream/GSE ]; then
	echo -e "GPiBE: GSE upstream found, copy to image ..."
	sudo mkdir -p chroot/opt/GSE
	sudo cp -rfv upstream/GSE chroot/opt
fi
if [ -d upstream/GS5 ]; then
	echo -e "GPiBE: GS5 upstream found, copy to image ..."
	sudo mkdir -p chroot/opt/GS5
	sudo cp -rfv upstream/GS5 chroot/opt
fi

# Compatibility with GBE
sudo ln -s be/GPiBE.conf chroot/gdfdl.conf
sudo sh -c "echo \"${BUILDNAME}\" > chroot/etc/gdfdl_build"
[ "${GIT_BRANCH}" != "" ] && sudo sh -c "echo \"${GIT_BRANCH}\" > chroot/etc/gemeinschaft_branch" || sudo sh -c "echo master > chroot/etc/gemeinschaft_branch"

echo -e "GPiBE: Running hooks ..."
for FILE in `find hooks -name "*.sh.chroot" | sort`; do
	sudo chroot chroot /be/${FILE}
	[ "$?" != "0" ] && break
done

# umount
echo -e "GPiBE: Unmounting image ..."
${MNT} -u chroot

cd - 2>&1>/dev/null
