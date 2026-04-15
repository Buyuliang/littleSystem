#! /bin/bash

set -euo pipefail

ROOTFS_PAK="ubuntu.tar.gz"
ROOTFS_DIR="$TOP_DIR/build/ubuntu"
MODULE_DIR="$TOP_DIR/build/_module"
PACKAGES_DIR="$TOP_DIR/packages/ubuntu"

if [ ! -f "$ROOTFS_PAK" ]; then
    wget -O "$ROOTFS_PAK" https://cdimage.ubuntu.com/ubuntu-base/releases/focal/release/ubuntu-base-20.04.5-base-arm64.tar.gz
fi

if [ ! -d "$ROOTFS_DIR" ] || [ -z "$(ls -A "$ROOTFS_DIR" 2>/dev/null || true)" ]; then
    rm -rf "$ROOTFS_DIR"
    mkdir -p "$ROOTFS_DIR"
    tar -xvf "$ROOTFS_PAK" -C "$ROOTFS_DIR"
fi

sudo mkdir -p "$ROOTFS_DIR/etc"
echo "nameserver 192.168.202.12" | sudo tee "$ROOTFS_DIR/etc/resolv.conf" > /dev/null
sudo sed -i 's|http://ports.ubuntu.com/ubuntu-ports/|http://mirrors.aliyun.com/ubuntu-ports/|g' "$ROOTFS_DIR/etc/apt/sources.list"
sudo mkdir -p "$ROOTFS_DIR/tmp" "$ROOTFS_DIR/dev/pts" "$ROOTFS_DIR/proc" "$ROOTFS_DIR/sys" "$ROOTFS_DIR/run"
sudo chmod 1777 "$ROOTFS_DIR/tmp"

sudo chroot "$ROOTFS_DIR" /bin/bash -c "DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y sudo iproute2 net-tools curl wget coreutils vim less udev pciutils parted ca-certificates dbus systemd systemd-sysv v4l-utils ffmpeg openssh-server"
sudo chroot "$ROOTFS_DIR" /bin/bash -c "id -u tom >/dev/null 2>&1 || useradd -m -s /bin/bash tom"
printf 'tom:tom\n' | sudo chroot "$ROOTFS_DIR" chpasswd
printf 'root:root\n' | sudo chroot "$ROOTFS_DIR" chpasswd
sudo chroot "$ROOTFS_DIR" /bin/bash -c "mkdir -p /root/.ssh && chmod 700 /root && chown root:root /root && chmod 700 /root/.ssh && chown root:root /root/.ssh"

sudo mkdir -p "$ROOTFS_DIR/etc/systemd/network"
sudo bash -c "cat > '$ROOTFS_DIR/etc/systemd/network/20-eth0.network'" <<'EOF'
[Match]
Name=eth0

[Network]
DHCP=yes
EOF

sudo mkdir -p \
    "$ROOTFS_DIR/etc/systemd/system/multi-user.target.wants" \
    "$ROOTFS_DIR/etc/systemd/system/sysinit.target.wants"
sudo ln -sf /lib/systemd/system/systemd-networkd.service \
    "$ROOTFS_DIR/etc/systemd/system/multi-user.target.wants/systemd-networkd.service"

sudo mkdir -p \
    "$ROOTFS_DIR/etc/systemd/system/getty.target.wants" \
    "$ROOTFS_DIR/etc/systemd/system/serial-getty@ttyFIQ0.service.d"
sudo ln -sf /lib/systemd/system/serial-getty@.service \
    "$ROOTFS_DIR/etc/systemd/system/getty.target.wants/serial-getty@ttyFIQ0.service"
sudo bash -c "cat > '$ROOTFS_DIR/etc/systemd/system/serial-getty@ttyFIQ0.service.d/autologin.conf'" <<'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --keep-baud 1500000,115200,57600,38400 ttyFIQ0 vt220
EOF

sudo mkdir -p "$ROOTFS_DIR/etc/ssh"
sudo bash -c "cat >> '$ROOTFS_DIR/etc/ssh/sshd_config'" <<'EOF'

# codex defaults
PermitRootLogin yes
PubkeyAuthentication yes
PasswordAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys .ssh/authorized_keys2
EOF

sudo mkdir -p "$ROOTFS_DIR/etc/systemd/system/multi-user.target.wants"
sudo ln -sf /lib/systemd/system/ssh.service \
    "$ROOTFS_DIR/etc/systemd/system/multi-user.target.wants/ssh.service"

sudo mkdir -p "$ROOTFS_DIR/usr/local/sbin" "$ROOTFS_DIR/var/lib/firstboot-grow-root" "$ROOTFS_DIR/etc/systemd/system" "$PACKAGES_DIR"
sudo install -m 755 "$PACKAGES_DIR/firstboot-grow-root.sh" "$ROOTFS_DIR/usr/local/sbin/firstboot-grow-root.sh"
sudo install -m 644 "$PACKAGES_DIR/firstboot-grow-root.service" "$ROOTFS_DIR/etc/systemd/system/firstboot-grow-root.service"
sudo ln -sf /etc/systemd/system/firstboot-grow-root.service "$ROOTFS_DIR/etc/systemd/system/multi-user.target.wants/firstboot-grow-root.service"