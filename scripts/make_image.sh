#! /bin/bash

set -xeo pipefail

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
BASE_SIZE="16M"
BOOT_SIZE="100M"
ROOTFS_SIZE="500M"
START_DEV="/dev/mmcblk0"

# del last image and other file
sudo umount ${MOUNT_POINT}/_boot || true
sudo umount ${MOUNT_POINT}/_rootfs || true
rm -rf $OUTPUT_IMG $BOOT_IMG $ROOTFS_IMG $MOUNT_POINT

truncate -s $(($(convert_size $BASE_SIZE) / 1024 / 1024 + \
        $(convert_size $BOOT_SIZE) / 1024 / 1024 + \
        $(convert_size $ROOTFS_SIZE) / 1024 / 1024))M \
         "$OUTPUT_IMG"
# dd if=/dev/zero of="$OUTPUT_IMG" bs=1M count=$(($(convert_size $BASE_SIZE) / 1024 / 1024 + \
#         $(convert_size $BOOT_SIZE) / 1024 / 1024 + \
#         $(convert_size $ROOTFS_SIZE) / 1024 / 1024))

# Print partition table
parted --script "$OUTPUT_IMG" \
mklabel msdos \
mkpart primary fat32 32768s 262143s \
mkpart primary ext4 262144s 100%

LOOP_DEV=$(losetup -f --show "$OUTPUT_IMG")
BOOT_DEV="$LOOP_DEV"p1
ROOT_DEV="$LOOP_DEV"p2
partprobe "$LOOP_DEV"

# Generate random uuid for rootfs
root_uuid=$(uuidgen)

# Format to FAT16 file system
mkfs.vfat -F 32 -n BOOT "${LOOP_DEV}p1"
# Format to ext4 file system
mkfs.ext4 -U "${root_uuid}" -L ROOTFS "${LOOP_DEV}p2"

# Mount partitions
mkdir -p ${MOUNT_POINT}/{_boot,_rootfs} 
sudo mount "${LOOP_DEV}p1" ${MOUNT_POINT}/_boot
sudo mount "${LOOP_DEV}p2" ${MOUNT_POINT}/_rootfs

# fill boot partitions
sudo cp $TOP_DIR/build/kernel/build/arch/arm64/boot/Image \
    $TOP_DIR/build/kernel/build/arch/arm64/boot/dts/rockchip/rk3588-blade3-v101-linux.dtb \
    ${MOUNT_POINT}/_boot

sudo mkdir -p ${MOUNT_POINT}/_boot/extlinux

sudo bash -c 'cat > '"${MOUNT_POINT}/_boot/extlinux/extlinux.conf"'' << EOF 
label rockchip-kernel6.1
        kernel /Image
        fdt /rk3588-blade3-v101-linux.dtb
        append console=ttyFIQ,1500000 root=${START_DEV}p2 rw rootfstype=ext4 rootwait
        # append console=ttyFIQ,1500000 root=${START_DEV}p2 rw init=/linuxrc rootfstype=ext4 rootwait
EOF

cat ${MOUNT_POINT}/_boot/extlinux/extlinux.conf

# fill rootfs partitions
sudo cp $TOP_DIR/build/alpine/* ${MOUNT_POINT}/_rootfs -a

sed -i '/\/dev\/mmcblk/d' $ROOTFS_DIR/etc/fstab
echo "${START_DEV}p1	/boot	    vfat		defaults  1 0" >> $ROOTFS_DIR/etc/fstab
echo "${START_DEV}p2	/       ext4		defaults  1 0" >> $ROOTFS_DIR/etc/fstab

# umount _boot and _rootfs
sudo umount ${MOUNT_POINT}/_boot
sudo umount ${MOUNT_POINT}/_rootfs

# shrink image
ROOT_PART_START=$(parted -ms "$OUTPUT_IMG" unit B print | tail -n 1 | cut -d ':' -f 2 | tr -d 'B')
ROOT_BLOCK_SIZE=$(tune2fs -l "$ROOT_DEV" | grep '^Block size:' | tr -d ' ' | cut -d ':' -f 2)
ROOT_MIN_SIZE=$(resize2fs -P "$ROOT_DEV" 2>/dev/null | grep -oP '\d+')

# shrink fs
e2fsck -f -p "$ROOT_DEV"
resize2fs -p "$ROOT_DEV" "$ROOT_MIN_SIZE"

# shrink partition
PART_END=$((ROOT_PART_START + (ROOT_MIN_SIZE * ROOT_BLOCK_SIZE)))
parted ---pretend-input-tty "$OUTPUT_IMG" <<EOF
unit B
resizepart 2 $PART_END
yes
quit
EOF

losetup -d "$LOOP_DEV"

# truncate free space
FREE_START=$(parted -ms "$OUTPUT_IMG" unit B print free | tail -1 | cut -d ':' -f 2 | tr -d 'B')
truncate -s "$FREE_START" "$OUTPUT_IMG"

# Write uboot and idbloader
dd if=$TOP_DIR/build/uboot/build/idbloader.img of="$OUTPUT_IMG" seek=64 conv=notrunc
dd if=$TOP_DIR/build/uboot/build/uboot.itb of="$OUTPUT_IMG" seek=16384 conv=notrunc
ls -lh "$OUTPUT_IMG"
