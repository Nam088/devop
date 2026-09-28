# 00 - Từ Điển Thuật Ngữ DevOps Cho Backend Developer

> Giải thích toàn bộ các thuật ngữ cốt lõi bằng ngôn ngữ bình dân, ẩn dụ thực tế và góc nhìn quen thuộc của lập trình viên Backend. Không dùng định nghĩa học thuật hàn lâm.

---

## 1. Hệ Điều Hành & Hệ Thống (OS & System)

### Linux là gì?
* **Định nghĩa:** Là hệ điều hành mã nguồn mở thống trị 99% máy chủ trên toàn cầu. Khác với Windows/macOS có giao diện đồ họa đẹp mắt, Linux trên server hoạt động hoàn toàn qua cửa sổ dòng lệnh (Terminal/CLI).
* **Ẩn dụ Backend:** Nếu code Backend của bạn là chiếc xe đua, thì Linux chính là mặt đường đua. Mọi thao tác cấp phát RAM, mở kết nối socket, đọc ghi file database đều do Linux điều khiển.

### Linux Kernel (Nhân hệ điều hành) là gì?
* **Định nghĩa:** Là trái tim của Linux, đóng vai trò trung gian đứng giữa phần cứng (CPU, RAM, Ổ cứng, Card mạng) và phần mềm (App của bạn).
* **Ẩn dụ Backend:** Giống như tầng ORM/Database Driver của bạn: Code của bạn không tự tay điều khiển đĩa từ xoay hay transitor đóng ngắt, mà Kernel sẽ thay bạn làm việc đó.

### Process (Tiến trình) & Daemon là gì?
* **Process:** Một chương trình đang được nạp vào RAM và chạy (ví dụ lệnh `node server.js` sinh ra 1 Process có mã số định danh `PID`).
* **Daemon (hoặc Service):** Một process chạy ngầm vĩnh viễn ở chế độ nền (background), tự khởi động cùng máy tính và tự bật lại khi bị sập (ví dụ: Nginx, MySQL, Systemd service).

### File Descriptor (FD) là gì?
* **Định nghĩa:** Một con số nguyên mà Linux dùng để đánh dấu và quản lý một tài nguyên I/O đang mở.
* **Góc nhìn Backend:** Trong Linux, triết lý là *"mọi thứ đều là file"*. Không chỉ file text trên ổ cứng mới là file; **mỗi kết nối mạng (TCP Socket) từ client tới API hay kết nối tới Postgres cũng được Linux tính là 1 File Descriptor**. Mặc định Linux chỉ cho 1 tiến trình mở 1024 FD, nếu app có 2000 user online cùng lúc mà không tăng FD thì server sẽ báo lỗi `Too many open files`.

---

## 2. Mạng Máy Tính (Networking)

### IP Address & Port là gì?
* **IP Address:** Địa chỉ định danh duy nhất của máy tính trên mạng (ví dụ: `192.168.1.10` hoặc `142.250.190.46`).
* **Port:** Số hiệu cổng dịch vụ trên máy đó (từ 0 đến 65535).
* **Ẩn dụ:** Địa chỉ IP là **số nhà của một tòa chung cư**, còn Port là **số phòng cụ thể**. Cùng 1 tòa nhà (1 IP), phòng 80 là tiếp tân (Nginx), phòng 5432 là kho dữ liệu (Postgres), phòng 6379 là tủ đồ tạm (Redis).

### Subnet (Mạng con) & CIDR là gì?
* **Subnet:** Việc chia một dải mạng lớn thành nhiều khu vực mạng con nhỏ hơn để dễ quản lý và tăng tính bảo mật.
* **CIDR (dạng `10.0.1.0/24`):** Cách viết ký hiệu độ lớn của mạng:
  * `/24`: Mạng có $2^{(32-24)} = 256$ địa chỉ IP (thường dùng cho 1 Subnet nhỏ).
  * `/16`: Mạng có $2^{(32-16)} = 65.536$ địa chỉ IP (thường dùng cho toàn bộ hệ thống VPC của công ty).
* **Ẩn dụ:** Cả công ty thuê một tòa nhà 10 tầng (VPC). Tầng 1 mở cửa cho khách vãng lai (**Public Subnet**), Tầng 2-8 cho nhân viên ngồi code (**Private Subnet**), Tầng hầm chứa két sắt chỉ bảo vệ được vào (**Database Subnet**).

### NAT Gateway (Network Address Translation) là gì?
* **Định nghĩa:** Cổng chuyển tiếp cho phép các máy chủ nằm trong mạng kín (Private Subnet) có thể tải dữ liệu từ ngoài Internet về, nhưng chặn chiều ngược lại từ Internet tấn công vào.
* **Ẩn dụ:** Giống như **anh bảo vệ tòa chung cư**: Bạn ở trong phòng kín có thể nhờ anh bảo vệ nhận kiện hàng Shopee chuyển vào, nhưng người lạ ngoài đường không thể tự ý bước thẳng vào cửa phòng bạn.

### Reverse Proxy là gì? (Ví dụ: Nginx)
* **Forward Proxy:** Đứng trước Client để giấu danh tính Client (ví dụ: VPN vượt tường lửa).
* **Reverse Proxy:** Đứng trước các Server Backend để tiếp khách thay cho Backend. Khách hàng chỉ nói chuyện với Nginx (cổng 80/443), Nginx sẽ phân phối request vào các container Backend phía sau (cổng 8080, 8081). Backend không bao giờ phải lộ diện trực tiếp ra ngoài Internet.

---

## 3. Container & Đóng Gói (Containerization)

### Docker là gì?
* **Định nghĩa:** Công cụ giúp đóng gói mã nguồn ứng dụng cùng toàn bộ môi trường chạy (Node.js, Python, JRE, thư viện hệ thống C, biến môi trường) thành một khối duy nhất.
* **Tại sao cần:** Giải quyết triệt để câu nói kinh điển của lập trình viên: *"Code chạy ngon trên máy em, mà lên server lại lỗi!"*.

### Docker Image vs Container là gì?
* **Docker Image:** Bản thiết kế / khuôn đúc đóng băng (Read-only template).
* **Docker Container:** Một thực thể sống được đúc ra từ Image và đang chạy trong RAM.
* **Ẩn dụ Backend:** Image giống như **Class (Lớp đối tượng)** trong code OOP, còn Container giống như một **Instance (Đối tượng cụ thể)** được tạo ra bằng từ khóa `new Class()`. Từ 1 Image bạn có thể tạo ra 10 Container giống hệt nhau.

### Volume trong Docker là gì?
* **Định nghĩa:** Cơ chế gắn một thư mục trên máy thật (Host) vào bên trong Container.
* **Tại sao cần:** Container có tính chất tạm thời, khi container bị xóa, toàn bộ file bên trong nó cũng biến mất. Nếu bạn chạy Database (PostgreSQL) trong container mà không dùng Volume, mỗi lần restart container bạn sẽ **mất trắng toàn bộ dữ liệu**.

---

## 4. Điều Phối Container (Kubernetes / K8s)

### Kubernetes (K8s) là gì?
* **Định nghĩa:** Hệ thống quản lý và điều phối hàng trăm/hàng ngàn Docker container trên một cụm gồm nhiều máy chủ liên kết với nhau.
* **Ẩn dụ:** Nếu mỗi Container là một **nhạc công** chơi một loại nhạc cụ, thì Kubernetes chính là **vị nhạc trưởng**. Nhạc trưởng điều khiển ai chơi lúc nào, khi một nhạc công bị ngất xỉu thì ngay lập tức kéo người khác vào thay thế (Self-healing), khi khán phòng quá đông thì gọi thêm nhạc công (Autoscaling).

### Pod là gì?
* **Định nghĩa:** Đơn vị triển khai nhỏ nhất của Kubernetes. Một Pod thường bọc 1 container chính (App Backend của bạn) và có một địa chỉ IP nội bộ riêng.

### Node (Worker Node / Master Node) là gì?
* **Master Node (Control Plane):** Máy chủ đầu não chứa các dịch vụ chỉ huy cụm K8s.
* **Worker Node:** Các máy chủ cấu hình mạnh dùng để cắm các Pod vào chạy thực tế.

### Helm là gì?
* **Định nghĩa:** Là trình quản lý gói (Package Manager) cho Kubernetes, tương tự như `npm` trong Node.js, `maven` trong Java, hay `pip` trong Python. Thay vì viết 10 file YAML lẻ tẻ, Helm gộp tất cả lại thành một **Helm Chart** và cho phép truyền biến tùy biến theo môi trường.

---

## 5. Điện Toán Đám Mây & Hạ Tầng (Cloud & IaC)

### VPC (Virtual Private Cloud) là gì?
* **Định nghĩa:** Một trung tâm dữ liệu ảo độc lập của riêng công ty bạn được thuê trên hạ tầng khổng lồ của AWS hoặc Google Cloud. Không ai bên ngoài có thể nhìn thấy hay can thiệp vào máy chủ trong VPC của bạn trừ khi bạn chủ động mở cổng.

### IAM (Identity and Access Management) là gì?
* **Định nghĩa:** Hệ thống quản trị danh tính và cấp quyền truy cập tài nguyên trên Cloud (ai được phép làm gì, trên tài nguyên nào, vào lúc nào).

### Terraform & Infrastructure as Code (IaC) là gì?
* **IaC:** Tư duy định nghĩa toàn bộ hạ tầng (máy chủ, mạng, database, firewall) bằng các dòng mã nguồn văn bản thay vì dùng chuột click trên giao diện Web Console.
* **Terraform:** Công cụ số 1 thế giới để viết IaC. Bạn viết file `.tf` mô tả: *"Tôi muốn 1 VPC, 3 Subnet, 1 Database Postgres"*, sau đó gõ `terraform apply`, Terraform sẽ tự động gọi API của AWS để tạo chính xác những gì bạn mô tả trong vòng 2 phút.

---

## 6. Vận Hành & Đo Lường (CI/CD & SRE)

### CI/CD là gì?
* **CI (Continuous Integration - Tích hợp liên tục):** Mỗi khi dev commit code -> Hệ thống tự động kích hoạt máy ảo để tải code về, chạy Unit Test, kiểm tra lỗi cú pháp (Lint). Nếu test tạ -> Báo lỗi từ chối merge.
* **CD (Continuous Delivery / Deployment - Triển khai liên tục):** Sau khi test pass -> Hệ thống tự động build Docker Image, quét lỗ hổng bảo mật và đẩy thẳng lên môi trường Staging/Production mà không cần con người copy file thủ công.

### GitOps là gì?
* **Định nghĩa:** Phương pháp quản lý hạ tầng hiện đại lấy **Git Repository làm nguồn chân lý duy nhất**. Trạng thái của toàn bộ hệ thống máy chủ được đồng bộ tự động theo các commit trên Git. Muốn scale từ 3 pod lên 5 pod? Chỉ cần sửa số `3` thành `5` trong file YAML trên Git và merge PR.

### Observability vs Monitoring là gì?
* **Monitoring (Giám sát):** Nói cho bạn biết: *"Hệ thống vừa sập!"* (thông báo kết quả).
* **Observability (Khả năng quan sát):** Cung cấp đủ dữ liệu đo lường bên trong (Metrics, Logs, Traces) để bạn tự trả lời được: *"Tại sao nó lại sập và đang nghẽn ở dòng code nào?"*.

### 3 Trụ Cột: Metrics, Logs, Traces là gì?
* **Metrics:** Các con số thống kê theo thời gian (RAM 85%, Latency 200ms).
* **Logs:** Các dòng text ghi lại chi tiết sự kiện (`User 102 vừa thanh toán thất bại: Thẻ hết hạn`).
* **Traces:** Bản ghi lộ trình của một request khi nó chạy xuyên qua nhiều Microservices (mất 50ms ở Auth, 2000ms ở Database query, 10ms ở Payment).
