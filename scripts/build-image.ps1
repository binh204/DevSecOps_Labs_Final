# Write-Host ""
# Write-Host "========== BUILD IMAGE =========="
# 
# # Nếu chạy trong GitHub Actions thì dùng số lần chạy
# if ($env:GITHUB_RUN_NUMBER) {
#     $Version = "v$($env:GITHUB_RUN_NUMBER)"
# }
# else {
#     # Chạy thủ công
#     $Version = "dev"
# }
# 
# Write-Host "Building image version: $Version"
# 
# docker build `
#     -t juice-shop:latest `
#     -t juice-shop:$Version `
#     ./juice-shop
# 
# if ($LASTEXITCODE -ne 0) {
#     throw "Docker build failed!"
# }
# 
# Write-Host "Image built successfully."
# Write-Host "Tags:"
# Write-Host "  juice-shop:latest"
# Write-Host "  juice-shop:$Version"

#!/bin/bash
echo ""
echo "========== BUILD IMAGE =========="

# Nếu chạy trong GitHub Actions thì dùng số lần chạy
if [ -n "$GITHUB_RUN_NUMBER" ]; then
    Version="v$GITHUB_RUN_NUMBER"
else
    # Chạy thủ công
    Version="dev"
fi

echo "Building image version: $Version"

docker build \
    -t juice-shop:latest \
    -t juice-shop:$Version \
    ./juice-shop

if [ $? -ne 0 ]; then
    echo "Docker build failed!" >&2
    exit 1
fi

echo "Image built successfully."
echo "Tags:"
echo "  juice-shop:latest"
echo "  juice-shop:$Version"
