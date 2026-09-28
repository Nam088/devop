# 04 - Các Cạm Bẫy Kinh Điển Của Backend Developer

> Những lỗi tưởng chừng là "do mạng lag" hoặc "do server yếu", nhưng 90% bắt nguồn từ việc thiếu hiểu biết về hệ điều hành và giao thức mạng.

---

## 1. Cạn Kiệt Cổng Tạm Thời (Ephemeral Port Exhaustion)

* **Hiện tượng:** Server bỗng nhiên không thể gọi sang Database, Redis, hay 3rd-party API. Log báo: `Cannot assign requested address`.
* **Nguyên nhân:**
  * Mỗi khi backend mở kết nối TCP ra ngoài, Linux cấp cho nó một cổng tạm thời trong dải `net.ipv4.ip_local_port_range` (khoảng ~28.000 ports).
  * Nếu backend dùng `HttpClient` tạo kết nối mới cho mỗi request rồi đóng ngay (không dùng Connection Pool), các socket này sẽ bị treo ở trạng thái `TIME_WAIT` trong 60 giây.
  * Hàng chục ngàn kết nối đóng dồn dập sẽ ngốn sạch toàn bộ 28.000 ports trong vòng vài phút.
* **Cách khắc phục:**
  1. **Bắt buộc dùng Connection Pool** (tái sử dụng kết nối HTTP/TCP trong code backend).
  2. Bật cờ tái sử dụng socket trong Linux Kernel:
     ```bash
     sudo sysctl -w net.ipv4.tcp_tw_reuse=1
     ```

---

## 2. Lỗi "Too many open files" (Chạm Giới Hạn File Descriptor)

* **Hiện tượng:** Server Backend chạy được vài ngày thì crash đột ngột khi traffic tăng nhẹ.
* **Nguyên nhân:**
  * Mặc định Linux chỉ cho phép 1 tiến trình mở tối đa `1024` file descriptors.
  * Khi có 500 người dùng online + 50 kết nối DB + vài file log/cấu hình mở -> Chạm ngưỡng 1024. Mọi yêu cầu kết nối mạng mới bị Kernel từ chối thẳng thừng.
* **Cách khắc phục:**
  * Luôn khai báo `LimitNOFILE=65535` trong systemd unit file (hoặc cấu hình Docker container với `ulimits.nofile`).

---

## 3. Lũ Kết Nối `CLOSE_WAIT` (Socket Leak Từ Code)

* **Hiện tượng:** Kiểm tra `ss -tan` thấy hàng nghìn socket ở trạng thái `CLOSE_WAIT`, dung lượng RAM tăng dần, server chậm dần đều.
* **Nguyên nhân:**
  * Khách hàng đóng app hoặc ngắt kết nối (Client gửi gói tin FIN).
  * Linux Kernel nhận được gói FIN và chuyển socket sang `CLOSE_WAIT`, đồng thời thông báo cho ứng dụng Backend biết.
  * **Code Backend bỏ quên việc đóng kết nối** (thiếu block `try-with-resources`, thiếu `defer resp.Body.Close()`, hoặc không đóng connection trong catch block).
* **Cách khắc phục:**
  * Đây là lỗi 100% thuộc về Code Backend. Rà soát toàn bộ các vị trí tạo socket, HTTP stream, database cursor để đảm bảo luôn đóng khi hoàn thành.

---

## 4. Bẫy Cache DNS Vô Tận Của Ngôn Ngữ Lập Trình (JVM / Node.js)

* **Hiện tượng:** Sau khi nâng cấp hoặc chuyển vùng Database/Redis, database có IP mới nhưng Backend vẫn liên tục báo lỗi `Connection refused` hoặc `Timeout` trỏ vào IP cũ.
* **Nguyên nhân:**
  * Mặc định JVM (Java) hoặc một số thư viện Node.js cache kết quả phân giải DNS vô thời hạn (TTL = -1 hoặc vô cực) khi JVM đang chạy.
* **Cách khắc phục:**
  * Cấu hình JVM DNS TTL xuống khoảng 30s đến 60s:
    `-Dnetworkaddress.cache.ttl=30` trong tham số khởi động JVM.
