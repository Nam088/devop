# 02 - K8s Manifest Chuẩn Production (Zero-Downtime)

> Mẫu cấu hình YAML hoàn chỉnh cho một Backend Microservice trên môi trường Production, đảm bảo không rớt request khi cập nhật code (Zero-Downtime Deployment).

---

## 1. File Manifest Hoàn Chỉnh (`backend-production.yaml`)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-api
  namespace: production
  labels:
    app.kubernetes.io/name: backend-api
    app.kubernetes.io/component: api
    app.kubernetes.io/part-of: ecommerce-platform
spec:
  replicas: 3
  # 1. CHIẾN LƯỢC ZERO-DOWNTIME ROLLOUT
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 25%          # Cho phép tạo thêm tối đa 25% số Pod mới trong lúc rollout
      maxUnavailable: 0      # KHÔNG BAO GIỜ được thiếu bất kỳ Pod cũ nào cho tới khi Pod mới hoàn toàn sẵn sàng
  selector:
    matchLabels:
      app: backend-api
  template:
    metadata:
      labels:
        app: backend-api
    spec:
      # Thời gian chờ Pod hoàn tất việc xử lý request dở dang trước khi bị hạ
      terminationGracePeriodSeconds: 30

      containers:
      - name: backend-api
        image: ghcr.io/yourorg/backend-api:sha-7b8c9d0
        imagePullPolicy: IfNotPresent
        ports:
        - name: http
          containerPort: 8080

        # 2. GIỚI HẠN TÀI NGUYÊN (BẮT BUỘC)
        resources:
          requests:
            cpu: 200m         # K8s cam kết cấp ít nhất 0.2 core CPU
            memory: 256Mi     # K8s cam kết cấp ít nhất 256MB RAM
          limits:
            cpu: 1000m        # Giới hạn trần tối đa 1 core CPU
            memory: 512Mi     # Giới hạn trần 512MB RAM (vượt ngưỡng này sẽ bị OOMKilled)

        # 3. BỘ 3 HEALTH PROBES CHUẨN XÁC
        # a. Startup Probe: Che chở cho app trong giai đoạn khởi động (tối đa 30 x 5 = 150 giây)
        startupProbe:
          httpGet:
            path: /healthz/startup
            port: http
          failureThreshold: 30
          periodSeconds: 5

        # b. Readiness Probe: Chỉ cho Service đẩy traffic vào Pod khi endpoint này trả về HTTP 200
        readinessProbe:
          httpGet:
            path: /healthz/ready
            port: http
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 2
          failureThreshold: 2

        # c. Liveness Probe: Khởi động lại Pod nếu tiến trình bị treo hoặc deadlock
        livenessProbe:
          httpGet:
            path: /healthz/live
            port: http
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 3
          failureThreshold: 3

        # 4. TRUYỀN BIẾN MÔI TRƯỜNG TỪ CONFIGMAP VÀ SECRET
        envFrom:
        - configMapRef:
            name: backend-config
        - secretRef:
            name: backend-secret

---
apiVersion: v1
kind: Service
metadata:
  name: backend-api-svc
  namespace: production
spec:
  type: ClusterIP
  selector:
    app: backend-api
  ports:
  - name: http
    port: 80
    targetPort: 8080

---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backend-api-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend-api
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 75 # Khi CPU trung bình vượt 75%, HPA tự động scale thêm Pod
```

---

## 2. Giải Mã 3 Loại Health Probes

| Loại Probe | Mục đích | Điều gì xảy ra khi thất bại? | Lỗi thường gặp |
| :--- | :--- | :--- | :--- |
| **`startupProbe`** | Bảo vệ các ứng dụng khởi động chậm (load nhiều cache, JVM warmup, chạy DB migration). | K8s chờ đến khi probe này pass trước khi kích hoạt 2 probe còn lại. Nếu quá số lần `failureThreshold`, Pod bị restart. | Không cấu hình khiến Liveness Probe nhảy vào bắn hạ Pod ngay khi app chưa kịp khởi động xong. |
| **`readinessProbe`** | Xác định xem Pod đã sẵn sàng tiếp nhận người dùng hay chưa. | K8s **gỡ bỏ IP của Pod ra khỏi Service Endpoint**. Pod vẫn sống nhưng không nhận request nào. | Dùng chung logic với Liveness Probe. |
| **`livenessProbe`** | Phát hiện tiến trình bị treo vĩnh viễn (Deadlock, infinite loop). | K8s **tiêu diệt container và khởi động lại Pod**. | Viết logic ping Database vào đây khiến cả cụm Pod restart đồng loạt khi DB bị chậm. |
