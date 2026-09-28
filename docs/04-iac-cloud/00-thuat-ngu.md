# 04 - Từ Điển Thuật Ngữ Phase 4: Hạ Tầng Đám Mây & Terraform

> Làm sáng tỏ các thuật ngữ mạng Cloud (VPC, Subnet, NAT Gateway), quản trị phân quyền IAM, và tự động hóa hạ tầng bằng Terraform.

---

### 1. Public Cloud (AWS, GCP, Azure) là gì?
* **Hiểu đơn giản:** Là dịch vụ cho thuê tài nguyên máy tính khổng lồ (máy chủ, ổ đĩa, mạng, cơ sở dữ liệu) qua mạng Internet. Thay vì công ty bạn phải bỏ tiền tỷ mua máy chủ vật lý đặt trong phòng lạnh, bạn chỉ cần lên AWS thuê và trả tiền theo từng giây sử dụng (**Pay-as-you-go**).

### 2. Region & Availability Zone (AZ) là gì?
* **Region (Khu vực địa lý):** Một vùng vật lý trên thế giới nơi đặt các trung tâm dữ liệu của Cloud (ví dụ: `ap-southeast-1` là Singapore, `us-east-1` là Bắc Virginia).
* **Availability Zone - AZ (Vùng sẵn sàng):** Mỗi Region chứa nhiều AZ tách biệt nhau về nguồn điện, hệ thống mạng và vị trí địa lý (cách nhau vài chục km) để chống thảm họa. Ví dụ nếu sét đánh sập toàn bộ 1 AZ, các AZ còn lại trong cùng Region vẫn hoạt động bình thường (**High Availability - HA**).

### 3. VPC (Virtual Private Cloud) là gì?
* **Hiểu đơn giản:** Là một "trung tâm dữ liệu ảo độc lập" của riêng công ty bạn trên đám mây của AWS. Không ai ngoài Internet có thể nhìn thấy hay chạm vào các máy chủ trong VPC của bạn trừ khi bạn chủ động mở cổng.

### 4. Subnet (Mạng con) & Ký Hiệu CIDR là gì?
* **Subnet:** Việc chia dải mạng VPC lớn thành các khu vực mạng con nhỏ hơn để phân quyền và cô lập bảo mật.
* **Ký hiệu CIDR (như `10.0.1.0/24`):** Quy định số lượng địa chỉ IP mà mạng đó sở hữu:
  * `/24`: Có $2^{(32-24)} = 256$ địa chỉ IP (dành cho 1 Subnet).
  * `/16`: Có $2^{(32-16)} = 65.536$ địa chỉ IP (dành cho cả cụm VPC).

### 5. Ba Tầng Subnet Tiêu Chuẩn Trong Doanh Nghiệp
* **Public Subnet (Tầng mặt tiền):** Mở cửa tự do ra Internet -> Chứa Load Balancer (ALB) hoặc Nginx để đón khách từ Internet vào.
* **Private Subnet (Tầng nội bộ):** Không có IP công khai, người ngoài không thể kết nối vào -> Nơi đặt các máy chủ chạy code Backend API và worker.
* **Database Subnet (Tầng hầm cô lập):** Cấm hoàn toàn mọi đường đi ra/vào Internet -> Nơi đặt cơ sở dữ liệu (PostgreSQL, MySQL, Redis), chỉ chấp nhận kết nối từ Private Subnet.

### 6. Internet Gateway (IGW) vs NAT Gateway là gì?
* **Internet Gateway (IGW):** Chiếc cầu 2 chiều nối Public Subnet với toàn bộ mạng Internet toàn cầu (cho phép người ngoài vào và máy trong đi ra).
* **NAT Gateway (Cổng 1 chiều):** Cho phép các máy chủ trong Private Subnet có thể tải dữ liệu từ ngoài Internet về (để tải thư viện code, cập nhật bản vá OS), nhưng **chặn tuyệt đối chiều ngược lại** không cho hacker ngoài Internet kết nối trực tiếp vào máy chủ backend.
* **Ẩn dụ:** NAT Gateway giống như **anh bảo vệ tòa chung cư**: Bạn ở trong phòng kín có thể nhờ anh nhận bưu phẩm Shopee mang lên, nhưng người giao hàng không được phép tự xông vào cửa phòng ngủ của bạn.

### 7. Security Group (SG) là gì?
* **Hiểu đơn giản:** Là bức tường lửa ảo (Virtual Firewall) bảo vệ ở cấp độ từng máy chủ hoặc từng Pod. Nó quy định: Cổng nào (Port), giao thức nào (TCP/UDP), từ IP hoặc Security Group nào được phép đi vào (**Ingress**) hoặc đi ra (**Egress**).

### 8. Bastion Host (Jump Server) là gì?
* Một máy chủ nhỏ được đặt ở Public Subnet với cơ chế bảo mật cực cao. Khi lập trình viên muốn SSH vào máy chủ backend hoặc muốn xem database nằm trong Private Subnet, họ phải kết nối vào Bastion Host này trước làm bàn đạp để "nhảy" vào trong mạng nội bộ.

### 9. IAM (Identity and Access Management): User, Role, Policy là gì?
* **IAM User:** Tài khoản định danh cho từng người thật đăng nhập vào giao diện Cloud Console (ví dụ `nam.tran@company.com`).
* **IAM Role:** Một chiếc "áo khoác quyền hạn" tạm thời không có mật khẩu hay secret key cố định, có thể được trao cho máy ảo EC2 hoặc Pod K8s khoác lên để làm việc.
* **IAM Policy:** Văn bản JSON quy định chi tiết: Được phép đọc file từ S3 bucket nào, ghi vào database nào.

### 10. IRSA (IAM Roles for Service Accounts) là gì?
* Cơ chế bảo mật cao cấp: Thay vì tạo cặp mã khóa tĩnh nguy hiểm (`AWS_ACCESS_KEY_ID` & `AWS_SECRET_ACCESS_KEY`) rồi dán vào file `.env` của container Backend, K8s tự động cấp một token ngắn hạn cho Pod. Code backend dùng token này để nhận quyền từ AWS một cách tự động và token tự đổi mới sau mỗi 60 phút.

### 11. Infrastructure as Code (IaC) & Terraform là gì?
* **IaC:** Tư duy định nghĩa toàn bộ hạ tầng phần cứng bằng các dòng mã nguồn văn bản thay vì dùng chuột click thủ công trên web console.
* **Terraform:** Công cụ số 1 thế giới để viết IaC. Bạn viết file `.tf` mô tả: *"Tôi muốn 1 VPC, 4 Subnet, 1 RDS Postgres"*, sau đó chạy `terraform apply`, Terraform sẽ tự động gọi API của AWS để tạo ra toàn bộ hệ thống chuẩn xác 100% trong 2 phút.

### 12. State File (`.tfstate`) & State Locking (DynamoDB) là gì?
* **State File:** File "sổ đỏ" mà Terraform dùng để ghi nhớ danh sách toàn bộ các tài nguyên nó đã tạo ra trên Cloud.
* **State Locking:** Cơ chế khóa file State (bằng DynamoDB) khi có người đang chạy lệnh, nhằm ngăn chặn thảm họa 2 kỹ sư cùng gõ lệnh apply một lúc làm hỏng hạ tầng.

### 13. ClickOps & Configuration Drift là gì?
* **ClickOps:** Thói quen xấu dùng chuột click tay trên web console AWS để tạo hoặc sửa máy chủ.
* **Configuration Drift (Lệch cấu hình):** Sự sai lệch giữa mã nguồn Terraform trên Git và hạ tầng thực tế trên Cloud do ai đó đã lén ClickOps sửa tay.
