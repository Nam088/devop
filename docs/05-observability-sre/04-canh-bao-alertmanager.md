# 04 - Hệ Thống Cảnh Báo Chuẩn SRE Với Alertmanager

> Nguyên tắc thiết lập cảnh báo nhắm trúng mục tiêu, loại bỏ hiện tượng chai lì cảnh báo (Alert Fatigue) và bảo vệ giấc ngủ của kỹ sư trực On-call.

---

## 1. Triết Lý Cảnh Báo SRE: Symptom-Based vs Cause-Based

* **Cause-Based Alerting (Cảnh báo theo nguyên nhân - Lối mòn cũ):**
  * *Ví dụ:* Alert khi CPU máy chủ vượt 85%.
  * *Hậu quả:* Nửa đêm bị đánh thức vì CPU lên 86% trong khi website vẫn phản hồi người dùng siêu nhanh (10ms) và không có lỗi nào xảy ra. Lâu dần kỹ sư sẽ phớt lờ toàn bộ tin nhắn từ bot.
* **Symptom-Based Alerting (Cảnh báo theo triệu chứng - Chuẩn SRE):**
  * *Ví dụ:* Alert khi tỷ lệ lỗi 5xx vượt 2% hoặc latency P95 vượt 1000ms trong 3 phút liên tiếp.
  * *Lý do:* Đây là triệu chứng **người dùng thực tế đang bị ảnh hưởng trực tiếp**. CPU 100% không quan trọng bằng việc khách hàng có bấm mua hàng được hay không.

---

## 2. File Khai Báo Cảnh Báo Mẫu (`PrometheusRule`)

File: `monitoring/rules/backend-rules.yaml`

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: backend-slo-alerts
  namespace: monitoring
  labels:
    role: alert-rules
spec:
  groups:
  - name: backend.slo.rules
    rules:
    # 1. CẢNH BÁO CRITICAL: TỶ LỆ LỖI VƯỢT SLO
    - alert: BackendHighHttpErrorRate
      expr: |
        (
          sum(rate(http_requests_total{job="backend-api", status=~"5.."}[5m]))
          /
          sum(rate(http_requests_total{job="backend-api"}[5m]))
        ) * 100 > 2.0
      for: 3m
      labels:
        severity: critical
        team: backend
      annotations:
        summary: "Tỷ lệ lỗi HTTP 5xx cao trên service {{ $labels.job }}"
        description: "Tỷ lệ lỗi đạt {{ $value | printf \"%.2f\" }}% (> 2.0%) liên tục trong 3 phút qua."
        runbook_url: "https://wiki.yourorg.com/runbooks/high-error-rate"

    # 2. CẢNH BÁO WARNING: ĐỘ TRỄ P99 BỊ NGHẼN
    - alert: BackendHighLatencyP99
      expr: |
        histogram_quantile(
          0.99,
          sum(rate(http_request_duration_seconds_bucket{job="backend-api"}[5m])) by (le)
        ) > 1.5
      for: 5m
      labels:
        severity: warning
        team: backend
      annotations:
        summary: "Độ trễ P99 vượt ngưỡng 1.5 giây"
        description: "99% request của người dùng đang mất tới {{ $value | printf \"%.2f\" }}s để hoàn tất."
        runbook_url: "https://wiki.yourorg.com/runbooks/high-latency"

    # 3. CẢNH BÁO INFRA: POD RESTART LIÊN TỤC
    - alert: PodCrashLooping
      expr: |
        sum by (pod, namespace) (increase(kube_pod_container_status_restarts_total[15m])) > 3
      for: 1m
      labels:
        severity: warning
      annotations:
        summary: "Pod {{ $labels.pod }} bị restart liên tục"
        description: "Pod đã bị khởi động lại hơn 3 lần trong 15 phút. Kiểm tra log ngay để tránh OOM hoặc crash lúc khởi động."
```

---

## 3. Điều Hướng Cảnh Báo Tới Telegram / Slack

File cấu hình của Alertmanager (`alertmanager.yaml`):

```yaml
route:
  group_by: ['alertname', 'namespace']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  receiver: 'slack-warning'
  routes:
  # Cảnh báo CRITICAL gửi thẳng về kênh On-call và Telegram
  - match:
      severity: critical
    receiver: 'pager-critical'

receivers:
- name: 'slack-warning'
  slack_configs:
  - channel: '#alerts-warning'
    send_resolved: true
    title: '[{{ .Status | toUpper }}] {{ .CommonAnnotations.summary }}'
    text: '{{ .CommonAnnotations.description }}'

- name: 'pager-critical'
  telegram_configs:
  - bot_token: '123456789:ABCdefGHIjkl...'
    chat_id: -1001234567890
    send_resolved: true
    message: "🚨 *[CRITICAL ALERT]* {{ .CommonAnnotations.summary }}\n\n{{ .CommonAnnotations.description }}\n👉 Runbook: {{ .CommonAnnotations.runbook_url }}"
```
