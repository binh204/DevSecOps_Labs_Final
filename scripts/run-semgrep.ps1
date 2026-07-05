Write-Host ""
Write-Host "========== SEMGREP =========="

docker compose run --rm semgrep

if ($LASTEXITCODE -ne 0) {
    throw "Semgrep scan failed!"
}

$Report = ".\reports\semgrep\report.json"
$Pretty = ".\reports\semgrep\report.pretty.json"

Write-Host ""
Write-Host "===== DEBUG ====="

Write-Host "Current Path:"
Get-Location

Write-Host "Report exists?"
Test-Path $Report

Write-Host "Report size:"
(Get-Item $Report).Length

try {

    Write-Host "Loading JSON..."

    $json = Get-Content $Report -Raw | ConvertFrom-Json

    Write-Host "Formatting..."

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
Write-Host "Semgrep completed successfully."