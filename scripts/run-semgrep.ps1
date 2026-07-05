Write-Host ""
Write-Host "========== SEMGREP =========="

# Chạy Semgrep
docker compose run --rm semgrep

if ($LASTEXITCODE -ne 0) {
    throw "Semgrep scan failed!"
}

# Đường dẫn báo cáo
$ReportPath = ".\reports\semgrep\report.json"
$PrettyReportPath = ".\reports\semgrep\report.pretty.json"

# Kiểm tra file có tồn tại không
if (-not (Test-Path $ReportPath)) {
    throw "Semgrep report not found: $ReportPath"
}

Write-Host "Formatting JSON report..."

try {

    # Đọc toàn bộ file JSON
    $json = Get-Content $ReportPath -Raw | ConvertFrom-Json

    # Xuất ra file pretty
    $json |
        ConvertTo-Json -Depth 100 |
        Out-File $PrettyReportPath -Encoding utf8

    Write-Host "Pretty report created:"
    Write-Host "  $PrettyReportPath"

}
catch {

    Write-Warning "Cannot format Semgrep report."
    Write-Warning $_.Exception.Message

}

Write-Host "Semgrep completed successfully."