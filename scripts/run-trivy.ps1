# Write-Host ""
# Write-Host "========== TRIVY =========="
# 
# # ==========================
# # 1. Generate SBOM
# # ==========================
# 
# Write-Host ""
# Write-Host "Generating SBOM..."
# 
# docker compose run --rm trivy-sbom
# 
# if ($LASTEXITCODE -ne 0) {
#     throw "SBOM generation failed!"
# }
# 
# # ==========================
# # 2. Check SBOM
# # ==========================
# 
# $WorkspaceSBOM = ".\reports\sbom"
# 
# if (!(Test-Path "$WorkspaceSBOM\sbom.json")) {
#     throw "SBOM file not found!"
# }
# 
# Write-Host "SBOM generated successfully."
# 
# # ==========================
# # 3. Scan SBOM (SCA)
# # ==========================
# 
# Write-Host ""
# Write-Host "Scanning SBOM..."
# 
# docker compose run --rm trivy-sca
# 
# if ($LASTEXITCODE -ne 0) {
#     throw "Trivy SCA scan failed!"
# }
# 
# Write-Host "SCA scan completed."
# 
# # ==========================
# # Workspace reports
# # ==========================
# 
# $WorkspaceTrivy = ".\reports\trivy"
# 
# # ==========================
# # Local destination
# # ==========================
# 
# $SBOMDestination = "D:\Final_Project\DevSecOps\reports\sbom"
# $TrivyDestination = "D:\Final_Project\DevSecOps\reports\trivy"
# 
# Write-Host ""
# Write-Host "========== COPY REPORTS =========="
# 
# foreach ($Folder in @($SBOMDestination, $TrivyDestination)) {
# 
#     if (!(Test-Path $Folder)) {
#         New-Item -ItemType Directory -Path $Folder -Force | Out-Null
#     }
# 
# }
# 
# # Copy SBOM
# Copy-Item `
#     "$WorkspaceSBOM\*" `
#     $SBOMDestination `
#     -Recurse `
#     -Force
# 
# # Copy SCA Report
# Copy-Item `
#     "$WorkspaceTrivy\*" `
#     $TrivyDestination `
#     -Recurse `
#     -Force
# 
# Write-Host "Reports copied successfully."
# 
# Write-Host ""
# Write-Host "Trivy completed successfully."

#!/bin/bash
echo ""
echo "========== TRIVY =========="

# Tạo các thư mục báo cáo và thư mục chứa cache cho Trivy
mkdir -p ./reports/sbom
mkdir -p ./reports/trivy
mkdir -p ./reports/trivy-cache

# ==========================
# 1. Generate SBOM
# ==========================
echo ""
echo "Generating SBOM..."

# Lấy GID của nhóm docker trên host để cấp quyền truy cập Docker socket
DOCKER_GID=$(getent group docker | cut -d: -f3)
if [ -z "$DOCKER_GID" ]; then
    DOCKER_GID=$(id -g)
fi

# Chạy dưới quyền user hiện tại và nhóm docker để đọc được docker.sock
docker compose run --user "$(id -u):$DOCKER_GID" \
    -v "$(pwd)/reports/trivy-cache:/tmp/trivy-cache" \
    -e TRIVY_CACHE_DIR=/tmp/trivy-cache \
    --rm trivy-sbom
if [ $? -ne 0 ]; then
    echo "SBOM generation failed!" >&2
    exit 1
fi

# ==========================
# 2. Check SBOM
# ==========================
WorkspaceSBOM="./reports/sbom"

if [ ! -f "$WorkspaceSBOM/sbom.json" ]; then
    echo "SBOM file not found!" >&2
    exit 1
fi

echo "SBOM generated successfully."

# ==========================
# 3. Scan SBOM (SCA)
# ==========================
echo ""
echo "Scanning SBOM..."

# Chạy dưới quyền user hiện tại, mount thư mục cache và thiết lập biến môi trường TRIVY_CACHE_DIR
docker compose run --user "$(id -u):$(id -g)" \
    -v "$(pwd)/reports/trivy-cache:/tmp/trivy-cache" \
    -e TRIVY_CACHE_DIR=/tmp/trivy-cache \
    --rm trivy-sca
if [ $? -ne 0 ]; then
    echo "Trivy SCA scan failed!" >&2
    exit 1
fi

echo "SCA scan completed."

# ==========================
# Workspace reports
# ==========================
WorkspaceTrivy="./reports/trivy"

# ==========================
# Local destination
# ==========================
SBOMDestination="/home/soc_server/reports/sbom"
TrivyDestination="/home/soc_server/reports/trivy"

echo ""
echo "========== COPY REPORTS =========="

# Check if destination is a Windows path and we are on Linux
if [[ "$SBOMDestination" =~ ^[A-Za-z]:/ ]] && [[ "$OSTYPE" != "msys" && "$OSTYPE" != "cygwin" ]]; then
    echo "Windows destination path detected on Linux. Skipping copy."
else
    for Folder in "$SBOMDestination" "$TrivyDestination"; do
        mkdir -p "$Folder"
    done

    # Copy SBOM
    cp -r "$WorkspaceSBOM"/* "$SBOMDestination/"
    # Copy SCA Report
    cp -r "$WorkspaceTrivy"/* "$TrivyDestination/"

    echo "Reports copied successfully."
fi

echo ""
echo "Trivy completed successfully."