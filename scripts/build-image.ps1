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

# Lấy ID của Image juice-shop:latest hiện tại trước khi build
OLD_IMAGE_ID=$(docker images -q juice-shop:latest 2>/dev/null)

echo "Building image version: $Version"

docker build \
    -t juice-shop:latest \
    -t juice-shop:$Version \
    ./juice-shop

if [ $? -ne 0 ]; then
    echo "Docker build failed!" >&2
    exit 1
fi

NEW_IMAGE_ID=$(docker images -q juice-shop:latest 2>/dev/null)

# Tự động dọn dẹp Image cũ nếu ID khác Image mới
if [ -n "$OLD_IMAGE_ID" ] && [ "$OLD_IMAGE_ID" != "$NEW_IMAGE_ID" ]; then
    echo "Cleaning up old image (ID: $OLD_IMAGE_ID)..."
    docker rmi -f "$OLD_IMAGE_ID" >/dev/null 2>&1 || true
fi

# Dọn dẹp toàn bộ các dangling layer (<none>) tích tụ
docker image prune -f >/dev/null 2>&1 || true

echo "Image built successfully."
echo "Tags:"
echo "  juice-shop:latest"
echo "  juice-shop:$Version"