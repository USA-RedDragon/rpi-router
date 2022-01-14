#!/bin/bash

if [ -n "$DEBUG" ]; then
    DEBUG=-debug
fi

export KEY_FILE="../keys/private.pem"
export PUBKEY_FILE="../keys/private.pem"
export RPIBOOT_PATH="../../rpi-usbboot/"
export RPIBOOT_OUT="./out${DEBUG}.rpiboot"
rm -rf ${RPIBOOT_OUT}
mkdir -p ${RPIBOOT_OUT}
${RPIBOOT_PATH}/tools/update-pieeprom.sh -c boot${DEBUG}.conf -k "${KEY_FILE}" -p "${PUBKEY_FILE}" -o ${RPIBOOT_OUT}/pieeprom.bin $pieeprom.original.bin
# Workaround an issue in update-pieeprom.sh when placing output in different dir
mv .sig ${RPIBOOT_OUT}/pieeprom.sig
cp ../../rpi-usbboot/secure-boot-recovery/bootcode4.bin ${RPIBOOT_OUT}
