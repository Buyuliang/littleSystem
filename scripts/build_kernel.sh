#! /bin/bash

set -euo pipefail

source $TOP_DIR/scripts/apply_patch.sh

KERNEL_DIR="$TOP_DIR/build/kernel"
MODULE_DIR="$TOP_DIR/build/_module"
KERNEL_PATCH_DIR="$TOP_DIR/patch/kernel/$BOARD"

# 默认 Kernel 版本
KERNEL_VERSION=${KERNEL_VERSION:-6.1}

# 使用关联数组存储版本、仓库和分支
declare -A REPOS=(
    [6.1]="https://github.com/Joshua-Riek/linux-rockchip.git"
    [5.10]="https://github.com/Buyuliang/linux-rockchip.git"
)
declare -A BRANCHES=(
    [6.1]="noble"
    [5.10]="master"
)

# 检查 KERNEL_VERSION 是否支持
if [[ -z "${REPOS[$KERNEL_VERSION]}" || -z "${BRANCHES[$KERNEL_VERSION]}" ]]; then
    echo "错误：不支持的 KERNEL_VERSION: $KERNEL_VERSION"
    exit 1
fi

# 获取对应的仓库和分支
REPO=${REPOS[$KERNEL_VERSION]}
BRANCH=${BRANCHES[$KERNEL_VERSION]}

mkdir -p $MODULE_DIR

# 补丁列表文件名
SERIES_FILE="$KERNEL_PATCH_DIR/$KERNEL_VERSION/series"
SERIES_FLAG=1

# 检查 series 文件是否存在
if [[ ! -f "$SERIES_FILE" ]]; then
    echo "Error: $SERIES_FILE not found! No patches will be applied or reversed."
    SERIES_FLAG=0
fi

if [ ! -d "$KERNEL_DIR" ]; then
    git clone --depth=1 $REPO -b $BRANCH $KERNEL_DIR
fi

pushd $KERNEL_DIR

if [ -d $KERNEL_PATCH_DIR/$KERNEL_VERSION ] && [ "$(ls -A $KERNEL_PATCH_DIR/$KERNEL_VERSION)" ] && [ $SERIES_FLAG ]; then
    apply_patches "$SERIES_FILE" "$KERNEL_PATCH_DIR/$KERNEL_VERSION"
fi

export ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-
time make O=build $BOARD_CONFIG
time make O=build Image -j$(nproc)
time make O=build $BOARD_DTS_FILE
time make O=build -j$(nproc) modules
time make O=build -j$(nproc) modules_install INSTALL_MOD_PATH=$MODULE_DIR

if [ -d $KERNEL_PATCH_DIR/$KERNEL_VERSION ] && [ "$(ls -A $KERNEL_PATCH_DIR/$KERNEL_VERSION)" ] && [ $SERIES_FLAG ]; then
    reverse_patches "$SERIES_FILE" "$KERNEL_PATCH_DIR/$KERNEL_VERSION"
fi

pushd
