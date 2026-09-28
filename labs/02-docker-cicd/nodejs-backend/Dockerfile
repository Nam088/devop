# ==========================================
# GIAI ĐOẠN 1: DEPENDENCIES BUILDER
# ==========================================
FROM node:22-alpine AS dependencies

WORKDIR /app

# Tối ưu Layer Cache: Copy file định nghĩa package trước
COPY package.json ./

# Chỉ cài production dependencies, bỏ qua devDependencies
RUN npm install --only=production

# ==========================================
# GIAI ĐOẠN 2: RUNTIME CHUẨN PRODUCTION
# ==========================================
FROM node:22-alpine AS runner

WORKDIR /app

# 1. Cài đặt dumb-init để làm init process (PID 1) chuyển tiếp tín hiệu SIGTERM
RUN apk add --no-cache dumb-init

# 2. Tạo non-root user và group riêng biệt (UID 1001)
RUN addgroup -S -g 1001 nodejs && adduser -S -u 1001 appuser -G nodejs

# 3. Copy artifacts sạch từ Stage 1 sang và phân quyền cho appuser
COPY --from=dependencies /app/node_modules ./node_modules
COPY --chown=appuser:nodejs . .

# 4. CHUYỂN SANG USER NON-ROOT
USER appuser

EXPOSE 3000

ENV NODE_ENV=production
ENV PORT=3000

# Bắt buộc dạng Exec Array ["..."] để dumb-init đón nhận tín hiệu hệ thống
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["node", "src/server.js"]
