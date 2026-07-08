# Write-Host ""
# Write-Host "========== CHECKOV =========="
# 
# # Chạy Checkov
# docker compose run --rm checkov
# 
# Write-Host "Checkov Exit Code: $LASTEXITCODE"
# 
# switch ($LASTEXITCODE) {
#     0 {
#         Write-Host "No policy violations found."
#     }
#     1 {
#         Write-Host "Policy violations found."
#     }
#     2 {
#         throw "No IaC files found or Checkov execution failed."
#     }
#     default {
#         throw "Unexpected Checkov exit code: $LASTEXITCODE"
#     }
# }
# 
# # ===== Workspace report =====
# $WorkspaceReport = ".\reports\checkov"
# $Report = "$WorkspaceReport\report.json\results_json.json"
# 
# # ===== Repo gốc =====
# $Destination = "D:\Final_Project\DevSecOps\reports\checkov"
# 
# Write-Host ""
# Write-Host "========== FORMAT REPORT =========="
# 
# if (!(Test-Path $Report)) {
#     throw "Checkov report file not found!"
# }
# 
# try {
#     Write-Host "Formatting JSON..."
#     $json = Get-Content $Report -Raw | ConvertFrom-Json
#     $json |
#         ConvertTo-Json -Depth 100 |
#         Out-File $Report -Encoding utf8
#     Write-Host "Report formatted successfully."
# }
# catch {
#     Write-Host ""
#     Write-Host "========== ERROR =========="
#     Write-Host $_.Exception.Message
#     throw
# }
# 
# Write-Host ""
# Write-Host "========== COPY REPORT =========="
# 
# if (!(Test-Path $WorkspaceReport)) {
#     throw "Checkov report folder not found!"
# }
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
# Write-Host "Checkov completed successfully."

#!/bin/bash
echo ""
echo "========== CHECKOV =========="

# Chạy Checkov
docker compose run --rm checkov
exit_code=$?

echo "Checkov Exit Code: $exit_code"

case $exit_code in
    0)
        echo "No policy violations found."
        ;;
    1)
        echo "Policy violations found."
        ;;
    2)
        echo "No IaC files found or Checkov execution failed." >&2
        exit 2
        ;;
    *)
        echo "Unexpected Checkov exit code: $exit_code" >&2
        exit $exit_code
        ;;
esac

# ===== Workspace report =====
WorkspaceReport="./reports/checkov"
Report="$WorkspaceReport/report.json/results_json.json"

# ===== Repo gốc =====
Destination="D:/Final_Project/DevSecOps/reports/checkov"

echo ""
echo "========== FORMAT REPORT =========="

if [ ! -f "$Report" ]; then
    echo "Checkov report file not found!" >&2
    exit 1
fi

echo "Formatting JSON..."
if python3 -c "import json; f=open('$Report', 'r+'); d=json.load(f); f.seek(0); json.dump(d, f, indent=4); f.truncate()" 2>/dev/null; then
    echo "Report formatted successfully."
else
    echo "========== ERROR =========="
    echo "Failed to format JSON report" >&2
    exit 1
fi

echo ""
echo "========== COPY REPORT =========="

# Check if destination is a Windows path and we are on Linux
if [[ "$Destination" =~ ^[A-Za-z]:/ ]] && [[ "$OSTYPE" != "msys" && "$OSTYPE" != "cygwin" ]]; then
    echo "Windows destination path detected on Linux. Skipping copy."
else
    if [ ! -d "$WorkspaceReport" ]; then
        echo "Checkov report folder not found!" >&2
        exit 1
    fi

    mkdir -p "$Destination"
    cp -r "$WorkspaceReport"/* "$Destination/"
    echo "Reports copied successfully."
fi

echo ""
echo "Checkov completed successfully."