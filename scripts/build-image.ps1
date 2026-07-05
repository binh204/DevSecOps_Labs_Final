Write-Host ""
Write-Host "========== BUILD IMAGE =========="

docker build -t juice-shop:latest ./juice-shop

if ($LASTEXITCODE -ne 0) {
    throw "Docker build failed!"
}

Write-Host "Image built successfully."