#!/bin/bash

# 更新 apt 索引
echo "Updating apt index..."
apt update

# 安装 Sing-Box
echo "Installing Sing-Box..."
# 下载 Sing-Box 安装包 (注意替换为需要的版本和架构)
wget https://github.com/SagerNet/sing-box/releases/download/v1.12.15/sing-box_1.12.15_linux_arm64.deb -O /tmp/sing-box_1.12.15_linux_arm64.deb
apt install -y /tmp/sing-box_1.12.15_linux_arm64.deb

# 创建 Sing-Box 服务文件
echo "Creating Sing-Box service file..."
cat << EOF > /etc/systemd/system/sing-box.service
[Unit]
Description=Sing-Box Service
After=network.target

[Service]
Type=simple
# 指定用户，建议不要用 root，如果你创建了 singbox 用户可以改成 singbox
User=root
# 可选：指定工作目录
#WorkingDirectory=/etc/sing-box
# 启动命令，修改为你的配置文件路径
ExecStart=/usr/bin/sing-box -D /var/lib/sing-box -c /etc/sing-box/main_config.json run
# 失败重启策略
Restart=on-failure
RestartSec=10s
# 日志输出到 systemd journal
StandardOutput=journal
StandardError=journal
# 可选：环境变量
# Environment="ENV_VAR=value"

[Install]
WantedBy=multi-user.target
EOF

# 重新加载 systemd 配置
echo "Reloading systemd configuration..."
systemctl daemon-reload

# 设置开机自启动
echo "Enabling Sing-Box to start on boot..."
systemctl enable sing-box

# 启动 Sing-Box 服务
echo "Starting Sing-Box service..."
systemctl start sing-box

echo "Sing-Box installation and configuration completed successfully!"
