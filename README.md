# Live Scheduler 部署版

Live Scheduler 是面向主播和直播运营团队的节目预约、审核、直播排期、产品订单及后台管理系统。

## Docker 一键部署

要求服务器已安装 Docker 和 Docker Compose。

```bash
docker compose up -d --build
```

默认端口为 `3500`。启动后访问：

```text
http://服务器IP:3500/install
```

按照安装向导创建管理员并完成初始化。业务数据和会话密钥保存在 Docker volume `live-scheduler-data` 中，重新构建容器不会丢失。

使用其他端口，例如 `8080`：

```bash
APP_PORT=8080 docker compose up -d --build
```

## 常用命令

```bash
docker compose ps
docker compose logs -f
docker compose restart
docker compose down
```

不要执行 `docker compose down -v`，否则会删除持久化业务数据。

## 反向代理

使用 Nginx、宝塔或 CDN 时，将域名代理至 `127.0.0.1:3500`，并保留 `Host`、`X-Forwarded-Host` 和 `X-Forwarded-Proto` 请求头。

## 发布说明

本压缩包仅包含生产运行产物和部署文件，不包含 TypeScript/React 项目源码、数据库、系统配置、安装锁或会话密钥。
