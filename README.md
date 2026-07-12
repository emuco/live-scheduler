# Live Scheduler v1.1.0

Live Scheduler 是一套面向主播、直播团队和小型内容运营团队的预约与排期管理系统。它将产品展示、用户注册、余额下单、节目审核、直播排期、邮件通知和运营后台集中在一个系统中。

## 本版本功能

- 用户名或邮箱注册、登录和密码找回
- 可选的注册邮箱验证码
- 产品管理、140 字产品说明、余额下单和订单记录
- 节目预约、审核、拖拽排期、双击编辑和自动排期
- 下单成功与排期通过邮件通知
- 公告、用户、缓存、Redis、系统日志和操作日志管理
- SQLite 本地持久化，可选 Redis 缓存
- `/install` 图形化安装向导
- Docker Compose 一键部署

## 环境要求

- Linux x86_64 或 ARM64 服务器
- Docker 24 或更高版本
- Docker Compose v2
- 首次构建时能够访问 npm 软件源

检查环境：

```bash
docker --version
docker compose version
```

## 首次部署

### 1. 下载代码

从 GitHub 主分支部署：

```bash
git clone https://github.com/emuco/live-scheduler.git
cd live-scheduler
```

也可以从 Releases 下载压缩包：

```bash
tar -xzf live-scheduler-docker-v1.1.0.tar.gz
cd live-scheduler
```

### 2. 启动

```bash
docker compose up -d --build
```

默认端口为 `3500`。如需使用其他端口：

```bash
APP_PORT=8080 docker compose up -d --build
```

### 3. 完成安装

浏览器打开：

```text
http://服务器IP:3500/install
```

按照向导填写站点名称并创建管理员。安装完成后 `/install` 会自动锁定。

## 更新已有版本

业务数据保存在 Docker volume `live-scheduler-data` 中，更新容器不会清空数据。

更新前查看容器和 volume：

```bash
docker compose ps
docker volume ls | grep live-scheduler
```

从 GitHub 主分支更新：

```bash
git pull
docker compose down
docker compose up -d --build
```

使用新版压缩包更新时，将新版文件解压到新目录，再执行：

```bash
docker compose down
docker compose up -d --build
```

只要继续使用 `live-scheduler-data` volume，原数据库、配置、安装状态和会话密钥都会保留。系统启动时会自动执行兼容迁移。

> 不要执行 `docker compose down -v`，该命令会删除业务数据 volume。

## 宝塔面板部署

1. 在宝塔安装 Docker 管理器和 Nginx。
2. 将项目放在 `/www/wwwroot/live-scheduler`。
3. 在项目目录执行 `docker compose up -d --build`。
4. 新建站点并反向代理到 `http://127.0.0.1:3500`。
5. 为域名申请 HTTPS 证书。

Nginx 需要保留以下请求头：

```nginx
proxy_set_header Host $host;
proxy_set_header X-Forwarded-Host $host;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
```

## CDN 配置

- 不缓存 `/admin/*`、`/dashboard`、`/recharge`、`/api/*`、`/login`、`/register`。
- `/_next/static/*` 可以长期缓存。
- 不要缓存带有 `Set-Cookie` 响应头的请求。
- CDN 必须向源站传递 `Host` 和 `X-Forwarded-Proto`。

## Redis

Redis 是可选功能。未启用或连接失败时，系统自动使用进程内存缓存。

在“系统管理 → 系统设置”中开启 Redis，并填写：

```text
redis://用户名:密码@Redis服务器:6379/0
```

如果 Redis 位于同一个 Docker 网络并且服务名是 `redis`：

```text
redis://redis:6379
```

## 邮件通知

在“系统管理 → 系统设置”中配置 SMTP，可分别开启：

- 注册邮箱验证
- 密码找回验证码
- 下单成功通知
- 排期审核通过通知

配置后先点击“发送测试邮件”确认 SMTP 可用。

## 数据与备份

运行数据位于 Docker volume `live-scheduler-data`，包括：

- SQLite 数据库
- 系统配置
- 安装锁
- 自动生成的会话密钥

查看实际挂载位置：

```bash
docker volume inspect live-scheduler_live-scheduler-data
```

备份示例：

```bash
docker run --rm \
  -v live-scheduler_live-scheduler-data:/data \
  -v "$PWD":/backup \
  alpine tar -czf /backup/live-scheduler-data-backup.tar.gz -C /data .
```

不同目录下 Compose 自动生成的 volume 前缀可能不同，请以 `docker volume ls` 输出为准。

## 常用命令

```bash
# 查看状态
docker compose ps

# 查看实时日志
docker compose logs -f

# 重启
docker compose restart

# 停止但保留数据
docker compose down

# 重新构建
docker compose up -d --build
```

## 常见问题

### Docker 构建时 npm 下载失败

确认服务器可以访问 npm。必要时在 Dockerfile 中临时配置可用的软件源，然后重新构建。

### 页面无法访问

检查容器状态和端口：

```bash
docker compose ps
docker compose logs --tail=200
ss -lntp | grep 3500
```

### Redis 无法连接

系统会自动回退到内存缓存。检查 Redis 地址、密码、防火墙和 Docker 网络后，在缓存管理页面刷新连接。

### 更新后仍显示旧页面

重新构建容器并清理 CDN/浏览器缓存：

```bash
docker compose down
docker compose up -d --build
```

## 发布说明

此目录是生产部署构建，不包含 TypeScript/React 项目源码、`node_modules`、数据库、系统配置、安装锁或会话密钥。Docker 构建时会根据 `package.json` 自动安装 Linux 生产依赖。
