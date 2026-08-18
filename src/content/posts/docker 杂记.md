---
title: docker 杂记
published: 2026-08-19
updated: 2026-08-19
description: '用于备忘的 docker 学习笔记'
image: ''
tags: [开发, Docker, 笔记]
category: '技术'
draft: false
lang: 'zh_CN'
---

## Docker 杂记

学习 Docker 时的随笔记录。

## 正文

### pull

用于从仓库中下载镜像。

```bash
docker pull <registry>/<namespace>/<image>:<tag>
## example
docker pull docker.io/library/nginx:latest
docker pull docker.n8n.io/n8nio/n8n
```

其中：

- **registry**：代表仓库地址，`docker.io` 是 Docker Hub 的官方仓库。在不填写时默认指代官方仓库。
- **namespace**：代表命名空间（作者名），`library` 是 Docker 官方仓库的命名空间。在不填写时默认指代官方命名空间。
- **tag**：代表标签（版本号），可以指定获取某个镜像的版本，`latest` 表示最新版本。在不填写时默认指代最新版本。

参数：

- `platform=<xxx>`：表示拉取特定 CPU 架构的镜像，如 `linux/amd64`, `linux/arm64`, `linux/arm/v7` 等。

### images

列出所有下载过的镜像。

```bash
docker images
```

### rmi

删除某一下载过的镜像。

```bash
docker rmi <image id>
```

### run

用镜像创建并运行容器。

```bash
docker run <image | image id>
## example
docker run nginx
```

参数：

- `-d`：代表让容器在后台执行。
- `-p <宿主机端口>:<容器端口>`：端口映射。由于一般容器网络与宿主机隔离，所以可以用端口映射，通过宿主机端口来访问容器端口。
- `-v <宿主机目录>:<容器目录>`：挂载卷。绑定宿主机与容器内的目录，当其中一端修改，另一端也会同步保存修改。
- `-e <环境变量信息>`：用于传递环境变量。
- `--name <自定义名称>`：可以给容器起一个自定义名称。该名称必须在宿主机上唯一，不能重复。可以在命令中代替 `image id` 的位置。
- `-it`：通过控制台进入容器。可以衔接 `--rm`：当从容器退出时自动删除，用于临时调试。
- `--restart <策略>`：配置容器停止时的重启策略。常用策略：
    - `always`：只要容器停止就立即重启。
    - `unless-stopped`：类似 `always`，但手动停止不会尝试重启。

### create

用镜像创建容器（不运行）

```bash
docker create <image | image id>
```

要启动需要使用 `start` 命令。

### ps

查看正在运行的容器。

```bash
docker ps
```

### rm

删除容器。

```bash
docker rm <container id>
```

参数：

- `-f`：强制删除。可以删除正在运行的容器。

### start / stop

启用/停止已有的容器。

```bash
docker start <container id>
docker stop <container id>
```

### inspect

展示容器的检查信息。

```bash
docker inspect <container id>
```