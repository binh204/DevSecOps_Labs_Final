Write-Host ""
Write-Host "========== SEMGREP =========="

docker compose run --rm semgrep

if ($LASTEXITCODE -ne 0) {
    throw "Semgrep scan failed!"
}

Write-Host "Semgrep completed successfully."