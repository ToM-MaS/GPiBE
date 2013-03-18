#!/bin/bash -e

. GPiBE.conf

MNT="tools/mnt-pi-img.sh"
GPI_IMAGE="images/gs5-rpi.img"

cd $(dirname $(readlink -f $0))

# Mount
echo -e "GPiBE: Mounting image ..."
${MNT} "${GPI_IMAGE}" chroot
[ ! -d chroot/be ] && mkdir -p chroot/be
mount -o bind ./ chroot/be

echo -e "GPiBE: Running hooks ..."
for FILE in hooks/*.sh.chroot; do
	sudo chroot chroot /be/${FILE}
done

# umount
echo -e "GPiBE: Unmounting image ..."
${MNT} -u chroot

cd - 2>&1>/dev/null
