# DevOps Handbook & Labs for Backend Developers

Kho tài liệu ghi chép và bài tập thực hành DevOps thực chiến dành cho Backend Developer, phân chia theo 5 Phase từ Linux/Mạng đến Kubernetes và Observability.

---

## 🗂️ Cấu Trúc Repository

* **[docs/](file:///Users/nam088/code/nam088/devop/docs)**: Tài liệu lý thuyết, từ điển thuật ngữ, cạm bẫy thực tế và tiêu chí nghiệm thu cho từng Phase.
* **[labs/](file:///Users/nam088/code/nam088/devop/labs)**: Toàn bộ mã nguồn bài tập thực hành (Node.js, Python, Nginx config, Dockerfile, scripts tự động test).
* **[AGENTS.md](file:///Users/nam088/code/nam088/devop/AGENTS.md)**: Hướng dẫn cấu hình môi trường máy ảo `devops-lab` cho AI Agent và kỹ sư.

---

## 📑 Tài Liệu Các Phase (`docs/`)

### [Phase 01: Linux Internals & Networking](file:///Users/nam088/code/nam088/devop/docs/01-linux-networking)
* [00 - Từ Điển Thuật Ngữ](file:///Users/nam088/code/nam088/devop/docs/01-linux-networking/00-thuat-ngu.md): Linux, Kernel, Process vs Daemon, `SIGTERM`/`SIGKILL`, File Descriptors, OOM-Killer, Socket, TCP Handshake, `TIME_WAIT`/`CLOSE_WAIT`, DNS, Reverse Proxy.
* [01 - Kiến Thức Cần Nắm](file:///Users/nam088/code/nam088/devop/docs/01-linux-networking/01-kien-thuc-can-nam.md): Vòng đời tiến trình, Systemd Unit, cấu hình `LimitNOFILE`, phân tích OOM-Killer, luồng DNS.
* [02 - Bộ Lệnh Troubleshooting](file:///Users/nam088/code/nam088/devop/docs/01-linux-networking/02-bo-lenh-troubleshooting.md): `ps`, `top`, `pidstat`, `ss -tulpn`, `lsof`, bắt gói tin `tcpdump`, đo lường độ trễ chi tiết bằng `curl -w`.
* [03 - Cấu Hình Nginx Reverse Proxy Chuẩn Production](file:///Users/nam088/code/nam088/devop/docs/01-linux-networking/03-nginx-reverse-proxy.md): Tối ưu worker limits, Rate limiting, Upstream Keepalive pool, SSL/TLSv1.3, Proxy buffers.
* [04 - Các Cạm Bẫy Kinh Điển Của Backend](file:///Users/nam088/code/nam088/devop/docs/01-linux-networking/04-cam-bay-thuong-gap.md): Cạn kiệt Ephemeral Ports, Too many open files, Socket leak `CLOSE_WAIT`, Lỗi cache DNS vô tận của JVM/Node.
* [05 - Bài Tập Thực Hành & Nghiệm Thu Milestone 1](file:///Users/nam088/code/nam088/devop/docs/01-linux-networking/05-bai-tap-milestone.md): Hands-on lab dựng Systemd + Nginx Reverse Proxy + kiểm chứng kết nối.

---

### [Phase 02: Production Containerization & CI/CD](file:///Users/nam088/code/nam088/devop/docs/02-docker-cicd)
* [00 - Từ Điển Thuật Ngữ](file:///Users/nam088/code/nam088/devop/docs/02-docker-cicd/00-thuat-ngu.md): Container vs VM, Docker Image vs Container, Namespaces & cgroups, Layer Caching, Volume, Non-root, Multi-stage, Distroless, CI/CD, Artifact, CVE.
* [01 - Kiến Thức Cần Nắm](file:///Users/nam088/code/nam088/devop/docs/02-docker-cicd/01-kien-thuc-can-nam.md): Bản chất Container, 6 Linux Namespaces, cgroups v2, Overlay2 UnionFS, tư duy Artifact bất biến (Immutable Artifact).
* [02 - Dockerfile Chuẩn Production](file:///Users/nam088/code/nam088/devop/docs/02-docker-cicd/02-dockerfile-production.md): Multi-stage builds, Distroless (<25MB) vs Alpine, chạy user Non-Root (UID 65532), `dumb-init`, xử lý `SIGTERM` Graceful Shutdown, file `.dockerignore`.
* [02b - Bóc Tách So Sánh Tối Ưu Size (1.1GB vs 61.8MB)](file:///Users/nam088/code/nam088/devop/docs/02-docker-cicd/02-so-sanh-toi-uu-dung-luong.md): Giải phẫu chi tiết layer, Debian vs Alpine, Multi-stage vứt bỏ cache rác, lọc devDependencies, và ROI tốc độ CI/CD.
* [03 - Pipeline CI/CD Thực Chiến Với GitHub Actions](file:///Users/nam088/code/nam088/devop/docs/02-docker-cicd/03-github-actions-cicd.md): Unit Test, Quét lỗ hổng CVE tự động bằng Aqua Trivy, Docker Buildx cache `type=gha`, Push multi-arch (AMD64/ARM64) lên GHCR.
* [04 - Các Cạm Bẫy Thường Gặp Về Container & CI/CD](file:///Users/nam088/code/nam088/devop/docs/02-docker-cicd/04-cam-bay-thuong-gap.md): Nguy cơ chạy quyền root (Container Escape), cấm dùng `:latest` trên Production, rò rỉ secret vào lịch sử Layer của image.
* [05 - Bài Tập Thực Hành & Nghiệm Thu Milestone 2](file:///Users/nam088/code/nam088/devop/docs/02-docker-cicd/05-bai-tap-milestone.md): Hands-on lab tối ưu Dockerfile < 80MB và kiểm chứng Graceful Shutdown trong 2 giây.

---

### [Phase 03: Kubernetes Orchestration & GitOps](file:///Users/nam088/code/nam088/devop/docs/03-kubernetes-gitops)
* [00 - Từ Điển Thuật Ngữ](file:///Users/nam088/code/nam088/devop/docs/03-kubernetes-gitops/00-thuat-ngu.md): Kubernetes & Cluster, Control Plane vs Worker Node, `apiserver`, `etcd`, `scheduler`, Pod, Deployment, Service, Ingress, 3 Probes, RollingUpdate, Helm, GitOps & ArgoCD.
* [01 - Kiến Thức Cần Nắm](file:///Users/nam088/code/nam088/devop/docs/03-kubernetes-gitops/01-kien-thuc-can-nam.md): Kiến trúc K8s Control Plane & Worker Node, Pod, Deployment, Service, Ingress.
* [02 - K8s Manifest Chuẩn Production](file:///Users/nam088/code/nam088/devop/docs/03-kubernetes-gitops/02-production-manifests.md): RollingUpdate Zero-Downtime, bộ 3 Health Probes, Requests & Limits, HPA v2.
* [03 - Quản Lý Ứng Dụng Với Helm 3](file:///Users/nam088/code/nam088/devop/docs/03-kubernetes-gitops/03-helm-chart-quan-tri.md): Cấu trúc Helm Chart chuẩn, tách `values-staging.yaml` và `values-prod.yaml`, template helpers, lệnh lint, dry-run, rollback.
* [04 - GitOps Hiện Đại Với ArgoCD](file:///Users/nam088/code/nam088/devop/docs/03-kubernetes-gitops/04-gitops-argocd.md): Triết lý GitOps, mô hình 2 Repositories, khai báo `Application` CRD, automated sync, self-healing.
* [05 - Các Cạm Bẫy Thường Gặp Trong Kubernetes](file:///Users/nam088/code/nam088/devop/docs/03-kubernetes-gitops/05-cam-bay-thuong-gap.md): Liveness Probe check Database gây Thundering Herd sập cụm, quên requests/limits, CPU throttling.
* [06 - Bài Tập Thực Hành & Nghiệm Thu Milestone 3](file:///Users/nam088/code/nam088/devop/docs/03-kubernetes-gitops/06-bai-tap-milestone.md): Hands-on lab dựng cụm K8s local `k3d`, deploy bằng Helm, cài đặt ArgoCD tự động sync.

---

### [Phase 04: Infrastructure as Code (IaC) & Cloud Architecture](file:///Users/nam088/code/nam088/devop/docs/04-iac-cloud)
* [00 - Từ Điển Thuật Ngữ](file:///Users/nam088/code/nam088/devop/docs/04-iac-cloud/00-thuat-ngu.md): Public Cloud, Region & AZ, VPC, Subnet & CIDR (`/16`, `/24`), Internet Gateway vs NAT Gateway, Security Group, Bastion Host, IAM (User/Role/Policy), IRSA, Terraform & State Locking, ClickOps.
* [01 - Kiến Thức Cần Nắm](file:///Users/nam088/code/nam088/devop/docs/04-iac-cloud/01-kien-thuc-can-nam.md): Kiến trúc mạng AWS Multi-AZ VPC, Quản trị IAM, IRSA (IAM Roles for Service Accounts) loại bỏ static credentials.
* [02 - Cấu Trúc Dự Án Terraform Chuẩn Doanh Nghiệp](file:///Users/nam088/code/nam088/devop/docs/04-iac-cloud/02-cau-truc-du-an-terraform.md): Phân tách thư mục `modules/` và `environments/`, Remote State trên S3 có mã hóa và DynamoDB State Locking.
* [03 - Code Mẫu Hạ Tầng Terraform](file:///Users/nam088/code/nam088/devop/docs/04-iac-cloud/03-code-mau-ha-tang.md): Mã nguồn HCL hoàn chỉnh cho VPC Module, Subnets, Route Tables, NAT Gateway, và Security Group Least Privilege giữa App và Database.
* [04 - Các Cạm Bẫy Thường Gặp Về Cloud & IaC](file:///Users/nam088/code/nam088/devop/docs/04-iac-cloud/04-cam-bay-thuong-gap.md): Mở Database ra Public `0.0.0.0/0`, commit `terraform.tfstate` lộ credentials, hardcode Access Key vào container, ClickOps gây Configuration Drift.
* [05 - Bài Tập Thực Hành & Nghiệm Thu Milestone 4](file:///Users/nam088/code/nam088/devop/docs/04-iac-cloud/05-bai-tap-milestone.md): Hands-on lab viết module VPC và kiểm thử trên LocalStack hoặc AWS Free Tier.

---

### [Phase 05: Observability & SRE Practice](file:///Users/nam088/code/nam088/devop/docs/05-observability-sre)
* [00 - Từ Điển Thuật Ngữ](file:///Users/nam088/code/nam088/devop/docs/05-observability-sre/00-thuat-ngu.md): Monitoring vs Observability, Telemetry, 3 Trụ cột (Metrics/Logs/Traces), 4 Golden Signals, Phân vị P95/P99, Prometheus, 4 loại metric, PromQL, High-Cardinality, Loki, OpenTelemetry, Alertmanager, SLI/SLO/SLA & Error Budget.
* [01 - Kiến Thức Cần Nắm](file:///Users/nam088/code/nam088/devop/docs/05-observability-sre/01-kien-thuc-can-nam.md): 3 trụ cột (Metrics, Logs, Traces), 4 Golden Signals, Bộ thuật ngữ SLI, SLO, SLA, Error Budget.
* [02 - Prometheus & PromQL Thực Chiến](file:///Users/nam088/code/nam088/devop/docs/05-observability-sre/02-prometheus-promql.md): 4 loại metric, cấu hình Backend `/metrics`, công thức PromQL chuẩn tính RPS, Error Rate %, Latency P95/P99.
* [03 - Quản Trị Log Tập Trung & Distributed Tracing](file:///Users/nam088/code/nam088/devop/docs/05-observability-sre/03-logging-tracing.md): Grafana Loki + LogQL, OpenTelemetry SDK, chuẩn W3C `traceparent` (Trace ID, Span ID), biểu đồ Gantt Chart trên Grafana Tempo.
* [04 - Hệ Thống Cảnh Báo Chuẩn SRE Với Alertmanager](file:///Users/nam088/code/nam088/devop/docs/05-observability-sre/04-canh-bao-alertmanager.md): Nguyên tắc Symptom-based alerting, file cấu hình `PrometheusRule`, điều hướng cảnh báo tới Slack/Telegram.
* [05 - Các Cạm Bẫy Thường Gặp Về Giám Sát & SRE](file:///Users/nam088/code/nam088/devop/docs/05-observability-sre/05-cam-bay-thuong-gap.md): Thảm họa High-Cardinality nhãn Prometheus làm sập server, lộ lọt dữ liệu nhạy cảm PII trong Log, bẫy đo lường trung bình (Average vs P99).
* [06 - Bài Tập Thực Hành & Nghiệm Thu Milestone 5](file:///Users/nam088/code/nam088/devop/docs/05-observability-sre/06-bai-tap-milestone.md): Hands-on lab dựng stack Prometheus + Grafana qua Docker Compose và thiết kế Dashboard 4 Golden Signals.

---

## 🧪 Mã Nguồn Thực Hành (`labs/`)

* **[labs/01-linux-networking/](file:///Users/nam088/code/nam088/devop/labs/01-linux-networking)**: Code server Python, file service Systemd tự hồi sinh, cấu hình Nginx upstream keepalive.
* **[labs/02-docker-cicd/](file:///Users/nam088/code/nam088/devop/labs/02-docker-cicd)**: App Express Node.js, unit tests, Dockerfile multi-stage non-root, docker-compose, script test graceful shutdown và workflow CI GitHub Actions.
