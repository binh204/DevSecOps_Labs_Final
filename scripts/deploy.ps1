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
echo "========== DEPLOY TO TARGET SERVER (VM1) =========="

# Kiểm tra các biến môi trường từ GitHub Actions
if [ -z "$GITHUB_TOKEN" ] || [ -z "$IMAGE_TAG" ]; then
    echo "ERROR: GITHUB_TOKEN or IMAGE_TAG is not set!" >&2
    exit 1
fi

TARGET_IP="192.168.11.129"
TARGET_USER="target_server"
IMAGE_NAME="ghcr.io/binh204/juice-shop:$IMAGE_TAG"

echo "Deploying image: $IMAGE_NAME to $TARGET_USER@$TARGET_IP..."

# 1. Đăng nhập vào GHCR trên target_server
ssh -o StrictHostKeyChecking=no "$TARGET_USER@$TARGET_IP" "echo '$GITHUB_TOKEN' | docker login ghcr.io -u $GITHUB_ACTOR --password-stdin"
if [ $? -ne 0 ]; then
    echo "Docker login on target server failed!" >&2
    exit 1
fi

# 2. Pull image mới nhất về target_server
ssh -o StrictHostKeyChecking=no "$TARGET_USER@$TARGET_IP" "docker pull $IMAGE_NAME"
if [ $? -ne 0 ]; then
    echo "Docker pull on target server failed!" >&2
    exit 1
fi

# 3. Tắt và xóa container cũ nếu có
ssh -o StrictHostKeyChecking=no "$TARGET_USER@$TARGET_IP" "docker stop juice-shop || true && docker rm -f juice-shop || true"

# 4. Khởi chạy container mới
ssh -o StrictHostKeyChecking=no "$TARGET_USER@$TARGET_IP" "docker run -d --name juice-shop -p 3000:3000 -e \"NODE_ENV=unsafe\" --restart always \$IMAGE_NAME"
if [ $? -ne 0 ]; then
    echo "Docker run on target server failed!" >&2
    exit 1
fi

echo "Deploy completed successfully to target server."