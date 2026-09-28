# 05 - Bài Tập Thực Hành & Nghiệm Thu Milestone 2

> Bài tập thực hành đóng gói container chuẩn production và tự động hóa chu trình CI/CD.

---

## 🛠️ Đề Bài Thực Hành (Hands-on Lab)

### Nhiệm Vụ 1: Viết Lại Dockerfile Chuẩn Production
1. Chọn một repository backend API bạn đang làm.
2. Viết file `Dockerfile` áp dụng kỹ thuật **Multi-stage build**:
   * Tách riêng stage `builder` và stage `runtime`.
   * Chạy với non-root user (sử dụng Google Distroless hoặc tạo user với UID khác 0).
   * Image thành phẩm phải có dung lượng < 80MB (với Go/Rust) hoặc < 160MB (với Node/Python/Java).
3. Viết file `.dockerignore` loại bỏ toàn bộ file rác, `.git`, `.env`.

### Nhiệm Vụ 2: Kiểm Chứng Graceful Shutdown
1. Chạy container: `docker run -d --name test-app -p 8080:8080 myapp:local`
2. Thực hiện lệnh dừng: `time docker stop test-app`
3. **Tiêu chí nghiệm thu:**
   * Nếu lệnh dừng hoàn tất trong vòng **1 đến 2 giây**: Container đã bắt được tín hiệu `SIGTERM` và thoát êm ái thành công.
   * Nếu lệnh dừng mất đúng **10 giây**: Container của bạn đang không nhận được `SIGTERM` và bị Docker cưỡng chế bắn hạ bằng `SIGKILL` -> Cần sửa lại `ENTRYPOINT` sang dạng exec array `["/path/binary"]` hoặc bổ sung `dumb-init`.

### Nhiệm Vụ 3: Dựng GitHub Actions CI/CD Tự Động
1. Tạo repo trên GitHub và đưa code kèm Dockerfile lên.
2. Thiết lập GitHub Actions workflow `.github/workflows/ci-cd.yml`:
   * Chạy unit test.
   * Tích hợp Trivy quét bảo mật (đảm bảo không còn CVE mức `CRITICAL`).
   * Sử dụng Docker Buildx build và push image lên GitHub Packages (GHCR) với tag là short commit SHA (`sha-xxxx`).

---

## ✅ Bảng Kiểm Tra Nghiệm Thu (Definition of Done)

- [ ] Phân tích được bản chất cách ly của Container (Namespaces, cgroups, Overlay2).
- [ ] Docker image thành phẩm chạy với non-root user và không chứa build tool.
- [ ] Container tắt trong < 3 giây khi nhận lệnh `docker stop`.
- [ ] Pipeline CI/CD tự động kích hoạt, quét Trivy pass và push image thành công với tag commit SHA.
