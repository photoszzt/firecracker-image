#!/bin/bash
set -ex

rm -rf /output/*

cp /linux-$KERNEL_SOURCE_VERSION/vmlinux /output/vmlinux
cp /linux-$KERNEL_SOURCE_VERSION/.config /output/config

wget https://raw.githubusercontent.com/alpinelinux/alpine-make-rootfs/v0.5.1/alpine-make-rootfs \
    && echo 'a7159f17b01ad5a06419b83ea3ca9bbe7d3f8c03  alpine-make-rootfs' | sha1sum -c \
    || exit 1
chmod +x alpine-make-rootfs
./alpine-make-rootfs \
  --branch v3.13 \
  --packages 'openrc util-linux' \
  --timezone 'America/Chicago' \
  --script-chroot \
    rootfs-$(date +%Y%m%d).tar.gz - <<'SHELL'
    ln -s agetty /etc/init.d/agetty.ttyS0
    echo ttyS0 > /etc/securetty
    echo 'nameserver 1.1.1.1' > /etc/resolv.conf
    rc-update add agetty.ttyS0 default
    rc-update add devfs boot
    rc-update add procfs boot
    rc-update add sysfs boot
SHELL

apk add e2fsprogs
truncate -s 2G /output/image.ext4
mkfs.ext4 /output/image.ext4

mount /output/image.ext4 /rootfs
tar xzvf rootfs-$(date +%Y%m%d).tar.gz -C /rootfs
umount /rootfs || true
