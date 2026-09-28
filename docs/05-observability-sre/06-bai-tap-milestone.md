# 06 - Bài Tập Thực Hành & Nghiệm Thu Milestone 5

> Dựng cụm giám sát toàn diện gồm Prometheus, Grafana, và cài đặt Dashboard hiển thị 4 Golden Signals cho ứng dụng Backend của bạn.

---

## 🛠️ Đề Bài Thực Hành (Hands-on Lab)

### Nhiệm Vụ 1: Xuất Metrics Từ Ứng Dụng Backend
1. Cài đặt thư viện Prometheus client vào code backend của bạn:
   * Go: `prometheus/client_golang`
   * Node.js: `prom-client`
   * Java: `micrometer-registry-prometheus`
   * Python: `prometheus_client`
2. Mở endpoint HTTP `/metrics`.
3. Khai báo 2 metric đo lường chuẩn:
   * `http_requests_total` (Counter): Đếm số lượng request kèm nhãn `method`, `path`, `status`.
   * `http_request_duration_seconds` (Histogram): Đo lường thời gian xử lý request với các buckets: `[0.05, 0.1, 0.25, 0.5, 1, 2.5, 5]`.

### Nhiệm Vụ 2: Dựng Cụm Prometheus & Grafana Bằng Docker Compose
Tạo file `docker-compose.monitoring.yml` để chạy cụm giám sát trên máy cá nhân:

```yaml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:v2.50.0
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml

  grafana:
    image: grafana/grafana:10.3.0
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
```

File `prometheus.yml`:
```yaml
global:
  scrape_interval: 5s

scrape_configs:
  - job_name: 'backend-api'
    metrics_path: '/metrics'
    static_configs:
      - targets: ['host.docker.internal:8080'] # Trỏ về app backend đang chạy trên máy
```

### Nhiệm Vụ 3: Thiết Kế Grafana Dashboard Chuẩn 4 Golden Signals
1. Mở Grafana tại `http://localhost:3000` (User: `admin`, Pass: `admin`).
2. Thêm Prometheus Data Source trỏ về `http://prometheus:9090`.
3. Tạo 4 Panels đại diện cho 4 Golden Signals:
   * **Traffic:** `sum(rate(http_requests_total[1m]))` (Đơn vị: req/s).
   * **Error Rate:** Biểu đồ phần trăm lỗi `sum(rate(http_requests_total{status=~"5.."}[1m])) / sum(rate(http_requests_total[1m])) * 100` (Đơn vị: %).
   * **Latency P95 & P99:** `histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket[1m])) by (le))` (Đơn vị: giây/ms).
   * **Saturation:** Bộ nhớ RAM hoặc số active connections.
4. Chạy tool bắn tải nhẹ và quan sát các kim đo và đồ thị trên Dashboard biến động theo thời gian thực.

---

## ✅ Bảng Kiểm Tra Nghiệm Thu (Definition of Done)

- [ ] Phân biệt được sự khác biệt giữa Metrics, Logs và Traces.
- [ ] Thành thạo 4 loại metric cơ bản của Prometheus (`Counter`, `Gauge`, `Histogram`, `Summary`).
- [ ] Tự viết được câu truy vấn PromQL tính toán độ trễ P99 và tỷ lệ % lỗi 5xx.
- [ ] Hiểu rõ thảm họa High-Cardinality để không bao giờ đưa User ID vào label của Prometheus.
- [ ] Phân biệt được SLI, SLO, SLA và biết cách đặt cảnh báo theo triệu chứng người dùng (Symptom-based).
