# 🔍 SCRIPT PENTRU URMĂRIRE CONSOLĂ DEBUG
# Monitorizează mesajele importante din aplicația FriendsRide

Write-Host "=== 🔍 URMĂRIRE CONSOLĂ DEBUG - FRIENDRIDE ===" -ForegroundColor Green
Write-Host ""
Write-Host "Filtrare pentru mesaje importante:" -ForegroundColor Yellow
Write-Host "  ✅ Auto cleanup stuck rides" -ForegroundColor Cyan
Write-Host "  ✅ Firestore operations" -ForegroundColor Cyan
Write-Host "  ✅ Ride flow & voice AI" -ForegroundColor Cyan
Write-Host "  ✅ Erori și warning-uri" -ForegroundColor Cyan
Write-Host ""
Write-Host "Apasă Ctrl+C pentru a opri urmărirea" -ForegroundColor Yellow
Write-Host ""

# Curăță consola logcat
adb logcat -c

# Filtrează și afișează mesajele importante
adb logcat | Select-String -Pattern "FIRESTORE|RIDE_FLOW|VOICE|AUTO.*CLEANUP|Stuck.*ride|Auto.*cleanup|🧹|🔄|✅|❌|⚠️|Logger|debugPrint" -CaseSensitive:$false

