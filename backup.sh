#!/bin/bash

# 设置备份路径
BACKUP_DIR="/mnt/nvme/backup/"
MYSQL_BACKUP_FILE="$BACKUP_DIR/mysql_backup.sql"
DOCKER_BACKUP_FILE="$BACKUP_DIR/docker_backup.tar.gz"

# 创建备份目录
mkdir -p $BACKUP_DIR

# 备份 Docker 数据
echo "正在备份 Docker 数据..."
tar -czvf $DOCKER_BACKUP_FILE -C /root docker/
echo "Docker 数据备份完成：$DOCKER_BACKUP_FILE"

# 备份 MySQL 数据
echo "正在备份 MySQL 数据..."
mysqldump -u mtab -pmtab xzy000616 mtab > $MYSQL_BACKUP_FILE
echo "MySQL 数据备份完成：$MYSQL_BACKUP_FILE"