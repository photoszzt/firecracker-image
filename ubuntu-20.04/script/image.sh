#! /bin/bash
set -ex

rm -rf /output/*

cp /root/linux-$KERNEL_SOURCE_VERSION/vmlinux /output/vmlinux
cp /root/linux-$KERNEL_SOURCE_VERSION/.config /output/config

truncate -s 2G /output/image.ext4
mkfs.ext4 /output/image.ext4

mount /output/image.ext4 /rootfs
debootstrap --include python3 focal /rootfs http://archive.ubuntu.com/ubuntu/
mount --bind / /rootfs/mnt

chroot /rootfs /bin/bash /mnt/script/provision.sh

umount /rootfs/mnt || true
umount /rootfs || true
