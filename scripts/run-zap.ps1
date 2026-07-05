Write-Host ""
Write-Host "========== OWASP ZAP =========="

docker compose run --rm zap `
    zap-baseline.py `
    -t http://host.docker.internal:3000 `
    -r report.html `
    -J report.json `
    -w report.md

if ($LASTEXITCODE -ne 0) {
    throw "OWASP ZAP failed!"
}

Write-Host "OWASP ZAP completed."