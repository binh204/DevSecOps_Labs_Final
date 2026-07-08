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

sleep 10

response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000)

if [ "$response" -eq 200 ]; then
    echo "Juice Shop is healthy."
else
    echo "Health check failed." >&2
    exit 1
fi