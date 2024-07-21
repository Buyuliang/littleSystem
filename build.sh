#!/bin/bash

export TOP_DIR=$(dirname $(realpath $0))
echo "TOP_DIR: $TOP_DIR"

pushd build

bash $TOP_DIR/scripts/make_image.sh

popd