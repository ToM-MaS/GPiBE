#!/bin/bash -x

http_proxy=http://localhost:3128/
DIST="raspbian"
ARCH="armhf"
CHROOT_DIR="./chroot-${DIST}-${ARCH}"

KEYSTATUS="`apt-key list | grep 90FDDD2E`"
[ x"${KEYSTATUS}" == x"" ] && wget http://mirrordirector.raspbian.org/raspbian.public.key -O - | sudo apt-key add -

if [[ "${REINSTALL}" == "yes" ]]; then
 sudo apt-get -y --force-yes install binfmt-support qemu qemu-user-static debootstrap

 # force umount
 [[ "x`cat /proc/mounts | grep ${CHROOT_DIR}/dev/pts`" != "x" ]] && sudo umount ${CHROOT_DIR}/dev/pts
 [[ "x`cat /proc/mounts | grep ${CHROOT_DIR}/sys`" != "x" ]] && sudo umount ${CHROOT_DIR}/sys
 [[ "x`cat /proc/mounts | grep ${CHROOT_DIR}/proc`" != "x" ]] && sudo umount ${CHROOT_DIR}/proc

 sudo rm -rf "${CHROOT_DIR}"
fi

# Install Build Environment
#
if [ ! -d "${CHROOT_DIR}" ]; then
 sudo http_proxy=$http_proxy qemu-debootstrap --keyring=/etc/apt/trusted.gpg --arch armhf wheezy ${CHROOT_DIR} http://mirrordirector.raspbian.org/raspbian
 echo "deb http://mirrordirector.raspbian.org/raspbian wheezy main" > sources.list
 sudo cp -f sources.list "${CHROOT_DIR}/etc/apt/sources.list"
 rm -f sources.list

 if [ "${http_proxy}" != "" ]; then
  echo "export http_proxy=$http_proxy" > environment
  sudo cp -f environment "${CHROOT_DIR}/etc/environment"
  rm environment
 fi

 # mount
 [[ "x`cat /proc/mounts | grep ${CHROOT_DIR}/dev/pts`" == "x" ]] && sudo mount -o bind /dev/pts "${CHROOT_DIR}/dev/pts"
 [[ "x`cat /proc/mounts | grep ${CHROOT_DIR}/sys`" == "x" ]] && sudo mount -o bind /sys "${CHROOT_DIR}/sys"
 [[ "x`cat /proc/mounts | grep ${CHROOT_DIR}/proc`" == "x" ]] && sudo mount -o bind /proc "${CHROOT_DIR}/proc"

 wget http://archive.raspbian.org/raspbian.public.key -O - | sudo LC_ALL=C chroot "${CHROOT_DIR}" apt-key add -
 sudo LC_ALL=C http_proxy=$http_proxy chroot "${CHROOT_DIR}" apt-get update
 sudo LC_ALL=C http_proxy=$http_proxy chroot "${CHROOT_DIR}" apt-get -y --force-yes install build-essential dpkg-dev git-core cowbuilder git-buildpackage automake autoconf libtool pkg-config libssl-dev unixodbc-dev libpq-dev libncurses5-dev libjpeg62-dev python-dev erlang-dev doxygen uuid-dev libexpat1-dev libgdbm-dev libdb-dev bison ladspa-sdk libogg-dev libasound2-dev libx11-dev libsnmp-dev libflac-dev libvorbis-dev libvlc-dev default-jdk gcj-jdk libperl-dev libyaml-dev

 # umount
 [[ "x`cat /proc/mounts | grep ${CHROOT_DIR}/dev/pts`" != "x" ]] && sudo umount ${CHROOT_DIR}/dev/pts
 [[ "x`cat /proc/mounts | grep ${CHROOT_DIR}/sys`" != "x" ]] && sudo umount ${CHROOT_DIR}/sys
 [[ "x`cat /proc/mounts | grep ${CHROOT_DIR}/proc`" != "x" ]] && sudo umount ${CHROOT_DIR}/proc

# Update Build Environement
#
else

 # mount
 [[ "x`cat /proc/mounts | grep ${CHROOT_DIR}/dev/pts`" == "x" ]] && sudo mount -o bind /dev/pts "${CHROOT_DIR}/dev/pts"
 [[ "x`cat /proc/mounts | grep ${CHROOT_DIR}/sys`" == "x" ]] && sudo mount -o bind /sys "${CHROOT_DIR}/sys"
 [[ "x`cat /proc/mounts | grep ${CHROOT_DIR}/proc`" == "x" ]] && sudo mount -o bind /proc "${CHROOT_DIR}/proc"

 sudo LC_ALL=C http_proxy=$http_proxy chroot chroot-raspbian-armhf apt-get update
 sudo LC_ALL=C http_proxy=$http_proxy chroot chroot-raspbian-armhf apt-get -y --force-yes upgrade

 # umount
 [[ "x`cat /proc/mounts | grep ${CHROOT_DIR}/dev/pts`" != "x" ]] && sudo umount ${CHROOT_DIR}/dev/pts
 [[ "x`cat /proc/mounts | grep ${CHROOT_DIR}/sys`" != "x" ]] && sudo umount ${CHROOT_DIR}/sys
 [[ "x`cat /proc/mounts | grep ${CHROOT_DIR}/proc`" != "x" ]] && sudo umount ${CHROOT_DIR}/proc
fi