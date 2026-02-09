# 使用方法
下载脚本 设置权限 执行
```shell
sudo wget https://raw.githubusercontent.com/xiezy1/install-sing-box/main/install.sh && \
sudo chmod +x install.sh && \
sudo ./install.sh
```

# 修改订阅地址

编辑update_subscript.sh
```shell
# 这里替换自己的订阅地址
VAR1=$(curl -s https://example.com/your-subscription-url)
```

```shell
sudo wget https://raw.githubusercontent.com/xiezy1/install-sing-box/main/setup.sh && \
sudo chmod +x setup.sh && \
sudo ./setup.sh
```

# 运行在海外机器可以加速镜像拉取
docker run -d -p 5000:5000 \
  --name registry-proxy \
  --restart always \
  -e REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io \
  registry:2

# docker-companse.yml
```yml
services:
  qinglong:
    image: whyour/qinglong:latest
    container_name: qinglong
    restart: unless-stopped
    ports:
      - 5700:5700
    volumes:
      - /root/docker/container_data/qinglong:/ql/data
      - /root/docker/container_data/telethon/tg_session.session:/ql/tg_session.session
    environment:
      - PUID=0
      - PGID=0
    extra_hosts:
      - "host.dpanel.local:host-gateway"
    logging:
      driver: "json-file"
      options:
        max-size: "5m"
        max-file: "10"
  jellyfin:
    image: jellyfin/jellyfin:latest
    container_name: jellyfin
    restart: unless-stopped
    ports:
      - 8096:8096
      - 8920:8920
    volumes:
      - /root/docker/container_data/jellyfin/config:/config
      - /root/docker/container_data/jellyfin/cache:/cache
      - /mnt/nvme/jellyfin/media:/media
    environment:
      - PUID=0
      - PGID=0
    extra_hosts:
      - "host.dpanel.local:host-gateway"
    logging:
      driver: "json-file"
      options:
        max-size: "5m"
        max-file: "10"
  navidrome:
    image: deluan/navidrome:latest
    container_name: navidrome
    restart: unless-stopped
    ports:
      - 4533:4533
    volumes:
      - /root/docker/container_data/navidrome/data:/data
      - /mnt/nvme/jellyfin/media/Music:/music
    environment:
      - PUID=0
      - PGID=0
    extra_hosts:
      - "host.dpanel.local:host-gateway"
    logging:
      driver: "json-file"
      options:
        max-size: "5m"
        max-file: "10"
  telegram:
    image: telegram_checkin:latest
    container_name: telegram_checkin_container
    restart: unless-stopped
    volumes:
      - /root/docker/container_data/telethon/tg_session.session:/app/tg_session.session
  mtabServer:
    image: itushan/mtab
    container_name: mtab_server
    ports:
      - "9200:80"
    volumes:
      - /root/docker/container_data/mtab_server:/app
    restart: unless-stopped
```