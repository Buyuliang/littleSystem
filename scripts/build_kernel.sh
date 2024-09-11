#! /bin/bash

set -euo pipefail

KERNEL_DIR="$TOP_DIR/build/kernel"
MODULE_DIR="$TOP_DIR/build/_module"
KERNEL_PATCH_DIR="$TOP_DIR/patch/kernel/$BOARD"
KERNEL_VERSION=6.1
mkdir -p $MODULE_DIR

if [ ! -d "$KERNEL_DIR" ]; then
    # git clone --depth=1 https://github.com/Buyuliang/linux-rockchip.git -b master $KERNEL_DIR
    git clone --depth=1 https://github.com/Joshua-Riek/linux-rockchip.git -b noble $KERNEL_DIR
    # git clone --depth=1 https://github.com/armbian/linux-rockchip.git -b rk-6.1-rkr3 $KERNEL_DIR
fi

pushd $KERNEL_DIR

if [ -d $KERNEL_PATCH_DIR/$KERNEL_VERSION ] && [ "$(ls -A $KERNEL_PATCH_DIR/$KERNEL_VERSION)" ]; then
    for i in $KERNEL_PATCH_DIR/$KERNEL_VERSION/*; do patch -Np1 < "$i"; done
fi

export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
time make O=build $BOARD_CONFIG
time make O=build Image -j$(nproc)
time make O=build $BOARD_DTS_FILE
time make O=build modules modules_install INSTALL_MOD_PATH=$MODULE_DIR

if [ -d $KERNEL_PATCH_DIR/$KERNEL_VERSION ] && [ "$(ls -A $KERNEL_PATCH_DIR/$KERNEL_VERSION)" ]; then
    for i in $KERNEL_PATCH_DIR/$KERNEL_VERSION/*; do patch -Np1 -R < "$i"; done
fi

pushd
