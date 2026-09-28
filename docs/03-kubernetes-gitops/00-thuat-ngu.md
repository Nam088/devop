# 00 - Từ Điển Thuật Ngữ Phase 3: Kubernetes (K8s) & GitOps

> Giải mã hệ sinh thái điều phối container Kubernetes và triết lý GitOps bằng các so sánh thực tế dễ nhớ nhất.

---

### 1. Kubernetes (K8s) là gì?
* **Hiểu đơn giản:** Là một hệ thống mã nguồn mở dùng để tự động hóa việc triển khai, mở rộng quy mô (scale) và quản lý hàng trăm/hàng ngàn Docker container trên một cụm máy chủ liên kết với nhau.
* **Ẩn dụ:** Nếu mỗi Container là một **nhạc công** chơi một loại nhạc cụ riêng, thì Kubernetes chính là **vị nhạc trưởng tài ba**. Nhạc trưởng ra hiệu cho ai chơi lúc nào, khi một nhạc công bị ngất xỉu thì lập tức kéo người khác vào thay thế (**Self-healing**), khi khán phòng quá đông khách thì vẫy tay gọi thêm dàn nhạc công (**Autoscaling**).

### 2. Cluster là gì?
* **Hiểu đơn giản:** Là một "đội quân" gồm nhiều máy chủ vật lý hoặc máy ảo được gom lại với nhau, chia sẻ chung sức mạnh CPU và RAM dưới sự chỉ huy thống nhất của Kubernetes.

### 3. Master Node (Control Plane) vs Worker Node là gì?
* **Master Node (Bộ não):** Máy chủ chỉ huy, chỉ chứa các dịch vụ điều hành hệ thống, không chạy code ứng dụng của bạn.
* **Worker Node (Cửu vạn):** Các máy chủ cấu hình mạnh dùng để cắm các container của bạn vào chạy thực tế.

### 4. Bốn Cơ Quan Đầu Não Của Master Node
* **`kube-apiserver` (Tiếp tân):** Cổng giao tiếp duy nhất của K8s. Mọi lệnh bạn gõ (`kubectl`) hay các thành phần nội bộ muốn nói chuyện với nhau đều phải đi qua API Server.
* **`etcd` (Sổ cái kế toán):** Cơ sở dữ liệu dạng Key-Value cực kỳ an toàn, lưu trữ toàn bộ trạng thái sống còn của cả cụm K8s.
* **`kube-scheduler` (Người phân công):** Xem xét Pod mới cần bao nhiêu CPU/RAM để chọn Worker Node nào còn chỗ trống phù hợp nhất nhằm xếp Pod vào đó.
* **`kube-controller-manager` (Đốc công giám sát):** Liên tục kiểm tra xem trạng thái thực tế có đúng như mong muốn không (ví dụ bạn bảo cần 3 Pod, mà hiện chỉ có 2 Pod sống thì nó lập tức ra lệnh tạo thêm 1 Pod).

### 5. `kubelet` & `kube-proxy` Trên Worker Node
* **`kubelet` (Đội trưởng tại chỗ):** Chạy trên từng Worker Node, nhận lệnh từ Master Node để điều khiển Docker/containerd bật hoặc tắt container.
* **`kube-proxy` (Cảnh sát giao thông):** Cài đặt các luật chuyển tiếp mạng (iptables) trên từng Node để đảm bảo traffic gửi tới Service được phân phối tới đúng Pod.

### 6. Pod là gì?
* **Hiểu đơn giản:** Là đơn vị triển khai nhỏ nhất của K8s. K8s **không bao giờ quản lý một container trần trụi**, mà bọc container đó vào một cái kén gọi là **Pod**.
* **Đặc điểm:** Các container trong cùng 1 Pod dùng chung một địa chỉ IP nội bộ và có thể gọi nhau qua `localhost`. Pod có tính chất "sinh tử" liên tục: Khi Pod chết, IP của nó biến mất và Pod thay thế sẽ có IP hoàn toàn mới.

### 7. Deployment & ReplicaSet là gì?
* **Deployment:** Là bản mô tả cấp cao nói cho K8s biết: *"Tôi muốn ứng dụng backend này chạy phiên bản image `v1.2`, luôn duy trì 3 bản sao (`replicas: 3`)"*.
* **ReplicaSet:** Là công cụ thực thi cấp dưới do Deployment tạo ra để trực tiếp đếm và giữ đúng số lượng Pod luôn bằng 3.

### 8. Service (`ClusterIP`, `NodePort`, `LoadBalancer`) là gì?
* Vì các Pod sinh ra và chết đi liên tục với IP luôn thay đổi, **Service** sinh ra để làm một **địa chỉ IP ảo cố định** và tên miền nội bộ đại diện cho cả nhóm Pod:
  * **`ClusterIP` (Mặc định):** Chỉ các service nằm bên trong cụm K8s mới gọi được nhau (Internal).
  * **`NodePort`:** Mở một cổng tĩnh (từ 30000-32767) trên tất cả các Worker Node để máy ngoài gọi vào.
  * **`LoadBalancer`:** Gọi trực tiếp Cloud (AWS/GCP) tự động tạo bộ cân bằng tải thật trỏ vào K8s.

### 9. Ingress & Ingress Controller là gì?
* **Ingress:** Luật định tuyến HTTP/HTTPS ở cửa ngõ Cluster (Layer 7). Ví dụ: `api.domain.com/users` trỏ vào User-Service, `api.domain.com/orders` trỏ vào Order-Service.
* **Ingress Controller:** Phần mềm thực tế đứng ở cổng để thực thi các luật Ingress đó (phổ biến nhất là **Nginx Ingress Controller**).

### 10. Bộ 3 Health Probes (`Startup`, `Readiness`, `Liveness`) là gì?
* **`startupProbe`:** Dành cho app khởi động nặng (load cache/DB). Trong lúc probe này đang chạy, K8s không can thiệp.
* **`readinessProbe`:** App đã sẵn sàng tiếp khách chưa? Nếu chưa (đang bận kết nối DB), K8s tạm thời ngắt traffic không gửi request vào Pod.
* **`livenessProbe`:** Tiến trình có bị deadlock/treo vĩnh viễn không? Nếu fail, K8s lập tức **khởi động lại Pod**.

### 11. RollingUpdate & Zero-Downtime là gì?
* Cơ chế cập nhật ứng dụng của K8s: Bật Pod mới lên, chờ Pod mới khỏe mạnh sẵn sàng tiếp khách (`Readiness pass`), rồi mới từ từ tắt Pod cũ đi. Người dùng hoàn toàn không hề nhận ra hệ thống vừa được nâng cấp code mới (**Zero-Downtime**).

### 12. Helm & Helm Chart là gì?
* **Helm:** Là trình quản lý gói (Package Manager) cho K8s, giống như `npm` của Node.js hay `pip` của Python.
* **Helm Chart:** Một bộ khung đóng gói sẵn toàn bộ YAML (Deployment, Service, Ingress), cho phép bạn chỉ cần thay đổi 1 file biến `values.yaml` là có thể deploy lên bất kỳ môi trường nào (Dev, Staging, Prod).

### 13. GitOps & ArgoCD là gì?
* **GitOps:** Triết lý lấy **Git Repository làm nguồn chân lý duy nhất (Single Source of Truth)**. Trạng thái của toàn bộ hệ thống máy chủ được đồng bộ tự động theo Git. Không ai gõ lệnh deploy từ máy cá nhân lên server production nữa.
* **ArgoCD:** Công cụ GitOps số 1 hiện nay. ArgoCD chạy bên trong K8s, liên tục nhìn vào Git. Mỗi khi bạn merge code đổi tag image trên Git, ArgoCD tự động kéo và cập nhật K8s ngay lập tức.
