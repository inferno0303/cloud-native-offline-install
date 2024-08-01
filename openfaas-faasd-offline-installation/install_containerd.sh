#!/bin/bash

# Copyright xbc8118 2024

set -e -x -o pipefail

TARGET_PATH="./containerd"

# 通用文件查找函数
find_file() {
    local pattern="$1"
    local file=$(find "$TARGET_PATH" -name "$pattern" | head -n 1)

    if [ -z "$file" ]; then
        echo -e "\033[31mCannot find file $pattern\033[0m"
        exit 1
    fi

    echo "$file"
}

# 安装containerd
CONTAINERD_FILE=$(find_file 'containerd-*-linux-amd64.tar.gz')
sudo tar -C /usr/local -xzvf "$CONTAINERD_FILE"

# 安装containerd服务，通过 systemd启动containerd
sudo mkdir -p /usr/local/lib/systemd/system
sudo cp "$TARGET_PATH"/containerd.service /usr/local/lib/systemd/system/containerd.service
sudo systemctl daemon-reload
sudo systemctl enable --now containerd

# 安装runc
sudo install -m 755 "$TARGET_PATH"/runc.amd64 /usr/local/sbin/runc

# 安装CNI plugins
CNI_FILE=$(find_file 'cni-plugins-linux-amd64-*.tgz')
sudo mkdir -p /opt/cni/bin
sudo tar -C /opt/cni/bin -xzvf "$CNI_FILE"

# 允许宿主机网络栈转发
sudo /sbin/sysctl -w net.ipv4.conf.all.forwarding=1
echo "net.ipv4.conf.all.forwarding=1" | sudo tee -a /etc/sysctl.conf

# 安装完成
echo -e "\n\033[32mSuccessfully installed containerd.\033[0m"
