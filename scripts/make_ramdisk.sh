#! /bin/bash

### make ramdisk
### busybox 生成 _install 文件夹
# 1、修改 添加一些目录

mkdir dev etc mnt proc var tmp sys root lib

# 2、Custom profile

# 1）/etc/inittab

cat > etc/inittab <<EOF 
::sysinit:/etc/init.d/rcS
# Stuff to do when restarting the init process
::restart:/sbin/init
# Stuff to do before rebooting
::ctrlaltdel:/sbin/reboot
::shutdown:/bin/umount -a -r
::shutdown:/sbin/swapoff -a
EOF

# 2) /etc/fstab

cat > etc/fstab <<EOF 
#device         mount-point     type    options         dump    fsck    order
proc            /proc           proc    defaults        0       0
sysfs           /sys            sysfs   defaults        0       0
tmpfs           /dev            tmpfs   defaults        0       0
EOF

# 3) /etc/profile

cat > etc/profile <<EOF  
#!/bin/sh
export HOSTNAME=tom
export USER=root
export HOME=root
export PS1="[\${USER}@\${HOSTNAME} \\W]\\# "
PATH=/bin:/sbin:/usr/bin:/usr/sbin
LD_LIBARAY_PATH=/lib:usr/lib:\$LD_LIBARAY_PATH
export PATH LD_LIBRARY_PATH
EOF

# 4) /etc/init.d/rcS

# ...... loading ......

### package ramdisk

dd if=/dev/zero of=ramdisk bs=1k count=8192
mkfs.ext2 -F ramdisk
sudo mkdir -p /mnt/initrd
sudo mount -t ext2 ramdisk /mnt/initrd
sudo cp ../busybox-1.36.1/_install/* /mnt/initrd/ -a
sudo umount /mnt/initrd
gzip --best -c ramdisk > ramdisk.gz
mkimage -n "ramdisk" -A arm -O linux -T ramdisk -C gzip -d ramdisk.gz ramdisk.img

### alpine rootfs
# 1、apk add openrc

# 2、/etc/inittab
