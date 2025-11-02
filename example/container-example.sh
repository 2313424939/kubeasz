#!/bin/bash
#--------------------------------------------------
# kubeasz容器部署模式使用示例
# 展示如何使用容器模式部署和管理Kubernetes集群
#--------------------------------------------------

set -e

echo "=== kubeasz容器部署模式使用示例 ==="
echo

# 1. 检查Docker环境
echo "1. 检查Docker环境..."
if ! docker info &> /dev/null; then
    echo "错误: Docker未运行，请先启动Docker"
    exit 1
fi
echo "✓ Docker环境正常"
echo

# 2. 下载kubeasz (如果需要)
echo "2. 准备kubeasz环境..."
if [ ! -f "./ezdown" ]; then
    echo "下载ezdown脚本..."
    export release=3.6.8
    wget -q https://github.com/easzlab/kubeasz/releases/download/${release}/ezdown
    chmod +x ./ezdown
fi

if [ ! -d "/etc/kubeasz" ]; then
    echo "下载kubeasz代码和二进制文件..."
    ./ezdown -D
fi
echo "✓ kubeasz环境准备完成"
echo

# 3. 启动容器模式
echo "3. 启动kubeasz容器模式..."
./ezdown -T
echo "✓ 容器模式启动完成"
echo

# 4. 部署Kubernetes集群
echo "4. 部署Kubernetes集群..."
docker exec kubeasz-container ezctl start-container
echo "✓ Kubernetes集群部署完成"
echo

# 5. 验证集群状态
echo "5. 验证集群状态..."
echo "集群信息:"
docker exec kubeasz-container kubectl cluster-info

echo
echo "节点状态:"
docker exec kubeasz-container kubectl get nodes

echo
echo "系统Pod状态:"
docker exec kubeasz-container kubectl get pods -A
echo

# 6. 部署示例应用
echo "6. 部署示例应用..."
docker exec kubeasz-container bash -c "
    kubectl create deployment hello-world --image=nginx:latest
    kubectl expose deployment hello-world --type=NodePort --port=80
    kubectl wait --for=condition=available --timeout=60s deployment/hello-world
"

echo "获取服务信息:"
docker exec kubeasz-container kubectl get svc hello-world
echo

# 7. 创建Ingress资源
echo "7. 创建Ingress资源..."
docker exec kubeasz-container bash -c "
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hello-world-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: hello.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: hello-world
            port:
              number: 80
EOF
"

echo "Ingress资源:"
docker exec kubeasz-container kubectl get ingress
echo

# 8. 显示访问方法
echo "8. 应用访问方法:"
echo "----------------------------------------"
echo "NodePort访问:"
NODEPORT=$(docker exec kubeasz-container kubectl get svc hello-world -o jsonpath='{.spec.ports[0].nodePort}')
echo "  curl http://localhost:${NODEPORT}"
echo
echo "Ingress访问:"
echo "  1. 添加hosts记录: echo '127.0.0.1 hello.local' >> /etc/hosts"
echo "  2. 访问: curl http://hello.local"
echo
echo "kubectl命令:"
echo "  docker exec kubeasz-container kubectl get pods"
echo "  docker exec kubeasz-container kubectl get svc"
echo "  docker exec kubeasz-container kubectl get ingress"
echo
echo "进入容器:"
echo "  docker exec -it kubeasz-container bash"
echo "----------------------------------------"
echo

echo "=== 容器部署模式示例完成 ==="
echo "集群已就绪，可以开始使用Kubernetes了！"