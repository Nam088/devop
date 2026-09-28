# 03 - Cấu Hình Nginx Reverse Proxy Chuẩn Production

> File cấu hình hoàn chỉnh dành cho cụm Backend API, tối ưu hóa tái sử dụng kết nối TCP, bảo vệ chống DoS và đảm bảo an toàn SSL.

---

## 1. Cấu Hình Toàn Cục Tối Ưu (`/etc/nginx/nginx.conf`)

```nginx
user www-data;
# Tự động gán worker process theo số core CPU
worker_processes auto;
# Tăng giới hạn file descriptor cho worker
worker_rlimit_nofile 65535;

pid /run/nginx.pid;

events {
    # Số kết nối tối đa 1 worker có thể xử lý
    worker_connections 8192;
    # Chấp nhận nhiều kết nối cùng lúc khi có đợt traffic ùa vào
    multi_accept on;
    use epoll;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Tối ưu I/O đĩa
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;

    # Thời gian giữ kết nối với Client
    keepalive_timeout 65;
    types_hash_max_size 2048;

    # Log format chuẩn có kèm thông số thời gian response từ Backend
    log_format production_json escape=json '{'
        '"time_local":"$time_iso8601",'
        '"remote_addr":"$remote_addr",'
        '"request_method":"$request_method",'
        '"request_uri":"$request_uri",'
        '"status":$status,'
        '"body_bytes_sent":$body_bytes_sent,'
        '"request_time":$request_time,'
        '"upstream_response_time":"$upstream_response_time",'
        '"upstream_connect_time":"$upstream_connect_time",'
        '"upstream_addr":"$upstream_addr",'
        '"http_user_agent":"$http_user_agent"'
    '}';

    access_log /var/log/nginx/access.log production_json;
    error_log /var/log/nginx/error.log warn;

    # Gzip nén dữ liệu JSON/Text
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 5;
    gzip_types application/json text/plain text/css application/javascript;

    include /etc/nginx/conf.d/*.conf;
}
```

---

## 2. Cấu Hình Reverse Proxy Cho API (`/etc/nginx/conf.d/api.conf`)

```nginx
# 1. Định nghĩa rate-limiting zone dựa trên IP (10MB lưu được khoảng 160.000 IP)
limit_req_zone $binary_remote_addr zone=api_rate_limit:10m rate=30r/s;
limit_conn_zone $binary_remote_addr zone=api_conn_limit:10m;

# 2. Cụm Upstream Backend
upstream backend_api_cluster {
    server 127.0.0.1:8080 max_fails=3 fail_timeout=10s;
    server 127.0.0.1:8081 max_fails=3 fail_timeout=10s;

    # QUAN TRỌNG NHẤT: Giữ 64 kết nối idle mở sẵn tới backend server
    # Giảm thiểu 90% chi phí bắt tay TCP và SSL giữa Nginx và App Backend
    keepalive 64;
}

# Redirect HTTP -> HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name api.yourdomain.com;
    return 301 https://$host$request_uri;
}

# HTTPS Server
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name api.yourdomain.com;

    # SSL Certificates
    ssl_certificate /etc/letsencrypt/live/api.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.yourdomain.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;

    # SSL Session Caching
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off;

    # Bảo mật Headers
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Buffer giới hạn payload
    client_max_body_size 10M;
    client_body_buffer_size 128k;

    location / {
        # Áp dụng giới hạn: cho phép burst tối đa 20 request vượt ngưỡng
        limit_req zone=api_rate_limit burst=20 nodelay;
        limit_conn api_conn_limit 20;

        proxy_pass http://backend_api_cluster;

        # 3 dòng BẮT BUỘC để kích hoạt HTTP Keepalive tới Upstream
        proxy_http_version 1.1;
        proxy_set_header Connection "";

        # Chuyển tiếp Headers chuẩn
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Timeout bảo vệ
        proxy_connect_timeout 5s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;

        # Buffer phản hồi từ backend
        proxy_buffering on;
        proxy_buffer_size 8k;
        proxy_buffers 16 8k;
    }
}
```
