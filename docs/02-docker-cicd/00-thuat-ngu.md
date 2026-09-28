# 00 - Từ Điển Thuật Ngữ Phase 2: Containerization & CI/CD

> Giải mã toàn bộ các khái niệm xoay quanh Docker, Container, và tự động hóa CI/CD theo góc nhìn gần gũi của lập trình viên.

---

### 1. Container là gì?
* **Hiểu đơn giản:** Là một "chiếc hộp cách ly" đóng gói toàn bộ code của bạn kèm theo mọi thứ nó cần để chạy (Node.js/Python/Go/Java runtime, thư viện hệ thống, biến môi trường). Bạn mang chiếc hộp này quăng lên bất kỳ máy tính hay máy chủ nào có Docker thì nó đều chạy giống hệt 100%.
* **Tại sao ra đời:** Giải quyết triệt để câu nói cay đắng nhất của lập trình viên: *"Code chạy bình thường trên máy em, mà sao lên server công ty lại lỗi?"*.

### 2. Máy ảo (Virtual Machine - VM) khác Container thế nào?
* **Máy ảo (VM):** Giống như một **ngôi nhà độc lập hoàn toàn**. Nó có móng riêng, cột riêng, và có hẳn một hệ điều hành riêng (Guest OS tốn hàng gigabyte RAM, khởi động mất vài phút).
* **Container:** Giống như một **căn phòng trọ trong cùng một tòa nhà**. Các phòng dùng chung hệ thống điện nước ngầm (**chung Linux Kernel** của máy chủ host), nhưng mỗi phòng có chìa khóa riêng, không nhìn thấy phòng bên cạnh làm gì. Container khởi động chỉ mất vài mili-giây và tốn cực ít RAM.

### 3. Docker Image vs Docker Container khác nhau thế nào?
* **So sánh với Lập Trình Hướng Đối Tượng (OOP):**
  * **Docker Image** giống như **Class**: Là bản thiết kế khuôn mẫu tĩnh, được đóng băng trên đĩa cứng, không thể bị sửa đổi (Read-only).
  * **Docker Container** giống như **Instance (`new Class()`)**: Là một thực thể sống cụ thể được đúc ra từ Image, được cấp CPU/RAM và đang thực sự chạy. Từ 1 Image bạn có thể tạo ra 5 hay 10 Container cùng lúc.

### 4. Dockerfile & Image Layer Caching là gì?
* **Dockerfile:** File văn bản chứa công thức từng bước để nấu ra một Docker Image (ví dụ: lấy base image nào, copy file gì, cài thư viện nào, chạy lệnh gì).
* **Layer Caching:** Mỗi dòng lệnh trong Dockerfile tạo ra một tầng (Layer). Nếu lần build sau bạn chỉ sửa 1 dòng code mà không đổi file thư viện (`package.json`, `go.mod`), Docker sẽ tái sử dụng lại các layer cũ đã tải trước đó, giúp tốc độ build nhanh gấp 10 lần.

### 5. Namespaces & cgroups là gì? (Bản chất container)
* **Linux Namespaces:** Rào chắn cách ly tầm nhìn: Giúp container chỉ nhìn thấy các tiến trình bên trong nó và card mạng riêng của nó, không nhìn thấy các tiến trình khác của máy chủ.
* **Control Groups (cgroups):** Vòng kim cô giới hạn tài nguyên: Đảm bảo container không được dùng quá 2 core CPU hay quá 512MB RAM, tránh việc một app bị lỗi ăn sạch tài nguyên của máy chủ.

### 6. Docker Volume là gì?
* **Hiểu đơn giản:** Cơ chế khoét một lỗ hổng an toàn từ trong container cắm thẳng ra một thư mục trên ổ cứng máy thật.
* **Tại sao cần:** Container có tính chất "dùng xong rồi bỏ" (Ephemeral). Khi container bị xóa, toàn bộ dữ liệu bên trong nó biến mất sạch. Nếu bạn chạy PostgreSQL trong container mà không dùng Volume, mỗi lần restart container bạn sẽ **mất toàn bộ dữ liệu database**.

### 7. Non-root User là gì? Tại sao quan trọng?
* **Hiểu đơn giản:** Là chạy ứng dụng bên trong container bằng một tài khoản người dùng bình thường, không có quyền tối cao (root - UID 0).
* **Bảo mật:** Nếu hacker tìm ra lỗ hổng trong code Backend của bạn, nếu bạn chạy non-root, hacker chỉ bị nhốt trong tài khoản vô quyền đó. Nếu bạn chạy root, hacker có thể thoát khỏi container và cướp luôn quyền điều khiển toàn bộ máy chủ thật (**Container Escape**).

### 8. Multi-stage Build là gì?
* **Hiểu đơn giản:** Kỹ thuật chia Dockerfile thành nhiều giai đoạn (Stage).
* **Ví dụ:** Giai đoạn 1 (Builder) chứa đầy đủ SDK, compiler nặng 1GB để dịch code thành file binary. Giai đoạn 2 (Runtime) chỉ copy duy nhất file binary đó sang một image siêu nhẹ (chỉ khoảng 20MB) để mang lên production.

### 9. Google Distroless Image là gì?
* **Hiểu đơn giản:** Là loại image siêu tối giản của Google: Chỉ chứa đúng binary của bạn và chứng chỉ SSL. Nó **không có terminal (`/bin/sh`)**, không có công cụ cài đặt (`apt`, `curl`). Hacker có xâm nhập được vào cũng không có shell để gõ bất kỳ lệnh phá hoại nào.

### 10. CI (Continuous Integration) là gì?
* **Tích hợp liên tục:** Mỗi khi bạn hoặc đồng nghiệp tạo Pull Request hoặc push code lên Git, một máy chủ tự động tải code về, chạy bộ kiểm thử (Unit Test), quét lỗi cú pháp (Lint). Nếu test tạ, hệ thống sẽ chặn không cho merge code vào nhánh chính.

### 11. CD (Continuous Delivery / Deployment) là gì?
* **Triển khai liên tục:** Nối tiếp sau khi CI thành công. Hệ thống tự động đóng gói code thành Docker Image, quét lỗ hổng bảo mật, và tự động đẩy phiên bản mới lên môi trường Staging/Production mà không cần con người SSH thủ công vào server.

### 12. Artifact & Container Registry (Docker Hub, GHCR) là gì?
* **Artifact:** Thành phẩm đầu ra sau khi build (file `.jar`, file binary hoặc chính Docker Image).
* **Container Registry:** "Kho lưu trữ" chứa các Docker Image trên mạng (tương tự như GitHub là kho chứa code). Ví dụ: Docker Hub, GitHub Container Registry (GHCR), AWS ECR.

### 13. CVE & Quét Lỗ Hổng Bảo Mật (Trivy) là gì?
* **CVE (Common Vulnerabilities and Exposures):** Danh mục các lỗ hổng bảo mật đã được thế giới công bố.
* **Trivy:** Một công cụ quét bảo mật tự động: Nó soi từng gói thư viện trong Docker Image của bạn để báo xem bạn có đang dùng thư viện nào bị lỗi bảo mật mức nguy hiểm (CRITICAL) hay không.
