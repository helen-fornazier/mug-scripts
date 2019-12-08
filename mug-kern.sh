#!/bin/bash

set -eux

MNT=/tmp/mnt

if [[ ${PWD##*/} != "linux" ]]; then
	echo "ERROR: This script should be executed in a linux directory"
	exit 1
fi

case "${1-}" in
	rpi3-install)
		# rpi3 b+ bcm2837-rpi-3-b-plus.dts
		build=../kbuild/rpi3
		KERNEL=pipoca.zImage
		DTB=bcm2837-rpi-3-b-plus.dtb
		#SD=/dev/mmcblk0
		SD=/dev/sda
		MNT=/tmp/rpi-mnt
		BOOT=$MNT/boot
		ROOTFS=$MNT/rootfs

		mkdir -p $BOOT
		mkdir -p $ROOTFS
		if ! mount | grep -q "$MNT"; then
			#sudo umount ${SD}p1 || true
			#sudo umount ${SD}p2 || true
			sudo umount ${SD}1 || true
			sudo umount ${SD}2 || true
			echo "Mounting rpi rootfs:"
			#sudo mount ${SD}p1 $BOOT
			#sudo mount ${SD}p2 $ROOTFS
			sudo mount ${SD}1 $BOOT
			sudo mount ${SD}2 $ROOTFS
		fi

		make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- KBUILD_OUTPUT=$build -j9 zImage modules dtbs && \
		sudo cp $build/arch/arm/boot/zImage $BOOT/$KERNEL && \
		sudo cp $build/arch/arm/boot/dts/$DTB $BOOT/ && \
		sudo make -C $build modules_install INSTALL_MOD_PATH=$ROOTFS

		#sudo cp $build/arch/arm/boot/dts/overlays/*.dtb* ${BOOT}/overlays/ || true
		#sudo cp $build/arch/arm/boot/dts/overlays/README ${BOOT}/overlays/ || true

		# Do this only once
		if ! grep -q "kernel=" $BOOT/config.txt; then
			echo "kernel=$KERNEL" | sudo tee -a $BOOT/config.txt
		fi

		if ! grep -q "device_tree=" $BOOT/config.txt; then
			echo "device_tree=$DTB" | sudo tee -a $BOOT/config.txt
		fi

		sudo grep "kernel=" $BOOT/config.txt
		sudo grep "device_tree=" $BOOT/config.txt

		#sudo umount ${SD}p1
		#sudo umount ${SD}p2
		sudo umount ${SD}1
		sudo umount ${SD}2
		;;
	rockpi-install)
		build=../kbuild/rockpi-4
		MNT=/home/koike/mug/nfsshare/arm64_rootfs
		make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- KBUILD_OUTPUT=$build -j9 && \
		cp $build/arch/arm64/boot/dts/rockchip/rk3399-rock-pi-4.dtb /srv/tftp/rk3399-rockpi/ && \
		cp $build/arch/arm64/boot/Image /srv/tftp/rk3399-rockpi/Image && \
		sudo make -C $build modules_install INSTALL_MOD_PATH=$MNT
		;;
	samus-install)
		build=../kbuild/samus
		if ! mount | grep -q "$MNT"; then
			echo "Mounting samus rootfs:";
			mkdir -p $MNT
			sudo sshfs -o allow_other root@galliumos:/ "$MNT"
		fi
		make KBUILD_OUTPUT=$build -j9 && \
		make -C $build modules_install install INSTALL_MOD_PATH=$MNT INSTALL_PATH=$MNT/boot && \
		krelease=$(make KBUILD_OUTPUT=$build kernelrelease | grep -v directory) && \
		ssh root@galliumos "mkinitramfs -o /boot/initrd.img-$krelease $krelease && update-grub" && \
		sudo umount "$MNT" && \
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
		virtme-run --pwd --rwdir /tmp --kdir=$build --mdir=$build/lib/modules/$krelease --qemu-opts -m 2G -smp 2
		;;
	virtme-test-media)
		shift
		rm -rf /tmp/virtme-scripts
		mkdir /tmp/virtme-scripts
		cat >/tmp/virtme-scripts/test.sh <<-EOF
			set -x
			export PATH=.:/usr/local/bin:\$PATH
			echo running test-media $@
			/home/koike/mug/git/v4l-utils/contrib/test/test-media $@
			echo o >/proc/sysrq-trigger
		EOF
		chmod +x /tmp/virtme-scripts/test.sh

		build=../kbuild/virtme
		krelease=$(make KBUILD_OUTPUT=$build kernelrelease | grep -v directory)
		virtme_args="--pwd --rwdir /tmp --kdir=$build --mdir=$build/lib/modules/$krelease --qemu-opts -m 2G -smp 2"
		if echo $@ |grep -q -v kmemleak ; then
			virtme_args="-a kmemleak=off $virtme_args"
		fi

		virtme-run --script-dir /tmp/virtme-scripts $virtme_args | tee virtme.log
		;;
	*)
		echo "Usage: $0 {virtme-install|virtme-run|virtme-test-media|rockpi-install|samus-install|rpi3-install}"
		exit 1
esac
