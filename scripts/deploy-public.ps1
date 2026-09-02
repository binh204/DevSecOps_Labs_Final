#!/bin/bash
echo ""
echo "========== DEPLOY PUBLIC (CLOUDFLARE QUICK TUNNEL) =========="

TARGET_IP="192.168.11.129"
TARGET_USER="target_server"

echo "Deploying Cloudflare Quick Tunnel on $TARGET_USER@$TARGET_IP..."

# 1. Tắt và xóa container cloudflared cũ nếu đang chạy
echo "Stopping any existing cloudflared container..."
ssh -o StrictHostKeyChecking=no "$TARGET_USER@$TARGET_IP" "docker stop cloudflared || true && docker rm -f cloudflared || true"

# 2. Khởi chạy cloudflared container trỏ vào Nginx Reverse Proxy (http://localhost:80)
# Nginx lắng nghe ở port 80, chuyển tiếp tới juice-shop (port 3000) và ghi log cho Wazuh
echo "Starting cloudflared container targeting Nginx (http://localhost:80)..."
ssh -o StrictHostKeyChecking=no "$TARGET_USER@$TARGET_IP" "docker run -d --name cloudflared --network host cloudflare/cloudflared:latest tunnel --url http://localhost:80"

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to start cloudflared container on target server!" >&2
    exit 1
fi

# 3. Đợi vài giây để Cloudflare kết nối và khởi tạo Quick Tunnel URL
echo "Waiting for Cloudflare Tunnel to establish..."
sleep 5

PUBLIC_URL=$(ssh -o StrictHostKeyChecking=no "$TARGET_USER@$TARGET_IP" "docker logs cloudflared 2>&1" | grep -o 'https://[-a-zA-Z0-9]*\.trycloudflare\.com' | head -n 1)

if [ -z "$PUBLIC_URL" ]; then
    echo "Retrying to fetch Quick Tunnel URL..."
    sleep 5
    PUBLIC_URL=$(ssh -o StrictHostKeyChecking=no "$TARGET_USER@$TARGET_IP" "docker logs cloudflared 2>&1" | grep -o 'https://[-a-zA-Z0-9]*\.trycloudflare\.com' | head -n 1)
fi

if [ -z "$PUBLIC_URL" ]; then
    echo "WARNING: Could not automatically parse trycloudflare.com URL from container logs."
    echo "Check container logs manually via: ssh $TARGET_USER@$TARGET_IP 'docker logs cloudflared'"
else
    echo ""
    echo "================================================================="
    echo " 🌐 PUBLIC ACCESS URL (Cloudflare Quick Tunnel):"
    echo " $PUBLIC_URL"
    echo "================================================================="
    echo ""
    
    # Nếu chạy trong GitHub Actions, ghi URL trực tiếp vào Job Summary
    if [ -n "$GITHUB_STEP_SUMMARY" ]; then
        echo "### 🌐 Public Web Application URL" >> "$GITHUB_STEP_SUMMARY"
        echo "Application is now publicly available for testing at:" >> "$GITHUB_STEP_SUMMARY"
        echo "**[$PUBLIC_URL]($PUBLIC_URL)**" >> "$GITHUB_STEP_SUMMARY"
        echo "" >> "$GITHUB_STEP_SUMMARY"
        echo "*Monitored by Nginx & Wazuh SIEM Agent on Target Server.*" >> "$GITHUB_STEP_SUMMARY"
    fi
fi

echo "Public deployment completed successfully."
