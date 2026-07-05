Write-Host ""
Write-Host "========== HEALTH CHECK =========="

Start-Sleep -Seconds 10

try {
    $response = Invoke-WebRequest http://localhost:3000 -UseBasicParsing

    if ($response.StatusCode -eq 200) {
        Write-Host "Juice Shop is healthy."
    }
    else {
        throw "Application unhealthy."
    }
}
catch {
    throw "Health check failed."
}