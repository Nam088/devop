# 02 - Bộ Lệnh Troubleshooting Mạng & Tiến Trình

> Các câu lệnh thực chiến dùng để khoanh vùng và khắc phục sự cố hiệu năng, tắc nghẽn mạng và lỗi hệ điều hành.

---

## 1. Giám Sát Tiến Trình & Tài Nguyên (Process & Resource)

```bash
# 1. Tìm nhanh tiến trình backend đang chạy và mức tiêu thụ tài nguyên
ps aux | grep -E 'backend|node|java|go'

# 2. Xem các tiến trình ngốn nhiều CPU/RAM nhất theo thời gian thực
top -b -n 1 -o %MEM | head -n 20

# 3. Xem chi tiết I/O đĩa của một tiến trình cụ thể (thay <PID>)
pidstat -d -p <PID> 1 5

# 4. Kiểm tra giới hạn tài nguyên thực tế của một tiến trình đang chạy
cat /proc/<PID>/limits | grep "Max open files"

# 5. Đếm số lượng file descriptor tiến trình đang mở
ls -1 /proc/<PID>/fd | wc -l
```

---

## 2. Kiểm Tra Socket & Kết Nối Mạng (Network Sockets)

Thay thế hoàn toàn công cụ cũ `netstat` bằng `ss` (Socket Statistics) vì `ss` đọc trực tiếp từ kernel nhanh hơn nhiều lần:

```bash
# 1. Liệt kê toàn bộ các cổng TCP đang LẮNG NGHE (Listen) kèm Process Name và PID
sudo ss -tulpn

# 2. Đếm số lượng kết nối theo từng trạng thái (ESTABLISHED, TIME_WAIT, CLOSE_WAIT)
ss -tan | awk '{print $1}' | sort | uniq -c

# 3. Xem danh sách các IP đang kết nối nhiều nhất tới cổng 80/443
ss -tan dst :80 or dst :443 | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | head -n 10

# 4. Tìm tiến trình nào đang chiếm dụng cổng 8080 bằng lsof
sudo lsof -i :8080
```

---

## 3. Đo Lường Chi Tiết Độ Trễ HTTP Bằng cURL

Tách bạch thời gian DNS, bắt tay TCP, TLS Handshake và thời gian backend xử lý (Time To First Byte - TTFB):

### Bước 1: Tạo file cấu hình đo lường `curl-format.txt`
```text
      time_namelookup (DNS):  %{time_namelookup}s\n
         time_connect (TCP):  %{time_connect}s\n
    time_appconnect (TLS/SSL):  %{time_appconnect}s\n
   time_pretransfer (Chuẩn bị):  %{time_pretransfer}s\n
      time_redirect (Chuyển hướng):  %{time_redirect}s\n
 time_starttransfer (Backend TTFB):  %{time_starttransfer}s\n
                    ----------\n
           time_total (Tổng cộng):  %{time_total}s\n
```

### Bước 2: Chạy lệnh đo lường
```bash
curl -w "@curl-format.txt" -o /dev/null -s -k https://api.yourdomain.com/v1/health
```

* **Phân tích kết quả:**
  * Nếu `time_namelookup` lớn (> 0.2s): DNS Server phân giải chậm.
  * Nếu `time_connect` - `time_namelookup` lớn: Mạng vật lý/định tuyến có độ trễ cao.
  * Nếu `time_starttransfer` - `time_pretransfer` lớn: **Code backend xử lý chậm hoặc Database query bị nghẽn**.

---

## 4. Bắt Gói Tin Mạng Bằng `tcpdump`

Khi cần bằng chứng cụ thể gói tin HTTP/TCP có đến máy chủ hay không:

```bash
# 1. Bắt 10 gói tin trên cổng 8080, in ra địa chỉ IP dạng số (-nn)
sudo tcpdump -nn -i any port 8080 -c 10

# 2. Bắt gói tin kèm nội dung ASCII (để đọc headers HTTP)
sudo tcpdump -nn -A -i any port 80 -c 5

# 3. Ghi ra file pcap để mở phân tích chuyên sâu bằng Wireshark
sudo tcpdump -i eth0 port 8080 -w /tmp/traffic.pcap
```

---

## 5. Kiểm Tra Khả Năng Kết Nối Nhanh

```bash
# Kiểm tra port từ xa có thông không mà không cần cài curl/telnet (dùng nc)
nc -zvw 3 10.0.1.50 5432
# (z: zero-I/O scan, v: verbose, w 3: timeout 3 giây)
```
