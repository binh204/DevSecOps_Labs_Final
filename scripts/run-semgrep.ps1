#!/bin/bash
echo ""
echo "========== SEMGREP =========="

# Tạo thư mục trước để Docker mount với đúng quyền sở hữu của user hiện tại
mkdir -p ./reports/semgrep

# Chạy Semgrep dưới quyền của user hiện tại
docker compose run --pull missing --user "$(id -u):$(id -g)" --rm semgrep
if [ $? -ne 0 ]; then
    echo "Semgrep scan failed!" >&2
    exit 1
fi

# ===== Đường dẫn trong workspace =====
Report="./reports/semgrep/report.json"

# ===== Đường dẫn repo gốc =====
Destination="/home/soc_server/reports/semgrep"

echo ""
echo "========== COPY REPORT =========="

# Check if destination is a Windows path and we are on Linux
if [[ "$Destination" =~ ^[A-Za-z]:/ ]] && [[ "$OSTYPE" != "msys" && "$OSTYPE" != "cygwin" ]]; then
    echo "Windows destination path detected on Linux. Skipping copy."
else
    if [ ! -f "$Report" ]; then
        echo "Semgrep report not found!" >&2
        exit 1
    fi
    mkdir -p "$Destination"
    cp -r ./reports/semgrep/* "$Destination/"
    echo "Reports copied successfully."
fi

echo ""
echo "Destination: $Destination"
echo ""
echo "Semgrep completed successfully."