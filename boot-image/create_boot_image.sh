#!/bin/bash

if [ -n "$DEBUG" ]; then
    DEBUG=-debug
fi

KEY_FILE="../secure-boot/keys/private.pem"
RPIBOOT_PATH="../rpi-usbboot/"
DEFCONFIG="rpi_cm4_io_router_defconfig"
KERNEL="Image.gz"
INITRAMFS="initramfs.xz"
# TODO: cmdline.txt generation
CMDLINE="earlycon=pl011,mmio32,0xfe201000 console=ttyS0,115200 root=LABEL=SYSTEM rootfstype=ext4 rootwait"

# Create and copy kernel
make -C ./linux ARCH=arm64 CC=clang LLVM=1 CROSS_COMPILE=aarch64-linux-gnu- ${DEFCONFIG}
make -C ./linux ARCH=arm64 CC=clang LLVM=1 CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc) ${KERNEL} modules dtbs
make -C ./linux ARCH=arm64 CC=clang LLVM=1 CROSS_COMPILE=aarch64-linux-gnu- INSTALL_MOD_PATH=$(pwd)/bootfs MODULES_NO_SYMLINK=true modules_install

rm -rf bootfs
mkdir -p bootfs

cp -v linux/arch/arm64/boot/dts/broadcom/*.dtb* bootfs/
mkdir -p bootfs/overlays/
cp -v ../boot-image/firmware/boot/fixup* bootfs/
cp -v ../boot-image/firmware/boot/start* bootfs/
cp -v ../boot-image/firmware/boot/LICENSE.broadcom bootfs/
cp -v ../boot-image/firmware/boot/COPYING.linux bootfs/
cp -v ../boot-image/firmware/boot/overlays/*.dtb* bootfs/overlays/
cp -v ../boot-image/firmware/boot/overlays/README bootfs/overlays/

TMPFILE=$(mktemp tmp.XXXXX)
env KERNEL=${KERNEL} INITRAMFS=${INITRAMFS} CMDLINE="${CMDLINE}" envsubst < bootfs.tpl/config-kernel.txt.tpl > ${TMPFILE}
echo "${CMDLINE}" > bootfs/cmdline.txt
cat bootfs.tpl/config${DEBUG}.txt ${TMPFILE} > bootfs/config.txt
rm -f ${TMPFILE}

# Create and copy ramdisk (secondary bootloader)
TMPFILE=$(mktemp tmp.XXXXX)
# Create a 64mb ext4 ramdisk image
dd if=/dev/zero of=${TMPFILE} bs=1M count=64
LOOP=$(sudo losetup -f)
sudo mkfs.ext4 ${TMPFILE}
sudo losetup -f ${TMPFILE}
sudo rm -rf ramdisk-mount
sudo mkdir -p ramdisk-mount
sudo mount ${LOOP} ramdisk-mount/

# TODO: Place files
sudo cp -Rv ramdisk-image/* ramdisk-mount/
cp busybox-config ../busybox/.config
make -C ../busybox CROSS_COMPILE=aarch64-linux-gnu- busybox
sudo make -C ../busybox CROSS_COMPILE=aarch64-linux-gnu- CONFIG_PREFIX="$(pwd)/ramdisk-mount/" install
sudo chown -R root:root ramdisk-mount/

sudo umount ramdisk-mount
sudo rm -rf ramdisk-mount
sudo losetup -d ${LOOP}

# Compress ramdisk to xz
xz -9 -T0 -e -z -v ${TMPFILE}
mv ${TMPFILE}.xz bootfs/${INITRAMFS}

# Create boot image
sudo ${RPIBOOT_PATH}/tools/make-boot-image -b cm4 -d bootfs/ -o boot${DEBUG}.img

rm -rf bootfs

# Create signature for boot.img
${RPIBOOT_PATH}/tools/rpi-eeprom-digest -i boot${DEBUG}.img -o boot${DEBUG}.sig -k "${KEY_FILE}"
