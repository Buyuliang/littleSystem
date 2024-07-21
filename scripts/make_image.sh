#! /bin/bash

# set -x

source $TOP_DIR/scripts/tools.sh

### make firmware
# --------------------------------------------------------------------
# | 0x40 idbloader | 0x4000 uboot.itb | 0x8000 fat | 0x40000 ramdisk |
# |                |                  | 32768      |  262144         |
# --------------------------------------------------------------------

OUTPUT_IMG=firmware.img
MOUNT_POINT=tmp

# File system and size
BOOT_IMG="boot.img"
ROOTFS_IMG="rootfs.img"
BOOT_SIZE="100M"
ROOTFS_SIZE="500M"

# del last image and other file
rm -rf $OUTPUT_IMG $BOOT_IMG $ROOTFS_IMG $MOUNT_POINT 2>/dev/null

# Create the boot partition
dd if=/dev/zero of="$BOOT_IMG" bs=1M count=$(($(convert_size $BOOT_SIZE) / 1024 / 1024))
# Create the rootfs partition
dd if=/dev/zero of="$ROOTFS_IMG" bs=1M count=$(($(convert_size $ROOTFS_SIZE) / 1024 / 1024))

# Generate random uuid for rootfs
root_uuid=$(uuidgen)

# Format to FAT16 file system
mkfs.vfat -F 32 -n BOOT "$BOOT_IMG"
# Format to ext4 file system
mkfs.ext4 -U "${root_uuid}" -L ROOTFS "$ROOTFS_IMG"

# Mount partitions
mkdir -p ${MOUNT_POINT}/{_boot,_rootfs} 
sudo mount "$BOOT_IMG" ${MOUNT_POINT}/_boot
sudo mount "$ROOTFS_IMG" ${MOUNT_POINT}/_rootfs

# fill boot partitions
sudo cp /home/tom/project/tomos/linux-rockchip/arch/arm64/boot/Image \
    /home/tom/project/tomos/linux-rockchip/arch/arm64/boot/dts/rockchip/rk3588-blade3-v101-linux.dtb \
    ${MOUNT_POINT}/_boot

sudo mkdir -p ${MOUNT_POINT}/_boot/extlinux

sudo bash -c 'cat > '"${MOUNT_POINT}/_boot/extlinux/extlinux.conf"'' << EOF 
label rockchip-kernel6.1
        kernel /Image
        fdt /rk3588-blade3-v101-linux.dtb
        append console=ttyFIQ,1500000 root=/dev/mmcblk0p2 rw rootfstype=ext4 rootwait
        # append console=ttyFIQ,1500000 root=/dev/mmcblk0p2 rw init=/linuxrc rootfstype=ext4 rootwait
EOF

# fill rootfs partitions
# sudo cp ../busybox-1.36.1/_install/* ${MOUNT_POINT}/_rootfs -a
sudo cp $TOP_DIR/build/alpine/* ${MOUNT_POINT}/_rootfs -a

# umount _boot and _rootfs
sudo umount ${MOUNT_POINT}/_boot
sudo umount ${MOUNT_POINT}/_rootfs

# Example Copy the boot partition to the offset of the output image file 32768
dd if="$BOOT_IMG" of="$OUTPUT_IMG" bs=512 seek=32768 conv=notrunc
ls -lh "$OUTPUT_IMG"

# Crop rootfs
# truncate -s $(convert_size $(du -sh $ROOTFS_IMG)) $ROOTFS_IMG
# stat -c %s $ROOTFS_IMG
ROOT_MIN_SIZE=$(resize2fs -P $ROOTFS_IMG 2>/dev/null | grep -oP '\d+' | tail -n 1)

# shrink fs
e2fsck -f -p "$ROOTFS_IMG"
resize2fs -p "$ROOTFS_IMG" "$ROOT_MIN_SIZE"
du -sh $ROOTFS_IMG

# Merge boot and rootfs into one file
dd if="$ROOTFS_IMG" of="$OUTPUT_IMG" bs=512 seek=262144 conv=notrunc
ls -lh "$OUTPUT_IMG"

dd if=/dev/zero of=$OUTPUT_IMG bs=512 count=2048 seek=$(( $(stat -c %s $OUTPUT_IMG) / 512 ))  

# Calculating partition size
BOOT_IMG_SIZE=$(stat -c %s "$BOOT_IMG")
ROOTFS_IMG_SIZE=$(stat -c %s "$ROOTFS_IMG")

# Calculates the end location of the partition
BOOT_PARTITION_END=$((32768 + (BOOT_IMG_SIZE / 512) - 1))
ROOTFS_PARTITION_END=$((262144 + (ROOTFS_IMG_SIZE / 512) - 1))

# Print partition table
parted --script "$OUTPUT_IMG" \
mklabel gpt \
mkpart primary fat32 32768s ${BOOT_PARTITION_END}s \
mkpart primary ext4 262144s ${ROOTFS_PARTITION_END}s

parted -s firmware.img print

# Write uboot and idbloader
dd if=../u-boot/idbloader.img of="$OUTPUT_IMG" seek=64 conv=notrunc
dd if=../u-boot/uboot.itb of="$OUTPUT_IMG" seek=16384 conv=notrunc
ls -lh "$OUTPUT_IMG"
