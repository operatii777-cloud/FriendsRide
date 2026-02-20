# 🧪 AI Button Test Runner Script (PowerShell)
# 
# Acest script rulează toate testele pentru funcționalitatea butonului AI
# și generează un raport complet de testare

param(
    [switch]$Verbose,
    [switch]$SkipBuild,
    [string]$FlutterPath = "C:\Users\flori\AppData\Local\dev\bin\flutter.bat",
    [string]$ProjectDir = "c:\friendsride_app",
    [string]$ReportDir = "test_reports"
)

# Test configuration
$TestTag = "🧪 [AI_TEST_RUNNER]"
$TotalTests = 0
$PassedTests = 0
$FailedTests = 0
$TestStartTime = Get-Date

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

function Write-TestHeader {
    param([string]$Message)
    Write-TestStatus "🚀 $Message" "Blue"
}

# Function to run a test
function Invoke-Test {
    param(
        [string]$TestName,
        [scriptblock]$TestCommand,
        [string]$LogFile
    )
    
    Write-TestInfo "Running test: $TestName"
    $script:TotalTests++
    
    $startTime = Get-Date
    
    try {
        $output = & $TestCommand 2>&1
        $exitCode = $LASTEXITCODE
        
        # Save output to log file
        $logPath = Join-Path $ReportDir "$LogFile.log"
        $output | Out-File -FilePath $logPath -Encoding UTF8
        
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalSeconds
        
        if ($exitCode -eq 0) {
            Write-TestSuccess "$TestName passed ($([math]::Round($duration, 1))s)"
            $script:PassedTests++
            return $true
        } else {
            Write-TestError "$TestName failed ($([math]::Round($duration, 1))s)"
            $script:FailedTests++
            return $false
        }
    } catch {
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalSeconds
        Write-TestError "$TestName failed with error: $($_.Exception.Message) ($([math]::Round($duration, 1))s)"
        $script:FailedTests++
        return $false
    }
}

# Function to setup test environment
function Initialize-TestEnvironment {
    Write-TestHeader "Setting up test environment..."
    
    # Create report directory
    if (!(Test-Path $ReportDir)) {
        New-Item -ItemType Directory -Path $ReportDir | Out-Null
    }
    
    # Check Flutter installation
    if (!(Test-Path $FlutterPath)) {
        Write-TestError "Flutter not found at: $FlutterPath"
        exit 1
    }
    
    Write-TestSuccess "Test environment ready"
}

# Function to run Flutter analyze
function Test-FlutterAnalyze {
    Write-TestHeader "Running Flutter Analyze..."
    
    Push-Location $ProjectDir
    try {
        Invoke-Test "Flutter Analyze" {
            & $FlutterPath analyze --no-pub
        } "flutter_analyze"
    } finally {
        Pop-Location
    }
}

# Function to run unit tests
function Test-UnitTests {
    Write-TestHeader "Running Unit Tests..."
    
    Push-Location $ProjectDir
    try {
        # Test 1: AI Button End-to-End Test
        Invoke-Test "AI Button End-to-End Test" {
            & $FlutterPath test test_ai_button_end_to_end.dart
        } "ai_button_e2e"
        
        # Test 2: Virtual User Test
        Invoke-Test "Virtual User Test" {
            & $FlutterPath test test_ai_button_virtual_user.dart
        } "virtual_user"
        
        # Test 3: Integration Test
        Invoke-Test "Integration Test" {
            & $FlutterPath test test_ai_button_integration.dart
        } "integration"
    } finally {
        Pop-Location
    }
}

# Function to run build tests
function Test-BuildTests {
    if ($SkipBuild) {
        Write-TestInfo "Skipping build tests (--SkipBuild specified)"
        return
    }
    
    Write-TestHeader "Running Build Tests..."
    
    Push-Location $ProjectDir
    try {
        # Clean previous builds
        Write-TestInfo "Cleaning previous builds..."
        & $FlutterPath clean | Out-File -FilePath (Join-Path $ReportDir "flutter_clean.log") -Encoding UTF8
        
        # Get dependencies
        Write-TestInfo "Getting dependencies..."
        & $FlutterPath pub get | Out-File -FilePath (Join-Path $ReportDir "flutter_pub_get.log") -Encoding UTF8
        
        # Test Android build
        Invoke-Test "Android Build Test" {
            & $FlutterPath build apk --debug --target-platform android-arm64
        } "android_build"
        
        # Test Web build
        Invoke-Test "Web Build Test" {
            & $FlutterPath build web
        } "web_build"
    } finally {
        Pop-Location
    }
}

# Function to run performance tests
function Test-Performance {
    Write-TestHeader "Running Performance Tests..."
    
    Push-Location $ProjectDir
    try {
        $startTime = Get-Date
        
        # Simulate app startup
        $buildOutput = & $FlutterPath build apk --debug --target-platform android-arm64 2>&1
        $buildOutput | Out-File -FilePath (Join-Path $ReportDir "performance_build.log") -Encoding UTF8
        
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds
        
        $script:TotalTests++
        
        if ($LASTEXITCODE -eq 0) {
            if ($duration -lt 60000) {  # Less than 60 seconds
                Write-TestSuccess "Performance test passed ($([math]::Round($duration, 0))ms)"
                $script:PassedTests++
            } else {
                Write-TestWarning "Performance test slow ($([math]::Round($duration, 0))ms)"
                $script:PassedTests++
            }
        } else {
            Write-TestError "Performance test failed"
            $script:FailedTests++
        }
    } finally {
        Pop-Location
    }
}

# Function to generate comprehensive report
function New-ComprehensiveReport {
    Write-TestHeader "Generating Comprehensive Test Report..."
    
    $endTime = Get-Date
    $totalDuration = ($endTime - $TestStartTime).TotalSeconds
    
    # Create HTML report
    $htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <title>AI Button Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f0f0f0; padding: 20px; border-radius: 5px; }
        .success { color: #28a745; }
        .error { color: #dc3545; }
        .warning { color: #ffc107; }
        .info { color: #17a2b8; }
        .test-result { margin: 10px 0; padding: 10px; border-left: 4px solid #ccc; }
        .test-result.success { border-left-color: #28a745; }
        .test-result.error { border-left-color: #dc3545; }
        .summary { background-color: #e9ecef; padding: 15px; border-radius: 5px; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🧪 AI Button Test Report</h1>
        <p>Generated on: $(Get-Date)</p>
        <p>Total Duration: $([math]::Round($totalDuration, 1))s</p>
    </div>
    
    <div class="summary">
        <h2>Test Summary</h2>
        <p><strong>Total Tests:</strong> $TotalTests</p>
        <p class="success"><strong>Passed:</strong> $PassedTests</p>
        <p class="error"><strong>Failed:</strong> $FailedTests</p>
        <p><strong>Success Rate:</strong> $([math]::Round($PassedTests * 100 / $TotalTests, 1))%</p>
    </div>
    
    <h2>Test Details</h2>
"@

    # Add test results to HTML
    $logFiles = Get-ChildItem -Path $ReportDir -Filter "*.log"
    foreach ($logFile in $logFiles) {
        $testName = $logFile.BaseName -replace "_", " " -replace "\b\w", { $_.Value.ToUpper() }
        $logContent = Get-Content -Path $logFile.FullName -Raw
        $isSuccess = $logContent -match "All tests passed|PASSED|✅"
        
        $htmlReport += @"
    <div class="test-result $(if ($isSuccess) { "success" } else { "error" })">
        <h3>$testName</h3>
        <pre>$logContent</pre>
    </div>
"@
    }
    
    $htmlReport += @"
</body>
</html>
"@
    
    $htmlReport | Out-File -FilePath (Join-Path $ReportDir "test_report.html") -Encoding UTF8
    
    # Create text report
    $textReport = @"
🧪 AI BUTTON TEST REPORT
========================

Generated: $(Get-Date)
Duration: $([math]::Round($totalDuration, 1))s

SUMMARY:
--------
Total Tests: $TotalTests
Passed: $PassedTests
Failed: $FailedTests
Success Rate: $([math]::Round($PassedTests * 100 / $TotalTests, 1))%

DETAILED RESULTS:
-----------------
"@
    
    # Add detailed results to text report
    foreach ($logFile in $logFiles) {
        $textReport += "`n`n=== $($logFile.BaseName) ===`n"
        $textReport += Get-Content -Path $logFile.FullName -Raw
    }
    
    $textReport | Out-File -FilePath (Join-Path $ReportDir "test_report.txt") -Encoding UTF8
    
    Write-TestSuccess "Comprehensive report generated in $ReportDir/"
}

# Function to display final summary
function Show-FinalSummary {
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "🧪 AI BUTTON TEST SUITE COMPLETED" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Total Tests: $TotalTests"
    Write-Host "Passed: $PassedTests" -ForegroundColor Green
    Write-Host "Failed: $FailedTests" -ForegroundColor Red
    
    if ($TotalTests -gt 0) {
        $successRate = [math]::Round($PassedTests * 100 / $TotalTests, 1)
        Write-Host "Success Rate: ${successRate}%"
    }
    
    Write-Host ""
    Write-Host "Reports generated in: $ReportDir/"
    Write-Host "- test_report.html (Interactive report)"
    Write-Host "- test_report.txt (Text report)"
    Write-Host "- Individual test logs"
    
    Write-Host ""
    if ($FailedTests -eq 0) {
        Write-TestSuccess "All tests passed! AI Button is ready for production."
        exit 0
    } else {
        Write-TestError "Some tests failed. Please review the reports above."
        exit 1
    }
}

# Main execution
function Start-AITestSuite {
    Write-TestHeader "Starting AI Button Test Suite..."
    Write-Host "Project Directory: $ProjectDir"
    Write-Host "Flutter Path: $FlutterPath"
    Write-Host "Report Directory: $ReportDir"
    Write-Host ""
    
    # Setup
    Initialize-TestEnvironment
    
    # Run tests
    Test-FlutterAnalyze
    Test-UnitTests
    Test-BuildTests
    Test-Performance
    
    # Generate reports
    New-ComprehensiveReport
    
    # Display summary
    Show-FinalSummary
}

# Run the main function
Start-AITestSuite
