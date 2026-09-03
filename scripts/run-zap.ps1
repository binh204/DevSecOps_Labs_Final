# #!/bin/bash
# echo ""
# echo "========== OWASP ZAP (REST API DAEMON SCAN) =========="

# # Tạo thư mục chứa báo cáo
# mkdir -p ./reports/zap

# TARGET_URL="http://192.168.11.129:3000"

# # 1. Dọn dẹp container daemon cũ nếu có
# docker rm -f zap-daemon 2>/dev/null || true

# # 2. Khởi chạy ZAP Daemon Container trên port 8090 (tránh trùng port 8080 của DefectDojo)
# echo "Starting OWASP ZAP Daemon container..."
# docker run -d --name zap-daemon \
#     -p 8090:8090 \
#     -v $(pwd)/reports/zap:/zap/wrk:rw \
#     zaproxy/zap-stable:latest \
#     zap.sh -daemon \
#     -port 8090 -host 0.0.0.0 \
#     -config api.addrs.addr.name=.* \
#     -config api.addrs.addr.regex=true \
#     -config api.disablekey=true \
#     -config addons.autoUpdate.checkOnStart=false

# echo "Waiting for ZAP Daemon to become ready..."
# until curl -s http://localhost:8090/JSON/core/view/version/ > /dev/null; do
#     echo "ZAP is starting up..."
#     sleep 2
# done
# echo "ZAP Daemon is Ready!"

# # 3. Kích hoạt Spider Scan
# echo "Starting ZAP Spider Scan on $TARGET_URL..."
# SPIDER_ID=$(curl -s "http://localhost:8090/JSON/spider/action/scan/?url=$TARGET_URL/&recurse=true" | grep -o '"scan":"[0-9]*"' | cut -d'"' -f4)
# if [ -z "$SPIDER_ID" ]; then
#     SPIDER_ID="0"
# fi
# echo "Spider ID = $SPIDER_ID"

# echo "Waiting for Spider Scan to reach 100%..."
# while true; do
#     PROGRESS=$(curl -s "http://localhost:8090/JSON/spider/view/status/?scanId=$SPIDER_ID" | grep -o '"status":"[0-9]*"' | cut -d'"' -f4)
#     if [ -z "$PROGRESS" ]; then
#         PROGRESS="100"
#     fi
#     echo "Spider progress: ${PROGRESS}%"
#     if [ "$PROGRESS" -ge 100 ] 2>/dev/null; then
#         break
#     fi
#     sleep 3
# done
# echo "✅ Spider Complete!"

# # 4. Xuất Báo cáo XML / HTML / JSON cho DefectDojo
# echo "Exporting scan reports..."
# curl -s "http://localhost:8090/OTHER/core/other/xmlreport/" --output ./reports/zap/report.xml 2>/dev/null || true
# curl -s "http://localhost:8090/OTHER/core/other/htmlreport/" --output ./reports/zap/report.html 2>/dev/null || true
# curl -s "http://localhost:8090/OTHER/core/other/jsonreport/" --output ./reports/zap/report.json 2>/dev/null || true

# # 5. Dọn dẹp container ZAP Daemon
# echo "Cleaning up ZAP Daemon container..."
# docker rm -f zap-daemon 2>/dev/null || true
# chmod -R 777 ./reports/zap 2>/dev/null || true

# # ===== Đường dẫn trong workspace =====
# WorkspaceReport="./reports/zap"

# # ===== Đường dẫn repo gốc =====
# Destination="/home/soc_server/reports/zap"

# echo ""
# echo "========== COPY REPORT =========="

# # Check if destination is a Windows path and we are on Linux
# if [[ "$Destination" =~ ^[A-Za-z]:/ ]] && [[ "$OSTYPE" != "msys" && "$OSTYPE" != "cygwin" ]]; then
#     echo "Windows destination path detected on Linux. Skipping copy."
# else
#     mkdir -p "$Destination"
#     cp -r "$WorkspaceReport"/* "$Destination/"
#     echo "Reports copied successfully."
# fi

# echo ""
# echo "Destination: $Destination"
# echo ""
# echo "OWASP ZAP completed."

#!/bin/bash

echo ""
echo "========== OWASP ZAP =========="

mkdir -p ./reports/zap

docker compose run -T --pull missing --rm zap \
    zap-baseline.py \
    -t http://192.168.11.129:3000 \
    -I \
    -z "-silent" \
    -r report.html \
    -J report.json \
    -w report.md \
    -x report.xml

exit_code=$?

chmod -R 777 ./reports/zap 2>/dev/null || true

echo ""
echo "========== ZAP RESULT =========="
echo "ZAP Exit Code: $exit_code"

if [ $exit_code -eq 3 ]; then
    echo "OWASP ZAP execution failed!" >&2
    exit 1
fi

WorkspaceReport="./reports/zap"
Destination="/home/soc_server/reports/zap"

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