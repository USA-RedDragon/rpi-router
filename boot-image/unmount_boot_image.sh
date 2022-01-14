#!/bin/bash

sudo umount boot-mount
sudo losetup -d $(cat .boot-mount)
rm .boot-mount
sudo rmdir boot-mount
