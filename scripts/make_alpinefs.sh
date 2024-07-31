#! /bin/bash

set -euo pipefail

ROOTFS_PAK="alpine.tar.gz"
ROOTFS_DIR="$TOP_DIR/build/alpine"
MODULE_DIR="$TOP_DIR/build/_module"
PACKAGES_DIR="$TOP_DIR/packages/alpine"

if [ ! -f "$ROOTFS_PAK" ]; then
    wget -O $ROOTFS_PAK https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/aarch64/alpine-minirootfs-3.20.2-aarch64.tar.gz
    tar -xvf $ROOTFS_PAK -C $ROOTFS_DIR -p
fi

sudo mkdir -p "$ROOTFS_DIR/etc"
echo "nameserver 8.8.8.8 " | sudo tee $ROOTFS_DIR/etc/resolv.conf > /dev/null

sudo chroot $ROOTFS_DIR /bin/sh -c "apk update && \
	apk add alpine-base openssh-server mkinitfs parted e2fsprogs-extra chrony acpid-openrc dhcpcd dhclient lsblk pciutils networkmanager-cli bluez && \
	rc-update add sshd default && \
	rc-update add networking default && \
	rc-update add sysctl boot && \
	rc-update add hostname boot && \
	rc-update add crond default && \
	rc-update add chronyd default && \
	rc-update add acpid default && \
	rc-update add klogd default && \
	rc-update add dhcpcd default && \
	rc-update add syslog boot && \
	rc-update add machine-id boot && \
	rc-update add modules boot && \
	rc-update add hwclock boot && \
	rc-update add swap boot"

cp $MODULE_DIR/* $ROOTFS_DIR -a
mkdir -p $ROOTFS_DIR/boot
sed -i 's|#ttyS0::respawn:/sbin/getty -L 115200 ttyS0 vt100|console::respawn:-/bin/sh|' $ROOTFS_DIR/etc/inittab

cp $PACKAGES_DIR/* $ROOTFS_DIR -a
chmod a+x $ROOTFS_DIR/etc/init.d/first-boot $ROOTFS_DIR/usr/bin/first-boot
chroot $ROOTFS_DIR /bin/sh -c "rc-update add first-boot sysinit"
