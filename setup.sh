#!/bin/bash
set -euo pipefail

# 设置代理
export http_proxy="http://192.168.66.181:10808"
export https_proxy="http://192.168.66.181:10808"

# 挂载分区
echo "== 准备挂载 NTFS 分区: /dev/nvme0n1p1 -> /mnt/nvme =="
DEV="/dev/nvme0n1p1"
MOUNT_POINT="/mnt/nvme"
FS_TYPE="exfat"

# 检查设备
if [ ! -b "$DEV" ]; then
    echo "Device not found: $DEV"
    exit 1
fi

# 获取 UUID
UUID=$(blkid -s UUID -o value "$DEV")

if [ -z "$UUID" ]; then
    echo "Cannot get UUID"
    exit 1
fi

# 创建挂载目录
mkdir -p "$MOUNT_POINT"

# 删除旧配置
sed -i "\|$MOUNT_POINT|d" /etc/fstab
sed -i "\|$UUID|d" /etc/fstab

# 写入 fstab
echo "UUID=$UUID  $MOUNT_POINT  $FS_TYPE  defaults,nofail  0  0" >> /etc/fstab

# 重载 systemd
systemctl daemon-reload

# 测试挂载
umount "$MOUNT_POINT" 2>/dev/null
mount -a

# 显示结果
df -h | grep "$MOUNT_POINT" && echo "Mount OK"
echo "挂载完成。"

# 安装 Samba 和 cifs-utils
echo "== 安装 Samba 和 cifs-utils =="
sudo -E apt update
sudo -E apt install -y samba cifs-utils git

# 设置 Samba 用户密码
echo "设置 Samba 密码..."
sudo -E smbpasswd -a root

# 修改 Samba 配置文件
echo "修改 Samba 配置文件..."
cat << EOF | sudo -E tee /etc/samba/smb.conf > /dev/null
[nvme_share]
   path = /mnt/nvme
   valid users = root
   read only = no
   browsable = yes
   guest ok = no
   force user = root
   force group = root
EOF

# 启动并设置 Samba 服务自启动
echo "启用并启动 Samba 服务..."
sudo -E systemctl enable smbd
sudo -E systemctl start smbd
echo "Samba 配置完成。"

# 安装 MySQL
echo "== 安装 MySQL =="
sudo -E apt install default-mysql-server -y

# 检查是否成功安装
if [ $? -ne 0 ]; then
    echo "MySQL 安装失败"
    exit 1
fi

# 修改 MySQL 配置文件，允许远程连接
echo "修改 MySQL 配置文件，允许远程连接..."
sudo -E sed -i "s/^bind-address\s*=.*$/bind-address = 0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf

# 启动 MySQL 服务
sudo -E systemctl enable mysql
sudo -E systemctl start mysql

echo "MySQL 服务已启动"

# 等待 MySQL 服务完全启动
sleep 3

# 进入数据库以及创建数据库和用户
echo "创建数据库和用户..."

mysql << EOF
CREATE DATABASE IF NOT EXISTS mtab DEFAULT CHARACTER SET utf8mb4;
CREATE USER IF NOT EXISTS 'mtab'@'%' IDENTIFIED BY 'xzy000616';
GRANT ALL PRIVILEGES ON mtab.* TO 'mtab'@'%';
CREATE DATABASE IF NOT EXISTS dylives DEFAULT CHARACTER SET utf8mb4;
CREATE USER IF NOT EXISTS 'dylives'@'%' IDENTIFIED BY 'xzy000616';
GRANT ALL PRIVILEGES ON dylives.* TO 'dylives'@'%';
FLUSH PRIVILEGES;
EOF

if [ $? -eq 0 ]; then
    echo "数据库和用户创建成功"
else
    echo "数据库和用户创建失败"
    exit 1
fi

echo "MySQL 安装完成。"

# 安装 Docker
echo "== 安装 Docker =="
sudo -E apt update || { echo "Error: apt update failed"; exit 1; }
sudo -E apt upgrade -y || { echo "Error: apt upgrade failed"; exit 1; }

sudo -E apt install -y apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release || \
  { echo "Error: Failed to install dependencies"; exit 1; }

curl -fsSL https://download.docker.com/linux/debian/gpg | sudo -E gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg || \
  { echo "Error: Failed to add Docker GPG key"; exit 1; }

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | \
  sudo -E tee /etc/apt/sources.list.d/docker.list > /dev/null || \
  { echo "Error: Failed to add Docker repository"; exit 1; }

sudo -E apt update || { echo "Error: apt update failed"; exit 1; }
sudo -E apt install -y docker-ce docker-ce-cli containerd.io || \
  { echo "Error: Failed to install Docker"; exit 1; }

sudo -E systemctl enable docker || { echo "Error: Failed to enable Docker"; exit 1; }
sudo -E systemctl start docker || { echo "Error: Failed to start Docker"; exit 1; }

sudo -E apt install -y docker-compose-plugin || \
  { echo "Error: Failed to install docker-compose-plugin"; exit 1; }

# 配置 Docker 镜像加速
if [ ! -d "/etc/docker" ]; then
    echo "/etc/docker 不存在，正在创建..."
    sudo -E mkdir -p /etc/docker
    echo "创建完成。"
fi

sudo -E tee /etc/docker/daemon.json > /dev/null << 'EOF'
{
    "registry-mirrors": ["http://43.130.45.49:5000"]
}
EOF
sudo -E systemctl daemon-reload || { echo "Error: Failed to reload systemd daemon"; exit 1; }
sudo -E systemctl restart docker || { echo "Error: Failed to restart Docker"; exit 1; }

echo "Docker 安装完成。"
