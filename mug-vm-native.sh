#!/bin/bash

QEMU="kvm"
VDISK="/home/koike/caneca/collabora/qemu-images/ubuntu-14.04.4-desktop-amd64.qcow2"

$QEMU -hda $VDISK \
	-cpu host \
	-net nic -net user,hostfwd=tcp::5555-:22 \
	-m 1G $@
