# 03 - Code Mẫu Hạ Tầng Terraform (VPC & Security Groups)

> Mã nguồn Terraform HCL hoàn chỉnh để khởi tạo mạng VPC Multi-AZ chuẩn và các nhóm bảo mật (Security Groups) theo nguyên tắc đặc quyền tối thiểu.

---

## 1. File Khai Báo Biến (`modules/vpc/variables.tf`)

```hcl
variable "vpc_cidr" {
  type        = string
  description = "Dải CIDR của toàn bộ VPC"
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  type        = list(string)
  description = "Danh sách các vùng sẵn sàng (AZs)"
  default     = ["ap-southeast-1a", "ap-southeast-1b"]
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Danh sách CIDR cho Public Subnets"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Danh sách CIDR cho Private Subnets (App & EKS)"
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "environment" {
  type        = string
  description = "Tên môi trường (staging/production)"
}
```

---

## 2. File Khởi Tạo Hạ Tầng Mạng (`modules/vpc/main.tf`)

```hcl
# 1. TẠO VIRTUAL PRIVATE CLOUD (VPC)
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.environment}-vpc"
  }
}

# 2. INTERNET GATEWAY CHO PUBLIC TRAFFIC
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.environment}-igw"
  }
}

# 3. PUBLIC SUBNETS
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                     = "${var.environment}-public-${var.availability_zones[count.index]}"
    "kubernetes.io/role/elb" = "1" # Tag để AWS Load Balancer Controller tự nhận diện
  }
}

# 4. ELASTIC IP & NAT GATEWAY (Đặt tại Public Subnet đầu tiên để tiết kiệm chi phí)
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name = "${var.environment}-nat-eip"
  }
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.environment}-nat-gw"
  }
  depends_on = [aws_internet_gateway.this]
}

# 5. PRIVATE SUBNETS (Nơi chạy Pods / EKS / Microservices)
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name                              = "${var.environment}-private-${var.availability_zones[count.index]}"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# 6. BẢNG ĐỊNH TUYẾN (ROUTE TABLES)
# Public Route: Đi thẳng ra Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.environment}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route: Đi ra ngoài qua NAT Gateway
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name = "${var.environment}-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
```

---

## 3. Khởi Tạo Security Groups Giữa Backend Và Database

Chỉ cho phép ứng dụng Backend trong Private Subnet kết nối tới Database cổng 5432:

```hcl
# Security Group của Backend Workload
resource "aws_security_group" "backend_app" {
  name        = "${var.environment}-backend-app-sg"
  description = "Security Group cho Backend Pods"
  vpc_id      = aws_vpc.this.id

  egress {
    description = "Cho phep goi ra ngoai"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group của PostgreSQL Database
resource "aws_security_group" "rds_postgres" {
  name        = "${var.environment}-rds-postgres-sg"
  description = "Chi nhan traffic tu Backend App Security Group"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "PostgreSQL tu Backend"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    # CHỈ CHẤP NHẬN TRAFFIC ĐẾN TỪ SG CỦA APP, KHÔNG MỞ THEO DẢI IP
    security_groups = [aws_security_group.backend_app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```
