# 06 - Bài Tập Thực Hành & Nghiệm Thu Milestone 3

> Thực hành dựng cụm Kubernetes nội bộ trên máy cá nhân (k3d), đóng gói Helm Chart và thiết lập luồng triển khai tự động bằng ArgoCD.

---

## 🛠️ Đề Bài Thực Hành (Hands-on Lab)

### Nhiệm Vụ 1: Khởi Tạo Cụm K8s Đa Node Bằng `k3d`
Cài đặt `k3d` (chạy cụm K8s siêu nhẹ k3s bên trong Docker trên máy Mac/Linux):
```bash
# Tạo cụm gồm 1 Master Node và 2 Worker Nodes, mở port 80/443 vào máy thật
k3d cluster create dev-cluster \
  --servers 1 \
  --agents 2 \
  --port 80:80@loadbalancer \
  --port 443:443@loadbalancer

# Kiểm tra trạng thái các node
kubectl get nodes
```

### Nhiệm Vụ 2: Đóng Gói Ứng Dụng Thành Helm Chart
1. Khởi tạo cấu trúc chart: `helm create my-backend-chart`
2. Tinh chỉnh `values.yaml` và `templates/`:
   * Khai báo đầy đủ `startupProbe`, `readinessProbe`, `livenessProbe`.
   * Cấu hình chiến lược `RollingUpdate` (`maxSurge: 25%`, `maxUnavailable: 0`).
   * Khai báo tài nguyên: `requests.cpu: 100m`, `limits.cpu: 500m`.
3. Cài đặt vào namespace `staging`:
   ```bash
   helm upgrade --install my-backend ./my-backend-chart \
     --namespace staging --create-namespace
   ```

### Nhiệm Vụ 3: Kiểm Chứng Zero-Downtime Rollout
1. Mở một terminal riêng và chạy vòng lặp bắn request liên tục vào service:
   ```bash
   while true; do curl -s -o /dev/null -w "%{http_code}\n" http://localhost:80/healthz; sleep 0.1; done
   ```
2. Ở terminal thứ hai, tiến hành cập nhật phiên bản image mới:
   ```bash
   helm upgrade my-backend ./my-backend-chart --set image.tag="v2.0.0" -n staging
   ```
3. **Tiêu chuẩn nghiệm thu:** Toàn bộ mã phản hồi ở terminal 1 phải luôn là `200`, không được xuất hiện bất kỳ mã `502` hay `Connection refused` nào trong suốt quá trình Pod mới thay thế Pod cũ.

### Nhiệm Vụ 4: Triển Khai ArgoCD & Đồng Bộ Tự Động
1. Cài đặt ArgoCD lên cụm:
   ```bash
   kubectl create namespace argocd
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   ```
2. Tạo file `Application` YAML trỏ vào repo chứa Helm Chart của bạn.
3. Kích hoạt tính năng `syncPolicy.automated`: Thay đổi một giá trị trên Git, quan sát ArgoCD tự phát hiện và sync cập nhật lên K8s trong vòng 3 phút.

---

## ✅ Bảng Kiểm Tra Nghiệm Thu (Definition of Done)

- [ ] Hiểu rõ vai trò của Control Plane components (`kube-apiserver`, `etcd`, `scheduler`).
- [ ] Phân biệt được khi nào dùng Service `ClusterIP` và khi nào dùng `Ingress`.
- [ ] Tự viết được Helm Chart tham số hóa được image, replicas, env vars.
- [ ] Thực hiện thành công một đợt Rolling Update Zero-Downtime.
- [ ] Thiết lập thành công ArgoCD theo đúng chuẩn GitOps Declarative.
