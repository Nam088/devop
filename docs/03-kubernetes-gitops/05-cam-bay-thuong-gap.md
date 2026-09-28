# 05 - Các Cạm Bẫy Thường Gặp Trong Kubernetes

> Những sai lầm phổ biến khi thiết kế ứng dụng chạy trên Kubernetes dẫn đến sự cố sập cả cụm (Cascading Outage).

---

## 1. Liveness Probe Kiểm Tra Cơ Sở Dữ Liệu (Thundering Herd)

* **Sai lầm:** Viết code cho endpoint `/healthz/live` thực hiện query `SELECT 1` tới Database PostgreSQL.
* **Kịch bản thảm họa:**
  1. Database bị nghẽn CPU tạm thời do có một câu query nặng.
  2. Thời gian phản hồi query `SELECT 1` vượt quá timeout của Liveness Probe (ví dụ > 3s).
  3. K8s kết luận toàn bộ các Pod Backend đều đã "chết". Nó lập tức ra lệnh **Restart đồng loạt 20 Pod**.
  4. 20 Pod khởi động lại cùng lúc, kết nối lại Database, khởi tạo lại connection pool.
  5. Cú sốc kết nối dồn dập này đè bẹp hoàn toàn Database -> Database sập hẳn -> Hệ thống chết lâm sàng.
* **Quy tắc vàng:**
  * **Liveness Probe:** Tuyệt đối chỉ kiểm tra cục bộ (Internal State của tiến trình: có bị deadlock không, event loop có chạy không).
  * **Readiness Probe:** Mới là nơi kiểm tra kết nối tới Database để quyết định tạm ngừng định tuyến traffic vào Pod.

---

## 2. Quên Khai Báo `requests` và `limits`

* **Nếu không khai báo `requests`:**
  * K8s Scheduler coi như Pod cần 0 CPU và 0 RAM. Nó có thể xếp 50 Pod vào chung một Worker Node, dẫn đến việc các Pod tranh chấp tài nguyên và làm treo Node.
* **Nếu không khai báo `limits.memory`:**
  * Một Pod bị rò rỉ bộ nhớ (Memory Leak) sẽ ngốn sạch toàn bộ RAM của Node. Khi Node hết RAM, Linux OOM Killer sẽ bị kích hoạt và bắn hạ các tiến trình quan trọng khác (`kubelet`, `containerd`), khiến Node chuyển sang trạng thái `NotReady`.

---

## 3. Đặt `CPU limit` Quá Thắt Chặt (Hiện Tượng CPU Throttling)

* **Bản chất:** K8s quản lý CPU limit bằng cơ chế CFS (Completely Fair Scheduler) Quota của Linux Kernel theo chu kỳ 100ms.
* **Hậu quả:** Nếu app của bạn là đa luồng (multi-threaded), nhiều luồng cùng tính toán trong vài mili-giây đầu tiên có thể dùng hết quota của chu kỳ đó. Trong thời gian còn lại của chu kỳ, Kernel sẽ **bóp băng thông CPU về 0 (Throttle)**.
* **Hiện tượng:** Ứng dụng không báo lỗi, không crash, nhưng thời gian phản hồi API (Response Time) đột ngột nhảy từ 20ms lên 2000ms.
* **Khuyến nghị hiện đại:** Đặt `requests.cpu` cẩn thận dựa trên tải thực tế, và có thể cân nhắc bỏ hẳn `limits.cpu` (hoặc đặt rất cao) đối với các app backend nhạy cảm về độ trễ.

---

## 4. Rớt Request Trong Lúc Deploy (Thiếu `preStop` Hook)

* **Hiện tượng:** Mặc dù đã cấu hình `RollingUpdate`, mỗi lần deploy phiên bản mới người dùng vẫn gặp vài lỗi `502 Bad Gateway`.
* **Nguyên nhân:** Khi Pod cũ bị xóa, K8s gửi lệnh tới Service để gỡ IP của Pod, **đồng thời** gửi tín hiệu `SIGTERM` tới Pod. Do độ trễ phân tán mạng, Ingress Controller có thể vẫn gửi request vào Pod cũ thêm 1-2 giây sau khi app đã bắt đầu tắt.
* **Khắc phục:** Thêm một đoạn delay ngắn trước khi gửi tín hiệu tắt:
  ```yaml
  lifecycle:
    preStop:
      exec:
        command: ["/bin/sh", "-c", "sleep 5"]
  ```
