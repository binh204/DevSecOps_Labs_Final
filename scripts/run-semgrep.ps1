Write-Host ""
Write-Host "========== SEMGREP =========="

docker compose run --rm semgrep

if ($LASTEXITCODE -ne 0) {
    throw "Semgrep scan failed!"
}

Write-Host "Formatting JSON report..."

Get-Content .\reports\semgrep\report.json |
    ConvertFrom-Json |
    ConvertTo-Json -Depth 100 |
    Set-Content .\reports\semgrep\report.json

Write-Host "Semgrep completed successfully."