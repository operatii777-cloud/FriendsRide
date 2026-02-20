# Script pentru capturarea logurilor delivery într-un fișier
$logFile = "delivery_logs_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

Write-Host "📝 Capturare loguri în: $logFile" -ForegroundColor Cyan
Write-Host "Apasă Ctrl+C pentru a opri capturarea" -ForegroundColor Yellow
Write-Host ""

# Curăță logurile vechi
adb logcat -c

# Capturează logurile Flutter și le salvează în fișier
adb logcat flutter:I *:E | Tee-Object -FilePath $logFile | Select-String -Pattern "DELIVERY|SYNC|RESTAURANT|comanda|order|webhook|Error|Exception|Timeout|Failed|❌|⚠️|🔄|✅" -CaseSensitive:$false | ForEach-Object {
    $line = $_.Line
    $timestamp = Get-Date -Format "HH:mm:ss"
    
    # Afișează în consolă cu culori
    if ($line -match "❌|Error|Exception|Failed|Timeout") {
        Write-Host "[$timestamp] $line" -ForegroundColor Red
    } elseif ($line -match "⚠️|Warning") {
        Write-Host "[$timestamp] $line" -ForegroundColor Yellow
    } elseif ($line -match "✅|Success") {
        Write-Host "[$timestamp] $line" -ForegroundColor Green
    } elseif ($line -match "🔄|DELIVERY|SYNC") {
        Write-Host "[$timestamp] $line" -ForegroundColor Cyan
    } else {
        Write-Host "[$timestamp] $line"
    }
}

