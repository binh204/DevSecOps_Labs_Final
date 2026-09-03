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

# Options SSH dùng chung
SSH_CMD="ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 $TARGET_USER@$TARGET_IP"

# 1. Truyền trực tiếp Docker Image từ Runner (VM2) sang Target Server (VM1) qua mạng local (Siêu nhanh 3-5 giây)
echo "1. Direct transferring Docker Image to Target Server over local network..."
docker save juice-shop:latest | $SSH_CMD "docker load"
if [ $? -ne 0 ]; then
    echo "Direct image transfer failed. Falling back to GHCR pull..." >&2
    $SSH_CMD "echo '$GITHUB_TOKEN' | docker login ghcr.io -u $GITHUB_ACTOR --password-stdin 2>/dev/null || true"
    $SSH_CMD "docker pull $IMAGE_NAME"
fi

# Gán tag phiên bản cho Image trên Target Server
$SSH_CMD "docker tag juice-shop:latest $IMAGE_NAME 2>/dev/null || true"

# 2. Xóa container juice-shop cũ (dùng rm -f trực tiếp)
echo "2. Removing old juice-shop container..."
$SSH_CMD "docker rm -f juice-shop 2>/dev/null || true"

# 3. Khởi chạy container mới
echo "3. Starting new juice-shop container..."
$SSH_CMD "docker run -d --name juice-shop -p 3000:3000 --restart always juice-shop:latest"
if [ $? -ne 0 ]; then
    echo "ERROR: Docker run on target server failed!" >&2
    exit 1
fi

# 4. Dọn dẹp các dangling layer và tag rác cũ
echo "4. Cleaning up old image tags and dangling images on target server..."
$SSH_CMD "docker images --format '{{.Repository}}:{{.Tag}}' | grep -E 'juice-shop:v|ghcr.io/binh204/juice-shop' | xargs -r docker rmi 2>/dev/null || true"
$SSH_CMD "docker image prune -f 2>/dev/null || true"

echo "Deploy completed successfully to target server."