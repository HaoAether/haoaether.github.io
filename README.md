# 🏗️ 高可用个人知识库

> **Hexo + Docker + GitHub** 全自动化博客部署方案  
> 知行合一小组 出品

---

## 📋 目录

- [项目简介](#项目简介)
- [技术栈](#技术栈)
- [环境准备](#环境准备)
- [快速开始](#快速开始)
- [详细步骤](#详细步骤)
- [GitHub Pages 部署](#github-pages-部署)
- [日常使用](#日常使用)
- [项目结构](#项目结构)

---

## 项目简介

解决传统博客框架（WordPress、Typecho 等）的六大痛点：

| 痛点 | 解决方案 |
|------|---------|
| 安全性低（对外 API 多） | 静态页面，无后端接口 |
| 内容上传流程繁琐 | Markdown 编写 → Git Push → 自动发布 |
| 功能冗余 | 插件化，按需安装 |
| 架构复杂，迁移困难 | 基于目录管理，迁移只需复制目录 |
| 可靠性低 | Git + GitHub 版本控制 |
| 成本高 | 使用 GitHub 免费服务 |

---

## 技术栈

| 组件 | 作用 |
|------|------|
| **OS** | 支持 Docker 的任意系统（Mac/Linux/Windows） |
| **Docker** | 为 Hexo 提供隔离运行环境 |
| **Hexo** | 将 Markdown 转换为 HTML 静态页面 |
| **GitHub Repository** | 暂存静态文件，版本控制 |
| **GitHub Pages** | 免费托管静态网站 |
| **GitHub Actions** | 自动化 CI/CD 流水线 |

---

## 环境准备

### 1. 安装 Docker

```bash
# macOS (推荐使用 Docker Desktop)
brew install --cask docker

# Ubuntu / Debian
curl -fsSL https://get.docker.com | bash
sudo usermod -aG docker $USER
newgrp docker

# 验证安装
docker --version
```

### 2. 安装 Git

```bash
# macOS
brew install git

# Ubuntu
sudo apt-get install -y git

# 验证
git --version
```

### 3. 配置 GitHub SSH 密钥

```bash
# 生成 SSH 密钥对（已有可跳过）
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# 查看公钥内容，复制到 GitHub → Settings → SSH Keys
cat ~/.ssh/id_rsa.pub

# 测试连接
ssh -T git@github.com
```

---

## 快速开始

### Step 1 — 克隆项目

```bash
git clone https://github.com/your-username/hexo-knowledge-base.git
cd hexo-knowledge-base
```

### Step 2 — 修改配置

编辑 `scripts/blog.sh`，修改顶部配置区：

```bash
GIT_USER_NAME="你的名字"
GIT_USER_EMAIL="your@email.com"
SSH_KEY_PATH="$HOME/.ssh/id_rsa"
PORT=4000
```

### Step 3 — 构建镜像

```bash
chmod +x scripts/blog.sh
./scripts/blog.sh build
```

### Step 4 — 启动博客

```bash
./scripts/blog.sh run
```

访问 **http://localhost:4000** 即可看到博客 🎉

---

## 详细步骤

### 构建 Docker 镜像

```bash
# 标准构建
./scripts/blog.sh build

# 等价的完整命令（手动执行）
docker build \
  -t hexo-knowledge-base \
  -f docker/Dockerfile \
  ./docker/

# 验证镜像
docker images hexo-knowledge-base
```

### 运行容器

```bash
# 使用脚本（推荐）
./scripts/blog.sh run

# 等价的完整命令
docker run -d \
  --name hexo-blog \
  --restart unless-stopped \
  -p 4000:4000 \
  -v "$(pwd)/blog-data:/blog" \
  -e "GIT_USER_NAME=你的名字" \
  -e "GIT_USER_EMAIL=your@email.com" \
  hexo-knowledge-base
```

### 查看日志

```bash
./scripts/blog.sh logs

# 等价命令
docker logs -f hexo-blog
```

### 停止容器

```bash
./scripts/blog.sh stop
# 等价: docker stop hexo-blog
```

### 清理容器和镜像

```bash
./scripts/blog.sh clean
# 注意: 不会删除 blog-data/ 目录，数据安全 ✓
```

---

## GitHub Pages 部署

### 方式一：GitHub Actions（推荐，全自动）

1. 在 GitHub 创建仓库，名称为 `<username>.github.io` 或任意名称
2. 将项目推送到仓库 `main` 分支
3. 进入 **Settings → Pages**，Source 选择 `gh-pages` 分支
4. 每次 `git push main` 后自动触发构建和部署

```bash
# 初始化本地博客 Git 仓库
cd blog-data
git init
git remote add origin git@github.com:your-username/your-repo.git

# 写文章后推送
git add .
git commit -m "新增文章: 文章标题"
git push origin main
# GitHub Actions 将自动构建并发布 🚀
```

### 方式二：hexo-deployer-git（手动触发）

在 `blog-data/_config.yml` 中配置：

```yaml
deploy:
  type: git
  repo: git@github.com:your-username/your-username.github.io.git
  branch: main
  message: "Auto deploy: {{ now('YYYY-MM-DD HH:mm:ss') }}"
```

然后执行：

```bash
./scripts/blog.sh deploy
# 等价: docker exec hexo-blog bash -c "cd /blog && hexo generate && hexo deploy"
```

---

## 日常使用

### 新建文章

```bash
# 通过脚本
./scripts/blog.sh new "我的第一篇文章"

# 文件将生成在 blog-data/source/_posts/我的第一篇文章.md
# 使用 VS Code 或任意编辑器打开编辑
code blog-data/source/_posts/我的第一篇文章.md
```

### 文章格式（Front Matter）

```markdown
---
title: 文章标题
date: 2024-01-01 12:00:00
tags:
  - 技术
  - Docker
categories:
  - 运维
---

正文内容从这里开始，使用标准 Markdown 语法...
```

### 发布流程（完整工作流）

```bash
# 1. 新建文章
./scripts/blog.sh new "文章标题"

# 2. 编写内容
code blog-data/source/_posts/文章标题.md

# 3. 本地预览（访问 http://localhost:4000）
# 容器已在运行时，Hexo 会自动检测文件变更

# 4. 确认无误后推送（触发自动部署）
cd blog-data
git add .
git commit -m "发布: 文章标题"
git push origin main
```

### 查看运行状态

```bash
./scripts/blog.sh status
```

---

## 项目结构

```
hexo-knowledge-base/
├── docker/
│   ├── Dockerfile          # 镜像构建文件
│   ├── entrypoint.sh       # 容器运行时脚本
│   └── plugins.txt         # Hexo 插件列表
├── scripts/
│   └── blog.sh             # 一键管理脚本
├── .github/
│   └── workflows/
│       └── deploy.yml      # GitHub Actions 自动部署
├── blog-data/              # 博客数据目录（.gitignore 或单独管理）
│   ├── source/
│   │   └── _posts/         # Markdown 文章
│   ├── themes/             # 博客主题
│   ├── _config.yml         # Hexo 配置
│   └── package.json
└── README.md
```

---

## 迁移指南

由于采用目录化管理，迁移极其简单：

```bash
# 迁移只需复制 blog-data 目录
scp -r blog-data/ user@new-server:/path/to/new-location/

# 在新机器上重新构建即可
./scripts/blog.sh build
./scripts/blog.sh run
```

---

## 常见问题

**Q: 端口 4000 被占用怎么办？**  
修改 `scripts/blog.sh` 中的 `PORT=4000` 为其他端口。

**Q: 如何更换主题？**  
```bash
cd blog-data/themes
git clone https://github.com/theme-author/theme-name
# 然后修改 _config.yml: theme: theme-name
```

**Q: 插件如何管理？**  
编辑 `docker/plugins.txt` 后重建镜像：`./scripts/blog.sh clean && ./scripts/blog.sh build && ./scripts/blog.sh run`
