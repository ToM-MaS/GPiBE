#!/bin/bash -e

# Copy archives from GBE Debian Live repo
for FILE in /be/archives/*.list.chroot; do
	DEST_FILE="/etc/apt/sources.list.d/`basename "${FILE%%.*}"`.list"
	cp -f "${FILE}" "${DEST_FILE}"
done
find /be/archives -type f -name "*.key.chroot" -exec apt-key add {} \;

#FIXME
echo "89.221.14.194 repo.amooma.de" >> /etc/hosts

apt-get update 2>&1
apt-get -y --force-yes upgrade 2>&1
apt-get clean 2>&1

# load preseeds
for FILE in /be/upstream/GBE/config.v3/preseed/*.cfg.chroot; do
	debconf-set-selections "${FILE}"
done
for FILE in /be/preseed/*.cfg.chroot; do
	debconf-set-selections "${FILE}"
done

# Install packages
for FILE in /be/package-lists/*.list.chroot; do
	apt-get --yes install $(cat ${FILE} | grep -Ev ^# | grep -Ev "^$")
done
for FILE in /be/upstream/GBE/config.v3/package-lists/*.list.chroot; do
	[ "${FILE##*/}" == "01-gdfdl_system.list.chroot" || "${FILE##*/}" == "02-gemeinschaft_system.list.chroot" ] && continue
	apt-get --yes install $(cat ${FILE} | grep -Ev ^# | grep -Ev "^$")
done
