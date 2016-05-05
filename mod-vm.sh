#!/bin/bash
fim="aplay /usr/share/sounds/alsa/Front_Right.wav"
IMG="/home/koike/caneca/collabora/qemu-images/ubuntu-14.04.4-desktop-amd64.qcow2"
MNT="/mnt/qemu"

function vm_mount2 {
	sudo mount -o loop,offset=32256 $IMG $MNT
}

function vm_mount {
	sudo modprobe nbd max_part=63
	sudo qemu-nbd -c /dev/nbd0 $IMG
	sudo partprobe /dev/nbd0
	sudo mount /dev/nbd0p1 $MNT
}
function vm_umount {
	sudo umount $MNT &
	sleep 3
	sudo qemu-nbd -d /dev/nbd0
	sudo killall -q qemu-nbd
}

case "$1" in
	mount)
		vm_mount
		;;
	umount)
		vm_umount
		;;
	modules)
		vm_mount
		sudo make INSTALL_MOD_PATH=$MNT modules_install
		$fim # make some noise to warn about the password in the next sudo cmd
		sudo chroot $MNT depmod -a $(make kernelrelease)
		vm_umount
		;;
	media)
		make modules SUBDIRS=drivers/media/platform/$2
		vm_mount
		sudo make INSTALL_MOD_PATH=$MNT modules_install SUBDIRS=drivers/media/platform/$2
		$fim # make some noise to warn about the password in the next sudo cmd
		sudo chroot $MNT depmod -a $(make kernelrelease)
		vm_umount
		;;
	subdir)
		make modules SUBDIRS=$2
		vm_mount
		sudo make INSTALL_MOD_PATH=$MNT modules_install SUBDIRS=$2
		$fim # make some noise to warn about the password in the next sudo cmd
		sudo chroot $MNT depmod -a $(make kernelrelease)
		vm_umount
		;;
	*)
		echo "Usage: $0 {mount|umount|modules|media {tpg|vivid}|subdir {dir}}"
		exit 1
esac

exit 0
