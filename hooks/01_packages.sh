#!/bin/bash

# dpkg-reconfigure locales de+en

# Copy archives from GBE Debian Live repo
find upstream/GBE/config.v3/archives -type f -name "*.list.chroot" -exec cp {} chroot/etc/apt/sources.list.d \;
find upstream/GBE/config.v3/archives -type f -name "*.key.chroot" -exec apt-key add {} \;
