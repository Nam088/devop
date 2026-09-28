# 03 - Quản Lý Ứng Dụng Với Helm 3 (Package Manager & Template Engine)

> Hướng dẫn toàn diện dành cho Backend Developer: Helm là gì, tại sao không dùng YAML chay, và giải phẫu chi tiết 4 thành phần cốt lõi (`ingress`, `service`, `deployment`, `hpa`) trong luồng xử lý của Kubernetes.

---

## 1. Helm Là Gì? Vì Sao Không Thể Dùng YAML Chay?

### 1.1. Nỗi Đau Của Kubernetes YAML Chay (Raw Manifests)
Khi mới làm quen với Kubernetes, chúng ta thường viết các file YAML tĩnh và chạy `kubectl apply -f app.yaml`. Tuy nhiên, trong môi trường doanh nghiệp thực tế, cách này bộc lộ những nhược điểm chí mạng:

* **Trùng Lặp Mã Nguồn Khủng Khiếp (DRY Violation):** Một hệ thống luôn có nhiều môi trường (`dev`, `staging`, `production`). Cấu trúc ứng dụng giống nhau 95%, nhưng chỉ khác:
  * `dev`: 1 replica, CPU 50m, image tag `feat-auth`, domain `dev.api.local`
  * `prod`: 5 replicas, CPU 500m, image tag `v1.2.0`, domain `api.company.com`
  * Nếu dùng YAML chay, bạn phải duy trì hàng chục file YAML riêng biệt. Khi cần đổi 1 biến môi trường hay chỉnh sửa port, bạn phải đi sửa tay trên từng file.
* **Không Có Khái Niệm Phiên Bản & Rollback Gói:** Khi một đợt deploy gồm 5 file YAML (Deployment, Service, Ingress, HPA, ConfigMap) bị lỗi, `kubectl` không có khái niệm gom nhóm chúng lại để rollback đồng bộ.

### 1.2. Helm Giải Quyết Bài Toán Như Thế Nào?
Đối với một lập trình viên Backend, Helm đóng 2 vai trò quen thuộc:
1. **Template Engine (như EJS, Blade, Jinja2, Pug):** Bạn viết một bộ khung manifest duy nhất chứa các biến giữ chỗ (ví dụ: `{{ .Values.replicaCount }}`). Tất cả biến số được tách ra file `values.yaml` (tương đương file `.env` hoặc file config trong Backend).
2. **Package Manager (như `npm`, `pip`, `composer`):** Đóng gói toàn bộ ứng dụng thành 1 đơn vị gọi là **Helm Chart**. Cho phép cài đặt (`helm install`), nâng cấp (`helm upgrade`), và "quay xe" khẩn cấp (`helm rollback <release> <revision>`) chỉ bằng 1 lệnh duy nhất.

```text
       File Giá Trị (.env)                    Khung Mẫu Chung (Template)
     [ values.yaml ]            +            [ deployment.yaml ]
(chứa: replicas, cpu, image...)             (chứa: {{ .Values.replicas }}...)
                                     │
                                     ▼
                        Lệnh `helm upgrade --install`
                                     │
                                     ▼
                      Sinh ra file K8s Manifest hoàn chỉnh 
                      và nạp trực tiếp vào Kubernetes API!
```

---

## 2. Giải Phẫu Thư Mục Helm Chart Chuẩn Production

Một Helm Chart tiêu chuẩn (như trong bài lab [labs/03-kubernetes-gitops/helm/nodejs-backend/](file:///Users/nam088/code/nam088/devop/labs/03-kubernetes-gitops/helm/nodejs-backend)) có cấu trúc như sau:

```text
nodejs-backend/
├── Chart.yaml                  # Metadata của Chart (Tên app, phiên bản chart, phiên bản app)
├── values.yaml                 # File cấu hình mặc định (Source of Truth cho các biến số)
└── templates/                  # Thư mục chứa các bản mẫu manifest Kubernetes
    ├── _helpers.tpl            # Chứa các hàm tiện ích chung (đặt tên, gắn nhãn k8s chuẩn)
    ├── ingress.yaml            # Cửa đón khách (Layer 7 Ingress Controller)
    ├── service.yaml            # Bộ cân bằng tải nội bộ & DNS tĩnh (ClusterIP)
    ├── deployment.yaml         # Quản đốc tiến trình Pods, Health Probes & Zero-Downtime
    └── hpa.yaml                # Bộ tự động co giãn theo tải (Horizontal Pod Autoscaler)
```

---

## 3. Hành Trình Của Một HTTP Request Qua 4 Thành Phần K8s

Để hiểu vì sao cần đủ cả 4 file trong `templates/`, hãy theo dõi đường đi của 1 request gửi từ trình duyệt người dùng vào code Node.js:

```text
Client (Trình duyệt người dùng)
       │  gửi request: https://nodejs.devops.local/health
       ▼
┌─────────────────────────────────────────────────────────────┐
│ 1. INGRESS (ingress.yaml)                                   │
│    - Giống Nginx Reverse Proxy ở cửa ngõ                    │
│    - Lắng nghe Port 80/443, đọc Host Header và Path         │
│    - Định tuyến request vào Service tương ứng               │
└──────────────────────────────┬──────────────────────────────┘
                               │ chuyển tiếp nội bộ qua mạng CNI
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. SERVICE (service.yaml)                                   │
│    - Bộ cân bằng tải nội bộ (Layer 4 Internal Load Balancer)│
│    - Tạo ra IP cố định (ClusterIP) & Tên miền nội bộ        │
│    - Phân phối đều request tới các Pod đang ở trạng thái Ready│
└──────────────────────────────┬──────────────────────────────┘
                               │ phân phối tải (Round Robin)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. DEPLOYMENT (deployment.yaml)                             │
│    - Quản đốc quản lý các tiến trình (giống PM2 Cluster)    │
│    - Duy trì số lượng Pod (ví dụ: 3 Pods chạy song song)    │
│    - Quản lý vòng đời: Startup/Readiness/Liveness + PreStop │
└──────────────────────────────▲──────────────────────────────┘
                               │ tự động tăng/giảm số lượng Pod
┌──────────────────────────────┴──────────────────────────────┐
│ 4. HPA (hpa.yaml - Horizontal Pod Autoscaler)               │
│    - Giám sát CPU/RAM qua metrics-server                    │
│    - Tự động scale từ 3 lên tối đa 10 Pods khi CPU vượt 80% │
└─────────────────────────────────────────────────────────────┘
```

---

## 4. Chi Tiết Vai Trò Của Từng Thành Phần Trong `templates/`

### 4.1. `ingress.yaml` - Cửa Đón Khách (Layer 7 Reverse Proxy)
* **Tương đương Backend:** Nginx Reverse Proxy hoặc AWS ALB (Application Load Balancer).
* **Vì sao cần?**
  * Kubernetes chạy trên một dải mạng ảo riêng biệt (`10.42.0.0/16`). Các thiết bị bên ngoài Internet không thể trỏ thẳng vào IP của từng Pod bên trong cụm.
  * `Ingress` đóng vai trò là điểm tiếp nhận lưu lượng duy nhất từ bên ngoài vào. Nó phân tích tên miền (`Host: nodejs.devops.local`) và tiền tố đường dẫn (`/api/v1/...`) để quyết định chuyển tiếp traffic tới Service nào.
* **Cấu hình thực tế:**
  ```yaml
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: {{ include "nodejs-backend.fullname" . }}
  spec:
    ingressClassName: traefik
    rules:
      - host: {{ .Values.ingress.host }}
        http:
          paths:
            - path: /
              pathType: Prefix
              backend:
                service:
                  name: {{ include "nodejs-backend.fullname" . }}
                  port:
                    number: {{ .Values.service.port }}
  ```

---

### 4.2. `service.yaml` - Danh Bạ Cố Định & Cân Bằng Tải Nội Bộ (Layer 4)
* **Tương đương Backend:** Tổng đài CSKH nội bộ hoặc Internal VIP Load Balancer.
* **Vì sao cần? (Vấn đề chí mạng của Pod IP):**
  * Trong K8s, **Pods là tài nguyên phù du (ephemeral)**. Mỗi khi Pod bị crash, restart, hoặc rollout phiên bản mới, K8s sẽ cấp cho nó một địa chỉ IP hoàn toàn mới.
  * Nếu các thành phần khác gọi thẳng vào Pod IP, hệ thống sẽ gãy ngay lập tức khi Pod bị khởi động lại.
  * `Service` sinh ra một địa chỉ IP ảo cố định duy nhất (**ClusterIP**) và một tên miền DNS nội bộ (ví dụ: `backend-service.production.svc.cluster.local`). Địa chỉ này tồn tại vĩnh viễn suốt vòng đời ứng dụng.
  * `Service` liên tục theo dõi danh sách Pod thông qua nhãn (`labels`) và tự động chia đều request đến các Pod đang khỏe mạnh.

---

### 4.3. `deployment.yaml` - Quản Đốc Vòng Đời Tiến Trình (Process Manager)
* **Tương đương Backend:** **PM2 (Cluster Mode)** hoặc **Systemd**, nhưng ở quy mô toàn cụm máy chủ.
* **Nhiệm vụ:**
  * Đảm bảo luôn có đúng số lượng bản sao mong muốn (`replicaCount: 3`). Nếu một container chết bất đắc kỳ tử (OOMKilled, Uncaught Exception), Deployment tự động bật container mới thay thế.
  * **Giải mã 4 chốt chặn kỹ thuật chuẩn Production bên trong Deployment:**

#### ① `startupProbe` ("Đang nạp dữ liệu, đừng giục!")
* **Vấn đề:** Ứng dụng Node.js khi khởi động cần kết nối Database, load schema, đọc secret mất khoảng 3 - 5 giây.
* **Cơ chế:** K8s sẽ kiên nhẫn đợi probe này vượt qua (pass) rồi mới kích hoạt các probe khác. Giúp bảo vệ ứng dụng không bị K8s giết nhầm khi đang khởi động nguội (cold boot).

#### ② `readinessProbe` ("Đã sẵn sàng nhận khách chưa?")
* **Vấn đề:** Ứng dụng đã bật, nhưng chưa hoàn tất kết nối Redis/DB. Nếu lúc này đẩy request vào, người dùng sẽ lập tức nhận lỗi `500` hoặc `502`.
* **Cơ chế:** Chỉ khi endpoint `/health` trả về mã `200`, K8s mới thêm IP của Pod vào danh bạ của Service để nhận lưu lượng. Nếu Pod bị nghẽn, IP sẽ tạm thời bị rút ra, không để khách gặp lỗi.

#### ③ `livenessProbe` ("Còn thở hay đã tê liệt?")
* **Vấn đề:** Tiến trình Node.js bị dính lỗi Deadlock hoặc Event Loop bị block 100%. Container vẫn "sống" (PID vẫn chạy) nhưng không xử lý được request nào.
* **Cơ chế:** Cứ mỗi 5 giây gõ cửa `/health` một lần. Nếu liên tiếp 3 lần không trả lời, K8s kết luận tiến trình đã tê liệt và ra lệnh tiêu diệt để tạo mới.

#### ④ `lifecycle.preStop` & Graceful Shutdown ("Khoan hãy tắt, chờ 2 giây!")
* **Bí quyết đạt 100% Zero-Downtime:**
  * Khi cập nhật code mới, K8s phát lệnh xóa Pod cũ.
  * Tuy nhiên, hệ thống mạng (`iptables`, `kube-proxy`, `Ingress`) mất khoảng 1-2 giây để gỡ IP của Pod cũ ra khỏi danh sách định tuyến.
  * Nếu Pod cũ tắt ngay lập tức, các request đang trên đường truyền sẽ rơi vào khoảng trống và dính lỗi `Connection Refused` hoặc `502 Bad Gateway`.
  * Nhờ lệnh `lifecycle.preStop: sleep 2`, container sẽ kiên nhẫn đợi mạng cập nhật xong, xử lý nốt các kết nối dở dang rồi mới an toàn tắt hẳn.

---

### 4.4. `hpa.yaml` - Tự Động Co Giãn Theo Tải (Horizontal Pod Autoscaler)
* **Tương đương Backend:** Kịch bản Auto-scaling tự động của Cloud (AWS EC2 Auto Scaling / CloudWatch Alarm).
* **Vì sao cần?**
  * Giúp hệ thống tự thích ứng với các đợt bùng nổ traffic (Flash Sale, giờ cao điểm).
  * K8s liên tục đọc chỉ số CPU/RAM từ `metrics-server`. Khi CPU trung bình của cụm Pod vượt quá ngưỡng quy định (ví dụ: `80%`), HPA tự động gọi lệnh tăng số Pod từ 3 lên 4, 5... tối đa 10 Pods.
  * Khi hết giờ cao điểm, tải giảm xuống, HPA sẽ từ từ hạ số Pod về lại 3 để tiết kiệm chi phí điện toán máy chủ.

---

## 5. Bảng Đối Chiếu Khái Niệm Giữa Backend & Kubernetes Helm

| Khái Niệm Trong K8s / Helm | Tương Đương Trong Thế Giới Backend | Mục Đích Cốt Lõi |
| :--- | :--- | :--- |
| **`Chart.yaml`** | `package.json` / `composer.json` | Khai báo metadata, tên gói và phiên bản phần mềm. |
| **`values.yaml`** | File `.env` / `config.json` | Lưu trữ toàn bộ biến số cấu hình động độc lập với mã nguồn. |
| **`ingress.yaml`** | Nginx Reverse Proxy (Port 80/443) | Cửa ngõ định tuyến tên miền bên ngoài vào dịch vụ bên trong. |
| **`service.yaml`** | Internal Load Balancer / DNS tĩnh | Tạo địa chỉ IP cố định, cân bằng tải giữa các Pod. |
| **`deployment.yaml`** | PM2 Cluster / Supervisor | Quản lý tiến trình, tự phục hồi lỗi và kiểm soát vòng đời Pod. |
| **`startupProbe`** | Database Connection Check on Boot | Bảo vệ app trong giai đoạn khởi động nguội. |
| **`readinessProbe`** | Endpoint `/ready` kiểm tra phụ thuộc | Ngăn chặn đẩy khách vào Pod khi chưa sẵn sàng. |
| **`livenessProbe`** | Heartbeat / Watchdog check | Tự động khởi động lại container khi bị treo Event Loop. |
| **`lifecycle.preStop`** | Server Drainage Hook | Giữ Pod sống thêm 2s để mạng rút IP, chống rớt gói tin. |
| **`hpa.yaml`** | Auto Scaling Policy | Tự động tăng Pod khi quá tải, giảm Pod khi vắng khách. |

---

## 6. Các Lệnh Thao Tác Helm Thường Dùng Nhất

```bash
# 1. Kiểm tra tính hợp lệ của cú pháp Chart
helm lint ./helm/nodejs-backend

# 2. Xem trước toàn bộ YAML được render ra (rất hữu ích để debug biến)
helm template backend-release ./helm/nodejs-backend

# 3. Cài đặt hoặc Nâng cấp an toàn (Idempotent Deployment)
helm upgrade --install backend-release ./helm/nodejs-backend \
  --namespace production \
  --create-namespace \
  --wait \
  --timeout 60s

# 4. Kiểm tra lịch sử các lần triển khai
helm history backend-release -n production

# 5. Quay xe khẩn cấp về bản trước khi bản mới bị lỗi
helm rollback backend-release 1 -n production
```
