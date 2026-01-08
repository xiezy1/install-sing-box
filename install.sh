#!/bin/bash
export http_proxy="http://192.168.66.181:10808" 
export https_proxy="http://192.168.66.181:10808"
# 更新 apt 索引
echo "Updating apt index..."
sudo -E apt update

# 安装 Sing-Box
echo "Installing Sing-Box..."
# 下载 Sing-Box 安装包 (注意替换为需要的版本和架构)
sudo -E wget https://github.com/SagerNet/sing-box/releases/download/v1.12.15/sing-box_1.12.15_linux_arm64.deb -O /tmp/sing-box_1.12.15_linux_arm64.deb
sudo -E apt install -y /tmp/sing-box_1.12.15_linux_arm64.deb

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

# 创建必要的目录
echo "Creating necessary directories..."
mkdir -p /etc/sing-box/baseconfig
mkdir -p /etc/sing-box/subscript

# 下载baseconfig和订阅核心文件
echo "Downloading baseconfig and subscription core files..."
sudo -E wget https://raw.githubusercontent.com/xiezy1/install-sing-box/main/base.json -O /etc/sing-box/baseconfig/base.json
sudo -E wget https://raw.githubusercontent.com/xiezy1/install-sing-box/main/ggggg.js -O /etc/sing-box/ggggg.js
sudo -E wget https://raw.githubusercontent.com/xiezy1/install-sing-box/main/update_subscript.sh -O /etc/sing-box/update_subscript.sh

# 赋予执行权限
echo "Setting execute permissions..."
chmod +x /etc/sing-box/update_subscript.sh

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
