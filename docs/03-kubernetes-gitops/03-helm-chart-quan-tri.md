# 03 - Quản Lý Ứng Dụng Với Helm 3 (Package Manager)

> Biến các file manifest YAML cứng nhắc thành các mẫu động (templates) có thể tái sử dụng và quản lý triển khai đa môi trường (Dev, Staging, Production).

---

## 1. Cấu Trúc Chuẩn Của Một Helm Chart

```text
backend-chart/
├── Chart.yaml              # Thông tin metadata về chart và phiên bản ứng dụng
├── values.yaml             # Giá trị biến mặc định
├── values-staging.yaml     # Giá trị ghi đè cho môi trường Staging
├── values-prod.yaml        # Giá trị ghi đè cho môi trường Production
└── templates/              # Thư mục chứa các file template YAML
    ├── _helpers.tpl        # Các hàm tiện ích template (đặt tên, gắn nhãn)
    ├── deployment.yaml     # Template Deployment
    ├── service.yaml        # Template Service
    ├── ingress.yaml        # Template Ingress
    └── hpa.yaml            # Template HPA
```

---

## 2. File Khai Báo Biến Mẫu (`values-prod.yaml`)

```yaml
replicaCount: 5

image:
  repository: ghcr.io/yourorg/backend-api
  tag: "v1.2.0"
  pullPolicy: IfNotPresent

resources:
  requests:
    cpu: 500m
    memory: 512Mi
  limits:
    cpu: 2000m
    memory: 1024Mi

autoscaling:
  enabled: true
  minReplicas: 5
  maxReplicas: 20
  targetCPUUtilizationPercentage: 70

env:
  NODE_ENV: "production"
  LOG_LEVEL: "info"
```

---

## 3. Ví Dụ File Template (`templates/deployment.yaml`)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "backend.fullname" . }}
  labels:
    app.kubernetes.io/name: {{ .Chart.Name }}
    app.kubernetes.io/instance: {{ .Release.Name }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ include "backend.name" . }}
  template:
    metadata:
      labels:
        app: {{ include "backend.name" . }}
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: 8080
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
```

---

## 4. Các Lệnh Helm Bắt Buộc Phải Thuộc

```bash
# 1. Kiểm tra lỗi cú pháp của Chart
helm lint ./backend-chart

# 2. Render thử ra YAML mà không áp dụng vào cluster (để debug giá trị biến)
helm template backend-app ./backend-chart -f ./backend-chart/values-prod.yaml

# 3. Cài đặt hoặc Nâng cấp ứng dụng với cờ an toàn --dry-run
helm upgrade --install backend-release ./backend-chart \
  --namespace production \
  --create-namespace \
  -f ./backend-chart/values-prod.yaml \
  --dry-run

# 4. Triển khai chính thức
helm upgrade --install backend-release ./backend-chart \
  --namespace production \
  -f ./backend-chart/values-prod.yaml

# 5. Xem lịch sử các lần deploy và Rollback khi có sự cố
helm history backend-release -n production
helm rollback backend-release 1 -n production
```
