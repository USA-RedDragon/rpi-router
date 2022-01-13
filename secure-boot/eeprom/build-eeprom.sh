#!/bin/bash

export KEY_FILE="../keys/private.pem"

../../rpi-usbboot/tools/update-pieeprom.sh -k "${KEY_FILE}"
