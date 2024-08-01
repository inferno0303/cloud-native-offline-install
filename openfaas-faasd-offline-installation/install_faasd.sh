#!/bin/bash

# Copyright xbc8118 2024

set -e -x -o pipefail

# 安装 faas-cli 和 faasd
sudo install -m 755 ./faas-cli /usr/local/bin/
sudo install -m 755 ./faasd /usr/local/bin/

# 导入 faasd 所需的镜像到 containerd
IMAGE_PATH="./faasd_images"

# 定义一个通用函数来导入镜像
import_image() {
    local image_name="$1"
    local target_file=$(find "$IMAGE_PATH" -name "*${image_name}*.tar.gz" | head -n 1)

    if [ -z "$target_file" ]; then
        echo -e "\033[31mCannot find file *${image_name}*.tar.gz\033[0m"
        exit 1
    fi

    mkdir -p ./tmp
    tar -xzf "$target_file" -C ./tmp
    tar -cf ./tmp.tar -C ./tmp .
    sudo ctr -n openfaas image import ./tmp.tar
    rm -rf ./tmp ./tmp.tar

    echo -e "\033[32mImage ${image_name} imported successfully.\033[0m\n"
}

# 导入各个镜像
import_image "nats-streaming"
import_image "prom_prometheus"
import_image "queue-worker"
import_image "gateway"

# 清理路径变量
IMAGE_PATH=""
TARGET_FILE=""

# 执行 faasd install 命令
sudo faasd install

# 关闭调试输出

set +x

# 定义等待时间和最大重试次数
wait_time=3
max_retries=10
retry_count=0

# 循环检查"/var/lib/faasd/secrets/basic-auth-password"是否存在，如果不存在则休眠并重试
sleep $wait_time
while [ ! -f "/var/lib/faasd/secrets/basic-auth-password" ]; do
  sleep $wait_time
  retry_count=$((retry_count + 1))
  if [ $retry_count -ge $max_retries ]; then
    echo "\033[31mReached maximum retry limit. Exiting...\033[0m"
    exit 1
  fi
done

# 登录 faas-cli

sudo -E cat /var/lib/faasd/secrets/basic-auth-password | faas-cli login -s

# 打印 openfaas ui 用户名和密码

echo -e "\n\n\033[32mPlease remember your OpenFaaS UI username and password\n
username: $(sudo -E cat /var/lib/faasd/secrets/basic-auth-user)
password: $(sudo -E cat /var/lib/faasd/secrets/basic-auth-password)\033[0m\n\n"

# 打印安装成功提示
echo -e "\033[32mSuccessfully installed OpenFaaS-faasd.\033[0m"