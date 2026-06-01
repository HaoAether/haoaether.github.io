#!/bin/bash
# ============================================================
# entrypoint.sh — 容器运行时脚本
# 功能: 初始化 Hexo、安装插件、配置 SSH、启动服务
# ============================================================

set -e

BLOG_DIR="/blog"
PLUGINS_FILE="/blog/plugins.txt"

echo "================================================"
echo "  🚀 高可用个人知识库 — 启动中..."
echo "================================================"

# ── Step 1: 初始化 Hexo 工作目录 ──────────────────────────────
# 检测目录是否为空，为空则初始化；否则跳过
if [ -z "$(ls -A $BLOG_DIR 2>/dev/null)" ]; then
    echo "[INFO] 工作目录为空，正在初始化 Hexo..."
    hexo init $BLOG_DIR
    cd $BLOG_DIR
    npm install
    echo "[INFO] Hexo 初始化完成 ✓"
else
    echo "[INFO] 检测到已有博客目录，跳过初始化"
    cd $BLOG_DIR
    # 确保依赖已安装
    if [ ! -d "node_modules" ]; then
        echo "[INFO] 安装 npm 依赖..."
        npm install
    fi
fi

# ── Step 2: 安装插件 ──────────────────────────────────────────
# 根据传入的 PLUGINS 环境变量或 plugins.txt 安装插件
if [ -n "$HEXO_PLUGINS" ]; then
    echo "[INFO] 安装插件: $HEXO_PLUGINS"
    npm install $HEXO_PLUGINS --save
elif [ -f "$PLUGINS_FILE" ]; then
    echo "[INFO] 从 plugins.txt 读取并安装插件..."
    while IFS= read -r plugin || [[ -n "$plugin" ]]; do
        [[ "$plugin" =~ ^#.*$ ]] && continue  # 跳过注释行
        [[ -z "$plugin" ]] && continue
        echo "  → 安装 $plugin"
        npm install "$plugin" --save
    done < "$PLUGINS_FILE"
else
    echo "[INFO] 安装默认必要插件..."
    npm install \
        hexo-generator-archive \
        hexo-generator-category \
        hexo-generator-tag \
        hexo-generator-search \
        hexo-deployer-git \
        --save
fi

echo "[INFO] 插件安装完成 ✓"

# ── Step 3: 配置 SSH 密钥 (用于 GitHub 推送) ─────────────────
if [ -n "$SSH_PRIVATE_KEY" ]; then
    echo "[INFO] 配置 SSH 密钥..."
    mkdir -p ~/.ssh
    echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_rsa
    chmod 600 ~/.ssh/id_rsa
    # 信任 GitHub 主机
    ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts 2>/dev/null
    echo "[INFO] SSH 密钥配置完成 ✓"
elif [ -f "/run/secrets/ssh_key" ]; then
    echo "[INFO] 从 Docker Secret 加载 SSH 密钥..."
    cp /run/secrets/ssh_key ~/.ssh/id_rsa
    chmod 600 ~/.ssh/id_rsa
    ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts 2>/dev/null
    echo "[INFO] SSH 密钥配置完成 ✓"
else
    echo "[WARN] 未检测到 SSH 密钥，跳过 GitHub 部署配置"
fi

# ── Step 4: 配置 Git 用户信息 ────────────────────────────────
if [ -n "$GIT_USER_NAME" ] && [ -n "$GIT_USER_EMAIL" ]; then
    git config --global user.name "$GIT_USER_NAME"
    git config --global user.email "$GIT_USER_EMAIL"
    echo "[INFO] Git 用户配置完成: $GIT_USER_NAME <$GIT_USER_EMAIL> ✓"
fi

# ── Step 5: 启动 Hexo 服务 ───────────────────────────────────
echo ""
echo "================================================"
echo "  ✅ 初始化完成，启动 Hexo 服务..."
echo "  📖 访问地址: http://localhost:4000"
echo "================================================"
echo ""

hexo server --port 4000
