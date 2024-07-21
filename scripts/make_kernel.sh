#! /bin/bash

make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- rockchip_linux_defconfig
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- rockchip_defconfig

make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- menuconfig

/home/tom/project/tomos/linux-rockchip/arch/arm64/configs/rockchip_linux_defconfig

time make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j6
time make modules modules_install ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- INSTALL_MOD_PATH=/home/tom/project/tomos/build/_rootfs
time make modules modules_install ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- INSTALL_MOD_PATH=/home/tom/project/tomos/build/alpine