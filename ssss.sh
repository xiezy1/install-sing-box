#!/bin/bash
set -e

echo "== 停用 systemd-resolved =="
systemctl stop systemd-resolved || true
systemctl disable systemd-resolved || true


echo "== 重置 resolv.conf =="
rm -f /etc/resolv.conf
cat > /etc/resolv.conf <<EOF
nameserver 223.5.5.5
nameserver 8.8.8.8
EOF
chattr +i /etc/resolv.conf


echo "== 拉取 CoreDNS 镜像 =="
docker pull coredns/coredns:latest

echo "== 创建 CoreDNS 目录 =="
mkdir -p /opt/coredns

echo "== 写入 Corefile =="
cat > /opt/coredns/Corefile <<'EOF'
.:53 {
    # 打印日志（调试用）
    log

    # 错误日志
    errors

    # 本地域名（内网直连）
    hosts {
        192.168.66.194 music.xiezy.top
        fallthrough
    }

    # 外部域名转发
    forward . 223.5.5.5 8.8.8.8 {
        prefer_udp
    }

    # 缓存（提高性能）
    cache 30
}
EOF

echo "== 停止并删除旧的 coredns 容器（如果存在） =="
docker rm -f coredns 2>/dev/null || true

echo "== 启动 CoreDNS 容器 =="
docker run -d \
  --name coredns \
  --restart unless-stopped \
  -p 53:53/udp \
  -p 53:53/tcp \
  -v /opt/coredns/Corefile:/Corefile \
  coredns/coredns -conf /Corefile

echo "== CoreDNS 启动完成 =="
docker ps | grep coredns || true
