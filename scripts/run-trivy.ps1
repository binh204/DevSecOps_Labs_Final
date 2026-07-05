Write-Host ""
Write-Host "========== TRIVY =========="

# Chạy Trivy
docker compose run --rm trivy

if ($LASTEXITCODE -ne 0) {
    throw "Trivy scan failed!"
}

# ===== Đường dẫn trong workspace của GitHub Actions =====
$WorkspaceReport = ".\reports\trivy"

# ===== Đường dẫn repo gốc =====
$Destination = "D:\Đồ án\DevSecOps\reports\trivy"

Write-Host ""
Write-Host "========== COPY REPORT =========="

# Kiểm tra thư mục report có tồn tại không
if (!(Test-Path $WorkspaceReport)) {
    throw "Trivy report folder not found!"
}

# Tạo thư mục đích nếu chưa có
if (!(Test-Path $Destination)) {
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
}

# Copy toàn bộ báo cáo
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
Write-Host "Trivy completed successfully."