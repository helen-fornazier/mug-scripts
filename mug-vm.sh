#!/bin/bash

QEMU="kvm"
VDISK="/home/koike/caneca/collabora/qemu-images/ubuntu-14.04.4-desktop-amd64.qcow2"

$QEMU -hda $VDISK \
	-s \
	-smp 1 \
	-nographic \
	-kernel arch/x86_64/boot/bzImage \
	-append "root=/dev/sda1 debug console=ttyS0 console=ttyS1 console=tty1 drm.debug=0xff loglevel=8" \
	-net nic -net user,hostfwd=tcp::5555-:22 \
	-m 512 $@
