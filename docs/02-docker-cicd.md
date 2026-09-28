# Phase 2: Production Containerization & CI/CD Pipelines

> **Mục tiêu:** Đóng gói ứng dụng thành container bất biến (immutable), an toàn, tối ưu dung lượng, và tự động hóa quy trình test, quét lỗ hổng và phát hành qua CI/CD.

---

## 1. Bản Chất Của Container (Không Phải Virtual Machine)

Container là một tiến trình thông thường của Linux được cách ly bởi:
1. **Linux Namespaces:** Cách ly tầm nhìn (PID: process tree, NET: card mạng/IP, MNT: filesystem, IPC: bộ nhớ dùng chung, USER: phân quyền user).
2. **Control Groups (cgroups v2):** Giới hạn tài nguyên phần cứng (CPU shares/quota, Memory limit, I/O bandwidth).
3. **Overlay2 (Union File System):** Ghép các tầng (layers) read-only của image và 1 tầng read-write trên cùng của container.

---

## 2. Dockerfile Chuẩn Production (Non-Root & Multi-Stage)

### 2.1 Mẫu Cho Ngôn Ngữ Compile (Golang / Rust)
Tạo image siêu nhẹ (<25MB), bảo mật tuyệt đối với Google Distroless hoặc Scratch:

```dockerfile
# ==========================================
# GIAI ĐOẠN 1: BUILDER
# ==========================================
FROM golang:1.24-alpine AS builder

WORKDIR /src

# Tối ưu layer cache: copy file dependency trước
COPY go.mod go.sum ./
RUN go mod download && go mod verify

COPY . .

# Build static binary: tắt cgo, strip debug symbols (-ldflags "-s -w")
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-s -w -extldflags '-static'" -o /bin/server ./cmd/api

# ==========================================
# GIAI ĐOẠN 2: RUNTIME (DISTROLESS)
# ==========================================
# gcr.io/distroless/static-debian12 không có shell, không package manager -> Giảm 99% bề mặt tấn công
FROM gcr.io/distroless/static-debian12:nonroot

WORKDIR /app

# Copy binary từ builder stage
COPY --from=builder /bin/server /app/server

# Chạy với user non-root mặc định (UID: 65532)
USER nonroot:nonroot

EXPOSE 8080

# Chạy trực tiếp binary dạng exec, KHÔNG dùng shell wrapper
ENTRYPOINT ["/app/server"]
```

### 2.2 Mẫu Cho Ngôn Ngữ Thông Dịch / JRE (Node.js / Python / Java)
Đảm bảo bắt tín hiệu `SIGTERM` chuẩn xác (tránh bị kill cưỡng bức sau 10s timeout):

```dockerfile
FROM node:22-alpine AS dependencies
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --only=production

FROM node:22-alpine AS runner
WORKDIR /app

# Tạo non-root user và group rõ ràng
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 appuser

COPY --from=dependencies /app/node_modules ./node_modules
COPY --chown=appuser:nodejs . .

# Cài đặt dumb-init để làm init process chuyển tiếp tín hiệu SIGTERM
RUN apk add --no-cache dumb-init

USER appuser
EXPOSE 3000

ENV NODE_ENV=production
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["node", "src/index.js"]
```

### 2.3 Quy Chuẩn `.dockerignore` Bắt Buộc
```text
.git
.github
node_modules
dist
target
*.log
.env*
!*.env.example
docker-compose*.yml
Dockerfile*
README.md
```

---

## 3. GitHub Actions CI/CD Pipeline Chuẩn

Pipeline hoàn chỉnh gồm 3 công đoạn:
1. **Lint & Test:** Kiểm tra cú pháp và chạy unit test.
2. **Vulnerability Scan:** Quét CVE của Docker image bằng **Trivy**.
3. **Buildx & Push:** Build đa kiến trúc (amd64/arm64) kèm cache thông minh `type=gha`.

File: `.github/workflows/ci-cd.yml`

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ main ]
    tags: [ 'v*.*.*' ]
  pull_request:
    branches: [ main ]

permissions:
  contents: read
  packages: write
  security-events: write

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  test:
    name: Run Tests
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Set up Go (hoặc Node/Python)
        uses: actions/setup-go@v5
        with:
          go-version: '1.24'
          cache: true

      - name: Run Unit Tests
        run: go test -v -race ./...

  build-and-scan:
    name: Build & Security Scan
    needs: test
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Build Local Image for Scanning
        uses: docker/build-push-action@v6
        with:
          context: .
          load: true
          tags: ${{ env.IMAGE_NAME }}:scan-temp
          cache-from: type=gha
          cache-to: type=gha,mode=max

      # Quét lỗ hổng bằng Trivy trước khi push
      - name: Scan Image with Trivy
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ${{ env.IMAGE_NAME }}:scan-temp
          format: 'sarif'
          output: 'trivy-results.sarif'
          severity: 'CRITICAL,HIGH'
          exit-code: '1' # Sẽ fail pipeline nếu phát hiện lỗ hổng CRITICAL
        continue-on-error: false

      - name: Log in to GHCR
        if: github.event_name != 'pull_request'
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract Metadata (Tags & Labels)
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=semver,pattern={{version}}
            type=sha,format=short,prefix=sha-

      - name: Build and Push Docker Image
        if: github.event_name != 'pull_request'
        uses: docker/build-push-action@v6
        with:
          context: .
          platforms: linux/amd64,linux/arm64
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

---

## 4. Các Lỗi Phổ Biến Cần Tránh

1. **Chạy container dưới quyền `root`:**
   * Nếu kẻ tấn công khai thác được lỗi RCE (Remote Code Execution) trong app backend, họ sẽ có quyền root ngay trong container và có khả năng escape container để chiếm quyền máy chủ host.
2. **Dùng tag `:latest` trong production:**
   * `:latest` không bất biến (mutable). Bạn sẽ không thể biết container đang chạy bản commit nào, khiến việc rollback khi có sự cố trở thành thảm họa. **Luôn tag bằng Git SHA ngắn (`sha-xxxx`) hoặc Semantic Version (`v1.2.3`)**.
3. **Hardcode secret hoặc file `.env` vào image:**
   * Mọi file copy vào image đều nằm vĩnh viễn trong các layer lịch sử (kể cả khi bạn chạy `rm .env` ở lệnh sau). Image có thể bị xem trộm bằng công cụ như `dive`.
4. **Không xử lý `SIGTERM` (Graceful Shutdown):**
   * Nếu app backend không lắng nghe tín hiệu `SIGTERM`, khi Docker hoặc K8s muốn tắt Pod, container sẽ treo và bị `SIGKILL` sau 10 giây -> làm ngắt kết nối dở dang của database transaction hoặc request của client.

---

## 5. Tiêu Chuẩn Hoàn Thành (Milestone 2 Checklist)

- [ ] Viết Dockerfile multi-stage tối ưu size (<80MB cho compile apps, <150MB cho node/python).
- [ ] Container bắt buộc chạy với non-root user (UID khác 0).
- [ ] Cấu hình Graceful Shutdown trong backend code để hứng `SIGTERM` và đóng connection pool sạch sẽ.
- [ ] Dựng GitHub Actions pipeline tự động chạy test, quét Trivy và build image đa kiến trúc push lên Registry.
