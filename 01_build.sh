#!/bin/bash

. GPiBE.conf

MNT="tools/mnt-pi-img.sh"
GPI_IMAGE_TMPL="cache/gs5-rpi-tmpl.img"
GPI_IMAGE="images/gs5-rpi.img"

cd $(dirname $(readlink -f $0))

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
cp "${GPI_IMAGE_TMPL}" "${GPI_IMAGE}"

# Mount
echo -e "GPiBE: Mounting image ..."
${MNT} "${GPI_IMAGE}" chroot
[ ! -d chroot/be ] && mkdir -p chroot/be
mount -o bind ./ chroot/be

# Check for existing upstream projects
if [ ! -d upstream/GBE ]; then
	echo -e "GPiBE: Cloning GBE ..."
	git clone -b master ${GBE_GIT_URL} upstream/GBE
fi
if [ -d upstream/GSE ]; then
	echo -e "GPiBE: GSE upstream found, copy to image ..."
	sudo cp -arfv upstream/GSE chroot/opt
fi
if [ -d upstream/GS5 ]; then
	echo -e "GPiBE: GS5 upstream found, copy to image ..."
	sudo cp -arfv upstream/GS5 chroot/opt
fi

# Compatibility with GBE
ln -s be/GPiBE.conf chroot/gdfdl.conf
echo "rpi" > chroot/etc/gdfdl_build

echo -e "GPiBE: Running hooks ..."
for FILE in `find hooks -name "*.sh.chroot" | sort`; do
	sudo chroot chroot /be/${FILE}
	[ "$?" != "0" ] && break
done

# umount
echo -e "GPiBE: Unmounting image ..."
${MNT} -u chroot

cd - 2>&1>/dev/null
