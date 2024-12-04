# DAY 1
#### remote access
m1 access
> ssh m1@51.159.120.172
> echo "166CKcU5b2gj" | sudo -S mknod sda b 8 0

Rockchip board
> ssh root@10.1.152.205
> pass rockpro64

cosmos
> # user: cosmyx
> # pass: xQzjYK4s46XmwXu@9Q
> ssh -i ./id_rsa root@cosmos_ip


#### Docker in M1
Restart docker in M1

> launchctl list | grep docker
> launchctl stop application.com.docker.docker.1159275.
> open --background -a Docker

#### mount img file
> fdisk -l 2021-10-30-raspios-bullseye-armhf.img
> sector * 512
> sudo mount -o loop,offset=272629760 2021-10-30-raspios-bullseye-armhf mnt/

#### sysbench
> sysbench cpu run

#### raspberry boot time and system speed up
> systemd-analyze blame
```
sudo systemctl stop udisks2
systemctl disable udisks2
sudo systemctl mask udisks2
networking.service
systemd-journald.service
dhcpcd.service
systemd-journal-flush.service

wpa_supplicant.service
rpi-eeprom-update.service
keyboard-setup.service
dphys-swapfile.service
ntp.service
apt-daily.service
hciuart.service
raspi-config.service
avahi-daemon.service
triggerhappy.service
```


#### Remove unused packages to release space for root filesystem
> apt remove chromium-browser



# DAY 0223
#### VNC 
- vnc client: Remote Desktop Viewer
- connection: 51.159.120.172:10
- mouse mapping issue: move mouse to left and under menu item "bookmarks", this is mapped to raspberry desktop main menu


