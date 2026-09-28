#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"

echo "=========================================================="
echo "  BẮT ĐẦU KIỂM THỬ ZERO-DOWNTIME ROLLING UPDATE"
echo "=========================================================="

# Tìm IP Service và Ingress Host
SERVICE_IP=$(kubectl get svc backend-release-nodejs-backend -n production -o jsonpath='{.spec.clusterIP}')
TARGET_URL="http://${SERVICE_IP}/health"
LOG_FILE="/tmp/rolling_test.log"
rm -f "$LOG_FILE"

echo "-> Mục tiêu kiểm thử: $TARGET_URL"
echo "-> Khởi động tiến trình bắn HTTP request liên tục (50ms/request)..."

# Chạy loop bắn request ở background
STOP_TEST=0
(
  while true; do
    CODE=$(curl -s -o /dev/null -w "%{http_code}\n" --max-time 1 "$TARGET_URL" || echo "ERR")
    echo "$(date +%H:%M:%S.%N) $CODE" >> "$LOG_FILE"
    sleep 0.05
  done
) &
CURL_PID=$!

trap "kill -9 $CURL_PID 2>/dev/null || true" EXIT

sleep 2
echo "-> Đang thực hiện Rollout Restart Deployment (kích hoạt Rolling Update)..."
kubectl rollout restart deployment/backend-release-nodejs-backend -n production

echo "-> Chờ đợi toàn bộ Pods mới sẵn sàng (kubectl rollout status)..."
kubectl rollout status deployment/backend-release-nodejs-backend -n production --timeout=90s

# Chờ thêm 2 giây để traffic ổn định
sleep 2

# Dừng tiến trình bắn request
kill -9 $CURL_PID 2>/dev/null || true
trap - EXIT

echo -e "\n=========================================================="
echo "  PHÂN TÍCH KẾT QUẢ KIỂM THỬ TÍNH LIÊN TỤC (ZERO-DOWNTIME)"
echo "=========================================================="

TOTAL_REQUESTS=$(wc -l < "$LOG_FILE" | tr -d ' ')
SUCCESS_REQUESTS=$(grep -c " 200$" "$LOG_FILE" || true)
FAILED_REQUESTS=$(grep -v " 200$" "$LOG_FILE" | wc -l | tr -d ' ')

echo "Tổng số requests đã gửi   : $TOTAL_REQUESTS"
echo "Số requests thành công (200): $SUCCESS_REQUESTS"
echo "Số requests thất bại        : $FAILED_REQUESTS"

if [ "$FAILED_REQUESTS" -eq 0 ] && [ "$TOTAL_REQUESTS" -gt 0 ]; then
  SUCCESS_RATE=100.0
  echo "Tỷ lệ thành công            : ${SUCCESS_RATE}%"
  echo "----------------------------------------------------------"
  echo "✅ KẾT LUẬN: ZERO-DOWNTIME ĐẠT CHUẨN 100%! Không rớt bất kỳ request nào!"
  echo "=========================================================="
  exit 0
else
  echo "----------------------------------------------------------"
  echo "❌ KẾT LUẬN: Xuất hiện lỗi trong quá trình Rollout!"
  grep -v " 200$" "$LOG_FILE" | head -n 10
  echo "=========================================================="
  exit 1
fi
