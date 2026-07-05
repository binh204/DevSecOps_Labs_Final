Write-Host ""
Write-Host "========== DEPLOY =========="

$container = docker ps -aq -f name=^juice-shop$

if ($container) {
    Write-Host "Removing old container..."
    docker rm -f juice-shop
}

docker compose up -d --build juice-shop

if ($LASTEXITCODE -ne 0) {
    throw "Deploy failed!"
}

Write-Host "Deploy completed successfully."