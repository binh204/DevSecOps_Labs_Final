Write-Host ""
Write-Host "========== CHECKOV =========="

# Chạy Checkov
docker compose run --rm checkov

if ($LASTEXITCODE -ne 0) {
    throw "Checkov scan failed!"
}

# ===== Workspace report =====
$WorkspaceReport = ".\reports\checkov"

# ===== Repo gốc =====
$Destination = "D:\Final_Project\DevSecOps\reports\checkov"

Write-Host ""
Write-Host "========== COPY REPORT =========="

if (!(Test-Path $WorkspaceReport)) {
    throw "Checkov report folder not found!"
}

if (!(Test-Path $Destination)) {
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
}

Copy-Item `
    "$WorkspaceReport\*" `
    $Destination `
    -Recurse `
    -Force

Write-Host "Reports copied successfully."

Write-Host ""
Write-Host "Checkov completed successfully."