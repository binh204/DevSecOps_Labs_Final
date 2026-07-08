# Write-Host ""
# Write-Host "========== DEPLOY =========="
# 
# $container = docker ps -aq -f name=^juice-shop$
# 
# if ($container) {
#     Write-Host "Removing old container..."
#     docker rm -f juice-shop
# }
# 
# docker compose up -d --build juice-shop
# 
# if ($LASTEXITCODE -ne 0) {
#     throw "Deploy failed!"
# }
# 
# Write-Host "Deploy completed successfully."

#!/bin/bash
echo ""
echo "========== DEPLOY =========="

container=$(docker ps -aq -f name=^juice-shop$)

if [ -n "$container" ]; then
    echo "Removing old container..."
    docker rm -f juice-shop
fi

docker compose up -d --build juice-shop

if [ $? -ne 0 ]; then
    echo "Deploy failed!" >&2
    exit 1
fi

echo "Deploy completed successfully."