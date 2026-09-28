# 05 - Các Cạm Bẫy Thường Gặp Về Giám Sát & SRE

> Những sai lầm kinh điển khiến hệ thống giám sát tự lăn ra sập trước khi kịp cảnh báo cho người dùng, hoặc gửi cảnh báo rác làm tê liệt đội ngũ kỹ sư.

---

## 1. Thảm Họa Nổ Lũy Thừa Nhãn (High Cardinality Explosion)

* **Sai lầm:** Đưa các trường dữ liệu có giá trị động không giới hạn vào nhãn (Labels) của Prometheus:
  ```go
  // CỰC KỲ NGUY HIỂM: Đưa User ID hoặc Order ID vào Label
  httpRequestsTotal.WithLabelValues(method, path, statusCode, userId, orderId).Inc()
  ```
* **Bản chất:** Trong Prometheus, mỗi tổ hợp duy nhất của các nhãn (Labels) tạo ra **một Time-Series hoàn toàn riêng biệt trong RAM**.
  * Nếu bạn có: 5 methods x 20 paths x 5 status codes = **500 Time-Series** (Hoàn toàn bình thường).
  * Nhưng nếu bạn thêm `user_id` (100.000 users): 500 x 100.000 = **50.000.000 Time-Series**!
* **Hậu quả:** Bộ nhớ RAM của Prometheus server tăng vọt từ 1GB lên 64GB chỉ trong vài giờ và bị Linux OOM Killer bắn sập. Toàn bộ hệ thống giám sát bị mù hoàn toàn.
* **Quy tắc:**
  * **Chỉ đặt nhãn cho các giá trị có tập hợp hữu hạn, cố định** (như `method: GET/POST`, `status: 200/500`, `environment: prod`).
  * Nếu muốn tìm theo `user_id` hay `order_id`, hãy tìm trong **Logs (Loki)** hoặc **Traces (Tempo)**, tuyệt đối không đưa vào Metrics.

---

## 2. Ghi Log Cả Thông Tin Nhạy Cảm (PII & Credentials Leak)

* **Sai lầm:** In toàn bộ payload JSON của request hoặc in toàn bộ Headers vào file log:
  ```json
  {"path": "/login", "headers": {"Authorization": "Bearer eyJhbGci..."}, "body": {"password": "secretPassword123"}}
  ```
* **Hậu quả:** File log thường được tập trung về một dashboard chung (Grafana/Kibana) cho hàng chục kỹ sư, tester cùng xem. Việc lộ mật khẩu, số thẻ ngân hàng, JWT token trong log là vi phạm nghiêm trọng các tiêu chuẩn bảo mật quốc tế (PCI-DSS, ISO 27001, GDPR) và có thể bị phạt nặng.
* **Quy tắc:** Luôn cài đặt bộ lọc (Masking / Redaction) trong logger của Backend code để tự động che các trường nhạy cảm (`***`) trước khi ghi ra stdout.

---

## 3. Đo Lường Bằng Giá Trị Trung Bình (Average vs Percentiles)

* **Sai lầm:** Giám sát hiệu năng API bằng biểu đồ "Thời gian phản hồi trung bình" (Average Response Time).
* **Bản chất toán học:** Trung bình cộng che giấu hoàn toàn các giá trị dị biệt (Outliers):
  * Giả sử 99 khách hàng truy cập mất **10 mili-giây**.
  * Nhưng có 1 khách hàng VIP nạp đơn hàng lớn mất tới **10 giây**.
  * Con số trung bình hiển thị trên dashboard: `~110ms` (Trông rất đẹp và xanh mướt).
  * Nhưng thực tế: 1% khách hàng quan trọng nhất đang gặp sự cố nghiêm trọng mà bạn không hề hay biết!
* **Quy tắc:** Luôn theo dõi bằng **P95** (95% request nhanh hơn mốc này) và **P99** (99% request nhanh hơn mốc này).
