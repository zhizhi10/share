#!/bin/bash
source env.sh

case $1 in
	# fetch a file from M1 share
	fetch)
	if [ -z "$2" ]; then
		echo "Please specify the file to fetch"
		exit -1
	fi
	if [ "$SERVER" = "Linux" ]; then
		if [ $2 = "git" ]; then
			scp $M1_SSH:$M1_SHARE/.gitignore \
			    $M1_SSH:$M1_SHARE/README.md \
			    $M1_SSH:$M1_SHARE/qemu.sh \
			    $M1_SSH:$M1_SHARE/docker.sh \
			    $M1_SSH:$M1_SHARE/env.sh \
			    $M1_SSH:$M1_SHARE/init \
			    ./
		else
			scp $M1_SSH:$M1_SHARE/$2 ./
		fi
	else
		echo "This command should be excuted in My Laptop"
	fi
	;;

	# push a file to M1 share
	push)
	if [ -z "$2" ]; then
		echo "Please specify the file to push"
		exit -1
	fi
	if [ "$SERVER" = "Linux" ]; then
		scp $2 $M1_SSH:$M1_SHARE/
	else
		echo "This command should be excuted in My Laptop"
	fi
	;;

	initramfs)
	if [ ! "$SERVER" = "docker" ]; then
		echo "Can only run in a container"
		exit -1
	fi

	if [ ! -d "$CNT_BUSYBOX/_install" ]; then
		echo "$CNT_BUSYBOX/_install is not a directory"
		exit -1
	fi

	if [ ! -d "$CNT_INITRAMFS" ]; then
		echo "$CNT_INITRAMFS is not a directory"
		exit -1
	fi
	rm -rf $CNT_INITRAMFS
	mkdir -p $CNT_INITRAMFS/{bin,dev,etc,home,mnt,proc,sys,usr}	
	cp -ar $CNT_BUSYBOX/_install/bin $CNT_INITRAMFS/ >/dev/null 2>&1
	cp -ar $CNT_BUSYBOX/_install/sbin $CNT_INITRAMFS/>/dev/null 2>&1
	cp -ar $CNT_BUSYBOX/_install/usr $CNT_INITRAMFS/>/dev/null 2>&1
	cp -a $CNT_BUSYBOX/_install/linuxrc $CNT_INITRAMFS/
	cp $CNT_SHARE/init $CNT_INITRAMFS/
	cd $CNT_INITRAMFS
	find . -print0 | cpio --null -ov --format=newc > ../initramfs.cpio
	gzip -f ../initramfs.cpio
	;;

	test-initramfs)
	if [ "$SERVER" = "Linux" ]; then
		KERNEL_IMAGE_PATH=$HOST_LINUX_CODE/arch/x86/boot/bzImage
		sudo chmod 666 /dev/kvm
		qemu-system-x86_64  -smp 4 -enable-kvm -m 4G \
			-kernel $KERNEL_IMAGE_PATH -append "root=/dev/sda5 rw console=ttyS0" \
			-netdev user,id=n1,ipv6=off,hostfwd=tcp::5555-:22 -device e1000,netdev=n1 \
			-initrd $HOST_SHARE_DIR/data/initramfs.cpio.gz \
	       		-nographic \
			-hda data/images/image.img
	else
		KERNEL_IMAGE_PATH=linuxkit/images/Image-5.10.92-qj
		qemu-system-aarch64 \
		  -M virt,highmem=off,accel=hvf \
		  -cpu host \
		  -m 1G \
		  -smp 4 \
		  -nographic \
		  -kernel $KERNEL_IMAGE_PATH -append "root=/dev/vda2 rw console=ttyAMA0" \
		  -netdev user,id=n1,ipv6=off,hostfwd=tcp::5555-:22 -device e1000,netdev=n1 \
		  -initrd $HOST_SHARE_DIR/data/initramfs.cpio.gz 

	fi
	;;

	test-kernel)
	if [ "$SERVER" = "Linux" ]; then
		KERNEL_IMAGE_PATH=$HOST_LINUX_CODE/arch/x86/boot/bzImage
		sudo chmod 666 /dev/kvm
		qemu-system-x86_64  -smp 4 -enable-kvm -m 4G \
			-kernel $KERNEL_IMAGE_PATH -append "root=/dev/sda5 rw console=ttyS0" \
			-netdev user,id=n1,ipv6=off,hostfwd=tcp::5555-:22 -device e1000,netdev=n1 \
			-initrd $HOST_SHARE_DIR/data/initramfs.cpio.gz \
	       		-nographic \
			-hda data/images/image.img
	else
		KERNEL_IMAGE_PATH=linuxkit/images/Image-5.10.92-qj
		qemu-system-aarch64 \
		  -M virt,highmem=off,accel=hvf \
		  -cpu host \
		  -m 1G \
		  -smp 4 \
		  -nographic \
		  -kernel $KERNEL_IMAGE_PATH -append "root=/dev/vda2 rw console=ttyAMA0" \
		  -netdev user,id=n1,ipv6=off,hostfwd=tcp::5555-:22 -device e1000,netdev=n1 \
		  -hda data/images/2022-01-28-raspios-bullseye-arm64.img 
	fi
	;;

	img)
	qemu-img convert -f qcow2 -O raw /home/richard/data/qemu-cmdline/generic.qcow2 $HOST_SHARE/image.img
	;;

	*)
	echo "Unknow command"
	;;
esac
