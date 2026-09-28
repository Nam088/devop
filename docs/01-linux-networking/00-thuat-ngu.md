# 00 - Từ Điển Thuật Ngữ Phase 1: Linux & Mạng Cho Backend Dev

> Giải thích các khái niệm hệ điều hành và mạng máy tính bằng ngôn ngữ đời thường, so sánh trực quan với thế giới Backend.

---

### 1. Linux là gì?
* **Hiểu đơn giản:** Là hệ điều hành máy tính mã nguồn mở (tương tự như Windows hay macOS), nhưng gần như 100% máy chủ Internet chạy Linux. Trên server, Linux không có chuột click hay màn hình Desktop bóng bẩy, bạn làm việc với nó hoàn toàn qua cửa sổ dòng lệnh chữ trắng nền đen (**Terminal**).
* **Ẩn dụ Backend:** Nếu code Backend của bạn là **chiếc xe đua F1**, thì Linux chính là **mặt đường đua**. Mọi thứ như cấp RAM, mở kết nối Database hay ghi log xuống ổ đĩa đều do Linux trực tiếp quản lý.

### 2. Linux Kernel (Nhân hệ điều hành) là gì?
* **Hiểu đơn giản:** Là phần cốt lõi nằm sâu nhất của Linux, đứng làm cầu nối giữa phần cứng máy chủ (CPU, thanh RAM, Ổ cứng SSD, Card mạng) và các chương trình phần mềm (Node.js, Java, Go, Python).
* **Ẩn dụ Backend:** Kernel giống như **Database Driver / ORM**: Code của bạn không tự tay điều khiển đĩa từ xoay hay kích hoạt vi mạch, bạn chỉ cần ra lệnh cho Kernel và Kernel sẽ thay bạn làm việc đó.

### 3. Process (Tiến trình) & PID là gì?
* **Process:** Mỗi khi bạn chạy một ứng dụng (ví dụ gõ lệnh `node server.js`), hệ điều hành sẽ nạp code vào RAM và sinh ra một tiến trình đang hoạt động gọi là Process.
* **PID (Process ID):** Là số CMND/Căn cước định danh của tiến trình đó trong hệ điều hành (ví dụ PID `1245`).

### 4. Daemon & Systemd Service là gì?
* **Daemon:** Một tiến trình chạy ngầm vĩnh viễn ở chế độ nền (background), không chiếm màn hình dòng lệnh của bạn.
* **Systemd Service:** Công cụ quản lý tiến trình chuẩn số 1 của Linux. Nó giống như **người bảo mẫu cho ứng dụng Backend**: Bạn khai báo app vào systemd, nó sẽ tự bật app khi máy tính khởi động, và quan trọng nhất: **khi app của bạn crash sập, systemd tự động hồi sinh app lại sau 5 giây**.

### 5. Signal (Tín hiệu) & `SIGTERM` vs `SIGKILL` là gì?
* **Signal:** Cách hệ điều hành gửi "tin nhắn" yêu cầu một tiến trình làm gì đó.
* **SIGTERM (Tín hiệu số 15):** Lệnh lịch sự: *"Chuẩn bị đóng cửa nhé"*. Ứng dụng Backend có thể bắt tín hiệu này, xử lý xong các request dở dang, đóng kết nối Database rồi mới tắt hẳn (**Graceful Shutdown**).
* **SIGKILL (Tín hiệu số 9):** Lệnh rút phích cắm: *"Chết ngay lập tức!"*. Ứng dụng không kịp trở tay, toàn bộ dữ liệu đang ghi dở bị ngắt đột ngột.

### 6. File Descriptor (FD) là gì?
* **Hiểu đơn giản:** Một con số nguyên mà Linux dùng để quản lý một cổng vào/ra (I/O) đang mở.
* **Góc nhìn Backend:** Linux có triết lý nổi tiếng: *"Everything is a file"* (Mọi thứ đều là file). Không chỉ file `.txt` trên ổ cứng mới là file: **Mỗi kết nối mạng (TCP Socket) từ user tới API hay kết nối tới Postgres cũng được Linux tính là 1 File Descriptor**.
* **Tại sao cần quan tâm:** Linux mặc định chỉ cho 1 tiến trình mở 1024 FD. Nếu backend có hơn 1000 người kết nối đồng thời, server sẽ sập với lỗi `Too many open files`.

### 7. OOM-Killer (Out Of Memory Killer) là gì?
* **Hiểu đơn giản:** Là "sát thủ" dọn dẹp bộ nhớ của Linux Kernel. Khi máy chủ bị cạn kiệt RAM, Kernel sẽ tìm tiến trình nào ngốn nhiều RAM nhất mà ít quan trọng nhất để bắn hạ (`SIGKILL`) ngay lập tức nhằm cứu sống hệ điều hành không bị đơ cứng.

### 8. IP Address & Port là gì?
* **IP Address:** Địa chỉ định danh của một máy tính trên mạng (ví dụ `192.168.1.1` hoặc `142.250.190.46`).
* **Port:** Số hiệu cổng của dịch vụ cụ thể trên máy đó (từ 0 đến 65535).
* **Ẩn dụ:** Địa chỉ IP là **số nhà của một tòa chung cư**, còn Port là **số phòng cụ thể**. Cùng một tòa nhà (1 IP), phòng 80 là Lễ tân (Nginx), phòng 5432 là Kho két sắt (Postgres), phòng 6379 là Tủ đồ tạm (Redis).

### 9. TCP Handshake & Socket là gì?
* **Socket:** Điểm đầu mút để hai máy tính truyền nhận dữ liệu với nhau (gồm IP nguồn, Port nguồn, IP đích, Port đích).
* **TCP 3-Way Handshake (Bắt tay 3 bước):** Trước khi truyền dữ liệu, Client và Server phải gửi 3 gói tin chào hỏi nhau (SYN -> SYN-ACK -> ACK) để đồng ý mở kết nối.

### 10. `TIME_WAIT` & `CLOSE_WAIT` là gì?
* **`TIME_WAIT`:** Trạng thái bên chủ động ngắt kết nối (thường là Nginx hoặc Client) phải ngồi đợi 60 giây trước khi cổng đó được tái sử dụng, để tránh nhận nhầm các gói tin đến muộn. Nếu đóng mở kết nối liên tục, máy sẽ bị hết cổng mạng tạm thời (**Port Exhaustion**).
* **`CLOSE_WAIT`:** Đầu bên kia đã xin đóng, nhưng code Backend của bạn nhận được tín hiệu mà **quên không gọi lệnh đóng socket**. Quá nhiều `CLOSE_WAIT` là lỗi 100% do code Backend làm rò rỉ kết nối (Connection Leak).

### 11. DNS (Domain Name System) là gì?
* **Hiểu đơn giản:** Là "danh bạ điện thoại" của Internet, giúp chuyển đổi tên miền dễ nhớ (như `api.google.com`) thành địa chỉ IP thực tế (`142.250.190.46`).

### 12. Reverse Proxy là gì? (Ví dụ: Nginx)
* **Forward Proxy:** Đứng trước máy Client để che giấu danh tính người dùng (ví dụ phần mềm VPN).
* **Reverse Proxy:** Đứng trước các máy chủ Backend để tiếp khách thay cho Backend. Khách hàng chỉ nói chuyện với Nginx (cổng 80/443), Nginx kiểm tra SSL, lọc bot xấu, rồi mới đẩy request vào các container Backend phía sau (cổng 8080).
