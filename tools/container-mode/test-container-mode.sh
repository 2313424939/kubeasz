#!/bin/bash
#--------------------------------------------------
# kubeasz容器部署模式测试脚本
# 用于验证容器部署模式的基本功能
#--------------------------------------------------

set -o nounset
set -o errexit

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

function log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

function log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

function log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

function test_config_files() {
    log_info "测试配置文件..."
    
    # 检查hosts.container文件
    if [ ! -f "example/hosts.container" ]; then
        log_error "hosts.container配置文件不存在"
        return 1
    fi
    
    # 检查kind-config.yaml文件
    if [ ! -f "example/kind-config.yaml" ]; then
        log_error "kind-config.yaml配置文件不存在"
        return 1
    fi
    
    # 验证配置文件内容
    if ! grep -q "DEPLOYMENT_MODE.*container" example/hosts.container; then
        log_error "hosts.container中缺少DEPLOYMENT_MODE配置"
        return 1
    fi
    
    if ! grep -q "USE_KIND_CLUSTER.*true" example/hosts.container; then
        log_error "hosts.container中缺少USE_KIND_CLUSTER配置"
        return 1
    fi
    
    log_info "配置文件测试通过"
}

function test_ezctl_commands() {
    log_info "测试ezctl命令..."
    
    # 检查start-container命令是否存在
    if ! grep -q "start-container" ezctl; then
        log_error "ezctl中缺少start-container命令"
        return 1
    fi
    
    # 检查start-container函数是否存在
    if ! grep -q "function start-container" ezctl; then
        log_error "ezctl中缺少start-container函数"
        return 1
    fi
    
    # 检查install_kind函数是否存在
    if ! grep -q "function install_kind" ezctl; then
        log_error "ezctl中缺少install_kind函数"
        return 1
    fi
    
    log_info "ezctl命令测试通过"
}

function test_ezdown_commands() {
    log_info "测试ezdown命令..."
    
    # 检查-T选项是否存在
    if ! grep -q "\-T.*start kubeasz in container mode" ezdown; then
        log_error "ezdown中缺少-T选项说明"
        return 1
    fi
    
    # 检查start_kubeasz_container_mode函数是否存在
    if ! grep -q "function start_kubeasz_container_mode" ezdown; then
        log_error "ezdown中缺少start_kubeasz_container_mode函数"
        return 1
    fi
    
    # 检查参数处理是否包含T选项
    if ! grep -q "CDP:RSTX:" ezdown; then
        log_error "ezdown参数处理中缺少T选项"
        return 1
    fi
    
    log_info "ezdown命令测试通过"
}

function test_documentation() {
    log_info "测试文档..."
    
    # 检查容器部署文档是否存在
    if [ ! -f "docs/setup/containerStart.md" ]; then
        log_error "容器部署文档不存在"
        return 1
    fi
    
    # 检查README是否更新
    if ! grep -q "容器环境快速部署" README.md; then
        log_error "README.md中缺少容器部署模式介绍"
        return 1
    fi
    
    log_info "文档测试通过"
}

function test_demo_script() {
    log_info "测试演示脚本..."
    
    # 检查演示脚本是否存在
    if [ ! -f "demo-container.sh" ]; then
        log_error "演示脚本不存在"
        return 1
    fi
    
    # 检查脚本是否可执行
    if [ ! -x "demo-container.sh" ]; then
        log_error "演示脚本不可执行"
        return 1
    fi
    
    # 检查脚本语法
    if ! bash -n demo-container.sh; then
        log_error "演示脚本语法错误"
        return 1
    fi
    
    log_info "演示脚本测试通过"
}

function test_syntax() {
    log_info "测试脚本语法..."
    
    # 检查ezctl语法
    if ! bash -n ezctl; then
        log_error "ezctl脚本语法错误"
        return 1
    fi
    
    # 检查ezdown语法
    if ! bash -n ezdown; then
        log_error "ezdown脚本语法错误"
        return 1
    fi
    
    log_info "脚本语法测试通过"
}

function run_all_tests() {
    local failed=0
    
    echo "开始运行kubeasz容器部署模式测试..."
    echo "========================================"
    
    test_config_files || failed=1
    test_ezctl_commands || failed=1
    test_ezdown_commands || failed=1
    test_documentation || failed=1
    test_demo_script || failed=1
    test_syntax || failed=1
    
    echo "========================================"
    
    if [ $failed -eq 0 ]; then
        log_info "所有测试通过！容器部署模式实现正确。"
        return 0
    else
        log_error "部分测试失败，请检查实现。"
        return 1
    fi
}

# 切换到kubeasz目录
cd /workspace/kubeasz

# 运行所有测试
run_all_tests