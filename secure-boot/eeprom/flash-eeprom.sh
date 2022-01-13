#!/bin/bash

press_to_continue() {
  echo
  echo "${1}"
  echo
  echo "Press any key to continue"
  while [ true ] ; do
    read -t 3 -n 1
    if [ $? = 0 ] ; then
      return
    fi
  done
}

echo "Ensuring rpiboot is built"
make -C ../../rpi-usbboot/ >/dev/null

# Set nRPIBOOT jumper and remove EEPROM WP protection
press_to_continue "Power off the Pi, set nRPIBOOT, and remove EEPROM Write Protection"
../../rpi-usbboot/rpiboot -d .
