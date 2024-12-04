#!/bin/bash
# Server can be,
# - Linux --- My laptop
# - docker --- inside a container
# - Darwin --- M1
SERVER=`uname`

M1_SHARE=/Users/m1/Documents/qj/docker/share

# in My ubuntu laptop
if [ "$SERVER" = "Linux" ]; then
M1_SSH=m1@51.159.120.172
HOST_SHARE_DIR=/home/richard/work/2022/france/docker/share
HOST_LINUX_CODE=/home/richard/work/knet/linux-stable/
HOST_MODULES_DIR=/home/richard/work/knet/modulesinstallretail/
else
HOST_SHARE_DIR=$M1_SHARE
HOST_LINUX_CODE=/Users/m1/Documents/qj/linux/
HOST_MODULES_DIR=/Users/m1/Documents/qj/busybox-1.35.0/
fi

CNT_SHARE=/home/richard/share
CNT_LINUX_CODE=/home/richard/linux-code
CNT_MODULES=/lib/modules

CNT_BUSYBOX=$CNT_SHARE/data/busybox-1.35.0/
CNT_INITRAMFS=$CNT_SHARE/data/initramfs/


#if inside docker checkenv in docker, else if in env
if [ -f "/.dockerenv" ]; then
	SERVER="docker"
	for dir in $CNT_SHARE $CNT_LINUX_CODE $CNT_MODULES
	do
		if [ ! -d "$dir" ]; then
			echo "$dir is not a directory"
			exit -1
		fi
	done
else
	for dir in $HOST_SHARE_DIR $HOST_LINUX_CODE
	do
		if [ ! -d "$dir" ]; then
			echo "$dir is not a directory"
			exit -1
		fi
	done
fi

echo Host is $SERVER

