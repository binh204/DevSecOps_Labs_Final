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