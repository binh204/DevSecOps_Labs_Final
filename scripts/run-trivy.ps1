Write-Host ""
Write-Host "========== TRIVY =========="

docker compose run --rm trivy

if ($LASTEXITCODE -ne 0) {
    throw "Trivy scan failed!"
}

Write-Host "Trivy completed successfully."
