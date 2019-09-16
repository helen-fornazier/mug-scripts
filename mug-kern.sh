#!/bin/bash

set -eux

MNT=../mnt

if [[ ${PWD##*/} != "linux" ]]; then
	echo "ERROR: This script should be executed in a linux directory"
	exit 1
fi

case "${1-}" in
	rockpi-install)
		build=../kbuild/rockpi-4
		MNT=/home/koike/mug/nfsshare/arm64_rootfs
		make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- KBUILD_OUTPUT=$build -j9 && \
		cp $build/arch/arm64/boot/dts/rockchip/rk3399-rock-pi-4.dtb /srv/tftp/rk3399-rockpi/ && \
		cp $build/arch/arm64/boot/Image /srv/tftp/rk3399-rockpi/Image && \
		sudo make modules_install INSTALL_MOD_PATH=$MNT KBUILD_OUTPUT=$build
		;;
	samus-install)
		build=../kbuild/samus
		krelease=$(make KBUILD_OUTPUT=$build kernelrelease | grep -v directory)
		if ! mount | grep -q "$MNT"; then
			echo "Mounting samus rootfs:";
			sudo sshfs -o allow_other root@galliumos:/ "$MNT"
		fi
		make KBUILD_OUTPUT=$build -j9 && \
		make modules_install install KBUILD_OUTPUT=$build INSTALL_MOD_PATH=$MNT INSTALL_PATH=$MNT/boot && \
		ssh root@galliumos "mkinitramfs -o /boot/initrd.img-$krelease $krelease && update-grub"
		sudo umount "$MNT"
		ssh root@galliumos "sync && sleep 3 && reboot"
		echo "Grub entry $krelease"

		;;
	virtme-install)
		build=../kbuild/virtme
		make KBUILD_OUTPUT=$build -j9 && \
		make -C $build INSTALL_MOD_PATH=. modules_install
		;;
	virtme-run)
		build=../kbuild/virtme
		krelease=$(make KBUILD_OUTPUT=$build kernelrelease | grep -v directory)
		virtme-run --pwd --rwdir /tmp --kdir=$build --mdir=$build/lib/modules/$krelease
		;;
	*)
		echo "Usage: $0 {virtme-install|virtme-run|virtme-vimc-test|rockpi-install|samus-install}"
		exit 1
esac
