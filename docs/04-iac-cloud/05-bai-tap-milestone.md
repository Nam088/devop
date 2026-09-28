# 05 - Bài Tập Thực Hành & Nghiệm Thu Milestone 4

> Thực hành viết mã Terraform để dựng mạng VPC hoàn chỉnh và kiểm thử tính toàn vẹn của hạ tầng đám mây.

---

## 🛠️ Đề Bài Thực Hành (Hands-on Lab)

### Nhiệm Vụ 1: Viết Module VPC Chuẩn Multi-AZ
1. Tạo cấu trúc thư mục gồm `modules/vpc` và `environments/staging`.
2. Viết mã Terraform tạo:
   * 1 VPC dải `10.0.0.0/16`.
   * 2 Public Subnets (mỗi subnet ở 1 AZ khác nhau) có route ra Internet Gateway.
   * 2 Private Subnets có route trỏ qua NAT Gateway.
   * Gán đúng các tags `kubernetes.io/role/elb` và `kubernetes.io/role/internal-elb`.
3. Kiểm tra cú pháp: `terraform fmt` và `terraform validate`.

### Nhiệm Vụ 2: Chạy Thử Nghiệm Trên LocalStack Hoặc AWS Free Tier
* **Cách 1 (Không tốn tiền, dùng LocalStack):**
  Chạy LocalStack qua Docker để giả lập API của AWS trên máy local:
  ```bash
  docker run --rm -d --name localstack -p 4566:4566 localstack/localstack
  ```
  Cấu hình endpoint trong provider AWS trỏ về `http://localhost:4566`.
* **Cách 2 (Dùng AWS Account thật):**
  Chạy `terraform plan` để kiểm tra toàn bộ 15 tài nguyên mạng sẽ được tạo ra.
  *(Lưu ý: Nếu chạy `terraform apply` trên AWS thật, hãy nhớ chạy `terraform destroy` sau khi nghiệm thu để tránh phát sinh chi phí duy trì NAT Gateway).*

### Nhiệm Vụ 3: Thiết Lập Remote Backend State Locking
1. Tạo một S3 bucket và một bảng DynamoDB với partition key là `LockID` (kiểu String).
2. Cấu hình block `backend "s3"` trong file `backend.tf`.
3. Chạy `terraform init` để migrate state từ local lên S3.
4. Mở 2 cửa sổ terminal chạy đồng thời `terraform plan` để kiểm chứng cơ chế DynamoDB Lock từ chối tiến trình thứ hai.

---

## ✅ Bảng Kiểm Tra Nghiệm Thu (Definition of Done)

- [ ] Phân tích được luồng đi của gói tin từ Internet qua IGW, ALB, NAT Gateway tới Private Subnet.
- [ ] Tổ chức mã nguồn Terraform tách biệt rõ ràng giữa `modules` và `environments`.
- [ ] Cấu hình thành công S3 Backend kèm DynamoDB Lock để làm việc nhóm.
- [ ] Hiểu rõ cơ chế xác thực IRSA thay thế hoàn toàn cho Access Key tĩnh.
