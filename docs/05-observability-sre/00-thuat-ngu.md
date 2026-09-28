# 00 - Từ Điển Thuật Ngữ Phase 5: Observability & SRE Practice

> Giải mã thế giới giám sát hiện đại, đo lường độ tin cậy phần mềm và các thuật ngữ SRE cốt lõi.

---

### 1. Monitoring vs Observability khác nhau thế nào?
* **Monitoring (Giám sát thụ động):** Cho bạn biết **HỆ THỐNG ĐÃ HỎNG** (Ví dụ thông báo: *"Dịch vụ Backend vừa sập lúc 2:00 AM!"*). Nó chỉ trả lời được các câu hỏi bạn đã biết trước.
* **Observability (Khả năng quan sát chủ động):** Cho bạn biết **TẠI SAO NÓ HỎNG VÀ ĐANG HỎNG Ở DÒNG CODE NÀO** dựa trên việc phân tích các dữ liệu đo đạc (Telemetry) từ bên trong app phát ra, kể cả với những lỗi kỳ dị bạn chưa từng gặp bao giờ.

### 2. Ba Trụ Cột Observability: Metrics, Logs, Traces là gì?
* **Metrics (Số liệu đo lường):** Các con số thống kê theo thời gian (ví dụ: RAM 85%, CPU 60%, 250 request/giây). Dữ liệu này cực kỳ nhẹ, dùng để phát hiện bất thường và kích hoạt cảnh báo.
* **Logs (Bản ghi nhật ký):** Các dòng chữ ghi lại chi tiết một sự kiện đã xảy ra (ví dụ: `NullPointerException at UserService.java:125`). Dữ liệu rất nặng, dùng để bóc tách chi tiết nguyên nhân.
* **Traces (Dấu vết phân tán):** Bản đồ ghi lại lộ trình di chuyển của một request khi nó chạy xuyên qua 5-10 Microservices khác nhau trong hệ thống.

### 3. Bốn Tín Hiệu Vàng (The 4 Golden Signals) là gì?
Theo chuẩn Google SRE, mọi dịch vụ backend cần tập trung theo dõi 4 chỉ số sinh mệnh:
1. **Latency (Độ trễ):** Thời gian để xử lý xong một request (tính bằng mili-giây).
2. **Traffic (Lưu lượng):** Mức độ tải của hệ thống (RPS - Requests Per Second).
3. **Errors (Tỷ lệ lỗi):** Tỷ lệ phần trăm request bị lỗi (HTTP 5xx).
4. **Saturation (Độ bão hòa):** Mức độ quá tải tài nguyên (RAM còn bao nhiêu %, DB Connection Pool đã đầy chưa).

### 4. Phân vị P95 / P99 vs Trung bình (Average) là gì?
* **Average (Trung bình cộng):** Con số "dối trá" nhất trong giám sát: Nếu 99 người vào web mất 10ms, nhưng có 1 khách hàng VIP mất tới 10 giây -> Trung bình vẫn ra con số xanh mướt ~110ms.
* **P99 (99th Percentile):** 99% người dùng phản hồi nhanh hơn con số này. Nó vạch trần ngay lập tức việc 1% khách hàng đang phải chịu đựng độ trễ 10 giây. **SRE luôn nhìn vào P95/P99, không nhìn Average.**

### 5. Prometheus & Endpoint `/metrics` là gì?
* **Prometheus:** Hệ thống mã nguồn mở số 1 để thu thập và lưu trữ Metrics dạng chuỗi thời gian (Time-Series Database).
* **Cơ chế Pull:** Prometheus định kỳ (ví dụ cứ 15 giây một lần) tự động gửi request HTTP GET tới endpoint `/metrics` của app backend để "kéo" (scrape) các số liệu đo lường về lưu trữ.

### 6. Bốn Loại Metric Cơ Bản Của Prometheus
* **Counter:** Con số chỉ tăng (hoặc về 0 khi restart app) - Dùng đếm tổng số request, tổng số lỗi.
* **Gauge:** Con số có thể tăng giảm tự do bất kỳ lúc nào - Dùng đo lượng RAM, số active WebSocket.
* **Histogram:** Gom các lần đo vào từng ngăn định sẵn (buckets) - Dùng đo độ trễ Latency.
* **Summary:** Tính toán phân vị trực tiếp tại app.

### 7. PromQL là gì?
* **Prometheus Query Language:** Ngôn ngữ truy vấn mạnh mẽ của Prometheus, giúp bạn viết các phép tính toán thời gian thực như: tính tốc độ request/giây (`rate()`) hoặc tính độ trễ phân vị P99 (`histogram_quantile()`).

### 8. Thảm Họa High-Cardinality là gì?
* **Sai lầm chết người:** Gắn các dữ liệu có hàng triệu giá trị thay đổi liên tục (như `user_id`, `order_id`, `email`) vào nhãn (Labels) của Prometheus.
* **Hậu quả:** Prometheus sinh ra hàng chục triệu Time-Series trong RAM, ngốn sạch hàng chục GB bộ nhớ và sập hoàn toàn hệ thống giám sát.

### 9. Grafana & Dashboard là gì?
* **Grafana:** Công cụ hiển thị trực quan hóa dữ liệu số 1 thế giới. Nó kết nối tới Prometheus, Loki, Tempo để vẽ ra các biểu đồ, đồng hồ đo tốc độ và bảng điều khiển (Dashboard) tuyệt đẹp cho team theo dõi.

### 10. Grafana Loki & LogQL là gì?
* **Grafana Loki:** Hệ thống quản lý log tập trung siêu tiết kiệm. Khác với ElasticSearch đắt đỏ, Loki chỉ đánh index nhãn metadata và nén nội dung log đẩy lên S3 (rẻ hơn 80%).
* **LogQL:** Cú pháp tìm kiếm log tương tự như PromQL (ví dụ: `{app="backend"} |= "NullPointer"`).

### 11. OpenTelemetry (OTel) & W3C TraceContext là gì?
* **OpenTelemetry:** Chuẩn chung của toàn cầu để thu thập dữ liệu Metrics, Logs, Traces từ ứng dụng mà không bị khóa chặt vào một hãng giám sát cụ thể nào.
* **W3C TraceContext (`traceparent`):** Header HTTP tiêu chuẩn được truyền qua lại giữa các service để mang theo cùng một `Trace ID`, giúp liên kết toàn bộ các bước gọi API của các microservices thành một sợi dây duy nhất.

### 12. Alertmanager & Alert Fatigue là gì?
* **Alertmanager:** Thành phần của Prometheus chuyên nhận các cảnh báo, gom nhóm lại, và bắn thông báo tới Slack/Telegram/PagerDuty.
* **Alert Fatigue (Chai lì cảnh báo):** Hiện tượng bot gửi quá nhiều tin nhắn rác không quan trọng khiến kỹ sư tắt thông báo, để rồi khi có sự cố sập hệ thống thật sự thì không một ai thèm đọc.

### 13. Bộ Thuật Ngữ SRE: SLI, SLO, SLA & Error Budget là gì?
* **SLI (Indicator):** Chỉ số thực tế đo được (ví dụ: Tháng này đạt 99.5% request nhanh < 200ms).
* **SLO (Objective):** Mục tiêu nội bộ kỹ thuật cam kết phấn đấu đạt được (ví dụ: Mục tiêu 99.0%).
* **SLA (Agreement):** Hợp đồng pháp lý cam kết với khách hàng, nếu không đạt phải đền bù tiền.
* **Error Budget (Ngân sách lỗi):** Tỷ lệ được phép lỗi (`100% - SLO`). Nếu ngân sách lỗi còn nhiều, team được phép ra tính năng mới thoải mái. Nếu ngân sách lỗi cạn kiệt, team phải dừng ra tính năng để tập trung sửa lỗi hệ thống.
