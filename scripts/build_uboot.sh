#! /bin/bash

set -euo pipefail

RKBIN_DIR="$TOP_DIR/build/rkbin"
UBOOT_DIR="$TOP_DIR/build/uboot"
UBOOT_BUILD_DIR="$UBOOT_DIR/build"
UBOOT_PATCH_DIR="$TOP_DIR/patch/uboot/$BOARD"
RKBIN_COMMIT_ID="a2a0b89b6c8c612dca5ed9ed8a68db8a07f68bc0"
UBOOT_COMMIT_ID="63c55618fbdc36333db4cf12f7d6a28f0a178017"
if [ ! -d "$RKBIN_DIR" ]; then
    git clone --depth=1 https://github.com/rockchip-linux/rkbin.git -b master $RKBIN_DIR
    pushd $RKBIN_DIR
    git fetch --depth 1 origin $RKBIN_COMMIT_ID
    git checkout $RKBIN_COMMIT_ID
    popd
fi

if [ ! -d "$UBOOT_DIR" ]; then
    git clone --depth=1 https://github.com/rockchip-linux/u-boot.git -b next-dev $UBOOT_DIR
    pushd $UBOOT_DIR
    git fetch --depth 1 origin $UBOOT_COMMIT_ID
    git checkout $UBOOT_COMMIT_ID
    popd
fi

pushd $UBOOT_DIR

if [ -d $UBOOT_PATCH_DIR ] && [ "$(ls -A $UBOOT_PATCH_DIR)" ]; then
    for i in $UBOOT_PATCH_DIR/*; do patch -Np1 < "$i"; done
fi

export ARCH=arm CROSS_COMPILE=aarch64-linux-gnu-
time make O=$UBOOT_BUILD_DIR rk3588_defconfig
time make O=$UBOOT_BUILD_DIR -j$(nproc)

pushd $UBOOT_BUILD_DIR
# idbloader.img:
$UBOOT_BUILD_DIR/tools/mkimage -n rk3588 -T rksd -d $RKBIN_DIR/bin/rk35/rk3588_ddr_lp4_2112MHz_lp5_2400MHz_v1.22.bin:$UBOOT_BUILD_DIR/spl/u-boot-spl.bin $UBOOT_BUILD_DIR/idbloader.img

# u-boot.its:
cp $RKBIN_DIR/bin/rk35/rk3588_bl31_v1.45.elf $UBOOT_BUILD_DIR/bl31.elf
cp -rf $UBOOT_DIR/arch/arm/mach-rockchip/* $UBOOT_BUILD_DIR/arch/arm/mach-rockchip
export srctree=$UBOOT_BUILD_DIR; \
    $UBOOT_BUILD_DIR/arch/arm/mach-rockchip/make_fit_atf.sh $UBOOT_BUILD_DIR/u-boot.dtb > $UBOOT_BUILD_DIR/uboot.its; \
    unset srctree

# u-boot.itb:
cp $RKBIN_DIR/bin/rk35/rk3588_bl32_v1.15.bin $UBOOT_BUILD_DIR/tee.bin
$UBOOT_BUILD_DIR/tools/mkimage -f $UBOOT_BUILD_DIR/uboot.its -E $UBOOT_BUILD_DIR/uboot.itb

cp $UBOOT_BUILD_DIR/idbloader.img  $UBOOT_BUILD_DIR/uboot.itb $OUTPUT_DIR
popd

if [ -d $UBOOT_PATCH_DIR ] && [ "$(ls -A $UBOOT_PATCH_DIR)" ]; then
    for i in $UBOOT_PATCH_DIR/*; do patch -Np1 -R < "$i"; done
fi

popd

pushd $OUTPUT_DIR
# 1. 创建固定大小的空白文件
dd if=/dev/zero of=u-boot-rockchip.bin bs=1k count=$((0x4000))

# 2. 写入 idbloader.img（从 0 位置开始）
dd if=idbloader.img of=u-boot-rockchip.bin bs=1k seek=0 conv=notrunc

# 3. 写入 uboot.itb（确保从 0x4000 - 0x40 处开始）
dd if=uboot.itb of=u-boot-rockchip.bin bs=1k seek=$((0x4000 - 0x40)) conv=notrunc

popd
