#!/bin/bash

set -e

if [ -n "$DEBUG" ]; then
    DEBUG=-debug
fi

KEY_FILE="../secure-boot/keys/private.pem"
RPIBOOT_PATH="../rpi-usbboot/"
DEFCONFIG="rpi_cm4_io_router_defconfig"
KERNEL="Image.gz"
INITRAMFS="initramfs.xz"

if [ -n "$DEBUG" ]; then
    CMDLINE="earlycon=uart8250,mmio32,0xfe215040 8250.nr_uarts=1 console=ttyS0,115200"
else
    CMDLINE=""
fi

# Create and copy kernel
KBUILD_BUILD_TIMESTAMP='' make -C ./linux ARCH=arm64 CC="ccache clang" LLVM=1 CROSS_COMPILE=aarch64-linux-gnu- ${DEFCONFIG}
KBUILD_BUILD_TIMESTAMP='' make -C ./linux ARCH=arm64 CC="ccache clang" LLVM=1 CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc) ${KERNEL} modules dtbs
KBUILD_BUILD_TIMESTAMP='' make -C ./linux ARCH=arm64 CC="ccache clang" LLVM=1 CROSS_COMPILE=aarch64-linux-gnu- INSTALL_MOD_PATH=$(pwd)/bootfs MODULES_NO_SYMLINK=true modules_install

rm -rf bootfs
mkdir -p bootfs

cp -v linux/arch/arm64/boot/${KERNEL} bootfs/
mkdir -p bootfs/overlays
cp -v linux/arch/arm64/boot/dts/overlays/*.dtbo bootfs/overlays
cp -v linux/arch/arm64/boot/dts/overlays/README bootfs/overlays
cp -v linux/arch/arm64/boot/dts/broadcom/*.dtb* bootfs/
cp -v firmware/boot/fixup* bootfs/
cp -v firmware/boot/start* bootfs/
cp -v firmware/boot/LICENCE.broadcom bootfs/LICENSE.broadcom
cp -v linux/COPYING bootfs/COPYING.linux

TMPFILE=$(mktemp tmp.XXXXX)
env KERNEL=${KERNEL} INITRAMFS=${INITRAMFS} envsubst < bootfs.tpl/config-kernel.txt.tpl > ${TMPFILE}
echo "${CMDLINE}" > bootfs/cmdline.txt
cat bootfs.tpl/config${DEBUG}.txt ${TMPFILE} > bootfs/config.txt
rm -f ${TMPFILE}

# Create and copy ramdisk (secondary bootloader)
TMPDIR=$(mktemp -d tmp.XXXXX)

# Place files
mkdir -p ${TMPDIR}/{config,bin,boot,data,dev,run,sys,proc,usr/{bin,lib,sbin},sbin,var,tmp}
cp -Rv ramdisk-image/* ${TMPDIR}/

# Busybox
cp busybox-config ../busybox/.config
make -C ../busybox CC="ccache aarch64-linux-gnu-gcc" CROSS_COMPILE=aarch64-linux-gnu- busybox
make -C ../busybox CC="ccache aarch64-linux-gnu-gcc" CROSS_COMPILE=aarch64-linux-gnu- CONFIG_PREFIX="$(pwd)/${TMPDIR}" install

# Compress ramdisk to xz
cd ${TMPDIR}
sudo find . 2>/dev/null | sudo cpio -o -H newc -R root:root | xz -9 -T0 -e --check=crc32 > ../bootfs/${INITRAMFS}
cd -
sudo rm -rf ${TMPDIR}

# Create boot image
sudo ${RPIBOOT_PATH}/tools/make-boot-image -b cm4 -d bootfs/ -o boot${DEBUG}.img

rm -rf bootfs

# Create signature for boot.img
${RPIBOOT_PATH}/tools/rpi-eeprom-digest -i boot${DEBUG}.img -o boot${DEBUG}.sig -k "${KEY_FILE}"
