Write-Host ""
Write-Host "========== DEPLOY =========="

docker rm -f juice-shop 2>$null

docker compose up -d --build juice-shop

if ($LASTEXITCODE -ne 0) {
    throw "Deploy failed!"
}

Write-Host "Juice Shop deployed."