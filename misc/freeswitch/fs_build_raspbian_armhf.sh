#!/bin/bash -x
#

# settings
#
distro=wheezy
arch=armhf
suite=stable
export http_proxy=http://localhost:3128/

BE_ROOT="/var/lib/jenkins/jobs/PROD-BE_raspbian/workspace/chroot-raspbian-armhf"
BUILD_DIR="${BE_ROOT}/mnt"

rm -f *.tar.gz *.tar.xz *.dsc *.build *.changes *.deb

[ ! -L /dev/fd ] && sudo ln -s /proc/self/fd /dev/fd
if [ ! -d ./freeswitch ]; then
 git clone -b v1.2.stable git://git.freeswitch.org/freeswitch freeswitch
 (cd freeswitch; git branch master; git branch -D v1.2.stable)
fi


cd freeswitch

ver="$(cat build/next-release.txt | sed -e 's/-/~/g')~n$(date +%Y%m%dT%H%M%SZ)-1~${distro}+1"
git clean -fdx && git reset --hard HEAD

echo "# Do not generate diff for changes in configure.in
extend-diff-ignore = \"configure.in$\"" > debian/source/options
./build/set-fs-version.sh "$ver"
[ -f ../modules_raspbian.conf ] && cp -L ../modules_raspbian.conf debian/modules.conf
(cd debian && ./bootstrap.sh -c $distro)
git add configure.in && git commit -m "bump to custom v$ver"
dch -b -m -v "$ver" --force-distribution -D "$suite" "Custom build."

cd -


echo "export http_proxy="$http_proxy"; cd /mnt/freeswitch; dpkg-buildpackage -b -us -uc -Zxz -z9 -k09E60DF5; chmod 777 /mnt; chmod o+w ../*" > build.sh

# mount
[[ "x`cat /proc/mounts | grep ${BE_ROOT}/dev/pts`" == "x" ]] && sudo mount -o bind /dev/pts "${BE_ROOT}/dev/pts"
[[ "x`cat /proc/mounts | grep ${BE_ROOT}/sys`" == "x" ]] && sudo mount -o bind /sys "${BE_ROOT}/sys"
[[ "x`cat /proc/mounts | grep ${BE_ROOT}/proc`" == "x" ]] && sudo mount -o bind /proc "${BE_ROOT}/proc"
[[ "x`cat /proc/mounts | grep ${BUILD_DIR}`" == "x" ]] && sudo mount -o bind . "${BUILD_DIR}"

sudo LC_ALL=C chroot "${BE_ROOT}" bash -x /mnt/build.sh && rm -f build.sh

# umount
[[ "x`cat /proc/mounts | grep ${BE_ROOT}/dev/pts`" != "x" ]] && sudo umount ${BE_ROOT}/dev/pts
[[ "x`cat /proc/mounts | grep ${BE_ROOT}/sys`" != "x" ]] && sudo umount ${BE_ROOT}/sys
[[ "x`cat /proc/mounts | grep ${BE_ROOT}/proc`" != "x" ]] && sudo umount ${BE_ROOT}/proc
[[ "x`cat /proc/mounts | grep ${BUILD_DIR}`" != "x" ]] && sudo umount "${BUILD_DIR}"
git reset --hard HEAD^
