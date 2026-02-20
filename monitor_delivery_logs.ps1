# Script pentru monitorizarea logurilor delivery în timp real
Write-Host "🔍 Monitorizare loguri Delivery/Sync..." -ForegroundColor Cyan
Write-Host "Aștept conexiune device/emulator..." -ForegroundColor Yellow
Write-Host ""

# Verifică dacă există device conectat
$devices = adb devices
if ($devices -notmatch "device$") {
    Write-Host "❌ Nu există device conectat!" -ForegroundColor Red
    Write-Host "Conectează un device sau pornește un emulator." -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Device detectat. Monitorizare activă..." -ForegroundColor Green
Write-Host "Filtru: DELIVERY, SYNC, Error, Exception, Timeout, Failed" -ForegroundColor Cyan
Write-Host "Apasă Ctrl+C pentru a opri monitorizarea" -ForegroundColor Yellow
Write-Host ""

# Monitorizează logcat cu filtre pentru erori și mesaje relevante
adb logcat -c  # Curăță logurile vechi
adb logcat | Select-String -Pattern "DELIVERY|SYNC|Error|Exception|Timeout|Failed|❌|⚠️|🔄|✅|RESTAURANT" -Context 0,0 | ForEach-Object {
    $line = $_.Line
    $timestamp = Get-Date -Format "HH:mm:ss"
    
    # Colorează output-ul în funcție de tipul mesajului
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

