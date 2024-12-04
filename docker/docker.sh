#!/bin/bash
source env.sh

if [ "$SERVER" = "docker" ]; then
	echo "Can not run in a docker"
	exit -1
fi

case $1 in
	create)
	docker run --privileged -d -v $HOST_LINUX_CODE:$CNT_LINUX_CODE \
		-v $HOST_MODULES_DIR:$CNT_MODULES -v $HOST_SHARE_DIR:$CNT_SHARE \
		--name qemu jiangjqian/qemu-0216
	;;

	build)
	docker build . -t jiangjqian/qemu
	;;

	start)
	docker start qemu
	;;

	stop)
	docker stop qemu
	;;

	*)
	docker exec -it qemu /bin/bash
	;;
esac
