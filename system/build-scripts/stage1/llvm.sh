#!/bin/bash

set -e

BUILD_TYPE=Release
ENABLE_ASSERTIONS=OFF

if [ -n "$DEBUG" ]; then
    DEBUG=-debug
    BUILD_TYPE=Debug
    ENABLE_ASSERTIONS=ON
fi

cd packages/llvm

mkdir -p build
cd build

CXX=clang++ CC=clang cmake -G Ninja \
    -DLLVM_ENABLE_PROJECTS='clang;libcxx;libcxxabi;compiler-rt;lld' \
    -DCMAKE_INSTALL_PREFIX=$LFS/tools \
    -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
    -DLLVM_ENABLE_ASSERTIONS=$ENABLE_ASSERTIONS \
    -DLLVM_ENABLE_LTO=ON \
    -DLLVM_CCACHE_BUILD=ON \
    -DCMAKE_CROSSCOMPILING=ON \
    -DLLVM_DEFAULT_TARGET_TRIPLE=aarch64-linux-gnu \
    -DLLVM_TARGET_ARCH=AArch64 \
    -DLLVM_TARGETS_TO_BUILD=AArch64 \
    -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=AArch64 \
    ../llvm

# Build
cmake --build .

# Test
cmake --build . --target check-all

# Install
cmake --build . --target install
