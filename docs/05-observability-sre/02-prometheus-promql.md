# 02 - Prometheus & PromQL Thực Chiến

> Hiểu cách ứng dụng Backend xuất số liệu (Metrics Instrumentation) và sử dụng ngôn ngữ PromQL để đo lường hiệu năng thời gian thực.

---

## 1. Bốn Loại Metric Cơ Bản Của Prometheus

| Loại Metric | Đặc điểm | Trường hợp sử dụng tiêu biểu |
| :--- | :--- | :--- |
| **Counter** | Giá trị số chỉ tăng (hoặc reset về 0 khi tiến trình restart). | Đếm tổng số request (`http_requests_total`), tổng số lỗi ngoại lệ (`exceptions_total`). |
| **Gauge** | Giá trị có thể tăng hoặc giảm tức thì bất kỳ lúc nào. | Số active WebSocket connection, dung lượng RAM sử dụng, số item trong Kafka queue. |
| **Histogram** | Gom các giá trị đo vào các ngăn kích thước định sẵn (buckets). | Đo lường thời gian phản hồi (Latency), kích thước payload request/response. |
| **Summary** | Tính toán phân vị (Percentiles) trực tiếp tại phía client ứng dụng. | Khi không cần tổng hợp qua nhiều instance khác nhau. |

---

## 2. Ứng Dụng Backend Expose Endpoint `/metrics`

Ứng dụng backend sử dụng Prometheus Client SDK (như `prom-client` cho Node.js, `client_golang` cho Go, hoặc Micrometer cho Java Spring Boot) để mở một endpoint `/metrics` định dạng plain text:

```text
# HELP http_requests_total Tong so request da nhan
# TYPE http_requests_total counter
http_requests_total{method="GET",handler="/users",status="200"} 4125
http_requests_total{method="POST",handler="/users",status="500"} 12

# HELP http_request_duration_seconds Thoi gian xu ly request
# TYPE http_request_duration_seconds histogram
http_request_duration_seconds_bucket{le="0.1"} 3200
http_request_duration_seconds_bucket{le="0.5"} 4100
http_request_duration_seconds_bucket{le="1.0"} 4130
http_request_duration_seconds_bucket{le="+Inf"} 4137
http_request_duration_seconds_sum 842.5
http_request_duration_seconds_count 4137
```

---

## 3. Các Công Thức PromQL Bắt Buộc Phải Thành Thạo

### 3.1 Tính Số Request Mỗi Giây (Throughput - RPS)
Sử dụng hàm `rate()` để tính tốc độ tăng trưởng trung bình mỗi giây trong cửa sổ 5 phút:
```promql
sum(rate(http_requests_total{app="backend-api"}[5m]))
```

### 3.2 Tính Tỷ Lệ Phần Trăm Lỗi 5xx (Error Rate %)
Lấy tổng số request lỗi 5xx chia cho tổng toàn bộ request nhận được:
```promql
(
  sum(rate(http_requests_total{app="backend-api", status=~"5.."}[5m]))
  /
  sum(rate(http_requests_total{app="backend-api"}[5m]))
) * 100
```

### 3.3 Tính Độ Trễ Phân Vị P95 và P99 (Latency Quantiles)
Tính toán thời gian mà 99% người dùng phản hồi nhanh hơn con số đó bằng `histogram_quantile`:
```promql
# Độ trễ P99
histogram_quantile(
  0.99,
  sum(rate(http_request_duration_seconds_bucket{app="backend-api"}[5m])) by (le)
)

# Độ trễ P95
histogram_quantile(
  0.95,
  sum(rate(http_request_duration_seconds_bucket{app="backend-api"}[5m])) by (le)
)
```

### 3.4 Giám Sát Mức Sử Dụng Bộ Nhớ So Với Giới Hạn Của Container
```promql
(
  container_memory_working_set_bytes{container="backend-api"}
  /
  kube_pod_container_resource_limits{container="backend-api", resource="memory"}
) * 100
```
*(Nếu chỉ số này vượt 90%, Pod đang sắp bị Linux OOM Killer bắn hạ).*
