#!/bin/bash
echo ""
echo "========== UPLOAD REPORTS TO DEFECTDOJO =========="

# Kiểm tra các biến môi trường
if [ -z "$API_TOKEN" ] || [ -z "$RUN_NUMBER" ]; then
    echo "ERROR: API_TOKEN or RUN_NUMBER is not set!" >&2
    exit 1
fi

DEFECTDOJO_URL="http://192.168.11.130:8080"

# 1. Tìm hoặc tạo Product "Juice Shop"
echo "Checking Product 'Juice Shop' on DefectDojo..."
PRODUCT_ID=$(curl -s -X GET "$DEFECTDOJO_URL/api/v2/products/?name=Juice+Shop" \
  -H "Authorization: Token $API_TOKEN" | python3 -c "import sys, json; data=json.load(sys.stdin); results=data.get('results', []); print(results[0]['id'] if results else 'null')")

if [ "$PRODUCT_ID" == "null" ] || [ -z "$PRODUCT_ID" ]; then
  echo "Product 'Juice Shop' not found. Creating it..."
  PRODUCT_ID=$(curl -s -X POST "$DEFECTDOJO_URL/api/v2/products/" \
    -H "Authorization: Token $API_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "name": "Juice Shop",
      "description": "OWASP Juice Shop Application",
      "prod_type": 1
    }' | python3 -c "import sys, json; print(json.load(sys.stdin).get('id', 'null'))")
  
  if [ "$PRODUCT_ID" == "null" ] || [ -z "$PRODUCT_ID" ]; then
    echo "ERROR: Failed to create Product in DefectDojo!" >&2
    exit 1
  fi
  echo "Created Product 'Juice Shop' with ID: $PRODUCT_ID"
else
  echo "Found Product 'Juice Shop' with ID: $PRODUCT_ID"
fi

# 2. Tạo Engagement mới cho lần chạy pipeline này
START_DATE=$(date +%Y-%m-%d)
END_DATE=$(date -d "+1 day" +%Y-%m-%d 2>/dev/null || date -v+1d +%Y-%m-%d 2>/dev/null || echo "$START_DATE")
ENGAGEMENT_NAME="CI/CD Build #$RUN_NUMBER"

echo "Creating new Engagement: $ENGAGEMENT_NAME..."
ENGAGEMENT_ID=$(curl -s -X POST "$DEFECTDOJO_URL/api/v2/engagements/" \
  -H "Authorization: Token $API_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"$ENGAGEMENT_NAME\",
    \"product\": $PRODUCT_ID,
    \"target_start\": \"$START_DATE\",
    \"target_end\": \"$END_DATE\",
    \"status\": \"In Progress\",
    \"engagement_type\": \"CI/CD\"
  }" | python3 -c "import sys, json; print(json.load(sys.stdin).get('id', 'null'))")

if [ "$ENGAGEMENT_ID" == "null" ] || [ -z "$ENGAGEMENT_ID" ]; then
  echo "ERROR: Failed to create Engagement in DefectDojo!" >&2
  exit 1
fi
echo "Created Engagement with ID: $ENGAGEMENT_ID"

# Hàm helper để upload báo cáo
upload_scan() {
  local scan_type="$1"
  local file_path="$2"
  
  if [ -f "$file_path" ]; then
    echo "Uploading $scan_type report from $file_path..."
    response=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$DEFECTDOJO_URL/api/v2/import-scan/" \
      -H "Authorization: Token $API_TOKEN" \
      -F "active=true" \
      -F "verified=true" \
      -F "scan_type=$scan_type" \
      -F "engagement=$ENGAGEMENT_ID" \
      -F "file=@$file_path")
    
    if [ "$response" -eq 201 ] || [ "$response" -eq 200 ]; then
      echo "Successfully uploaded $scan_type."
    else
      echo "Failed to upload $scan_type. Status code: $response" >&2
    fi
  else
    echo "Report file not found for $scan_type at $file_path. Skipping."
  fi
}

# 3. Upload các báo cáo
upload_scan "Semgrep JSON Report" "/home/soc_server/reports/semgrep/report.json"
upload_scan "Trivy Scan" "/home/soc_server/reports/trivy/report.json"
upload_scan "Checkov Scan" "/home/soc_server/reports/checkov/report.json/results_json.json"
upload_scan "OWASP ZAP XML or JSON" "/home/soc_server/reports/zap/report.json"

echo "Upload reports process completed."
