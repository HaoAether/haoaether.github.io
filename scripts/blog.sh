#!/bin/bash
# ============================================================
# blog.sh — 博客一键管理脚本
# 用法: ./blog.sh [build|run|stop|clean|logs|deploy|status]
# ============================================================

set -e

# ── 配置区（请根据实际情况修改） ──────────────────────────────
IMAGE_NAME="hexo-knowledge-base"
CONTAINER_NAME="hexo-blog"
BLOG_DIR="$(pwd)/blog-data"          # 博客数据持久化目录
SSH_KEY_PATH="$HOME/.ssh/id_rsa"     # SSH 私钥路径
GIT_USER_NAME="your-name"            # Git 用户名
GIT_USER_EMAIL="your@email.com"      # Git 邮箱
PORT=4000                            # 映射端口

# ── 颜色输出 ──────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step()  { echo -e "${CYAN}[STEP]${NC} $1"; }

print_banner() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════╗"
    echo "║     🏗️  高可用个人知识库管理脚本          ║"
    echo "║     Hexo + Docker + GitHub               ║"
    echo "╚══════════════════════════════════════════╝"
    echo -e "${NC}"
}

# ── build: 构建 Docker 镜像 ───────────────────────────────────
cmd_build() {
    log_step "构建 Docker 镜像: $IMAGE_NAME"
    docker build \
        -t "$IMAGE_NAME" \
        -f docker/Dockerfile \
        ./docker/
    log_info "镜像构建完成 ✓"
}

# ── run: 运行容器 ─────────────────────────────────────────────
cmd_run() {
    # 确保数据目录存在
    mkdir -p "$BLOG_DIR"

    # 停止已存在的同名容器
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_warn "检测到已有同名容器，先停止并删除..."
        docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
    fi

    log_step "启动容器: $CONTAINER_NAME"

    # 读取 SSH 私钥内容
    SSH_KEY_CONTENT=""
    if [ -f "$SSH_KEY_PATH" ]; then
        SSH_KEY_CONTENT=$(cat "$SSH_KEY_PATH")
    fi

    docker run -d \
        --name "$CONTAINER_NAME" \
        --restart unless-stopped \
        -p "${PORT}:4000" \
        -v "${BLOG_DIR}:/blog" \
        -e "SSH_PRIVATE_KEY=${SSH_KEY_CONTENT}" \
        -e "GIT_USER_NAME=${GIT_USER_NAME}" \
        -e "GIT_USER_EMAIL=${GIT_USER_EMAIL}" \
        "$IMAGE_NAME"

    log_info "容器已启动 ✓"
    log_info "博客地址: http://localhost:${PORT}"
}

# ── stop: 停止容器 ────────────────────────────────────────────
cmd_stop() {
    log_step "停止容器: $CONTAINER_NAME"
    docker stop "$CONTAINER_NAME" 2>/dev/null || log_warn "容器未在运行"
    log_info "容器已停止 ✓"
}

# ── clean: 清理容器和镜像（不删数据目录） ─────────────────────
cmd_clean() {
    log_warn "即将清理容器和镜像（⚠️  不会删除 $BLOG_DIR 数据目录）"
    read -p "确认继续? (y/N) " confirm
    [[ "$confirm" != "y" && "$confirm" != "Y" ]] && { log_info "已取消"; exit 0; }

    log_step "清理容器..."
    docker rm -f "$CONTAINER_NAME" 2>/dev/null || log_warn "容器不存在"

    log_step "清理镜像..."
    docker rmi -f "$IMAGE_NAME" 2>/dev/null || log_warn "镜像不存在"

    log_info "清理完成 ✓（数据已保留在 $BLOG_DIR）"
}

# ── logs: 查看日志 ────────────────────────────────────────────
cmd_logs() {
    log_step "查看容器日志 (Ctrl+C 退出)"
    docker logs -f --tail=50 "$CONTAINER_NAME"
}

# ── deploy: 触发 Hexo 部署到 GitHub Pages ─────────────────────
cmd_deploy() {
    log_step "触发部署到 GitHub Pages..."
    docker exec "$CONTAINER_NAME" bash -c "cd /blog && hexo generate && hexo deploy"
    log_info "部署完成 ✓"
}

# ── status: 查看运行状态 ──────────────────────────────────────
cmd_status() {
    echo ""
    log_step "容器状态:"
    docker ps -a --filter "name=$CONTAINER_NAME" \
        --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    log_step "镜像信息:"
    docker images "$IMAGE_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
    echo ""
}

# ── new: 新建文章 ─────────────────────────────────────────────
cmd_new() {
    TITLE="${2:-新文章}"
    log_step "新建文章: $TITLE"
    docker exec -it "$CONTAINER_NAME" bash -c "cd /blog && hexo new post '$TITLE'"
    log_info "文章已创建，文件在 $BLOG_DIR/source/_posts/"
}

# ── 入口 ──────────────────────────────────────────────────────
print_banner

case "$1" in
    build)   cmd_build ;;
    run)     cmd_run ;;
    stop)    cmd_stop ;;
    clean)   cmd_clean ;;
    logs)    cmd_logs ;;
    deploy)  cmd_deploy ;;
    status)  cmd_status ;;
    new)     cmd_new "$@" ;;
    *)
        echo "用法: $0 <command>"
        echo ""
        echo "可用命令:"
        echo "  build    构建 Docker 镜像"
        echo "  run      运行博客容器"
        echo "  stop     停止容器"
        echo "  clean    清理容器和镜像（保留数据）"
        echo "  logs     查看实时日志"
        echo "  deploy   部署到 GitHub Pages"
        echo "  status   查看运行状态"
        echo "  new      新建文章 (./blog.sh new '文章标题')"
        echo ""
        exit 1
        ;;
esac
