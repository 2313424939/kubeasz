# kubeasz 容器部署模式工具

本目录包含kubeasz容器部署模式相关的工具和脚本。

## 文件说明

### demo-container.sh
完整的容器部署模式演示脚本，展示从环境准备到集群部署的完整流程。

**使用方法：**
```bash
./demo-container.sh
```

**功能：**
- 自动检查系统环境
- 下载kubeasz相关文件
- 启动容器模式环境
- 部署Kubernetes集群
- 验证集群状态
- 部署演示应用
- 提供使用指导

### test-container-mode.sh
自动化测试脚本，用于验证容器部署模式的实现正确性。

**使用方法：**
```bash
./test-container-mode.sh
```

**测试内容：**
- 配置文件完整性
- 命令实现正确性
- 文档完整性
- 脚本语法正确性

## 相关文档

- [容器部署模式快速指南](../../docs/setup/containerStart.md)
- [容器部署模式实现总结](../../docs/setup/CONTAINER_MODE_SUMMARY.md)

## 配置文件

相关配置文件位于 `example/` 目录：
- `hosts.container` - 容器模式的Ansible inventory配置
- `kind-config.yaml` - KIND集群配置模板
- `container-example.sh` - 基本使用示例脚本