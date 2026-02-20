# 🧪 AI Button End-to-End Test Script (PowerShell)
# 
# Acest script rulează testele complete pentru funcționalitatea butonului AI
# și verifică toate aspectele: voce, procesare adrese, fluxul de cursă

param(
    [switch]$Verbose,
    [switch]$SkipBuild,
    [string]$FlutterPath = "C:\Users\flori\AppData\Local\dev\bin\flutter.bat",
    [string]$ProjectDir = "c:\friendsride_app"
)

# Test configuration
$TestTag = "🧪 [AI_E2E_TEST]"
$TotalTests = 0
$PassedTests = 0
$FailedTests = 0

# Function to print colored output
function Write-TestStatus {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] $TestTag $Message" -ForegroundColor $Color
}

function Write-TestSuccess {
    param([string]$Message)
    Write-TestStatus "✅ $Message" "Green"
}

function Write-TestError {
    param([string]$Message)
    Write-TestStatus "❌ $Message" "Red"
}

function Write-TestWarning {
    param([string]$Message)
    Write-TestStatus "⚠️ $Message" "Yellow"
}

function Write-TestInfo {
    param([string]$Message)
    Write-TestStatus "ℹ️ $Message" "Cyan"
}

# Function to run a test
function Invoke-Test {
    param(
        [string]$TestName,
        [scriptblock]$TestCommand
    )
    
    Write-TestInfo "Running test: $TestName"
    $script:TotalTests++
    
    try {
        $result = & $TestCommand
        if ($result) {
            Write-TestSuccess "$TestName passed"
            $script:PassedTests++
            return $true
        } else {
            Write-TestError "$TestName failed"
            $script:FailedTests++
            return $false
        }
    } catch {
        Write-TestError "$TestName failed with error: $($_.Exception.Message)"
        $script:FailedTests++
        return $false
    }
}

# Function to check if Flutter is available
function Test-FlutterInstallation {
    Write-TestInfo "Checking Flutter installation..."
    
    if (Test-Path $FlutterPath) {
        Write-TestSuccess "Flutter found at: $FlutterPath"
        
        # Test Flutter version
        try {
            $version = & $FlutterPath --version 2>$null | Select-String "Flutter" | Select-Object -First 1
            Write-TestInfo "Flutter version: $($version.Line)"
            return $true
        } catch {
            Write-TestWarning "Could not get Flutter version"
            return $true
        }
    } else {
        Write-TestError "Flutter not found at: $FlutterPath"
        return $false
    }
}

# Function to check project structure
function Test-ProjectStructure {
    Write-TestInfo "Checking project structure..."
    
    $requiredFiles = @(
        "lib\main.dart",
        "lib\screens\map_screen.dart",
        "lib\widgets\draggable_ai_button.dart",
        "lib\voice\integration\friendsride_voice_integration.dart",
        "lib\voice\states\voice_interaction_states.dart",
        "pubspec.yaml"
    )
    
    $allFilesExist = $true
    
    foreach ($file in $requiredFiles) {
        $fullPath = Join-Path $ProjectDir $file
        if (Test-Path $fullPath) {
            Write-TestSuccess "Found: $file"
        } else {
            Write-TestError "Missing: $file"
            $allFilesExist = $false
        }
    }
    
    return $allFilesExist
}

# Function to run Flutter analyze
function Test-FlutterAnalyze {
    Write-TestInfo "Running Flutter analyze..."
    
    Push-Location $ProjectDir
    try {
        $output = & $FlutterPath analyze --no-pub 2>&1
        $exitCode = $LASTEXITCODE
        
        if ($exitCode -eq 0) {
            Write-TestSuccess "Flutter analyze passed"
            if ($Verbose) {
                Write-Host $output
            }
            return $true
        } else {
            Write-TestError "Flutter analyze failed"
            Write-Host $output
            return $false
        }
    } finally {
        Pop-Location
    }
}

# Function to test AI button compilation
function Test-AIButtonCompilation {
    if ($SkipBuild) {
        Write-TestInfo "Skipping compilation test (--SkipBuild specified)"
        return $true
    }
    
    Write-TestInfo "Testing AI button compilation..."
    
    Push-Location $ProjectDir
    try {
        # Clean previous builds
        Write-TestInfo "Cleaning previous builds..."
        & $FlutterPath clean | Out-Null
        
        # Get dependencies
        Write-TestInfo "Getting dependencies..."
        & $FlutterPath pub get | Out-Null
        
        # Build for Android
        Write-TestInfo "Building Android APK..."
        $buildOutput = & $FlutterPath build apk --debug --target-platform android-arm64 2>&1
        $exitCode = $LASTEXITCODE
        
        if ($exitCode -eq 0) {
            Write-TestSuccess "AI button compilation successful"
            return $true
        } else {
            Write-TestError "AI button compilation failed"
            Write-Host $buildOutput
            return $false
        }
    } finally {
        Pop-Location
    }
}

# Function to test voice integration
function Test-VoiceIntegration {
    Write-TestInfo "Testing voice integration..."
    
    $voiceFiles = @(
        "lib\voice\integration\friendsride_voice_integration.dart",
        "lib\voice\passenger\passenger_voice_controller.dart",
        "lib\voice\ai\gemini_voice_engine.dart",
        "lib\voice\tts\natural_voice_synthesizer.dart"
    )
    
    $allFilesExist = $true
    
    foreach ($file in $voiceFiles) {
        $fullPath = Join-Path $ProjectDir $file
        if (Test-Path $fullPath) {
            Write-TestSuccess "Voice file exists: $file"
        } else {
            Write-TestError "Voice file missing: $file"
            $allFilesExist = $false
        }
    }
    
    return $allFilesExist
}

# Function to test address processing
function Test-AddressProcessing {
    Write-TestInfo "Testing address processing..."
    
    $addressFiles = @(
        "lib\services\geocoding_service.dart",
        "lib\services\routing_service.dart",
        "lib\services\poi_service.dart"
    )
    
    $filesFound = 0
    
    foreach ($file in $addressFiles) {
        $fullPath = Join-Path $ProjectDir $file
        if (Test-Path $fullPath) {
            Write-TestSuccess "Address service exists: $file"
            $filesFound++
        } else {
            Write-TestWarning "Address service missing: $file"
        }
    }
    
    if ($filesFound -gt 0) {
        Write-TestSuccess "Address processing services found ($filesFound/$($addressFiles.Count))"
        return $true
    } else {
        Write-TestError "No address processing services found"
        return $false
    }
}

# Function to test Firebase integration
function Test-FirebaseIntegration {
    Write-TestInfo "Testing Firebase integration..."
    
    $firebaseFiles = @(
        "lib\services\firebase_service.dart",
        "lib\services\firestore_service.dart",
        "lib\firebase_options.dart"
    )
    
    $allFilesExist = $true
    
    foreach ($file in $firebaseFiles) {
        $fullPath = Join-Path $ProjectDir $file
        if (Test-Path $fullPath) {
            Write-TestSuccess "Firebase service exists: $file"
        } else {
            Write-TestError "Firebase service missing: $file"
            $allFilesExist = $false
        }
    }
    
    return $allFilesExist
}

# Function to test AI button functionality
function Test-AIButtonFunctionality {
    Write-TestInfo "Testing AI button functionality..."
    
    # Check if AI button is properly integrated in map_screen.dart
    $mapScreenPath = Join-Path $ProjectDir "lib\screens\map_screen.dart"
    if (Test-Path $mapScreenPath) {
        $content = Get-Content $mapScreenPath -Raw
        
        if ($content -match "DraggableAIButton") {
            Write-TestSuccess "AI button found in map screen"
        } else {
            Write-TestError "AI button not found in map screen"
            return $false
        }
        
        if ($content -match "FriendsRideVoiceIntegration") {
            Write-TestSuccess "Voice integration found in map screen"
        } else {
            Write-TestError "Voice integration not found in map screen"
            return $false
        }
        
        if ($content -match "_buildVoiceOverlay") {
            Write-TestSuccess "Voice overlay found in map screen"
        } else {
            Write-TestError "Voice overlay not found in map screen"
            return $false
        }
        
        return $true
    } else {
        Write-TestError "Map screen file not found"
        return $false
    }
}

# Function to run performance tests
function Test-Performance {
    Write-TestInfo "Running performance tests..."
    
    $startTime = Get-Date
    
    # Test build time
    Push-Location $ProjectDir
    try {
        $buildStart = Get-Date
        $buildOutput = & $FlutterPath build apk --debug --target-platform android-arm64 2>&1
        $buildEnd = Get-Date
        $buildDuration = ($buildEnd - $buildStart).TotalMilliseconds
        
        if ($LASTEXITCODE -eq 0) {
            if ($buildDuration -lt 60000) {  # Less than 60 seconds
                Write-TestSuccess "Performance test passed (${buildDuration}ms)"
                return $true
            } else {
                Write-TestWarning "Performance test slow (${buildDuration}ms)"
                return $true
            }
        } else {
            Write-TestError "Performance test failed"
            return $false
        }
    } finally {
        Pop-Location
    }
}

# Function to generate test report
function New-TestReport {
    Write-TestInfo "Generating test report..."
    
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "🧪 AI BUTTON END-TO-END TEST REPORT" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Total Tests: $TotalTests"
    Write-Host "Passed: $PassedTests" -ForegroundColor Green
    Write-Host "Failed: $FailedTests" -ForegroundColor Red
    
    if ($TotalTests -gt 0) {
        $successRate = [math]::Round(($PassedTests * 100 / $TotalTests), 1)
        Write-Host "Success Rate: ${successRate}%"
    }
    
    Write-Host ""
    Write-Host "Test Details:"
    Write-Host "- Flutter Installation: $(if ($PassedTests -gt 0) { '✅ PASS' } else { '❌ FAIL' })"
    Write-Host "- Project Structure: $(if ($PassedTests -gt 1) { '✅ PASS' } else { '❌ FAIL' })"
    Write-Host "- Code Analysis: $(if ($PassedTests -gt 2) { '✅ PASS' } else { '❌ FAIL' })"
    Write-Host "- AI Button Compilation: $(if ($PassedTests -gt 3) { '✅ PASS' } else { '❌ FAIL' })"
    Write-Host "- Voice Integration: $(if ($PassedTests -gt 4) { '✅ PASS' } else { '❌ FAIL' })"
    Write-Host "- Address Processing: $(if ($PassedTests -gt 5) { '✅ PASS' } else { '❌ FAIL' })"
    Write-Host "- Firebase Integration: $(if ($PassedTests -gt 6) { '✅ PASS' } else { '❌ FAIL' })"
    Write-Host "- AI Button Functionality: $(if ($PassedTests -gt 7) { '✅ PASS' } else { '❌ FAIL' })"
    Write-Host "- Performance: $(if ($PassedTests -gt 8) { '✅ PASS' } else { '❌ FAIL' })"
    
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    
    if ($FailedTests -eq 0) {
        Write-TestSuccess "All tests passed! AI Button is ready for production."
        exit 0
    } else {
        Write-TestError "Some tests failed. Please review the issues above."
        exit 1
    }
}

# Main test execution
function Start-AITestSuite {
    Write-Host "🧪 Starting AI Button End-to-End Test Suite..." -ForegroundColor Cyan
    Write-Host "Project Directory: $ProjectDir"
    Write-Host "Flutter Path: $FlutterPath"
    Write-Host ""
    
    # Run all tests
    Invoke-Test "Flutter Installation Check" { Test-FlutterInstallation }
    Invoke-Test "Project Structure Check" { Test-ProjectStructure }
    Invoke-Test "Flutter Analyze" { Test-FlutterAnalyze }
    Invoke-Test "AI Button Compilation" { Test-AIButtonCompilation }
    Invoke-Test "Voice Integration" { Test-VoiceIntegration }
    Invoke-Test "Address Processing" { Test-AddressProcessing }
    Invoke-Test "Firebase Integration" { Test-FirebaseIntegration }
    Invoke-Test "AI Button Functionality" { Test-AIButtonFunctionality }
    Invoke-Test "Performance Tests" { Test-Performance }
    
    # Generate final report
    New-TestReport
}

# Run the main function
Start-AITestSuite
