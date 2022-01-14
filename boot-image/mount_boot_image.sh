#!/bin/bash

if [ -n "$DEBUG" ]; then
    DEBUG=-debug
fi

sudo mkdir -p boot-mount
LOOP=$(sudo losetup -f)
sudo losetup -f boot${DEBUG}.img
sudo mount ${LOOP} boot-mount/
echo "${LOOP}" > .boot-mount

echo "boot${DEBUG}.img contents:"
sudo find boot-mount/
