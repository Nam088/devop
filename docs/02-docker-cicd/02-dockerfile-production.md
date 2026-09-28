# 02 - Dockerfile Chuẩn Production (Non-Root & Multi-Stage)

> Hướng dẫn viết Dockerfile chuẩn doanh nghiệp: tối ưu dung lượng dưới 80MB, bảo mật không quyền root, và xử lý tín hiệu tắt êm ái (Graceful Shutdown).

---

## 1. Mẫu 1: Ngôn Ngữ Compile (Golang / Rust) Dùng Google Distroless

Image Distroless (`gcr.io/distroless/static-debian12`) chỉ chứa binary của bạn và các chứng chỉ SSL hệ thống. Không có shell (`/bin/sh`), không có package manager (`apt`, `apk`), ngăn chặn 99% khả năng hacker khai thác sau khi xâm nhập:

```dockerfile
# ==========================================
# GIAI ĐOẠN 1: BUILDER
# ==========================================
FROM golang:1.24-alpine AS builder

WORKDIR /src

# BƯỚC QUAN TRỌNG: Tối ưu layer caching
# Copy file khai báo dependencies trước để tận dụng cache, không tải lại nếu dependencies không đổi
COPY go.mod go.sum ./
RUN go mod download && go mod verify

# Copy mã nguồn dự án
COPY . .

# Build static binary độc lập:
# - CGO_ENABLED=0: Không phụ thuộc vào thư viện C động của máy build
# - -ldflags="-s -w": Cắt bỏ symbol table và debug info (giảm 40% kích thước binary)
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-s -w -extldflags '-static'" -o /bin/server ./cmd/api

# ==========================================
# GIAI ĐOẠN 2: RUNTIME CHUẨN PRODUCTION
# ==========================================
FROM gcr.io/distroless/static-debian12:nonroot

WORKDIR /app

# Copy binary từ builder stage
COPY --from=builder /bin/server /app/server

# Chạy với user non-root mặc định có sẵn trong Distroless (UID: 65532)
USER nonroot:nonroot

EXPOSE 8080

# BẮT BUỘC DÙNG DẠNG EXEC ARRAY: ["..."]
# Tránh dùng dạng chuỗi ("ENTRYPOINT /app/server") vì nó sẽ sinh ra /bin/sh bao bọc, nuốt mất tín hiệu SIGTERM
ENTRYPOINT ["/app/server"]
```

---

## 2. Mẫu 2: Ngôn Ngữ Thông Dịch / Bytecode (Node.js / Python)

Các ngôn ngữ như Node.js hoặc Python khi chạy trong container không tự động nhận vai trò làm PID 1 và xử lý tín hiệu `SIGTERM` đúng cách. Cần dùng **`dumb-init`** để làm tiến trình init:

```dockerfile
# ==========================================
# GIAI ĐOẠN 1: DEPENDENCIES
# ==========================================
FROM node:22-alpine AS dependencies
WORKDIR /app
COPY package.json package-lock.json ./
# npm ci đảm bảo cài đặt chính xác tuyệt đối theo lockfile
RUN npm ci --only=production

# ==========================================
# GIAI ĐOẠN 2: RUNTIME
# ==========================================
FROM node:22-alpine AS runner
WORKDIR /app

# 1. Cài dumb-init để làm proxy tín hiệu hệ điều hành
RUN apk add --no-cache dumb-init

# 2. Tạo non-root user và group rõ ràng
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 appuser

# 3. Copy file phụ thuộc và mã nguồn với quyền appuser
COPY --from=dependencies /app/node_modules ./node_modules
COPY --chown=appuser:nodejs . .

# 4. Chuyển quyền sang non-root
USER appuser

EXPOSE 3000

ENV NODE_ENV=production

# dumb-init đứng ở PID 1 để đón nhận SIGTERM và chuyển tiếp cho Node.js
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["node", "src/index.js"]
```

---

## 3. Quy Chuẩn Xử Lý Tín Hiệu (Graceful Shutdown)

Khi Docker hoặc Kubernetes muốn dừng container, nó thực hiện theo quy trình sau:
1. Gửi tín hiệu **`SIGTERM`** tới PID 1 của container.
2. Bắt đầu đếm ngược thời gian chờ (mặc định Docker là 10 giây, K8s là 30 giây).
3. Nếu sau thời gian chờ mà tiến trình chưa tắt, Kernel gửi tín hiệu **`SIGKILL`** cưỡng chế dừng lại.

### Code Backend Phải Lắng Nghe SIGTERM (Ví dụ Go & Node.js):
* **Node.js:**
  ```javascript
  process.on('SIGTERM', () => {
    console.log('Nhan SIGTERM, bat dau dong ket noi...');
    server.close(() => {
      databasePool.end();
      process.exit(0);
    });
  });
  ```
* **Golang:**
  ```go
  quit := make(chan os.Signal, 1)
  signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
  <-quit
  log.Println("Nhan SIGTERM, shuting down gracefully...")
  server.Shutdown(ctx)
  ```

---

## 4. File `.dockerignore` Chuẩn

Tránh copy rác vào build context làm chậm tốc độ gửi dữ liệu sang Docker Daemon:

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
