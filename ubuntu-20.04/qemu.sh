#!/bin/bash
set -euo pipefail
set -x

qemu=../hypervisor/qemu/opt/qemu/bin/qemu-system-x86_64
KCMD="ip=192.168.20.2::192.168.20.1:255.255.255.0:::off:128.83.120.181:: \
systemd.mask=systemd-networkd.service systemd.mask=systemd-networkd.socket \
systemd.mask=systemd-resolved.service systemd.mask=systemd-journald.service \
systemd.mask=systemd-journald.socket systemd.mask=systemd-journal-flush.service \
systemd.mask=systemd-journald-dev-log.socket systemd.mask=systemd-udevd.service \
systemd.mask=systemd-udevd.socket systemd.mask=systemd-udev-trigger.service \
systemd.mask=systemd-udevd-kernel.socket systemd.mask=systemd-udevd-control.socket \
systemd.mask=systemd-timesyncd.service systemd.mask=systemd-update-utmp.service \
systemd.mask=systemd-tmpfiles-setup.service systemd.mask=systemd-tmpfiles-cleanup.service \
systemd.mask=systemd-tmpfiles-cleanup.timer systemd.mask=systemd-random-seed.service \
systemd.mask=systemd-coredump@.service systemd.mask=modprobe@drm.service \
systemd.mask=systemd-logind.service systemd.mask=e2scrub_reap.service \
systemd.unit=getty@ttyS0.service earlyprintk=ttyS0 console=ttyS0 nomodules panic=1 reboot=k pci=off \
i8042.noaux i8042.nomux i8042.nopnp i8042.dumbkbd root=/dev/vda"

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
