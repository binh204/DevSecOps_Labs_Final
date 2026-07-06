Write-Host ""
Write-Host "========== CHECKOV =========="

# Chạy Checkov
docker compose run --rm checkov

Write-Host "Checkov Exit Code: $LASTEXITCODE"

switch ($LASTEXITCODE) {
    0 {
        Write-Host "No policy violations found."
    }
    1 {
        Write-Host "Policy violations found."
    }
    2 {
        throw "No IaC files found or Checkov execution failed."
    }
    default {
        throw "Unexpected Checkov exit code: $LASTEXITCODE"
    }
}

# ===== Workspace report =====
$WorkspaceReport = ".\reports\checkov"
$Report = "$WorkspaceReport\report.json\results_json.json"

# ===== Repo gốc =====
$Destination = "D:\Final_Project\DevSecOps\reports\checkov"

Write-Host ""
Write-Host "========== FORMAT REPORT =========="

if (!(Test-Path $Report)) {
    throw "Checkov report file not found!"
}

try {
    Write-Host "Formatting JSON..."
    $json = Get-Content $Report -Raw | ConvertFrom-Json
    $json |
        ConvertTo-Json -Depth 100 |
        Out-File $Report -Encoding utf8
    Write-Host "Report formatted successfully."
}
catch {
    Write-Host ""
    Write-Host "========== ERROR =========="
    Write-Host $_.Exception.Message
    throw
}

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