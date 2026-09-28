# 01 - Kiến Thức Cần Nắm: Linux Internals & Networking

> Nền tảng hệ điều hành và giao thức truyền thông quyết định hiệu năng và độ ổn định của ứng dụng Backend khi tải cao.

---

## 1. Vòng Đời Tiến Trình (Process Lifecycle) & Tín Hiệu (Signals)

Trong Linux, mọi ứng dụng chạy dưới dạng một hoặc nhiều Process có ID riêng (`PID`). Ứng dụng Backend cần hiểu các tín hiệu hệ điều hành gửi tới:

* **SIGTERM (Tín hiệu số 15):** Lệnh yêu cầu ứng dụng dừng lại một cách lịch sự (*Graceful Termination*). Tiến trình có thể bắt (catch) tín hiệu này để dọn dẹp kết nối, hoàn thành nốt request hiện tại rồi mới thoát.
* **SIGKILL (Tín hiệu số 9):** Lệnh tiêu diệt tiến trình tức thì từ Kernel. Tiến trình **không thể** bắt hoặc phớt lờ tín hiệu này (dẫn đến ngắt kết nối đột ngột, hỏng transaction dữ liệu).
* **SIGINT (Tín hiệu số 2):** Ngắt từ bàn phím (khi gõ `Ctrl + C`).
* **SIGHUP (Tín hiệu số 1):** Yêu cầu tiến trình nạp lại file cấu hình (*Reload config*) mà không cần khởi động lại toàn bộ.

---

## 2. Quản Trị Dịch Vụ Với Systemd

Systemd là hệ thống khởi tạo (Init System - PID 1) chuẩn trên hầu hết các bản phân phối Linux hiện đại (Ubuntu, Debian, RHEL, CentOS).

### Cấu Trúc Unit File Chuẩn (`/etc/systemd/system/backend-api.service`)

```ini
[Unit]
Description=Production Backend API Service
After=network.target remote-fs.target
Wants=network-online.target

[Service]
Type=simple
User=appuser
Group=appuser
WorkingDirectory=/opt/backend-api
ExecStart=/opt/backend-api/bin/server
ExecReload=/bin/kill -HUP $MAINPID
Restart=always
RestartSec=5s

# Quản lý biến môi trường an toàn
Environment=NODE_ENV=production
EnvironmentFile=/opt/backend-api/.env

# Giới hạn tài nguyên ở cấp tiến trình
LimitNOFILE=65535
LimitNPROC=4096
TimeoutStopSec=30s

[Install]
WantedBy=multi-user.target
```

---

## 3. Quản Lý Tài Nguyên & Giới Hạn Hệ Điều Hành (OS Limits)

### 3.1 File Descriptors (Số Lượng File & Socket Đồng Thời)
* Trong Linux, mọi kết nối mạng (TCP socket), file trên đĩa cứng, hay pipe đều được cấp phát một **File Descriptor (FD)**.
* **Vấn đề:** Mặc định nhiều hệ điều hành giới hạn `1024` file descriptors cho mỗi tiến trình. Nếu backend có hơn 1000 kết nối đồng thời từ client hoặc database pool, server sẽ báo lỗi:
  ```text
  socket: too many open files
  ```
* **Cấu hình chuẩn hệ thống (`/etc/security/limits.conf`):**
  ```text
  *    soft    nofile    65535
  *    hard    nofile    65535
  ```

### 3.2 Bộ Nhớ Ảo (Virtual Memory) & Linux OOM-Killer
* Khi dung lượng RAM vật lý và Swap bị cạn kiệt, nhân Linux (Kernel) sẽ kích hoạt cơ chế **Out-Of-Memory Killer (OOM Killer)**.
* OOM Killer quét toàn bộ tiến trình và tính điểm `oom_score`. Tiến trình nào ngốn nhiều RAM nhất và có độ ưu tiên thấp sẽ bị gửi tín hiệu `SIGKILL` ngay lập tức để cứu hệ điều hành.
* Kiểm tra lịch sử OOM:
  ```bash
  dmesg -T | grep -E -i 'killed process|oom_reaper'
  ```

---

## 4. Networking: Socket States & Phân Giải DNS

### 4.1 Bắt Tay TCP & Các Trạng Thái Socket (Connection States)
* **ESTABLISHED:** Kết nối đã hoàn tất bắt tay 3 bước (SYN, SYN-ACK, ACK) và đang sẵn sàng truyền nhận dữ liệu.
* **TIME_WAIT:**
  * Xảy ra ở phía **chủ động đóng kết nối**. Phía này giữ socket ở trạng thái `TIME_WAIT` trong khoảng thời gian thường là 60 giây (2 * MSL - Maximum Segment Lifetime) để đảm bảo gói tin ACK cuối cùng đến đích và các gói tin lạc trôi trên mạng bị tiêu hủy.
  * Nếu hệ thống có hàng vạn kết nối ngắn hạn (short-lived HTTP) bị đóng liên tục, các cổng tạm thời (ephemeral ports) sẽ bị lấp đầy bởi `TIME_WAIT`, dẫn đến không thể mở thêm kết nối mới.
* **CLOSE_WAIT:**
  * Xảy ra ở phía **bị động nhận yêu cầu đóng kết nối**. Đầu bên kia đã gửi tín hiệu FIN, nhưng ứng dụng backend nhận được mà **chưa gọi hàm đóng socket (`close()`)**.
  * **Cảnh báo:** Quá nhiều kết nối ở trạng thái `CLOSE_WAIT` là lỗi 100% xuất phát từ code backend (rò rỉ kết nối / leak connection pool).

### 4.2 Chuỗi Phân Giải Tên Miền (DNS Resolution Chain)
```text
Ứng dụng Backend -> Local Cache (nscd / systemd-resolved) 
                -> /etc/hosts 
                -> /etc/resolv.conf (Nameservers) 
                -> DNS Resolver (Internal VPC / 8.8.8.8)
```
* Backend cần hiểu rõ cơ chế TTL (Time-To-Live) của DNS. Nếu runtime (như JVM) cấu hình cache DNS vô hạn, khi database switchover sang IP mới, app sẽ tiếp tục trỏ vào IP cũ và chết kết nối.
