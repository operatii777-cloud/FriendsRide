# Script pentru rularea testelor AI reale end-to-end
# Testeaza functionalitatea AI reala cu dispozitive conectate

Write-Host "Starting Real AI End-to-End Tests..." -ForegroundColor Cyan

# Verifica daca Flutter este disponibil
$flutterPath = "C:\Users\flori\AppData\Local\dev\bin\flutter.bat"
if (-not (Test-Path $flutterPath)) {
    Write-Host "ERROR: Flutter not found at $flutterPath" -ForegroundColor Red
    exit 1
}

# Verifica dispozitivele conectate
Write-Host "Checking connected devices..." -ForegroundColor Yellow
& $flutterPath devices

# Ruleaza testele AI
Write-Host "Running AI Tests..." -ForegroundColor Green

$testResults = @()

try {
    # Test 1: Teste AI mock simple (fara dependente Firebase)
    Write-Host "Running Mock AI Simple Tests..." -ForegroundColor Cyan
    & $flutterPath test test_ai_mock_simple.dart --verbose
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SUCCESS: Mock AI Tests completed successfully!" -ForegroundColor Green
        $testResults += "Mock AI Tests: PASSED"
    } else {
        Write-Host "ERROR: Mock AI Tests failed!" -ForegroundColor Red
        $testResults += "Mock AI Tests: FAILED"
    }
    
} catch {
    Write-Host "ERROR: Error running Mock AI tests: $_" -ForegroundColor Red
    $testResults += "Mock AI Tests: ERROR"
}

try {
    # Test 2: Teste E2E cu aplicatia reala
    Write-Host "Running E2E AI Tests with Real App..." -ForegroundColor Cyan
    & $flutterPath test integration_test/test_ai_e2e_with_app.dart --verbose
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SUCCESS: E2E AI Tests completed successfully!" -ForegroundColor Green
        $testResults += "E2E AI Tests: PASSED"
    } else {
        Write-Host "ERROR: E2E AI Tests failed!" -ForegroundColor Red
        $testResults += "E2E AI Tests: FAILED"
    }
    
} catch {
    Write-Host "ERROR: Error running E2E AI tests: $_" -ForegroundColor Red
    $testResults += "E2E AI Tests: ERROR"
}

# Afiseaza rezultatele finale
Write-Host "`nAI Test Results Summary:" -ForegroundColor Yellow
Write-Host "=======================" -ForegroundColor Yellow

foreach ($result in $testResults) {
    if ($result -like "*PASSED*") {
        Write-Host "SUCCESS: $result" -ForegroundColor Green
    } elseif ($result -like "*FAILED*") {
        Write-Host "ERROR: $result" -ForegroundColor Red
    } else {
        Write-Host "WARNING: $result" -ForegroundColor Yellow
    }
}

$passedTests = ($testResults | Where-Object { $_ -like "*PASSED*" }).Count
$totalTests = $testResults.Count

Write-Host "`nOverall Results: $passedTests/$totalTests tests passed" -ForegroundColor Cyan

if ($passedTests -eq $totalTests) {
    Write-Host "All AI tests completed successfully!" -ForegroundColor Green
} elseif ($passedTests -gt 0) {
    Write-Host "Some AI tests passed, some failed" -ForegroundColor Yellow
} else {
    Write-Host "All AI tests failed" -ForegroundColor Red
}

Write-Host "`nReal AI End-to-End Tests finished!" -ForegroundColor Cyan
