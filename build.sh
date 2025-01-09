#!/bin/bash

set -euo pipefail

# 检查至少有一个参数
if [ $# -lt 1 ]; then
    echo "Usage: $0 {uboot|kernel|ramdisk|alpine|image|image-ram|all} [board]"
    exit 1
fi

export TOP_DIR=$(dirname $(realpath $0))
echo "TOP_DIR: $TOP_DIR"
BUILD_DIR="$TOP_DIR/build"

mkdir -p $BUILD_DIR > /dev/null 2>&1

# 设置 BOARD 作为全局环境变量
export BOARD=${2:-az04}
source $TOP_DIR/packages/board/$BOARD
echo "Building for board: $BOARD"

function build_uboot() {
    echo "Building U-Boot for $BOARD..."
    pushd $BUILD_DIR
    bash $TOP_DIR/scripts/build_uboot.sh
    popd
}

function build_kernel() {
    echo "Building Kernel for $BOARD..."
    pushd $BUILD_DIR
    bash $TOP_DIR/scripts/build_kernel.sh
    popd
}

function build_alpine() {
    echo "Building Alpine Linux for $BOARD..."
    pushd $BUILD_DIR
    bash $TOP_DIR/scripts/build_alpinefs.sh
    popd
}

function build_ramdisk() {
    echo "Building Ramdisk for $BOARD..."
    pushd $BUILD_DIR
    bash $TOP_DIR/scripts/build_ramdisk.sh
    popd
}

function build_image() {
    echo "Building Image for $BOARD..."
    pushd $BUILD_DIR
    bash $TOP_DIR/scripts/build_image.sh
    popd
}

function build_ram_image() {
    echo "Building RAM Image for $BOARD..."
    pushd $BUILD_DIR
    bash $TOP_DIR/scripts/build_ramdisk_image.sh
    popd
}

function build_all() {
    echo "Building All for $BOARD..."
    build_uboot
    build_kernel
    build_alpine
    build_image
}

ARG=${1:-all}

case "$ARG" in
    uboot)
        build_uboot
        ;;
    kernel)
        build_kernel
        ;;
    ramdisk)
        build_ramdisk
        ;;
    alpine)
        build_alpine
        ;;
    image)
        build_image
        ;;
    image-ram)
        build_ram_image
        ;;
    all)
        build_all
        ;;
    *)
        echo "Invalid argument: $ARG"
        echo "Usage: $0 {uboot|kernel|ramdisk|alpine|image|image-ram|all} [board]"
        exit 1
        ;;
esac

unset BOARD