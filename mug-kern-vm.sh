#!/bin/bash

set -eux

if [[ ${PWD##*/} != "linux" ]]; then
	echo "ERROR: This script should be executed in a linux directory"
	exit 1
fi

DIST=sid
IMG=../deb-${DIST}-vm.img
MNT=../deb-${DIST}-vm-mount.dir
SHARE=../vm-share.dir
KERNEL=arch/x86_64/boot/bzImage

# PACKAGES TO INCLUDE IN THE IMG
# Base configuration
PKGS=openssh-server,xauth,xwayland
# Dev tools
PKGS=${PKGS},git,vim
# v4l-utils build dependencies
PKGS=${PKGS},dh-autoreconf,autotools-dev,doxygen,gettext,graphviz,libasound2-dev,libtool,libjpeg-dev,qtbase5-dev,libudev-dev,libx11-dev,pkg-config,udev,qt5-default

function vm_mount {
	if [[ ! -d ${MNT} ]]; then
		echo "Creating folder ${MNT} to mount the image when required"
		mkdir ${MNT}
	fi
	guestmount -a ${IMG} -i ${MNT}
	echo "$IMG mounted at ${MNT}"
}

function vm_umount {
	guestunmount ${MNT}
	echo "$IMG umounted from ${MNT}"
}

function create_img {
	if [[ -f ${IMG} ]]; then
		echo "${IMG} already exists, nothing to do"
		exit 1
	fi

	sudo vmdebootstrap --verbose --image=${IMG} --size=5g --distribution=${DIST} --grub --enable-dhcp --package=${PKGS} --owner=$USER
}

function config_img {
	vm_mount

	# Add host folder to mount automatically
	if [[ ! -d ${SHARE} ]]; then
		echo "Creating folder ${SHARE} to share files with the guest"
		mkdir ${SHARE}
		echo "This is a shared folder between the host and guest" > ${SHARE}/README
	fi
	echo "host-code /root/host 9p trans=virtio 0 0" >> ${MNT}/etc/fstab

	# Add ssh key
	if [[ ! -f ~/.ssh/kern-vm-key ]]; then
		ssh-keygen -t rsa -N "" -f ~/.ssh/kern-vm-key -C root
	fi
	mkdir ${MNT}/root/.ssh
	cat ~/.ssh/kern-vm-key.pub >> ${MNT}/root/.ssh/authorized_keys

	# Enable X forward
	touch ${MNT}/root/.Xauthority

	vm_umount
}

function vm_launch_native {
	# Launch VM with the kernel it is already installed
	kvm -hda $IMG \
		-fsdev local,id=fs1,path=${SHARE},security_model=none \
		-device virtio-9p-pci,fsdev=fs1,mount_tag=host-code \
		-net nic -net user,hostfwd=tcp::5555-:22 \
		-m 2g
}

function vm_launch {
	# Launch VM with custom kernel
	kvm -hda $IMG \
		-fsdev local,id=fs1,path=${SHARE},security_model=none \
		-device virtio-9p-pci,fsdev=fs1,mount_tag=host-code \
		-s \
		-smp 1 \
		-nographic \
		-kernel ${KERNEL} \
		-append "root=/dev/sda1 console=ttyS0" \
		-net nic -net user,hostfwd=tcp::5555-:22 \
		-m 2g
}

case "${1-}" in
	mount)
		vm_mount
		;;
	umount)
		vm_umount
		;;
	install)
		vm_mount
		make modules_install install INSTALL_MOD_PATH=$MNT INSTALL_PATH=$MNT/boot
		vm_umount
		;;
	launch)
		vm_launch
		;;
	launch-native)
		vm_launch_native
		;;
	create-img)
		create_img
		config_img
		;;
	*)
		echo "Usage: $0 {mount|umount|install|launch|launch-native|create-img}"
		echo "Requirements: libguestfs-tools kvm vmdebootstrap"
		exit 1
esac
