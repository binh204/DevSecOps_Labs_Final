# Write-Host ""
# Write-Host "========== HEALTH CHECK =========="
# 
# Start-Sleep -Seconds 10
# 
# try {
#     $response = Invoke-WebRequest http://localhost:3000 -UseBasicParsing
# 
#     if ($response.StatusCode -eq 200) {
#         Write-Host "Juice Shop is healthy."
#     }
#     else {
#         throw "Application unhealthy."
#     }
# }
# catch {
#     throw "Health check failed."
# }

#!/bin/bash
echo ""
echo "========== HEALTH CHECK =========="

TARGET_IP="192.168.11.129"
PORT="3000"

echo "Waiting for Juice Shop to start on http://$TARGET_IP:$PORT..."

# Thử kiểm tra tối đa 10 lần, mỗi lần cách nhau 5 giây (Tổng cộng 50 giây)
for i in {1..10}; do
    response=$(curl -s -o /dev/null -w "%{http_code}" http://$TARGET_IP:$PORT)
    
    if [ "$response" -eq 200 ]; then
        echo "Juice Shop is healthy (Connected on attempt $i)!"
        exit 0
    fi
    
    echo "Attempt $i: Application not ready yet (Status: $response). Retrying in 5 seconds..."
    sleep 5
done

echo "ERROR: Health check failed after 50 seconds! Status code: $response" >&2
exit 1