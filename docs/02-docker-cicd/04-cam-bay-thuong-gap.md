# 04 - Các Cạm Bẫy Thường Gặp Về Container & CI/CD

> Những thói quen xấu khi dùng Docker ở môi trường local nhưng lại biến thành thảm họa bảo mật và vận hành trên Production.

---

## 1. Chạy Container Dưới Quyền User `root`

* **Sai lầm:** Không khai báo chỉ thị `USER` trong Dockerfile. Mặc định container chạy với UID 0 (root).
* **Hậu quả:**
  * Nếu ứng dụng backend có một lỗ hổng RCE (Remote Code Execution) hoặc thư viện bên thứ 3 bị hack, kẻ tấn công lập tức có toàn quyền root trong container.
  * Nếu container có mount volume từ máy host (ví dụ `/var/run/docker.sock` hoặc thư mục log), kẻ tấn công có thể thoát khỏi container (**Container Escape**) và chiếm luôn máy chủ thật.
* **Quy tắc:** Luôn tạo user unprivileged (`appuser` UID 10001) hoặc dùng image Distroless `nonroot` (UID 65532).

---

## 2. Dùng Tag `:latest` Trên Môi Trường Production

* **Sai lầm:** Triển khai hạ tầng với cấu hình `image: myapp:latest`.
* **Hậu quả:**
  * `:latest` là một con trỏ có thể thay đổi (**Mutable**). Bạn hoàn toàn không biết hệ thống đang chạy mã nguồn của commit nào.
  * Khi có sự cố cần rollback về phiên bản trước, bạn không thể rollback vì không có tag cụ thể.
  * K8s có cơ chế `imagePullPolicy: IfNotPresent`. Nếu Node đã có bản `:latest` cũ, nó sẽ không bao giờ kéo code mới về.
* **Quy tắc:** Luôn dùng tag bất biến (**Immutable**): `sha-a1b2c3d` (Git commit SHA) hoặc `v1.2.3` (Semantic Version).

---

## 3. Rò Rỉ Secret Vào Lịch Sử Layer Của Image

* **Sai lầm:**
  ```dockerfile
  COPY .env /app/.env
  RUN npm run build
  RUN rm /app/.env   # Nghĩ rằng đã xóa file bí mật an toàn
  ```
* **Hậu quả:**
  * Mỗi câu lệnh `COPY` hoặc `RUN` sinh ra một layer chỉ đọc mới. Lệnh `rm` ở layer sau chỉ đánh dấu ẩn file trên layer đó, nhưng file `.env` chứa token/mật khẩu vẫn nằm nguyên vẹn ở layer trước.
  * Bất kỳ ai có quyền pull image đều có thể trích xuất lại file `.env` bằng các công cụ như `dive`.
* **Quy tắc:** Tuyệt đối không copy file `.env` vào image. Sử dụng cơ chế BuildKit Secret Mounts:
  `RUN --mount=type=secret,id=mysecret ...` nếu cần secret trong lúc build.

---

## 4. Thứ Tự Câu Lệnh `COPY` Làm Vô Hiệu Hóa Docker Layer Cache

* **Sai lầm:**
  ```dockerfile
  COPY . .
  RUN npm install
  ```
* **Hậu quả:** Mỗi khi bạn sửa một dòng code trong ứng dụng hoặc sửa file README, layer `COPY . .` bị thay đổi. Docker buộc phải tải lại toàn bộ dependencies `npm install` từ đầu (tốn thêm 3-5 phút cho mỗi lần chạy CI).
* **Quy tắc:** Copy lockfiles (`package.json`, `go.mod`, `pom.xml`) và chạy lệnh tải dependencies trước, rồi mới copy toàn bộ mã nguồn sau.
