# Write-Host ""
# Write-Host "========== SEMGREP =========="
# 
# # Chạy Semgrep
# docker compose run --rm semgrep
# 
# if ($LASTEXITCODE -ne 0) {
#     throw "Semgrep scan failed!"
# }
# 
# # ===== Đường dẫn trong workspace của GitHub Actions =====
# $Report = ".\reports\semgrep\report.json"
# 
# # ===== Đường dẫn repo gốc =====
# $Destination = "D:\Final_Project\DevSecOps\reports\semgrep"
# 
# Write-Host ""
# Write-Host "========== FORMAT REPORT =========="
# 
# if (!(Test-Path $Report)) {
#     throw "Semgrep report not found!"
# }
# 
# try {
# 
#     Write-Host "Formatting JSON..."
# 
#     $json = Get-Content $Report -Raw | ConvertFrom-Json
# 
#     $json |
#         ConvertTo-Json -Depth 100 |
#         Out-File $Report -Encoding utf8
# 
#     Write-Host "Report formatted successfully."
# 
# }
# catch {
# 
#     Write-Host ""
#     Write-Host "========== ERROR =========="
#     Write-Host $_.Exception.Message
#     throw
# 
# }
# 
# Write-Host ""
# Write-Host "========== COPY REPORT =========="
# 
# # Tạo thư mục nếu chưa có
# if (!(Test-Path $Destination)) {
#     New-Item -ItemType Directory -Path $Destination -Force | Out-Null
# }
# 
# # Copy toàn bộ report
# Copy-Item `
#     ".\reports\semgrep\*" `
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
# Write-Host "Semgrep completed successfully."

#!/bin/bash
echo ""
echo "========== SEMGREP =========="

# Chạy Semgrep dưới quyền của user hiện tại
docker compose run --user "$(id -u):$(id -g)" --rm semgrep
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