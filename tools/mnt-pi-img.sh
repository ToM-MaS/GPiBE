#!/bin/bash

if [[ x"${1}" == x"" || x"${2}" == x"" ]]; then
	echo -e "\nUsage mount:\t$0 <image> <mountpoint>\nUsage umount:\t$0 -u <mountpoint>"
	exit 2
fi

IMAGE="$1"
MOUNTPOINT="`readlink -f $2`"

[[ "x`cat /proc/mounts | grep ${MOUNTPOINT}/boot`" != "x" ]] && sudo umount "${MOUNTPOINT}/boot"
[[ "x`cat /proc/mounts | grep ${MOUNTPOINT}/dev/pts`" != "x" ]] && sudo umount "${MOUNTPOINT}/dev/pts"
[[ "x`cat /proc/mounts | grep ${MOUNTPOINT}/sys`" != "x" ]] && sudo umount "${MOUNTPOINT}/sys"
[[ "x`cat /proc/mounts | grep ${MOUNTPOINT}/proc`" != "x" ]] && sudo umount "${MOUNTPOINT}/proc"
[[ "x`cat /proc/mounts | grep ${MOUNTPOINT}`" != "x" ]] && sudo umount "${MOUNTPOINT}"

if [ "${IMAGE}" != "-u" ]; then
	if [ -e "${IMAGE}" ]; then
		if [ x"`file "${IMAGE}" | grep "partition 1" | grep "partition 2"`" == x"" ]; then
			echo -e "\nERROR: File '${IMAGE}' does not seem to be a valid image file."
			exit 1
		fi
		if [ ! -d "${MOUNTPOINT}" ]; then
			echo -e "\nERROR: Mountpoint directory '${MOUNTPOINT}' does not exist."
			exit 1
		fi

		OFFSET_BOOT=`sfdisk -uS -l "${IMAGE}" | grep img1 | awk '{print $2}'`
		OFFSET_ROOT=`sfdisk -uS -l "${IMAGE}" | grep img2 | awk '{print $2}'`

		sudo mount -o loop,offset=$((512*${OFFSET_ROOT})) "${IMAGE}" "${MOUNTPOINT}"
		sudo mount -o loop,offset=$((512*${OFFSET_BOOT})) "${IMAGE}" "${MOUNTPOINT}/boot"
		sudo mount -o bind /dev/pts "${MOUNTPOINT}/dev/pts"
		sudo mount -o bind /sys "${MOUNTPOINT}/sys"
		sudo mount -o bind /proc "${MOUNTPOINT}/proc"
		
		cp -f /usr/bin/qemu-arm-static "${MOUNTPOINT}/usr/bin/qemu-arm-static"
	else
		echo -e "\nERROR: Image file '${IMAGE}' not found."
		exit 1
	fi
else
	echo -e "\nImage was unmouted."
fi

exit 0