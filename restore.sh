#!/bin/bash

# 设置备份路径
BACKUP_DIR="/mnt/nvme/backup/"
MYSQL_BACKUP_FILE="$BACKUP_DIR/mysql_backup.sql"
DOCKER_BACKUP_FILE="$BACKUP_DIR/docker_backup.tar.gz"

# 恢复 Docker 数据
echo "正在恢复 Docker 数据..."
tar -xzvf $DOCKER_BACKUP_FILE -C /root/docker/
echo "Docker 数据恢复完成"

# 恢复 MySQL 数据
echo "正在恢复 MySQL 数据..."
mysql -u mtab -pmtab xzy000616 < $MYSQL_BACKUP_FILE
echo "MySQL 数据恢复完成"

# 恢复 MySQL 数据目录（如果有备份）
echo "正在恢复 MySQL 数据目录..."
cp -r $BACKUP_DIR/mysql_data $MYSQL_DATA_DIR
echo "MySQL 数据目录恢复完成"
