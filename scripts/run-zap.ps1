#!/bin/bash
echo ""
echo "========== OWASP ZAP =========="

# Tạo thư mục trước để Docker mount với đúng quyền sở hữu của user hiện tại
mkdir -p ./reports/zap

# Chạy OWASP ZAP Baseline Scan hướng về máy ảo đích (192.168.11.129), xuất thêm XML (-x) cho DefectDojo
docker compose run -T --pull missing --rm zap \
    zap-baseline.py \
    -t http://192.168.11.129:3000 \
    -m 3 \
    -d \
    -r report.html \
    -J report.json \
    -w report.md \
    -x report.xml

exit_code=$?

echo ""
echo "========== ZAP RESULT =========="
echo "ZAP Exit Code: $exit_code"

# 0 = Không có cảnh báo
# 1 hoặc 2 = Có cảnh báo/lỗ hổng (vẫn cho phép pipeline tiếp tục)
# 3 = Lỗi thực sự khi chạy ZAP

if [ $exit_code -eq 3 ]; then
    echo "OWASP ZAP execution failed!" >&2
    exit 1
fi

# ===== Đường dẫn trong workspace =====
WorkspaceReport="./reports/zap"

# ===== Đường dẫn repo gốc =====
Destination="/home/soc_server/reports/zap"

echo ""
echo "========== COPY REPORT =========="

# Check if destination is a Windows path and we are on Linux
if [[ "$Destination" =~ ^[A-Za-z]:/ ]] && [[ "$OSTYPE" != "msys" && "$OSTYPE" != "cygwin" ]]; then
    echo "Windows destination path detected on Linux. Skipping copy."
else
    mkdir -p "$Destination"
    cp -r "$WorkspaceReport"/* "$Destination/"
    echo "Reports copied successfully."
fi

echo ""
echo "Destination: $Destination"
echo ""
echo "OWASP ZAP completed."