# 05 - Bài Tập Thực Hành & Nghiệm Thu Milestone 1

> Hoàn thành bài tập thực hành này để đảm bảo bạn đã nắm vững toàn bộ kiến thức Phase 1 trước khi bước sang Containerization.

---

## 🛠️ Đề Bài Thực Hành (Hands-on Lab)

### Nhiệm Vụ 1: Chạy App Backend Dưới Dạng Systemd Service
1. Lấy một service backend bất kỳ (Go, Node, Java, Python).
2. Tạo file `/etc/systemd/system/my-backend.service`:
   * Chạy với non-root user (`appuser`).
   * Cấu hình tự động restart sau 5 giây nếu tiến trình crash (`Restart=always`).
   * Tăng giới hạn `LimitNOFILE=65535`.
3. Kiểm tra log ứng dụng trực tiếp bằng `journalctl -u my-backend -f`.
4. Dùng lệnh `kill -9 <PID>` để kiểm tra xem Systemd có tự động vực dậy ứng dụng hay không.

### Nhiệm Vụ 2: Dựng Nginx Reverse Proxy Đặt Phía Trước
1. Cài đặt Nginx trên máy hoặc VM.
2. Cấu hình Nginx đứng trước backend app (port 8080):
   * Cấu hình Upstream có `keepalive 32`.
   * Cấu hình Rate Limiting: 20 request/giây, burst 10.
   * Thêm các headers: `X-Forwarded-For`, `X-Real-IP`.
3. Dùng công cụ bắn tải nhẹ (`wrk -c 50 -d 10s http://localhost/`) để xem Nginx có trả mã lỗi `503 Service Temporarily Unavailable` khi vượt quá rate-limit không.

### Nhiệm Vụ 3: Đo Lường & Bắt Gói Tin Mạng
1. Viết file `curl-format.txt` và chạy lệnh curl đo TTFB của endpoint `/health`.
2. Dùng lệnh `tcpdump -nn -i any port 8080 -c 10` để xem trực tiếp các gói tin HTTP đi từ Nginx sang Backend.
3. Dùng lệnh `ss -tan` để đếm số lượng kết nối đang ở trạng thái `ESTABLISHED` và `TIME_WAIT`.

---

## ✅ Bảng Kiểm Tra Nghiệm Thu (Definition of Done)

- [ ] Hiểu rõ sự khác biệt giữa `SIGTERM` và `SIGKILL`.
- [ ] Tự viết được file `.service` cho systemd mà không cần copy máy móc.
- [ ] Biết cách dùng `ss -tulpn` để tìm port xung đột.
- [ ] Phân tích được các thông số đo lường của `curl` (DNS, TCP, TLS, TTFB).
- [ ] Giải thích được tại sao `upstream keepalive` trong Nginx lại quan trọng đối với Backend.
