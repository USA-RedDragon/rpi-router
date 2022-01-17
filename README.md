# RPI-Router OS

A POC router OS for RPI CM4 + The DFRobot Router Board

This is a POC, but a predecessor of this appliance has been running in my network for about a year. <https://github.com/USA-RedDragon/charch>

## Objectives

- Utilize a Raspberry PI CM4 and a DFRobot Router board as an internet gateway. The typical setup is modem on eth0, and lan out to eth1.
- Optional WIFI access point (not yet implemented). The hardware will work, just don't expect a the same performance as a dedicated WiFi access point.
- Secure boot to avoid the loading of unsigned kernels
- DM-Verity to ensure the validity of the system
- Provide an automatic delta update of the system
- Routing appliances are a solved problem, I don't want to reinvent the wheel, just make it shinier.
- Provide VPN connections either from external to internal LAN, or from LAN with the VPN as a gateway (tunneling).
- Minimize the amount of custom code I add, and build all dependencies from source, with CI pushing new builds as soon as the upstream dependencies release updates.
- Provide a recursive DNS resolver with caching and ad blocking via AdGuard Home.
- Make IPv6 support a first-class citizen.
- Provide a backup mechanism.
- Dynamic Firewall (for NAT reflection) <https://github.com/USA-RedDragon/redwall>

## Technology in this repo

- `boot-image` - Tools and templates used to make the FAT32 `boot.img` with the items typically contained within the `boot` partition, and `boot.sig` for secure boot. This `boot.img` should be placed on a FAT32 partition within the EMMC.
  - `firmware` - The upstream <https://github.com/raspberrypi/firmware/tree/stable> for boot binaries.
  - `linux` - The Linux kernel. This project utilizes the latest upstream kernel with a few defconfig changes for this project. See <https://github.com/USA-RedDragon/linux> for more details.
  - `bootfs.tpl` - Contains templates for boot.img filesystem contents. The .tpl files are parsed with `envsubst` in `create_boot_image.sh`.
  - `ramdisk-image` - Contains a secondary stage bootloader with the goal of managing a "bootloader" unlock of sorts, setting up dm-verity, selinux, and passing control to userspace.
- `rpi-usbboot` - The upstream <https://github.com/raspberrypi/usbboot> for the scripts and binaries
- `secure-boot` - Contains eeprom programming in order to support secure boot and locking down for potentially future shipping units.
  - `eeprom` - Contains eeprom programming and configuration
  - `keys` - Contains secure boot keys. Generate your own in the PEM format :)
  - `lockdown` - Burns the eeprom with `program_pubkey` and `revoke_devkey`, and `program_jtag_lock`. Only use this if you want to lock the bootloader
- `system` - Contains the actual system components, including packages
  - `build-scripts` - Contains the scripts used to build various components of the OS
    - `stage1` - Scripts pertaining to building a toolchain appropriate for cross-compiling the rest of the OS
    - `stage2` - Scripts pertaining to using the stage1 toolchain to build OS packages

## Security Enhancments

- Hardened kernel configuration
- Almost always up to date with upstream bug and security fixes
- SELinux access restrictions
- No ability to disable secure boot after the fact (you as the device owner are not locked out, and may unlock your device to run boot images)
- EEPROM reprogramming is only available to a system daemon used for updates, Alternatively, users may keep EEPROM completely write protected and update eeprom manually.
- AppArmour
- LoadPin, a kernel option only allowing kernel modules from the same filesystem (the signed boot.img in this case)

## Parition Layout

The `eeprom` is programmed with secure boot and some hardware configuration. The `emmc` contains 3 partitions:

1. Data - A FAT32 filesystem containing persistent data and user configuration. Backups are taken of this partition.
2. Boot - A FAT32 filesystem with the `boot.img` and `boot.sig`. They contain the kernel, cmdline, config.txt, the boot binaries, and the secondary bootloader.
3. System - An EXT4 filesystem with the main system image. System updates are delta diffs of this filesystem.

## Building

Note: If you want to build the debuggable version with kernel console via uart on GPIO pins, run `export DEBUG=true` in your shell before running any scripts.

### Required Host Software

- cmake
- ninja
- xz-utils
- clang
- ccache

1. The `eeprom` must be programmed. This can be done by building the `eeprom` image like so:

   - Build the `eeprom` image:

       ```bash
         cd secure-boot/eeprom/
         ./build-eeprom.sh
       ```

   - This will build an `out.rpiboot` folder in which `flash-eeprom.sh` will read. Follow its instructions to flash the EEPROM.

2. The `boot.img` and `boot.sig` must be placed onto the `emmc` on the boot partition]

   - Build the `boot.img` and `boot.sig` images:

       ```bash
         cd boot-image
         ./create_boot_image.sh
       ```

   - This will build the `boot.img` and `boot.sig`. These will need to be placed in the `emmc` FAT32 boot partition.

3. The `system.img` must be placed onto the `emmc` system partition.

   - Build the `system.img.xz` image:

       ```bash
         cd system
         ./create-system-image.sh
       ```

   - This will build the `system.img.xz`. This will need to be flashed in the `emmc`. It contains an ext4 system partition.
