#!/bin/bash
set -euo pipefail
set -x

qemu=../hypervisor/qemu/opt/qemu/bin/qemu-system-x86_64
KCMD="ip=192.168.20.2::192.168.20.1:255.255.255.0:::off:128.83.120.181:: \
earlyprintk=ttyS0 console=ttyS0 root=/dev/vda"

$qemu \
   -M microvm,x-option-roms=off,pit=off,pic=off,rtc=off \
   -bios ../hypervisor/qemu/opt/qemu/share/kata-qemu/qemu/bios-microvm.bin \
   -enable-kvm -cpu host -m 2304m -smp 2 \
   -kernel output/vmlinux -append "$KCMD" \
   -serial stdio \
   -nodefaults -no-user-config -nographic \
   -drive id=image,file=output/image.ext4,format=raw,if=none \
   -device virtio-blk-device,drive=image \
   -netdev tap,id=l_tap0,script=no,downscript=no \
   -device virtio-net-device,netdev=l_tap0
