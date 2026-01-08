#!/bin/bash

# 设置备份路径
BACKUP_DIR="/mnt/nvme/backup/"
MYSQL_BACKUP_FILE="$BACKUP_DIR/mysql_backup.sql"
DOCKER_BACKUP_FILE="$BACKUP_DIR/docker_backup.tar.gz"
IMAGE_PATH="/mnt/nvme/docker-images/export_image.tar"

# 创建备份目录
mkdir -p $BACKUP_DIR

# 备份 Docker 数据
echo "正在备份 Docker 数据..."
tar -czvf $DOCKER_BACKUP_FILE -C /root docker/
echo "Docker 数据备份完成：$DOCKER_BACKUP_FILE"

# 备份 Docker 镜像
echo "正在导出 Docker 镜像..."
docker save -o "$IMAGE_PATH" $(docker images -q)
echo "Docker 镜像导出完成：$IMAGE_PATH"

# 备份 MySQL 数据
echo "正在备份 MySQL 数据..."
mysqldump -u mtab -pmtab xzy000616 mtab > $MYSQL_BACKUP_FILE
echo "MySQL 数据备份完成：$MYSQL_BACKUP_FILE"