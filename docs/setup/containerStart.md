# 容器部署模式快速指南

本文档介绍如何使用kubeasz的容器部署模式，在容器环境中快速部署Kubernetes集群。该模式特别适用于开发、测试、CI/CD环境以及需要在容器内运行Kubernetes的场景。

## 特性

- **容器化部署**: 使用KIND (Kubernetes IN Docker) 在容器内创建Kubernetes集群
- **快速启动**: 一键部署，无需复杂配置
- **隔离环境**: 完全隔离的Kubernetes环境，不影响宿主机
- **开发友好**: 适合开发、测试和学习使用
- **CI/CD集成**: 可轻松集成到CI/CD流水线中

## 系统要求

- **Docker**: 需要Docker运行环境
- **内存**: 建议4GB以上
- **存储**: 建议10GB以上可用空间
- **网络**: 需要互联网连接下载镜像

## 支持的操作系统

容器部署模式支持所有能运行Docker的系统：
- **Linux**: Ubuntu, CentOS, RHEL, Debian等
- **macOS**: Docker Desktop
- **Windows**: Docker Desktop (WSL2模式)

## 快速开始

### 1. 下载kubeasz

```bash
export release=3.6.8
wget https://github.com/easzlab/kubeasz/releases/download/${release}/ezdown
chmod +x ./ezdown
```

### 2. 下载必要文件

```bash
# 下载kubeasz代码、二进制文件和容器镜像
./ezdown -D
```

### 3. 启动容器模式

```bash
# 启动kubeasz容器模式环境
./ezdown -T
```

### 4. 部署Kubernetes集群

```bash
# 进入kubeasz容器
docker exec -it kubeasz-container bash

# 部署容器模式的Kubernetes集群
ezctl start-container
```

### 5. 验证集群

```bash
# 检查集群状态
kubectl cluster-info
kubectl get nodes
kubectl get pods -A

# 检查网络插件
kubectl get pods -n calico-system

# 检查ingress控制器
kubectl get pods -n ingress-nginx
```

## 详细配置

### 自定义KIND配置

如果需要自定义KIND集群配置，可以修改 `clusters/container/kind-config.yaml` 文件：

```yaml
# 添加更多worker节点
nodes:
- role: control-plane
  image: kindest/node:v1.31.0
- role: worker
  image: kindest/node:v1.31.0
- role: worker
  image: kindest/node:v1.31.0
```

### 自定义集群配置

修改 `clusters/container/hosts` 文件来自定义集群配置：

```ini
# 修改网络插件
CLUSTER_NETWORK="flannel"  # 可选: calico, flannel, cilium

# 修改服务网段
SERVICE_CIDR="10.96.0.0/16"
CLUSTER_CIDR="10.244.0.0/16"
```

## 高级用法

### 端口映射

KIND集群默认映射以下端口：
- `6443`: Kubernetes API Server
- `80/443`: Ingress Controller
- `30000-30002`: NodePort服务示例

### 持久化存储

容器模式支持本地存储，数据会保存在KIND节点容器中：

```bash
# 查看存储类
kubectl get storageclass

# 创建PVC示例
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF
```

### 访问服务

#### 通过NodePort访问

```bash
# 创建NodePort服务
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --type=NodePort --port=80

# 获取NodePort
kubectl get svc nginx
```

#### 通过Ingress访问

```bash
# 创建Ingress资源
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
spec:
  rules:
  - host: nginx.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx
            port:
              number: 80
EOF

# 添加hosts记录
echo "127.0.0.1 nginx.local" >> /etc/hosts

# 访问服务
curl http://nginx.local
```

## 集群管理

### 停止集群

```bash
# 删除KIND集群
kind delete cluster --name=kubeasz-container
```

### 重新创建集群

```bash
# 在kubeasz容器中重新运行
ezctl start-container
```

### 清理环境

```bash
# 停止并删除kubeasz容器
docker stop kubeasz-container
docker rm kubeasz-container

# 清理KIND集群
kind delete cluster --name=kubeasz-container
```

## 故障排除

### 常见问题

1. **Docker权限问题**
   ```bash
   # 确保当前用户在docker组中
   sudo usermod -aG docker $USER
   # 重新登录或执行
   newgrp docker
   ```

2. **内存不足**
   ```bash
   # 检查系统资源
   docker system df
   docker system prune  # 清理未使用的资源
   ```

3. **网络问题**
   ```bash
   # 检查Docker网络
   docker network ls
   # 重启Docker服务
   sudo systemctl restart docker
   ```

4. **KIND集群创建失败**
   ```bash
   # 查看KIND日志
   kind create cluster --config=clusters/container/kind-config.yaml --name=kubeasz-container -v 1
   
   # 清理后重试
   kind delete cluster --name=kubeasz-container
   docker system prune -f
   ```

  #### 端口冲突导致的启动失败

  KIND 默认示例会把一些常用端口映射到宿主机（如 6443、80、443、30000-30002）。如果这些端口被宿主机上的其他进程占用，KIND 在创建容器时会因为无法绑定主机端口而失败，并出现类似 "address already in use" 的错误。

  解决方法：

  - 检查哪些进程占用了端口（以 6443 为例）：

  ```bash
  # 推荐：显示监听端口及对应的进程信息
  ss -ltnp | grep -E ':(6443|80|443|30000|30001|30002)'

  # 或使用 lsof（需安装 lsof）
  sudo lsof -i :6443
  ```

  - 停止或移除占用端口的服务，例如 nginx/traefik 等：

  ```bash
  sudo systemctl stop nginx
  sudo systemctl disable nginx
  # 或根据 PID 杀掉进程（谨慎）
  sudo kill <PID>
  ```

  - 如果不希望把这些端口映射到宿主机，可以编辑 `clusters/container/kind-config.yaml`，移除或注释 `extraPortMappings` 中对应的 `hostPort` 条目。例如把控制平面节点的映射部分删除或注释掉：

  ```yaml
    extraPortMappings:
    # - containerPort: 6443
    #   hostPort: 6443
    #   protocol: TCP
    # - containerPort: 80
    #   hostPort: 80
    #   protocol: TCP
  ```

  修改后重新运行 `ezctl start-container` 或直接使用 `kind create cluster --config=clusters/container/kind-config.yaml --name=kubeasz-container` 进行测试。

  如果仍然遇到问题，请把 `ss -ltnp` 的输出粘贴到 issue/讨论中以便定位。

### 日志查看

```bash
# 查看kubeasz容器日志
docker logs kubeasz-container

# 查看KIND节点日志
docker logs kubeasz-container-control-plane

# 查看Kubernetes组件日志
kubectl logs -n kube-system -l component=kube-apiserver
```

## 与传统部署模式的对比

| 特性 | 传统部署模式 | 容器部署模式 |
|------|-------------|-------------|
| 部署环境 | 物理机/虚拟机 | 容器内 |
| 资源隔离 | 系统级 | 容器级 |
| 启动速度 | 较慢 | 快速 |
| 资源消耗 | 较高 | 较低 |
| 适用场景 | 生产环境 | 开发/测试 |
| 网络配置 | 复杂 | 简单 |
| 清理难度 | 较难 | 简单 |

## 最佳实践

1. **资源规划**: 为容器分配足够的CPU和内存资源
2. **网络规划**: 避免端口冲突，合理规划服务暴露方式
3. **数据备份**: 重要数据应及时备份到宿主机
4. **版本管理**: 使用特定版本的镜像确保环境一致性
5. **监控告警**: 配置基础的监控和日志收集

## 参考链接

- [KIND官方文档](https://kind.sigs.k8s.io/)
- [Kubernetes官方文档](https://kubernetes.io/docs/)
- [kubeasz项目主页](https://github.com/easzlab/kubeasz)