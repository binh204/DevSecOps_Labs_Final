Write-Host ""
Write-Host "========== SEMGREP =========="

# Chạy Semgrep
docker compose run --rm semgrep

if ($LASTEXITCODE -ne 0) {
    throw "Semgrep scan failed!"
}

# ===== Đường dẫn trong workspace của GitHub Actions =====
$Report = ".\reports\semgrep\report.json"
$Pretty = ".\reports\semgrep\report.pretty.json"

# ===== Đường dẫn repo gốc =====
$Destination = "D:\Đồ án\DevSecOps\reports\semgrep"

Write-Host ""
Write-Host "========== FORMAT REPORT =========="

if (!(Test-Path $Report)) {
    throw "Semgrep report not found!"
}

try {

    Write-Host "Formatting JSON..."

    $json = Get-Content $Report -Raw | ConvertFrom-Json

    $json |
        ConvertTo-Json -Depth 100 |
        Out-File $Pretty -Encoding utf8

    Write-Host "Pretty report created."

}
catch {

    Write-Host ""
    Write-Host "========== ERROR =========="
    Write-Host $_.Exception.Message
    throw

}

Write-Host ""
Write-Host "========== COPY REPORT =========="

# Tạo thư mục nếu chưa có
if (!(Test-Path $Destination)) {
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
}

# Copy toàn bộ report
Copy-Item `
    ".\reports\semgrep\*" `
    $Destination `
    -Recurse `
    -Force

Write-Host "Reports copied successfully."

Write-Host ""
Write-Host "Destination:"
Write-Host $Destination

Write-Host ""
Write-Host "Semgrep completed successfully."