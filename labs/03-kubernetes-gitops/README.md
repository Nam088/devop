# Lab Phase 3: Kubernetes & GitOps Thực Chiến

Thư mục này chứa toàn bộ mã nguồn Helm Chart, kịch bản kiểm thử tự động, và cấu hình ArgoCD cho ứng dụng Node.js Backend chạy trên cụm Kubernetes (K3s).

---

## 1. Cấu Trúc Thư Mục

```text
labs/03-kubernetes-gitops/
├── helm/
│   └── nodejs-backend/           # Production Helm Chart
│       ├── Chart.yaml            # Metadata Chart
│       ├── values.yaml           # Cấu hình replicas, resources, probes, ingress, strategy
│       └── templates/            # K8s manifest templates
│           ├── _helpers.tpl      # Naming & Labeling helpers chuẩn K8s
│           ├── deployment.yaml   # Deployment kèm Startup/Readiness/Liveness + PreStop Hook
│           ├── service.yaml      # ClusterIP Service
│           ├── ingress.yaml      # Traefik Ingress route host: nodejs.devops.local
│           └── hpa.yaml          # HorizontalPodAutoscaler (CPU 80%, min 3, max 10)
├── argocd/
│   └── application.yaml          # Declarative ArgoCD Application manifest (GitOps)
└── scripts/
    ├── verify-milestone3.sh      # Kịch bản kiểm thử toàn diện toàn bộ tiêu chí Milestone 3
    └── test-zero-downtime.sh     # Kịch bản bắn HTTP tải liên tục kiểm chứng 100% Zero-Downtime
```

---

## 2. Các Kỹ Thuật Đạt Chuẩn Production

1. **Bộ 3 Health Probes (Startup / Readiness / Liveness):**
   - `startupProbe`: Cho phép ứng dụng có tối đa 30s khởi động, ngăn chặn K8s giết nhầm Pod khi đang boot cold.
   - `readinessProbe`: Chỉ chuyển Pod sang trạng thái `Ready` (cho phép Ingress/Service chuyển traffic) sau khi endpoint `/health` trả về 200.
   - `livenessProbe`: Tự động khởi động lại container nếu phát hiện deadlock hoặc process bị treo.

2. **Cơ Chế Thoát Mượt Mà (Graceful Shutdown & PreStop Hook):**
   - `lifecycle.preStop.exec`: Lệnh `sleep 2` giữ cho container tiếp tục nhận các packet đang trên đường truyền trong khi `kube-proxy` và `endpoints-controller` đang xóa IP của Pod khỏi iptables/IPVS.
   - `terminationGracePeriodSeconds: 30`: Cho phép Node.js hoàn thành các request dở dang trước khi nhận `SIGKILL`.

3. **Chiến Lược RollingUpdate Không Gián Đoạn (Zero-Downtime Strategy):**
   - `maxSurge: 1`: Khởi tạo Pod mới trước khi xóa bất kỳ Pod cũ nào.
   - `maxUnavailable: 0`: Đảm bảo luôn duy trì tối thiểu 100% số lượng Pod khả dụng (3/3 Pods) trong toàn bộ quá trình cập nhật phiên bản.

4. **Bảo Mật Tiến Trình:**
   - Container chạy hoàn toàn dưới quyền `appuser` (UID: 1001, non-root).

---

## 3. Hướng Dẫn Thực Thi & Nghiệm Thu

### Bước 1: Chạy kiểm thử tự động toàn bộ Milestone 3
```bash
bash labs/03-kubernetes-gitops/scripts/verify-milestone3.sh
```

### Bước 2: Kiểm chứng Zero-Downtime Rollout với lưu lượng thực tế
```bash
bash labs/03-kubernetes-gitops/scripts/test-zero-downtime.sh
```
*Kết quả yêu cầu: 100% requests thành công (HTTP 200), tỷ lệ lỗi = 0.00%.*

### Bước 3: Kiểm tra Ingress từ máy Host
```bash
curl -H "Host: nodejs.devops.local" http://192.168.252.2/health
```
