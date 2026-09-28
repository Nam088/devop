# 04 - Các Cạm Bẫy Thường Gặp Về Cloud & IaC

> Những lỗi nguy hiểm có thể dẫn đến việc lộ toàn bộ dữ liệu cơ sở dữ liệu hoặc hóa đơn đám mây tăng vọt hàng ngàn USD chỉ sau một đêm.

---

## 1. Đưa Cơ Sở Dữ Liệu Ra Public (`0.0.0.0/0`) Để Tiện Làm Việc

* **Thực trạng:** Khi làm dev, nhiều bạn muốn kết nối thẳng từ DBeaver trên laptop ở nhà vào Database trên Cloud, nên chọn cấu hình `Publicly Accessible: Yes` trên RDS và mở Security Group `0.0.0.0/0`.
* **Hậu quả:** Các bot quét tự động trên Internet liên tục brute-force cổng 5432/3306. Rất nhiều công ty đã bị hack toàn bộ cơ sở dữ liệu và bị ransomware mã hóa tống tiền chỉ sau vài giờ để lộ.
* **Giải pháp chuẩn:** Database **bắt buộc** phải nằm ở Private/Isolated Subnet. Khi cần truy cập để debug, sử dụng một trong các cách sau:
  1. Dựng **Bastion Host** (máy ảo EC2 nhỏ) và kết nối qua SSH Tunnel hoặc **AWS SSM Session Manager** (không cần mở port SSH).
  2. Kết nối thông qua VPN nội bộ (WireGuard / OpenVPN / AWS Client VPN).

---

## 2. Commit File `terraform.tfstate` Lên Git Repository

* **Sai lầm:** Không cấu hình Remote State trên S3 mà lưu file state cục bộ rồi `git add .` lên GitHub/GitLab.
* **Hậu quả:** File `terraform.tfstate` chứa toàn bộ cấu hình hạ tầng ở dạng văn bản thô (Plain Text), bao gồm cả mật khẩu root của Database, private keys, chứng chỉ SSL và token API. Bất kỳ ai đọc được repo đều có thể đánh cắp thông tin này.
* **Quy tắc:** Luôn thêm `*.tfstate` và `*.tfstate.backup` vào `.gitignore` và bắt buộc dùng S3 Remote Backend có mã hóa (`encrypt = true`).

---

## 3. Tạo IAM User và Hardcode Access Key Vào Container

* **Sai lầm:** Tạo một IAM User với quyền `AdministratorAccess`, sinh cặp `AWS_ACCESS_KEY_ID` và `AWS_SECRET_ACCESS_KEY`, rồi dán vào file cấu hình của Backend để upload ảnh lên S3.
* **Hậu quả:** Cặp key này không bao giờ hết hạn. Nếu vô tình bị lộ (qua log, commit nhầm, hacker dump memory), hacker sẽ tạo hàng trăm máy ảo EC2 cấu hình khủng để đào tiền ảo (crypto mining), khiến bạn phải gánh hóa đơn hàng chục ngàn USD.
* **Quy tắc:** Ứng dụng chạy trên Cloud **không bao giờ dùng static credentials**. Phải sử dụng **IAM Roles for Service Accounts (IRSA)** hoặc **IAM Instance Profile**.

---

## 4. Thao Tác Thủ Công Trên Web Console (Hiện Tượng Configuration Drift)

* **Hiện tượng:** Khi có sự cố, kỹ sư SSH vào server hoặc lên Web Console bấm đổi Security Group hoặc tăng dung lượng RAM.
* **Hậu quả:** Mã nguồn Terraform trên Git không còn khớp với hạ tầng thực tế. Lần tiếp theo ai đó chạy `terraform apply`, Terraform sẽ phát hiện sự sai lệch và có thể **xóa hoặc đè lại cấu hình**, làm hệ thống sập lần thứ hai.
* **Quy tắc:** Tuyệt đối không "ClickOps" trên môi trường Production. Mọi thay đổi phải đi qua file `.tf`, được review qua Pull Request rồi mới apply.
