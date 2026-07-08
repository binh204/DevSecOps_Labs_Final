# Write-Host ""
# Write-Host "========== OWASP ZAP =========="
# 
# # Chạy OWASP ZAP Baseline Scan
# docker compose run --rm zap `
#     zap-baseline.py `
#     -t http://host.docker.internal:3000 `
#     -r report.html `
#     -J report.json `
#     -w report.md
# 
# $ExitCode = $LASTEXITCODE
# 
# Write-Host ""
# Write-Host "========== ZAP RESULT =========="
# Write-Host "ZAP Exit Code: $ExitCode"
# 
# # 0 = Không có cảnh báo
# # 1 hoặc 2 = Có cảnh báo/lỗ hổng (vẫn cho phép pipeline tiếp tục)
# # 3 = Lỗi thực sự khi chạy ZAP
# 
# if ($ExitCode -eq 3) {
#     throw "OWASP ZAP execution failed!"
# }
# 
# # ===== Đường dẫn trong workspace =====
# $WorkspaceReport = ".\reports\zap"
# 
# # ===== Đường dẫn repo gốc =====
# $Destination = "D:\Final_Project\DevSecOps\reports\zap"
# 
# Write-Host ""
# Write-Host "========== COPY REPORT =========="
# 
# if (!(Test-Path $Destination)) {
#     New-Item -ItemType Directory -Path $Destination -Force | Out-Null
# }
# 
# Copy-Item `
#     "$WorkspaceReport\*" `
#     $Destination `
#     -Recurse `
#     -Force
# 
# Write-Host "Reports copied successfully."
# 
# Write-Host ""
# Write-Host "Destination:"
# Write-Host $Destination
# 
# Write-Host ""
# Write-Host "OWASP ZAP completed."

#!/bin/bash
echo ""
echo "========== OWASP ZAP =========="

# Chạy OWASP ZAP Baseline Scan
docker compose run --rm zap \
    zap-baseline.py \
    -t http://host.docker.internal:3000 \
    -r report.html \
    -J report.json \
    -w report.md

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
Destination="D:/Final_Project/DevSecOps/reports/zap"

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