#!/bin/bash

set -euo pipefail

export TOP_DIR=$(dirname $(realpath $0))
echo "TOP_DIR: $TOP_DIR"
BUILD_DIR="$TOP_DIR/build"

mkdir -p $BUILD_DIR > /dev/null 2>&1

pushd $BUILD_DIR

bash $TOP_DIR/scripts/make_uboot.sh
bash $TOP_DIR/scripts/make_kernel.sh
bash $TOP_DIR/scripts/make_alpinefs.sh
bash $TOP_DIR/scripts/make_image.sh

popd