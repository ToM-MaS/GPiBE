#!/bin/bash -e

. GPiBE.conf

MNT="tools/mnt-pi-img.sh"
GPI_IMAGE="images/gs5-rpi.img"

cd $(dirname $(readlink -f $0))

# Mount
${MNT} "${GPI_IMAGE}" chroot
[ ! -d chroot/be ] && mkdir -p chroot/be
mount -o bind ./ chroot/be

for FILE in hooks/*.sh; do
	sudo chroot chroot /be/${FILE}
done

# umount
${MNT} -u chroot

cd - 2>&1>/dev/null
