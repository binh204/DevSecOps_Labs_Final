Write-Host ""
Write-Host "========== OWASP ZAP =========="

# Chạy OWASP ZAP Baseline Scan
docker compose run --rm zap `
    zap-baseline.py `
    -t http://host.docker.internal:3000 `
    -r report.html `
    -J report.json `
    -w report.md

$ExitCode = $LASTEXITCODE

Write-Host ""
Write-Host "========== ZAP RESULT =========="
Write-Host "ZAP Exit Code: $ExitCode"

# 0 = Không có cảnh báo
# 1 hoặc 2 = Có cảnh báo/lỗ hổng (vẫn cho phép pipeline tiếp tục)
# 3 = Lỗi thực sự khi chạy ZAP

if ($ExitCode -eq 3) {
    throw "OWASP ZAP execution failed!"
}

# ===== Đường dẫn trong workspace =====
$WorkspaceReport = ".\reports\zap"

# ===== Đường dẫn repo gốc =====
$Destination = "D:\Đồ án\DevSecOps\reports\zap"

Write-Host ""
Write-Host "========== COPY REPORT =========="

if (!(Test-Path $Destination)) {
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
}

Copy-Item `
    "$WorkspaceReport\*" `
    $Destination `
    -Recurse `
    -Force

Write-Host "Reports copied successfully."

Write-Host ""
Write-Host "Destination:"
Write-Host $Destination

Write-Host ""
Write-Host "OWASP ZAP completed."