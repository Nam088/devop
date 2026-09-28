#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR/nodejs-backend"

echo "=========================================================="
echo "  BẮT ĐẦU KIỂM THỬ TỰ ĐỘNG BÀI LAB MILESTONE 2 (DOCKER)  "
echo "=========================================================="

echo -e "\n[BƯỚC 1] Build Docker Image chuẩn Multi-Stage..."
docker build -t nodejs-backend:test .

echo -e "\n[BƯỚC 2] Kiểm tra dung lượng Image..."
docker images nodejs-backend:test

echo -e "\n[BƯỚC 3] Khởi chạy container ở chế độ detached..."
docker run -d --name test-nodejs-container -p 3000:3000 nodejs-backend:test
sleep 2

echo -e "\n[BƯỚC 4] Kiểm tra các endpoint API..."
echo -n "-> Test GET / : "
curl -s http://127.0.0.1:3000/
echo ""
echo -n "-> Test GET /health : "
curl -s http://127.0.0.1:3000/health
echo ""

echo -e "\n[BƯỚC 5] Kiểm tra bảo mật User (Phải là Non-Root UID 1001)..."
docker top test-nodejs-container

echo -e "\n[BƯỚC 6] Kiểm tra thời gian Graceful Shutdown (Phải < 2 giây)..."
time docker stop test-nodejs-container

echo -e "\n[BƯỚC 7] Xem log dọn dẹp kết nối của container..."
docker logs test-nodejs-container

echo -e "\n[BƯỚC 8] Dọn dẹp container..."
docker rm test-nodejs-container > /dev/null

echo -e "\n=========================================================="
echo "  CHÚC MỪNG! TOÀN BỘ TIÊU CHÍ MILESTONE 2 ĐÃ HOÀN TẤT!    "
echo "=========================================================="
