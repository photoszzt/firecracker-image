#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

TMPFS_ROOT=/tmp/initramfs_build
BUSYBOX_URL=https://www.busybox.net/downloads/binaries/1.31.0-defconfig-multiarch-musl/busybox-x86_64

rm -rf $TMPFS_ROOT
mkdir -p $TMPFS_ROOT
cp $SCRIPT_DIR/init_script $TMPFS_ROOT/init

mkdir -p $TMPFS_ROOT/rootfs

cd $TMPFS_ROOT/rootfs
mkdir -p bin dev etc lib mnt proc sbin sys tmp var

wget $BUSYBOX_URL
mv busybox-x86_64 bin/busybox
chmod +x bin/busybox

ln -s /bin/busybox bin/sh
ln -s /bin/busybox bin/mount
ln -s /bin/busybox bin/mkdir
ln -s /bin/busybox bin/switch_root
ln -s /bin/busybox bin/umount

cp ../init .
chmod +x init

find . | cpio -ov --format=newc | gzip -9 >../initramfz
cd -

cp $TMPFS_ROOT/initramfz /var/local/$USER/.linux-img/base/initramfz
rm -rf $TMPFS_ROOT
