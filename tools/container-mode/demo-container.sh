#!/bin/bash
#--------------------------------------------------
# kubeasz容器部署模式演示脚本
# 该脚本演示如何使用kubeasz在容器环境中快速部署Kubernetes集群
# @author: kubeasz team
# @usage: ./demo-container.sh
#--------------------------------------------------

set -o nounset
set -o errexit

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

function log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

function log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

function log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

function log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

function check_prerequisites() {
    log_step "检查系统环境..."
    
    # 检查Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装，请先安装Docker"
        exit 1
    fi
    
    # 检查Docker是否运行
    if ! docker info &> /dev/null; then
        log_error "Docker未运行，请启动Docker服务"
        exit 1
    fi
    
    # 检查系统资源
    total_mem=$(free -m | awk 'NR==2{printf "%.0f", $2/1024}')
    if [ "$total_mem" -lt 4 ]; then
        log_warn "系统内存少于4GB，可能影响集群性能"
    fi
    
    log_info "系统环境检查通过"
}

function download_kubeasz() {
    log_step "下载kubeasz..."
    
    if [ ! -f "./ezdown" ]; then
        log_info "下载ezdown脚本..."
        export release=3.6.8
        wget -q https://github.com/easzlab/kubeasz/releases/download/${release}/ezdown
        chmod +x ./ezdown
    fi
    
    if [ ! -d "/etc/kubeasz" ]; then
        log_info "下载kubeasz代码和二进制文件..."
        ./ezdown -D
    else
        log_info "kubeasz已存在，跳过下载"
    fi
}

function start_container_mode() {
    log_step "启动kubeasz容器模式..."
    
    # 检查是否已有容器运行
    if docker ps -a --format="{{ .Names }}" | grep -q "kubeasz-container"; then
        log_warn "发现已存在的kubeasz-container，正在清理..."
        docker rm -f kubeasz-container > /dev/null 2>&1
    fi
    
    log_info "启动kubeasz容器模式环境..."
    ./ezdown -T
    
    # 等待容器启动
    sleep 5
    
    # 验证容器是否正常运行
    if ! docker ps --format="{{ .Names }}" | grep -q "kubeasz-container"; then
        log_error "kubeasz容器启动失败"
        exit 1
    fi
    
    log_info "kubeasz容器模式环境启动成功"
}

function deploy_kubernetes() {
    log_step "部署Kubernetes集群..."
    
    log_info "在容器中创建KIND集群..."
    docker exec kubeasz-container bash -c "ezctl start-container" || {
        log_error "Kubernetes集群部署失败"
        exit 1
    }
    
    log_info "Kubernetes集群部署成功"
}

function verify_cluster() {
    log_step "验证集群状态..."
    
    log_info "检查集群信息..."
    docker exec kubeasz-container kubectl cluster-info
    
    echo ""
    log_info "检查节点状态..."
    docker exec kubeasz-container kubectl get nodes
    
    echo ""
    log_info "检查系统Pod状态..."
    docker exec kubeasz-container kubectl get pods -A
    
    echo ""
    log_info "检查服务状态..."
    docker exec kubeasz-container kubectl get svc -A
}

function create_demo_app() {
    log_step "部署演示应用..."
    
    log_info "创建nginx演示应用..."
    docker exec kubeasz-container bash -c "
        kubectl create deployment nginx-demo --image=nginx:latest
        kubectl expose deployment nginx-demo --type=NodePort --port=80
        kubectl create ingress nginx-demo --class=nginx --rule='nginx-demo.local/*=nginx-demo:80'
    "
    
    echo ""
    log_info "等待应用就绪..."
    docker exec kubeasz-container kubectl wait --for=condition=available --timeout=300s deployment/nginx-demo
    
    echo ""
    log_info "获取服务信息..."
    docker exec kubeasz-container kubectl get svc nginx-demo
    docker exec kubeasz-container kubectl get ingress nginx-demo
    
    echo ""
    log_info "演示应用部署完成"
    log_info "可以通过以下方式访问："
    log_info "1. NodePort: kubectl get svc nginx-demo 查看端口，然后访问 http://localhost:<port>"
    log_info "2. Ingress: 添加 '127.0.0.1 nginx-demo.local' 到 /etc/hosts，然后访问 http://nginx-demo.local"
}

function show_usage_info() {
    log_step "使用说明..."
    
    cat << EOF

${GREEN}=== kubeasz容器部署模式演示完成 ===${NC}

${BLUE}集群访问方式：${NC}
1. 进入kubeasz容器：
   docker exec -it kubeasz-container bash

2. 使用kubectl管理集群：
   docker exec kubeasz-container kubectl get nodes
   docker exec kubeasz-container kubectl get pods -A

${BLUE}常用操作：${NC}
- 查看集群状态：docker exec kubeasz-container kubectl cluster-info
- 部署应用：docker exec kubeasz-container kubectl create deployment <name> --image=<image>
- 暴露服务：docker exec kubeasz-container kubectl expose deployment <name> --type=NodePort --port=<port>

${BLUE}清理环境：${NC}
- 删除KIND集群：docker exec kubeasz-container kind delete cluster --name=kubeasz-container
- 停止容器：docker stop kubeasz-container
- 删除容器：docker rm kubeasz-container

${BLUE}更多信息：${NC}
- 查看文档：docs/setup/containerStart.md
- 项目地址：https://github.com/easzlab/kubeasz

EOF
}

function cleanup_on_error() {
    log_error "部署过程中出现错误，正在清理..."
    docker rm -f kubeasz-container > /dev/null 2>&1 || true
    docker exec kubeasz-container kind delete cluster --name=kubeasz-container > /dev/null 2>&1 || true
}

function main() {
    echo -e "${GREEN}"
    cat << "EOF"
    _          _                        
   | | ___   _| |__   ___  __ _ ___ ____
   | |/ / | | | '_ \ / _ \/ _` / __|_  /
   |   <| |_| | |_) |  __/ (_| \__ \/ / 
   |_|\_\\__,_|_.__/ \___|\__,_|___/___|
                                       
   容器部署模式演示 - Container Deployment Demo
EOF
    echo -e "${NC}"
    
    # 设置错误处理
    trap cleanup_on_error ERR
    
    log_info "开始kubeasz容器部署模式演示..."
    
    check_prerequisites
    download_kubeasz
    start_container_mode
    deploy_kubernetes
    verify_cluster
    
    # 询问是否部署演示应用
    echo ""
    read -p "是否部署nginx演示应用？(y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        create_demo_app
    fi
    
    show_usage_info
    
    log_info "演示完成！"
}

# 检查是否以root权限运行
if [[ $EUID -eq 0 ]]; then
    log_warn "建议不要以root权限运行此脚本"
fi

# 运行主函数
main "$@"