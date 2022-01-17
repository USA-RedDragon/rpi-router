#!/bin/sh

# Builds binutils gold linker for LLVMgold.so plugin

set -e

if [ -n "$DEBUG" ]; then
    DEBUG=-debug
fi

COMMON_CFLAGS="-O2 -fstack-protector-strong -pie -fPIE -D_FORTIFY_SOURCE=2"
TARGET_CFLAGS="-march=armv8-a+crc -mcpu=cortex-a72 -mtune=cortex-a72"

cd packages/binutils

# AR=ar AS=as
LD="lld" CXX="ccache clang++" CFLAGS_FOR_TARGET="$COMMON_CFLAGS $TARGET_CFLAGS" CXXFLAGS_FOR_TARGET="$COMMON_CFLAGS $TARGET_CFLAGS" CFLAGS="$COMMON_CFLAGS" CC="ccache clang" CXXFLAGS="$COMMON_CFLAGS" ./configure \
    --enable-gold=default \
    --enable-plugins \
    --disable-werror \
    --enable-lto \
    --host=$LFS_HOST \
    --target=$LFS_TARGET \
    --prefix=$LFS/cross-tools \
    --with-sysroot=$LFS \
    --with-lib-path=$LFS/tools/lib \
    --disable-nls \
    --enable-threads \
    --disable-gdb \
    --disable-multilib

make -j$(nproc)
sudo make install
