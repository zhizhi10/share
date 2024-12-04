# Qemu
### run cosmos in x86 (emulated)
```
./qemu.sh x86-cosmos
```

### run raspios 32bit in x86 (emulated)
```
./qemu.sh x86-pi32
```

### run raspios 32bit in docker of m1 (emulated)
```
./qemu.sh m1-docker-pi32
```

### run raspios 32bit in m1 (emulated)
```
./qemu.sh m1-pi32
```

### run raspios 32bit in rockpro64 (emulated)
```
./qemu.sh rock-pi32
```

### run cosmos in m1 (emulated)
```
./qemu.sh m1-cosmos
```

### run raspios 64 in m1 (virtualized)
```
./qemu.sh m1-pi64-hvf
```





# Docker
We use docker to build kernel, to build busybox and to run qemu
```
#./docker.sh build          # build docker image from Dockerfile
#./docker.sh create	    # run the docker 
```
Normally, we only need start the container, enter container, and stop container
```
#./docker.sh start
#./docker.sh                # enter container
#./docker.sh stop
```



# Create initramfs
### Build Busybox
We build busybox inside the docker, especially in M1 macos machine.
Reference previous "Docker" section to enter the container.

```
cd /home/richard/share/data/busybox-1.35.0
# first time build
  make defconfig
  #then change CONFIG_STATIC=y in .config
# after first time
  make
  make install
```

### create initramfs
```
./utils.sh initramfs
```

### Test initramfs
```
./utills.sh test-initramfs
```



# Build Kernel
### For x86
Enter the container, "qemu"
/home/richard/work/knet/linux-stable/:/home/richard/linux-code --- build x86 kernel image
```
cd /home/richard/linux-code
make
```
/home/richard/work/2022/france/docker/share:/home/richard/share --- build aarch64 kernel image
```
cd /home/richard/share/linux-stable
make ARCH=arm64
or ?
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- 
```


Test the kernel,
```
./utils.sh test-kernel
```

### from LinuxKit
#### on M1
linuxkit installation and build
> git clone https://github.com/linuxkit/linuxkit.git
> cd linuxkit
> make
> sudo make install


build and pull kernel source
> linuxkit build examples/redis-os.yml

test kernel using hvf and host cpu
> ...

build kernel image 
Reference: 
linuxkit/kernel/kernels.md 
in linuxkit/docs/kernels.md, "## Modifying the kernel config" 
```
docker run --rm -ti -v $(pwd):/src linuxkit/kconfig
apk add perl
cd /linux-5.10.92
make ARCH=arm64 defconfig # or
make ARCH=arm64 oldconfig # or menuconfig
make ARCH=arm64
```

commit container as linuxkit/kconfig:v1

Later
```
docker run linuxkit/kconfig:v1
docker start zen_nash
docker attach zen_nash
cd /linux-5.10.92
make ARCH=arm64
cp arch/arm64/boot/Image.gz ../src/images/
make ARCH=arm64 modules_install INSTALL_MOD_PATH=../src/images/modules
# in pi64, restart ssh
# free for disk space
# dpkg-query -Wf '${Installed-Size}\t${Package}\n' | sort -n | tail -n 10
# 
# scp -P 5555 to pi64
```



# Utils
Used to fetch/push file from/to M1 machine.
To create initramfs

# Create a new machine on Qemu



xxxx
yyyy
