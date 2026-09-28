# Phase 1: Linux Internals & Networking Thực Chiến

> **Mục tiêu:** Hiểu rõ môi trường hệ điều hành nơi backend vận hành và luồng traffic mạng đi từ Client -> Reverse Proxy -> Ứng dụng.

---

## 1. Linux Internals Cần Nắm

### 1.1 Quản trị Tiến trình (Process) & Systemd
* Khác biệt giữa tiến trình chạy foreground, background (`&`, `nohup`), và quản lý bởi init system (**systemd**).
* **Systemd Service Unit chuẩn** cho backend app (`/etc/systemd/system/backend.service`):

```ini
[Unit]
Description=Backend API Service
After=network.target

[Service]
Type=simple
User=appuser
Group=appuser
WorkingDirectory=/opt/backend
ExecStart=/opt/backend/bin/server
Restart=always
RestartSec=5s
Environment=PORT=8080
EnvironmentFile=/opt/backend/.env

# Giới hạn tài nguyên ở cấp tiến trình
LimitNOFILE=65535
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
```
* **Lệnh điều khiển:**
  ```bash
  sudo systemctl daemon-reload
  sudo systemctl enable --now backend
  sudo journalctl -u backend -f --output=cat
  ```

### 1.2 Resource Limits & File Descriptors
Backend throughput cao thường bị crash do chạm ngưỡng mặc định của Linux:
* **File Descriptors (`LimitNOFILE`):** Trong Linux, "everything is a file" (mỗi socket kết nối TCP là 1 file descriptor). Nếu giới hạn mặc định là `1024`, server sẽ sập với lỗi `Too many open files`.
  * Kiểm tra giới hạn: `ulimit -n`
  * Cấu hình vĩnh viễn: `/etc/security/limits.conf`
* **Virtual Memory & OOM Killer (Out Of Memory):**
  * Khi tiến trình xin cấp phát RAM vượt giới hạn hệ thống, Linux Kernel sẽ gọi OOM Killer để bắn hạ tiến trình có điểm `oom_score` cao nhất.
  * Kiểm tra log OOM: `dmesg -T | grep -i oom`

---

## 2. Networking Thực Chiến Cho Backend

### 2.1 Luồng phân giải DNS & Socket States
* **Luồng DNS:** Client Cache -> `/etc/hosts` -> `/etc/resolv.conf` (Local resolver) -> Recursive DNS -> Authoritative DNS.
* **TCP States:**
  * `ESTABLISHED`: Kết nối đang truyền nhận data.
  * `TIME_WAIT`: Socket bên chủ động đóng đợi xác nhận gói tin muộn (thường tồn tại 60s). Quá nhiều `TIME_WAIT` làm cạn kiệt ephemeral ports.
  * `CLOSE_WAIT`: App backend nhận lệnh đóng từ client nhưng code chưa gọi hàm `.close()` socket -> **Lỗi rò rỉ socket từ code backend**.

### 2.2 Bộ Lệnh Điều Tra Mạng (Troubleshooting Toolbelt)

| Nhu cầu | Lệnh chuẩn | Mục đích kiểm tra |
| :--- | :--- | :--- |
| **Kiểm tra port lắng nghe** | `ss -tulpn` | Xem process nào đang chiếm port TCP/UDP |
| **Đo lường chi tiết HTTP** | `curl -w "@curl-format.txt" -o /dev/null -s https://api.domain.com/health` | Bóc tách thời gian DNS, Connect, TLS Handshake, TTFB |
| **Kiểm tra file/socket mở** | `lsof -i :8080` hoặc `lsof -p <PID>` | Xem bao nhiêu socket/file đang mở bởi process |
| **Bắt gói tin kiểm tra packet**| `tcpdump -nn -i any port 8080 -c 10` | Xem gói tin có đến được network interface không |
| **Kiểm tra route & latency** | `traceroute -n <IP>` / `mtr <IP>` | Phát hiện điểm tắc nghẽn hoặc rớt gói tin trên đường truyền |

*Format file đo lường `curl-format.txt`:*
```text
    time_namelookup:  %{time_namelookup}s\n
       time_connect:  %{time_connect}s\n
    time_appconnect:  %{time_appconnect}s\n
   time_pretransfer:  %{time_pretransfer}s\n
      time_redirect:  %{time_redirect}s\n
 time_starttransfer:  %{time_starttransfer}s (TTFB)\n
                    ----------\n
         time_total:  %{time_total}s\n
```

---

## 3. Cấu Hình Nginx Reverse Proxy Chuẩn Production

Tối ưu Nginx đặt trước cụm Backend application (`/etc/nginx/conf.d/api.conf`):

```nginx
# 1. Định nghĩa rate limit zone (bảo vệ DoS/Brute Force)
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=50r/s;

# 2. Cấu hình Upstream backend với Keepalive connections
upstream backend_cluster {
    server 127.0.0.1:8080 max_fails=3 fail_timeout=10s;
    server 127.0.0.1:8081 backup;

    # QUAN TRỌNG: Duy trì kết nối TCP mở sẵn tới backend, tránh lặp lại TCP handshake
    keepalive 64;
}

server {
    listen 80;
    server_name api.example.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.example.com;

    ssl_certificate /etc/letsencrypt/live/api.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.example.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    # Tối ưu kích thước buffer
    client_max_body_size 20M;
    client_body_buffer_size 128k;

    location / {
        limit_req zone=api_limit burst=100 nodelay;

        proxy_pass http://backend_cluster;
        
        # Bắt buộc cho HTTP keepalive tới upstream
        proxy_http_version 1.1;
        proxy_set_header Connection "";

        # Chuyển tiếp đúng metadata của client
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Timeouts
        proxy_connect_timeout 5s;
        proxy_read_timeout 60s;
        proxy_send_timeout 60s;
    }
}
```

---

## 4. Các Lỗi Kinh Điển Backend Developer Hay Mắc Phải

1. **Quên cấu hình Keepalive Upstream trên Reverse Proxy:**
   * Mặc định Nginx dùng HTTP/1.0 và gửi header `Connection: close` tới upstream backend. Mỗi request tạo mới 1 kết nối TCP -> dẫn đến cạn kiệt cổng (port exhaustion) khi traffic cao.
2. **Không phân biệt DNS TTL và App DNS Caching:**
   * Ngôn ngữ như Java mặc định cache DNS vĩnh viễn (hoặc rất lâu). Khi địa chỉ IP backend hoặc Database thay đổi sau khi switchover, app tiếp tục gọi vào IP cũ và chết kết nối.
3. **Bỏ qua Timeouts:**
   * Không set `connect_timeout` và `read_timeout` trên client HTTP pool ở code backend, dẫn đến hiện tượng cascade failure khi một service phụ trợ bị treo.

---

## 5. Tiêu Chuẩn Hoàn Thành (Milestone 1 Checklist)

- [ ] Viết được file `systemd` service chuẩn để chạy ứng dụng và tự restart khi sập.
- [ ] Sử dụng thành thạo `ss`, `curl -w`, `lsof` để phân tích độ trễ và số lượng kết nối của service.
- [ ] Dựng được Nginx làm reverse proxy xử lý SSL termination, rate limiting và chuyển tiếp headers đúng chuẩn.
- [ ] Giải thích được nguyên nhân gây ra trạng thái `TIME_WAIT` và `CLOSE_WAIT`.
