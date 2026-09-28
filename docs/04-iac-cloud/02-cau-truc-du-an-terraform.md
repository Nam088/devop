# 02 - Cấu Trúc Dự Án Terraform Chuẩn Doanh Nghiệp

> Cách tổ chức mã nguồn Infrastructure as Code (IaC) để làm việc nhóm, chống xung đột trạng thái (State Locking) và tái sử dụng qua các môi trường.

---

## 1. Cấu Trúc Thư Mục Chuẩn Production

```text
terraform-infrastructure/
├── modules/                        # Các module hạ tầng độc lập, có thể tái sử dụng
│   ├── vpc/
│   │   ├── main.tf                 # Khai báo tài nguyên chính
│   │   ├── variables.tf            # Định nghĩa biến đầu vào
│   │   └── outputs.tf              # Giá trị trả ra (VPC ID, Subnet IDs)
│   ├── eks/
│   └── rds/
└── environments/                   # Các môi trường tách biệt hoàn toàn về State
    ├── staging/
    │   ├── backend.tf              # Cấu hình lưu state riêng cho Staging
    │   ├── main.tf                 # Gọi các module ở trên
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── terraform.tfvars        # Giá trị thực tế của môi trường Staging
    └── production/
        ├── backend.tf
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── terraform.tfvars
```

---

## 2. Remote State & Khóa Trạng Thái (State Locking)

File: `environments/production/backend.tf`

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # LƯU TRỮ VÀ KHÓA FILE STATE TRÊN ĐÁM MÂY
  backend "s3" {
    bucket         = "mycompany-terraform-states-prod"
    key            = "platform/production/terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    dynamodb_table = "terraform-lock-table" # Ngăn chặn 2 kỹ sư cùng apply một lúc
  }
}

provider "aws" {
  region = var.aws_region

  # Tự động gắn tag nhận diện lên TẤT CẢ các tài nguyên AWS được tạo ra
  default_tags {
    tags = {
      Environment = "production"
      ManagedBy   = "Terraform"
      Project     = "CorePlatform"
    }
  }
}
```

---

## 3. Quy Trình Vận Hành Lệnh Terraform Chuẩn

```bash
# 1. Khởi tạo và tải các Provider / Modules
terraform init

# 2. Định dạng lại code theo chuẩn canonical của HashiCorp
terraform fmt -recursive

# 3. Kiểm tra tính hợp lệ về logic và cú pháp
terraform validate

# 4. Lập kế hoạch thay đổi (Bắt buộc chạy trước khi áp dụng)
terraform plan -out=tfplan.binary

# 5. Áp dụng kế hoạch đã được kiểm duyệt
terraform apply tfplan.binary
```
