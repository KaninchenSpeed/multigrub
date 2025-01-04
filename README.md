# Multigrub

Multi ISO boot with grub

## Partitioning the usb drive

GPT partition table:
- fat32 1gb
- ext4 remaining

## Install GRUB2 on the usb drive

1. Mount the usb drive to `/mnt`
2. Run `grub-install --force --removable --target=x86_64-efi --boot-directory=/mnt/boot --efi-directory=/mnt /dev/sdX` (replace `/dev/sdX` with the path of the usb drive)

## Setup the Script
1. Copy `update.sh` to the ext4 partition
2. `EFI-partition-id` with the uuid of the (fat32) efi partition of the usb drive
3. Copy iso files to the ext4 partition
4. Run `sudo ./update.sh` while in the ext4 partition (rerun this when changing the iso files)
