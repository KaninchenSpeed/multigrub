# Multigrub

Multi ISO boot with grub

## Partitioning the usb drive

GPT partition table:
- fat32 1gb
- ext4 remaining

## Setup
1. Copy `update.sh` to the ext4 partition
2. `EFI-partition-id` with the uuid of the (fat32) efi partition of the usb drive
3. Copy iso files to the ext4 partition
4. Run `sudo ./update.sh` while in the ext4 partition
