#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

echo "=========================================================="
echo "  BẮT ĐẦU KIỂM THỬ BÀI LAB MILESTONE 3 (KUBERNETES & HELM)"
echo "=========================================================="

echo -e "\n[BƯỚC 1] Nhập Docker image vào containerd của K3s..."
sudo docker save nodejs-production:v1.0.0 | sudo k3s ctr images import -

echo -e "\n[BƯỚC 2] Kiểm tra cú pháp Helm Chart (helm lint)..."
helm lint ./helm/nodejs-backend

echo -e "\n[BƯỚC 3] Triển khai ứng dụng vào namespace 'production' bằng Helm..."
helm upgrade --install backend-release ./helm/nodejs-backend \
  --namespace production \
  --create-namespace \
  --wait \
  --timeout 60s

echo -e "\n[BƯỚC 4] Kiểm tra trạng thái Deployment, Pods, Services..."
kubectl get all,hpa -n production

echo -e "\n[BƯỚC 5] Kiểm tra phản hồi qua ClusterIP Service..."
SERVICE_IP=$(kubectl get svc backend-release-nodejs-backend -n production -o jsonpath='{.spec.clusterIP}')
echo "-> Gọi thử Service IP: http://$SERVICE_IP/health"
curl -s "http://$SERVICE_IP/health"
echo ""

echo -e "\n[BƯỚC 6] Tạo image v2.0.0 để test Zero-Downtime Rolling Update..."
# Build bản v2.0.0
sudo docker tag nodejs-production:v1.0.0 nodejs-production:v2.0.0
sudo docker save nodejs-production:v2.0.0 | sudo k3s ctr images import -

echo -e "\n[BƯỚC 7] Bắt đầu Rolling Update từ v1.0.0 lên v2.0.0..."
helm upgrade backend-release ./helm/nodejs-backend \
  --namespace production \
  --set image.tag="v2.0.0"

echo "-> Quan sát quá trình thay thế Pod (Rolling Update):"
kubectl rollout status deployment/backend-release-nodejs-backend -n production

echo -e "\n[BƯỚC 8] Kiểm tra phiên bản mới sau khi Rollout..."
curl -s "http://$SERVICE_IP/health"
echo ""

echo -e "\n=========================================================="
echo "  CHÚC MỪNG! TOÀN BỘ TIÊU CHÍ MILESTONE 3 ĐÃ HOÀN TẤT!    "
echo "=========================================================="
