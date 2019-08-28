#!/bin/bash

# =======================================================================
# This script is deprecated
# See mug-kern.sh
# =======================================================================

set -eux

if [[ ${PWD##*/} != "linux" ]]; then
	echo "ERROR: This script should be executed in a linux directory"
	exit 1
fi

DIST=sid
IMG=../deb-${DIST}-vm.img
MNT=../deb-${DIST}-vm-mount.dir
SHARE=../vm-share.dir
KBUILD=../kbuild/vimc
KERNEL=$KBUILD/arch/x86_64/boot/bzImage

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

	sudo vmdebootstrap --verbose --image=${IMG} --size=5g --distribution=${DIST} --grub --enable-dhcp --package=${PKGS} --owner="${USER}"
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
		-m 2g -cpu host,migratable=off
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
		-append "nokaslr printk.synchronous=1 root=/dev/sda1 console=ttyS0 loglevel=15" \
		-net nic -net user,hostfwd=tcp::5555-:22 \
		-m 2g -cpu host,migratable=off
}

case "${1-}" in
	mount)
		vm_mount
		;;
	umount)
		vm_umount
		;;
	rpi-install)
		make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j9 zImage modules dtbs
		cp ./arch/arm/boot/dts/bcm2836-rpi-2-b.dtb /srv/tftp/rpi/
		cp ./arch/arm/boot/zImage /srv/tftp/rpi/
		;;
	rpi-install-sd)
		SD=/dev/mmcblk0
		MNT=rpi-mnt
		if ! mount | grep -q "$MNT"; then
			echo "Mounting rpi rootfs:";
			sudo mount ${SD}p1 ${MNT}/fat32
			sudo mount ${SD}p2 ${MNT}/ext4
		fi
		KERNEL=koike-zImage
		make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j9 zImage modules dtbs
		sudo make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_MOD_PATH=${MNT}/ext4 modules_install
		sudo cp arch/arm/boot/zImage ${MNT}/fat32/koike-zImage
		sudo cp arch/arm/boot/dts/*.dtb ${MNT}/fat32/
		sudo cp arch/arm/boot/dts/overlays/*.dtb* ${MNT}/fat32/overlays/ || true
		sudo cp arch/arm/boot/dts/overlays/README ${MNT}/fat32/overlays/ || true
		sudo umount ${MNT}/fat32
		sudo umount ${MNT}/ext4
		;;
	ficus-install)
		make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j9 && \
		cp ./arch/arm64/boot/dts/rockchip/rk3399-ficus.dtb /srv/tftp/rk3399-ficus/ && \
		cp ./arch/arm64/boot/Image /srv/tftp/rk3399-ficus/Image
		;;
	rockpi-install)
		build=../kbuild/rockpi-4
		make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- KBUILD_OUTPUT=$build -j9 && \
		cp $build/arch/arm64/boot/dts/rockchip/rk3399-rock-pi-4.dtb /srv/tftp/rk3399-rockpi/ && \
		cp $build/arch/arm64/boot/Image /srv/tftp/rk3399-rockpi/Image && \
		MNT=/home/koike/mug/nfsshare/arm64_rootfs && \
		sudo make modules_install INSTALL_MOD_PATH=$MNT KBUILD_OUTPUT=$build
		;;
	samus-install)
		build=../kbuild/samus
		MNT=board-rootfs
		KRELEASE=$(make KBUILD_OUTPUT=$build kernelrelease | grep -v directory)
		if ! mount | grep -q "$MNT"; then
			echo "Mounting samus rootfs:";
			sudo sshfs -o allow_other root@galliumos:/ "$MNT"
		fi
		make KBUILD_OUTPUT=$build -j9 && \
		make modules_install install KBUILD_OUTPUT=$build INSTALL_MOD_PATH=$MNT INSTALL_PATH=$MNT/boot && \
		ssh root@galliumos "mkinitramfs -o /boot/initrd.img-${KRELEASE} $KRELEASE && update-grub"
		sudo umount "$MNT"
		ssh root@galliumos "sync && sleep 3 && reboot"
		echo "Grub entry $KRELEASE"

		;;
	compile)
		make KBUILD_OUTPUT=${KBUILD} -j9
		;;
	install)
		make KBUILD_OUTPUT=${KBUILD} -j9
		vm_mount
		make modules_install install KBUILD_OUTPUT=${KBUILD} INSTALL_MOD_PATH=../$MNT INSTALL_PATH=../$MNT/boot
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
