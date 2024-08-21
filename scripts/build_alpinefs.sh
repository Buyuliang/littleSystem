#! /bin/bash

set -euo pipefail

ROOTFS_PAK="alpine.tar.gz"
ROOTFS_DIR="$TOP_DIR/build/alpine"
MODULE_DIR="$TOP_DIR/build/_module"
PACKAGES_DIR="$TOP_DIR/packages/alpine"

if [ ! -f "$ROOTFS_PAK" ]; then
    wget -O $ROOTFS_PAK https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/aarch64/alpine-minirootfs-3.20.2-aarch64.tar.gz 
    mkdir -p $ROOTFS_DIR
    tar -xvf $ROOTFS_PAK -C $ROOTFS_DIR
fi

sudo mkdir -p "$ROOTFS_DIR/etc"
echo "nameserver 8.8.8.8 " | sudo tee $ROOTFS_DIR/etc/resolv.conf > /dev/null
sed -i 's|^.*|https://mirrors.tuna.tsinghua.edu.cn/alpine/v3.20/main/|g' $ROOTFS_DIR/etc/apk/repositories
sed -i 'a https://mirrors.tuna.tsinghua.edu.cn/alpine/v3.20/community/' $ROOTFS_DIR/etc/apk/repositories

### prompt message ###
# gcompat 提供了 glibc 兼容层

sudo chroot $ROOTFS_DIR /bin/sh -c "apk update && \
			apk add alpine-base openssh-server openssh-client-common mkinitfs parted e2fsprogs-extra chrony bash gptfdisk \
			acpid-openrc dhcpcd dhclient lsblk pciutils wpa_supplicant networkmanager networkmanager-cli bluez iw iwd ethtool \
			hdparm gcompat fio i2c-tools eudev usbutils libdrm-dev libpng-dev && \
			rc-update add sshd default && \
			rc-update add networking default && \
			rc-update add sysctl boot && \
			rc-update add hostname boot && \
			rc-update add chronyd boot && \
			rc-update add acpid default && \
			rc-update add dhcpcd default && \
			rc-update add networkmanager boot && \
			rc-update add syslog boot && \
			rc-update add modules boot && \
			rc-update add bluetooth boot && \
			rc-update add wpa_supplicant boot && \
			rc-update add hwclock boot"

cp $MODULE_DIR/* $ROOTFS_DIR -a
mkdir -p $ROOTFS_DIR/boot
sed -i 's|#ttyS0::respawn:/sbin/getty -L 115200 ttyS0 vt100|console::respawn:-/bin/sh|' $ROOTFS_DIR/etc/inittab

cp $PACKAGES_DIR/* $ROOTFS_DIR -a
chmod a+x $ROOTFS_DIR/etc/init.d/first-boot $ROOTFS_DIR/usr/bin/first-boot
chmod a+x $ROOTFS_DIR/etc/init.d/adbd
chroot $ROOTFS_DIR /bin/sh -c "rc-update add first-boot sysinit"
chroot $ROOTFS_DIR /bin/sh -c "rc-update add adbd default"

### wpa_supplicant
chmod a+x $ROOTFS_DIR/etc/init.d/wpa_supplicant
chroot $ROOTFS_DIR /bin/sh -c "mkdir -p /var/run/wpa_supplicant"
chroot $ROOTFS_DIR /bin/sh -c "chown root:root /var/run/wpa_supplicant"
chroot $ROOTFS_DIR /bin/sh -c "chmod 755 /var/run/wpa_supplicant"

### display_png
chroot $ROOTFS_DIR /bin/sh -c "chmod 777 /usr/bin/display_png"

### brcm_patchram_plus1
chroot $ROOTFS_DIR /bin/sh -c "chmod 777 /usr/bin/brcm_patchram_plus1"