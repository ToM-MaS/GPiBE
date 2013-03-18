#!/bin/bash

. GPiBE.conf

MNT="tools/mnt-pi-img.sh"
GPI_IMAGE="images/gs5-rpi.img"

cd $(dirname $(readlink -f $0))

# Mount
echo -e "GPiBE: Mounting image ..."
${MNT} "${GPI_IMAGE}" chroot
[ ! -d chroot/be ] && mkdir -p chroot/be
mount -o bind ./ chroot/be

# Compatibility with GBE
ln -s be/GPiBE.conf chroot/gdfdl.conf

echo -e "GPiBE: Running hooks ..."
for FILE in `find hooks -name "*.sh.chroot" | sort`; do
	sudo chroot chroot /be/${FILE}
	[ "$?" != "0" ] && break
done

# umount
echo -e "GPiBE: Unmounting image ..."
${MNT} -u chroot

cd - 2>&1>/dev/null
