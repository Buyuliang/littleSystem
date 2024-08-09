#!/bin/bash

set -euo pipefail

export TOP_DIR=$(dirname $(realpath $0))
echo "TOP_DIR: $TOP_DIR"
BUILD_DIR="$TOP_DIR/build"

mkdir -p $BUILD_DIR > /dev/null 2>&1

function build_uboot() {
    echo "Building U-Boot..."
    pushd $BUILD_DIR
    bash $TOP_DIR/scripts/build_uboot.sh
    popd
}

function build_kernel() {
    echo "Building Kernel..."
    pushd $BUILD_DIR
    bash $TOP_DIR/scripts/build_kernel.sh
    popd
}

function build_alpine() {
    echo "Building Alpine Linux..."
    pushd $BUILD_DIR
    bash $TOP_DIR/scripts/build_alpinefs.sh
    popd
}

function build_ramdisk() {
    echo "Building Ramdisk..."
    pushd $BUILD_DIR
    bash $TOP_DIR/scripts/build_ramdisk.sh
    popd
}

function build_image() {
    echo "Building Image..."
    pushd $BUILD_DIR
    bash $TOP_DIR/scripts/build_image.sh
    popd
}

function build_all() {
    echo "Building All..."
    # build_uboot
    # build_kernel
    # build_alpine
    build_image
}

ARG=${1:-all}

case "$1" in
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
    all|*)
        build_all
        ;;
    *)
        echo "Invalid argument: $ARG"
        echo "Usage: $0 {uboot|kernel|ramdisk|alpine|image|all}"
        exit 1
        ;;
esac
