#!/bin/bash
echo ""
echo "========== BUILD IMAGE =========="

# Kiểm tra nếu đang ở trong Git repo và kiểm tra sự thay đổi trong thư mục juice-shop
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if ! git diff --name-only HEAD~1 HEAD 2>/dev/null | grep -q "^juice-shop/"; then
        if docker image inspect juice-shop:latest >/dev/null 2>&1; then
            echo "No source code changes detected in ./juice-shop since last commit."
            echo "Skipping docker build. Reusing existing local image 'juice-shop:latest'."
            if [ -n "$GITHUB_RUN_NUMBER" ]; then
                docker tag juice-shop:latest "juice-shop:v$GITHUB_RUN_NUMBER" 2>/dev/null || true
            fi
            exit 0
        fi
    fi
fi

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