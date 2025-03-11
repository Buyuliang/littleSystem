#! /bin/bash

set -xeo pipefail

ROOTFS_TAR="busybox.tar.bz2"
ROOTFS_PAK="$TOP_DIR/build/_busybox"
ROOTFS_DIR="$TOP_DIR/build/busybox"
MODULE_DIR="$TOP_DIR/build/_module"
PACKAGES_DIR="$TOP_DIR/packages/ramdisk"
ROOTFS_CON="$TOP_DIR/packages/configs/busybox_defconfig"

mkdir -p $ROOTFS_PAK
if [ ! -d "$ROOTFS_DIR" ]; then
    wget -O $ROOTFS_TAR https://busybox.net/downloads/busybox-1.36.1.tar.bz2
    mkdir -p /tmp/_busybox
    tar -xvjf $ROOTFS_TAR -C /tmp/_busybox
    rsync -av /tmp/_busybox/busybox*/* $ROOTFS_PAK
    rm -rf /tmp/_busybox
    rsync -av $ROOTFS_CON $ROOTFS_PAK/configs
    pushd $ROOTFS_PAK
    export ARCH=arm64
    export CROSS_COMPILE=aarch64-linux-gnu-
    make busybox_defconfig
    make -j$(nproc)
    make install
    popd
fi

sudo rsync -av $ROOTFS_PAK/_install/* $ROOTFS_DIR
sudo chroot $ROOTFS_DIR /bin/sh -c "mkdir -p dev etc mnt proc var tmp sys root lib"
sudo rsync -av $PACKAGES_DIR/* $ROOTFS_DIR
# rsync -av $MODULE_DIR/* $ROOTFS_DIR

### initrd

mkdir -p initrd
sudo rsync -av $ROOTFS_DIR/* initrd
sudo rsync -av $TOP_DIR/packages/initrd/* initrd
pushd initrd
sudo mv linuxrc init
sudo bash -c "find . |cpio -o -H newc| gzip > ../initrd.img"
popd

### package ramdisk

# dd if=/dev/zero of=ramdisk bs=1k count=8192
# mkfs.ext2 -F ramdisk
# sudo mkdir -p /mnt/initrd
# sudo mount -t ext2 ramdisk /mnt/initrd
# sudo rsync -av $ROOTFS_DIR/* /mnt/initrd/ -a
# sudo umount /mnt/initrd
# sudo sh -c 'gzip --best -c ramdisk > ramdisk.gz'
# mkimage -n "ramdisk" -A arm -O linux -T ramdisk -C gzip -d ramdisk.gz ramdisk.img

# rm ramdisk ramdisk.gz

### initramfs
mkdir -p initramfs
sudo rsync -av $ROOTFS_DIR/* initramfs
sudo rsync -av $TOP_DIR/packages/initrd/* initramfs
# sudo rsync -av $TOP_DIR/build/flash-firmware/* initramfs
sudo rm initramfs.cpio.gz || true
pushd initramfs
sudo mv linuxrc init
sudo bash -c "find . | cpio -H newc -ov --owner root:root -F ../initramfs.cpio"
popd
du -sh initramfs.cpio
sudo gzip initramfs.cpio
sudo mkimage -A arm64 -O linux -T ramdisk -d initramfs.cpio.gz uRamdisk
