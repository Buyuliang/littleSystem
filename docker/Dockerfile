# 使用 Ubuntu 22.04 作为基础镜像
FROM ubuntu:22.04

# 设置时区为 UTC (如果需要，可以更改为其他时区)
ENV TZ=UTC

# 更新包列表并安装常用工具
RUN apt update && apt purge needrestart -y && apt upgrade -y && \
        apt install -y sudo build-essential gcc-aarch64-linux-gnu bison \
        qemu-user-static qemu-system-arm qemu-efi u-boot-tools binfmt-support \
        debootstrap flex libssl-dev bc rsync kmod cpio xz-utils fakeroot parted \
        udev dosfstools uuid-runtime git-lfs device-tree-compiler python2 python3 \
        python-is-python3 fdisk bc debhelper python3-pyelftools python3-setuptools \
        python3-distutils python3-pkg-resources swig libfdt-dev libpython3-dev dctrl-tools

# 为 sudo 组添加不需要密码的权限
RUN echo '%sudo ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# 设置工作目录
WORKDIR /workspace

# 设置一个默认的命令 (可根据需求调整)
CMD ["bash"]
