Write-Host ""
Write-Host "========== TRIVY =========="

# ==========================
# 1. Generate SBOM
# ==========================

Write-Host ""
Write-Host "Generating SBOM..."

docker compose run --rm trivy-sbom

if ($LASTEXITCODE -ne 0) {
    throw "SBOM generation failed!"
}

# ==========================
# 2. Check SBOM
# ==========================

$WorkspaceSBOM = ".\reports\sbom"

if (!(Test-Path "$WorkspaceSBOM\sbom.json")) {
    throw "SBOM file not found!"
}

Write-Host "SBOM generated successfully."

# ==========================
# 3. Scan SBOM (SCA)
# ==========================

Write-Host ""
Write-Host "Scanning SBOM..."

docker compose run --rm trivy-sca

if ($LASTEXITCODE -ne 0) {
    throw "Trivy SCA scan failed!"
}

Write-Host "SCA scan completed."

# ==========================
# Workspace reports
# ==========================

$WorkspaceTrivy = ".\reports\trivy"

# ==========================
# Local destination
# ==========================

$SBOMDestination = "D:\Final_Project\DevSecOps\reports\sbom"
$TrivyDestination = "D:\Final_Project\DevSecOps\reports\trivy"

Write-Host ""
Write-Host "========== COPY REPORTS =========="

foreach ($Folder in @($SBOMDestination, $TrivyDestination)) {

    if (!(Test-Path $Folder)) {
        New-Item -ItemType Directory -Path $Folder -Force | Out-Null
    }

}

# Copy SBOM
Copy-Item `
    "$WorkspaceSBOM\*" `
    $SBOMDestination `
    -Recurse `
    -Force

# Copy SCA Report
Copy-Item `
    "$WorkspaceTrivy\*" `
    $TrivyDestination `
    -Recurse `
    -Force

Write-Host "Reports copied successfully."

Write-Host ""
Write-Host "Trivy completed successfully."