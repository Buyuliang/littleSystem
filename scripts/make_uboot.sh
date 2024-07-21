#! /bin/bash

make CROSS_COMPILE=aarch64-linux-gnu- rk3588_defconfig
make CROSS_COMPILE=aarch64-linux-gnu- -j16

# idbloader.img:
    tools/mkimage -n rk3588 -T rksd -d ../rkbin/bin/rk35/rk3588_ddr_lp4_2112MHz_lp5_2400MHz_v1.16.bin:spl/u-boot-spl.bin idbloader.img

# u-boot.its:
    cp ../rkbin/bin/rk35/rk3588_bl31_v1.45.elf bl31.elf
    ./arch/arm/mach-rockchip/make_fit_atf.sh u-boot.dtb > uboot.its

# u-boot.itb:
    cp ../rkbin/bin/rk35/rk3588_bl32_v1.15.bin tee.bin
    tools/mkimage -f uboot.its -E uboot.itb

# spi_flash:
#     dd if=/dev/zero of=rkspi_loader.img bs=1M count=0 seek=4
#     /sbin/parted -s rkspi_loader.img mklabel gpt
#     /sbin/parted -s rkspi_loader.img unit s mkpart idbloader 64 1023
#     /sbin/parted -s rkspi_loader.img unit s mkpart uboot 1024 7167
#     dd if=idbloader.img of=rkspi_loader.img seek=64 conv=notrunc
#     dd if=u-boot.itb of=rkspi_loader.img seek=1024 conv=notrunc