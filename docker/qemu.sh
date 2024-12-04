#!/bin/bash
source env.sh

case $1 in
	# ssh -p 33333 richard@192.168.100.1
	# ping does not work, but apt update work
	# ssh -p 5555 richard@localhost
	x86-x86)
	if [ "$SERVER" = "Linux" ]; then
		KERNEL_IMAGE_PATH=$HOST_LINUX_CODE/arch/x86/boot/bzImage
		#KERNEL_IMAGE_PATH=bzImage
	elif [ "$SERVER" = "docker" ]; then 
		KERNEL_IMAGE_PATH=$CNT_LINUX_CODE/arch/x86/boot/bzImage
	else
		echo "Unsupported server $SERVER"
		exit -1
	fi
	#sudo ip tuntap add mode tap user $(whoami)
	#ip tuntap show
	#sudo ip link set tap0 master virbr0
	#sudo ip link set dev virbr0 up
	#sudo ip link set dev tap0 up
	#sudo dnsmasq --interface=br0 --bind-interfaces \
	#    --dhcp-range=192.168.100.50,192.168.100.254
	#chmod 666 /dev/kvm
	qemu-system-x86_64  -smp 4 -enable-kvm -m 4G \
		-kernel $KERNEL_IMAGE_PATH -append "root=/dev/sda5 rw console=ttyS0" \
		-netdev user,id=n1,ipv6=off,hostfwd=tcp::5555-:22 -device e1000,netdev=n1 \
		-device e1000,netdev=network0 -netdev tap,id=network0,ifname=tap0 \
       		-nographic \
		-hda data/images/image.img 
	;;

	kgdb)
	KERNEL_IMAGE_PATH=$HOST_LINUX_CODE/arch/x86/boot/bzImage
	#sudo qemu-system-x86_64  -s -S -m 4G \
	#sudo qemu-system-x86_64  -smp 4 -enable-kvm -m 4G \
	sudo qemu-system-x86_64  -smp 4 -enable-kvm -m 4G \
		-kernel $KERNEL_IMAGE_PATH -append "root=/dev/sda5 rw console=ttyS0 xhci_hcd.quirks=0x120 nokaslr" \
		-netdev user,id=n1,ipv6=off,hostfwd=tcp::5555-:22 -device e1000,netdev=n1 \
		-device qemu-xhci,id=xhci \
		-device usb-host,hostbus=2,hostport=1 \
       		-nographic \
		-hda data/images/image.img
	;;
	#xhci_hcd.quirks=0x130

	x86-yocto-pi)
	/home/richard/work/knet/qemu/build/qemu-system-aarch64 \
	  -M virt,highmem=off\
	  -smp 8 \
          -m 2G \
          -cpu cortex-a72 \
	  -kernel $HOST_SHARE_DIR/linux-stable/arch/arm64/boot/Image \
	  -append "root=PARTUUID=737ed298-02 rw console=ttyAMA0 init=/bin/sh" \
	  -nographic \
	  -hda /home/richard/work/2022/yocto/poky/build/tmp/deploy/images/raspberrypi4-64/core-image-minimal-raspberrypi4-64.rpi-sdimg 
         # -hda $HOST_SHARE_DIR/data/images/2022-01-28-raspios-bullseye-arm64.0221.img
  	 ;;

	x86-openalpr)
	# network is working after "dhclient eth0"
	#network: run $dhclient eth0
	#resize image, resizef rootfs
	#qemu-img size xxx.img +4G
	#https://linuxconfig.org/how-to-resize-ext4-root-partition-live-without-umount
	# resize2fs /dev/xvdg1 

	# below service are disabled
	# sudo systemctl mask udisks2   
	# networking.service  systemd-journald.service  dhcpcd.service                
	# systemd-journal-flush.service wpa_supplicant.service        
	# rpi-eeprom-update.service     keyboard-setup.service        dphys-swapfile.service        
	# ntp.service                   apt-daily.service             hciuart.service               
	# raspi-config.service          avahi-daemon.service          triggerhappy.service          
	/home/richard/work/knet/qemu/build/qemu-system-aarch64 \
	  -M virt,highmem=off\
	  -smp 8 \
          -m 2G \
          -cpu cortex-a72 \
	  -kernel $HOST_SHARE_DIR/linux-stable/arch/arm64/boot/Image \
	  -append "root=PARTUUID=d97f5830-02 rw console=ttyAMA0" \
	  -nographic \
	  -netdev user,id=n1,ipv6=off,hostfwd=tcp::5555-:22 -device e1000,netdev=n1 \
          -hda $HOST_SHARE_DIR/data/images/2022-01-28-raspios-bullseye-arm64.0221.img
  	 ;;

	x86-raspi)
	# 2022-01-28-raspios-bullseye-arm64.0221.img
	# this can run to the desktop, network is working after "dhclient eth0"
	# below service are disabled
	# sudo systemctl mask udisks2   
	# networking.service  systemd-journald.service  dhcpcd.service                
	# systemd-journal-flush.service wpa_supplicant.service        
	# rpi-eeprom-update.service     keyboard-setup.service        dphys-swapfile.service        
	# ntp.service                   apt-daily.service             hciuart.service               
	# raspi-config.service          avahi-daemon.service          triggerhappy.service          
	# /home/richard/work/2022/yocto/poky/build/tmp/deploy/images/raspberrypi4-64/Image
	/home/richard/work/knet/qemu/build/qemu-system-aarch64 \
	  -M virt,highmem=off\
	  -smp 8 \
          -m 2G \
          -cpu cortex-a72 \
	  -kernel $HOST_SHARE_DIR/linux-stable/arch/arm64/boot/Image \
	  -append "root=PARTUUID=d97f5830-02 rw console=ttyAMA0" \
	  -serial telnet:localhost:4321,server,nowait \
  	  -monitor telnet:localhost:4322,server,nowait \
	  -device VGA,id=vga1 \
	  -device secondary-vga,id=vga2  \
    	  -device virtio-keyboard-pci \
	  -device virtio-mouse-pci \
          -hda $HOST_SHARE_DIR/data/images/2022-01-28-raspios-bullseye-arm64.0221.img
  	 ;;

	x86-cosmos)
	# Note, /usr/bin/qemu-system-aarch64 does not work well
	# Image.gz -- build in docker in m1
	#   location: /Users/m1/Documents/qj/linux/arch/arm64/boot/Image.gz
	#   config: data/images/config-5.17.0-rc2
	/home/richard/work/knet/qemu/build/qemu-system-aarch64 \
          -smp 4 -m 1G \
	  -M virt \
          -cpu cortex-a57 \
	  -kernel $HOST_SHARE_DIR/data/images/Image.gz -append "root=/dev/vda2 rw console=ttyAMA0" \
          -netdev user,id=n1,ipv6=off,hostfwd=tcp::5555-:22 -device e1000,netdev=n1 \
	  -nographic \
          -hda $HOST_SHARE_DIR/data/images/cosmos-staging-archive2.img

	;;

	x86-pi32)
	# Note, /usr/bin/qemu-system-aarch64 does not work well
	# Image.gz -- build in docker in m1
	#   location: /Users/m1/Documents/qj/linux/arch/arm64/boot/Image.gz
	#   config: data/images/config-5.17.0-rc2
	/home/richard/work/knet/qemu/build/qemu-system-aarch64 \
          -smp 4 -m 1G \
	  -M virt \
          -cpu cortex-a57 \
	  -kernel $HOST_SHARE_DIR/data/images/Image.gz -append "root=/dev/vda2 rw console=ttyAMA0" \
          -netdev user,id=n1,ipv6=off,hostfwd=tcp::5555-:22 -device e1000,netdev=n1 \
	  -nographic \
          -hda $HOST_SHARE_DIR/data/images/2021-10-30-raspios-bullseye-armhf.img
	;;


	m1-docker-pi32)
	KERNEL_IMAGE_PATH=/home/richard/linux-code/arch/arm64/boot/Image.gz
	qemu-system-aarch64  -smp 2 -M virt -m 1G \
		-cpu cortex-a53 \
		-kernel $KERNEL_IMAGE_PATH -append "root=/dev/vda2 rw console=ttyAMA0" \
		-netdev user,id=n1,ipv6=off,hostfwd=tcp::5555-:22 -device e1000,netdev=n1 \
	       	-nographic \
		-hda data/images/2021-10-30-raspios-bullseye-armhf.img
	;;

	m1-pi32)
	KERNEL_IMAGE_PATH=/Users/m1/Documents/qj/linux/arch/arm64/boot/Image.gz
	qemu-system-aarch64  -smp 2 -M virt -m 1G \
		-cpu cortex-a53 \
		-kernel $KERNEL_IMAGE_PATH -append "root=/dev/vda2 rw console=ttyAMA0" \
		-netdev user,id=n1,ipv6=off,hostfwd=tcp::5555-:22 -device e1000,netdev=n1 \
	       	-nographic \
		-hda data/images/2021-10-30-raspios-bullseye-armhf.img
	;;

	rock-pi32)
	KERNEL_IMAGE_PATH=/root/share/Image.gz
	#KERNEL_IMAGE_PATH=/Users/m1/Documents/qj/linux/arch/arm64/boot/Image.gz
	qemu-system-aarch64 -smp 2 -M virt,highmem=off -m 1G \
		-cpu cortex-a57 \
		-kernel $KERNEL_IMAGE_PATH -append "root=/dev/vda2 rw console=ttyAMA0" \
		-netdev user,id=n1,ipv6=off,hostfwd=tcp::5555-:22 -device e1000,netdev=n1 \
	       	-nographic \
		-hda data/images/2021-10-30-raspios-bullseye-armhf.img
	;;

	m1-cosmos)
	KERNEL_IMAGE_PATH=/Users/m1/Documents/qj/linux/arch/arm64/boot/Image.gz
	qemu-system-aarch64 \
	  -M virt,highmem=off \
	  -cpu cortex-a57 \
	  -m 1G \
	  -smp 4 \
	  -kernel $KERNEL_IMAGE_PATH -append "root=/dev/vda2 rw console=ttyAMA0" \
	  -nographic \
	  -netdev user,id=n1,ipv6=off,hostfwd=tcp::5555-:22 -device e1000,netdev=n1 \
	  -hda data/images/cosmos-staging-archive2.img
	;;

	m1-pi64-hvf-vnc)
	#hvf/host 64bit ok, 32 bit nok
	KERNEL_IMAGE_PATH=linuxkit/images/Image.gz
	qemu-system-aarch64 \
	  -M virt,highmem=off,accel=hvf \
	  -cpu host \
	  -m 1G \
	  -smp 4 \
	  -kernel $KERNEL_IMAGE_PATH -append "root=/dev/vda2 rw console=ttyAMA0" \
	  -netdev user,id=n1,ipv6=off,hostfwd=tcp::5555-:22 -device e1000,netdev=n1 \
	  -hda data/images/2022-01-28-raspios-bullseye-arm64.img \
	  -serial telnet:localhost:4321,server,nowait \
  	  -monitor telnet:localhost:4322,server,nowait \
	  -device virtio-gpu-pci,id=vga1 -vnc :10,display=vga1  \
    	  -device virtio-keyboard-pci \
	  -device virtio-mouse-pci \
	  -drive file=data/images/2021-10-30-raspios-bullseye-armhf.img,if=virtio

	  #-nographic \
	  # hvf will crash
	  #-device VGA,id=vga2 -vnc :1,display=vga2 \
	;;


	m1-pi64-hvf-std-vga)
	#hvf/host 64bit ok, 32 bit nok
	KERNEL_IMAGE_PATH=linuxkit/images/Image.gz
	qemu-system-aarch64 \
	  -M virt,highmem=off,accel=hvf \
	  -cpu host \
	  -m 1G \
	  -smp 4 \
	  -kernel $KERNEL_IMAGE_PATH -append "root=/dev/vda2 rw console=ttyAMA0" \
	  -netdev user,id=n1,ipv6=off,hostfwd=tcp::5555-:22 -device e1000,netdev=n1 \
	  -hda data/images/2022-01-28-raspios-bullseye-arm64.img \
	  -serial telnet:localhost:4321,server,nowait \
  	  -monitor telnet:localhost:4322,server,nowait \
    	  -device virtio-keyboard-pci \
	  -device virtio-mouse-pci \
	  -device VGA,id=vga1 \
	  -device secondary-vga,id=vga2 \
	  -drive file=data/images/2021-10-30-raspios-bullseye-armhf.img,if=virtio
	;;

	m1-pi64-hvf-virtio-vga)
	#hvf/host 64bit ok, 32 bit nok
	KERNEL_IMAGE_PATH=linuxkit/images/Image.gz
	qemu-system-aarch64 \
	  -M virt,highmem=off,accel=hvf \
	  -cpu host \
	  -m 1G \
	  -smp 4 \
	  -kernel $KERNEL_IMAGE_PATH -append "root=/dev/vda2 rw console=ttyAMA0" \
	  -netdev user,id=n1,ipv6=off,hostfwd=tcp::5555-:22 -device e1000,netdev=n1 \
	  -hda data/images/2022-01-28-raspios-bullseye-arm64.img \
	  -serial telnet:localhost:4321,server,nowait \
  	  -monitor telnet:localhost:4322,server,nowait \
    	  -device virtio-keyboard-pci \
	  -device virtio-mouse-pci \
	  -device virtio-gpu-pci,id=vga1 \
	  -drive file=data/images/2021-10-30-raspios-bullseye-armhf.img,if=virtio
	;;

	test-x86-raspi)
	/home/richard/work/knet/qemu/build/qemu-system-aarch64 \
	  -M virt,highmem=off\
	  -smp 8 \
          -m 2G \
          -cpu cortex-a72 \
	  -kernel $HOST_SHARE_DIR/linux-stable/arch/arm64/boot/Image \
	  -append "root=PARTUUID=d97f5830-02 rw console=ttyAMA0" \
	  -serial telnet:localhost:4321,server,nowait \
  	  -monitor telnet:localhost:4322,server,nowait \
	  -device VGA,id=vga1 \
	  -device secondary-vga,id=vga2  \
    	  -device virtio-keyboard-pci \
	  -device virtio-mouse-pci \
          -hda $HOST_SHARE_DIR/data/images/2022-01-28-raspios-bullseye-arm64.img
  	 ;;

	test)
	KERNEL_IMAGE_PATH=linuxkit/images/Image.gz
	qemu-system-aarch64 \
	  -M virt,highmem=off\
	  -cpu cortex-a53\
	  -m 2G \
	  -smp 4 \
	  -kernel $KERNEL_IMAGE_PATH -append "root=/dev/vda2 rw console=ttyAMA0" \
	  -netdev user,id=n1,ipv6=off,hostfwd=tcp::5555-:22 -device e1000,netdev=n1 \
	  -hda data/images/2022-01-28-raspios-bullseye-arm64.img \
	  -serial telnet:localhost:4321,server,nowait \
  	  -monitor telnet:localhost:4322,server,nowait \
	  -device VGA,id=vga2 -vnc :1,display=vga2 \
	  -drive file=data/images/2021-10-30-raspios-bullseye-armhf.img,if=virtio
	;;

	test-vga)
	KERNEL_IMAGE_PATH=linuxkit/images/Image.gz
	qemu-system-aarch64 \
	  -M virt,highmem=off,accel=hvf \
	  -cpu host \
	  -m 2G \
	  -smp 4 \
	  -kernel $KERNEL_IMAGE_PATH -append "root=/dev/vda2 rw console=ttyAMA0 vga=ask" \
	  -netdev user,id=n1,ipv6=off,hostfwd=tcp::5555-:22 -device e1000,netdev=n1 \
	  -hda data/images/2022-01-28-raspios-bullseye-arm64.img \
	  -serial telnet:localhost:4321,server,nowait \
  	  -monitor telnet:localhost:4322,server,nowait \
	  -device virtio-gpu-pci,id=vga1 -vnc :10,display=vga1  

	# 1. disable hvf, work well with VGA
	# 2. -device virtio-gpu-pci,id=vga1 -vnc :10,display=vga1  \
	# 3. hvf crash
	#-device VGA,id=vga2 -vnc :1,display=vga2 \
	#-device bochs-display,id=vga1  -vnc :1,display=vga1 
	# 4. all vga types
	#-device ati-vga,id=vga1 -vnc :1,display=vga1 \
	#-device cirrus-vga,id=vga2 -vnc :2,display=vga2 \
	#-device secondary-vga,id=vga3 -vnc :3,display=vga3 \
	#-device VGA,id=vga4 -vnc :4,display=vga4 \
	#-device vmware-svga,id=vga5 -vnc :5,display=vga5 \
	;;



	*)
		echo "Unknown command $1"
	;;
esac
