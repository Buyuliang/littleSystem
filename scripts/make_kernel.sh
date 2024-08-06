#! /bin/bash

set -euo pipefail

KERNEL_DIR="$TOP_DIR/build/kernel"
MODULE_DIR="$TOP_DIR/build/_module"
KERNEL_PATCH_DIR="$TOP_DIR/patch/kernel"

mkdir -p $MODULE_DIR

if [ ! -d "$KERNEL_DIR" ]; then
    git clone --depth=1 https://github.com/Joshua-Riek/linux-rockchip.git -b noble $KERNEL_DIR
    # git clone --depth=1 https://github.com/armbian/linux-rockchip.git -b rk-6.1-rkr3 $KERNEL_DIR
fi

pushd $KERNEL_DIR

# if [ -d $KERNEL_PATCH_DIR ] && [ "$(ls -A $KERNEL_PATCH_DIR)" ]; then
#     for i in $KERNEL_PATCH_DIR/*; do patch -Np1 < "$i"; done
# fi

export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
time make O=build rockchip_linux_defconfig
# time make O=build Image -j$(nproc)
time make O=build rockchip/rk3588-blade3-v101-linux.dtb
# time make O=build modules modules_install INSTALL_MOD_PATH=$MODULE_DIR

# if [ -d $KERNEL_PATCH_DIR ] && [ "$(ls -A $KERNEL_PATCH_DIR)" ]; then
#     for i in $KERNEL_PATCH_DIR/*; do patch -Np1 -R < "$i"; done
# fi

pushd