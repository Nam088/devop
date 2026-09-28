# AGENT LAB INSTRUCTIONS: devops-lab Environment Guide

> Tài liệu hướng dẫn dành cho các AI Agent (Antigravity, Cursor, Claude, v.v.) và kỹ sư cộng tác để tương tác, thực thi lệnh và thử nghiệm hạ tầng trên môi trường máy ảo `devops-lab`.

---

## 1. Thông Tin Môi Trường (Environment Specs)

* **Nền tảng ảo hóa:** [Canonical Multipass](https://multipass.run/) (chạy trực tiếp trên macOS ARM64 / Apple Silicon).
* **Tên máy ảo (VM Instance Name):** `devops-lab`
* **Hệ điều hành:** Ubuntu 24.04 LTS (aarch64 / Linux 6.8+).
* **Tài khoản mặc định:** `ubuntu` (có toàn quyền `sudo` không cần mật khẩu).
* **Địa chỉ IP nội bộ:** Được gán tự động qua bridge/DHCP của Multipass (hiện tại: `192.168.252.2`).

---

## 2. Cách Agent Thực Thi Lệnh Vào Máy Ảo

Mọi Agent có quyền truy cập shell trên máy chủ Host (macOS) có thể điều khiển `devops-lab` theo 2 phương thức:

### Cách 1: Sử dụng Native SSH (Khuyên dùng - Nhanh nhất)
Máy Mac đã được cấu hình sẵn alias `devops-lab` và SSH Key riêng biệt tại `~/.ssh/devops/id_ed25519`.
Đặc biệt, kết nối được cấu hình qua **`ProxyCommand multipass exec devops-lab -- nc 127.0.0.1 22`**, giúp đảm bảo **kết nối bất tử 100% không bao giờ bị đứt dù IP máy ảo có thay đổi hay Mac reboot**.

```bash
# Thực thi lệnh từ xa không cần nhập password (hoạt động bất kể IP là gì)
ssh devops-lab "uptime; uname -a"

# Chạy lệnh yêu cầu quyền root
ssh devops-lab "sudo systemctl status nginx"

# Copy file từ máy Mac vào máy ảo
scp ./myfile.conf devops-lab:/home/ubuntu/
```

### Cách 2: Sử dụng CLI của Multipass (Phương án dự phòng nếu SSH lỗi)
```bash
multipass exec devops-lab -- bash -c "<lệnh cần chạy>"
```

---

## 3. Quản Trị Vòng Đời Máy Ảo (VM Lifecycle)

Trước khi thực thi các bài lab, Agent nên kiểm tra trạng thái máy ảo:

```bash
# 1. Kiểm tra trạng thái máy ảo
multipass list

# 2. Khởi động máy ảo (nếu đang ở trạng thái Stopped)
multipass start devops-lab

# 3. Tắt máy ảo để giải phóng RAM sau khi hoàn tất bài test nặng
multipass stop devops-lab

# 4. Kiểm tra IP hiện tại (nếu cần truy cập HTTP trực tiếp qua IP)
multipass info devops-lab | grep IPv4
```

> **Lưu ý:** SSH `devops-lab` đã dùng `ProxyCommand` nên không phụ thuộc vào IP. Đồng thời, cổng web `80` của máy ảo đã được ánh xạ tự động qua `LocalForward 8080 127.0.0.1:80` (truy cập tại `http://localhost:8080` trên máy Mac).

---

## 4. Quy Tắc Thực Thi An Toàn Cho AI Agent

1. **Tránh treo lệnh (Non-Interactive Execution):**
   * Luôn thêm cờ `-y` và tắt interactive prompt khi cài package:
     ```bash
     ssh devops-lab "sudo DEBIAN_FRONTEND=noninteractive apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y <package>"
     ```
2. **Không đọc hoặc in Private Key:**
   * Tuyệt đối không chạy lệnh `cat` hiển thị file private key trong thư mục `~/.ssh/`.
3. **Chạy dịch vụ ngầm an toàn:**
   * Không chạy trực tiếp các tiến trình blocking (như `node server.js` hoặc `python app.py`) trên foreground qua SSH session. Luôn đóng gói chúng dưới dạng **Systemd Service** (theo chuẩn [docs/01-linux-networking/01-kien-thuc-can-nam.md](file:///Users/nam088/code/nam088/devop/docs/01-linux-networking/01-kien-thuc-can-nam.md)) hoặc chạy qua `systemctl start`.

---

## 5. Mở Trực Tiếp Code Bằng IDE

* **Zed Editor:**
  ```bash
  zed ssh://devops-lab/home/ubuntu
  ```
* **VS Code:**
  ```bash
  code --remote ssh-remote+devops-lab /home/ubuntu
  ```
