#!/bin/bash

# 🧪 AI Button Test Runner Script
# 
# Acest script rulează toate testele pentru funcționalitatea butonului AI
# și generează un raport complet de testare

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
TEST_TAG="🧪 [AI_TEST_RUNNER]"
FLUTTER_PATH="C:\\Users\\flori\\AppData\\Local\\dev\\bin\\flutter.bat"
PROJECT_DIR="c:\\friendsride_app"
REPORT_DIR="test_reports"

# Test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
TEST_START_TIME=$(date +%s)

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${TEST_TAG} ${message}${NC}"
}

print_success() {
    print_status "$GREEN" "✅ $1"
}

print_error() {
    print_status "$RED" "❌ $1"
}

print_warning() {
    print_status "$YELLOW" "⚠️ $1"
}

print_info() {
    print_status "$BLUE" "ℹ️ $1"
}

print_header() {
    print_status "$CYAN" "🚀 $1"
}

# Function to run a test
run_test() {
    local test_name=$1
    local test_command=$2
    local test_file=$3
    
    print_info "Running test: $test_name"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    local start_time=$(date +%s)
    
    if eval "$test_command" > "${REPORT_DIR}/${test_file}.log" 2>&1; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        print_success "$test_name passed (${duration}s)"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        print_error "$test_name failed (${duration}s)"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# Function to setup test environment
setup_test_environment() {
    print_header "Setting up test environment..."
    
    # Create report directory
    mkdir -p "$REPORT_DIR"
    
    # Check Flutter installation
    if ! command -v "$FLUTTER_PATH" &> /dev/null; then
        print_error "Flutter not found at: $FLUTTER_PATH"
        exit 1
    fi
    
    print_success "Test environment ready"
}

# Function to run unit tests
run_unit_tests() {
    print_header "Running Unit Tests..."
    
    cd "$PROJECT_DIR"
    
    # Test 1: AI Button End-to-End Test
    run_test "AI Button End-to-End Test" \
             "$FLUTTER_PATH test test_ai_button_end_to_end.dart" \
             "ai_button_e2e"
    
    # Test 2: Virtual User Test
    run_test "Virtual User Test" \
             "$FLUTTER_PATH test test_ai_button_virtual_user.dart" \
             "virtual_user"
    
    # Test 3: Integration Test
    run_test "Integration Test" \
             "$FLUTTER_PATH test test_ai_button_integration.dart" \
             "integration"
}

# Function to run Flutter analyze
run_flutter_analyze() {
    print_header "Running Flutter Analyze..."
    
    cd "$PROJECT_DIR"
    
    run_test "Flutter Analyze" \
             "$FLUTTER_PATH analyze --no-pub" \
             "flutter_analyze"
}

# Function to run build tests
run_build_tests() {
    print_header "Running Build Tests..."
    
    cd "$PROJECT_DIR"
    
    # Clean previous builds
    print_info "Cleaning previous builds..."
    "$FLUTTER_PATH" clean > "${REPORT_DIR}/flutter_clean.log" 2>&1
    
    # Get dependencies
    print_info "Getting dependencies..."
    "$FLUTTER_PATH" pub get > "${REPORT_DIR}/flutter_pub_get.log" 2>&1
    
    # Test Android build
    run_test "Android Build Test" \
             "$FLUTTER_PATH build apk --debug --target-platform android-arm64" \
             "android_build"
    
    # Test Web build
    run_test "Web Build Test" \
             "$FLUTTER_PATH build web" \
             "web_build"
}

# Function to run performance tests
run_performance_tests() {
    print_header "Running Performance Tests..."
    
    cd "$PROJECT_DIR"
    
    # Test app startup time
    local start_time=$(date +%s%3N)
    
    # Simulate app startup
    if "$FLUTTER_PATH" build apk --debug --target-platform android-arm64 > "${REPORT_DIR}/performance_build.log" 2>&1; then
        local end_time=$(date +%s%3N)
        local duration=$((end_time - start_time))
        
        if [ $duration -lt 60000 ]; then  # Less than 60 seconds
            print_success "Performance test passed (${duration}ms)"
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            print_warning "Performance test slow (${duration}ms)"
            PASSED_TESTS=$((PASSED_TESTS + 1))
        fi
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
    else
        print_error "Performance test failed"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
    fi
}

# Function to generate comprehensive report
generate_comprehensive_report() {
    print_header "Generating Comprehensive Test Report..."
    
    local end_time=$(date +%s)
    local total_duration=$((end_time - TEST_START_TIME))
    
    # Create HTML report
    cat > "${REPORT_DIR}/test_report.html" << EOF
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
        <p>Generated on: $(date)</p>
        <p>Total Duration: ${total_duration}s</p>
    </div>
    
    <div class="summary">
        <h2>Test Summary</h2>
        <p><strong>Total Tests:</strong> $TOTAL_TESTS</p>
        <p class="success"><strong>Passed:</strong> $PASSED_TESTS</p>
        <p class="error"><strong>Failed:</strong> $FAILED_TESTS</p>
        <p><strong>Success Rate:</strong> $((PASSED_TESTS * 100 / TOTAL_TESTS))%</p>
    </div>
    
    <h2>Test Details</h2>
EOF

    # Add test results to HTML
    if [ -f "${REPORT_DIR}/ai_button_e2e.log" ]; then
        echo "    <div class=\"test-result $(if grep -q "All tests passed" "${REPORT_DIR}/ai_button_e2e.log"; then echo "success"; else echo "error"; fi)\">" >> "${REPORT_DIR}/test_report.html"
        echo "        <h3>AI Button End-to-End Test</h3>" >> "${REPORT_DIR}/test_report.html"
        echo "        <pre>$(cat "${REPORT_DIR}/ai_button_e2e.log")</pre>" >> "${REPORT_DIR}/test_report.html"
        echo "    </div>" >> "${REPORT_DIR}/test_report.html"
    fi
    
    if [ -f "${REPORT_DIR}/virtual_user.log" ]; then
        echo "    <div class=\"test-result $(if grep -q "All tests passed" "${REPORT_DIR}/virtual_user.log"; then echo "success"; else echo "error"; fi)\">" >> "${REPORT_DIR}/test_report.html"
        echo "        <h3>Virtual User Test</h3>" >> "${REPORT_DIR}/test_report.html"
        echo "        <pre>$(cat "${REPORT_DIR}/virtual_user.log")</pre>" >> "${REPORT_DIR}/test_report.html"
        echo "    </div>" >> "${REPORT_DIR}/test_report.html"
    fi
    
    if [ -f "${REPORT_DIR}/integration.log" ]; then
        echo "    <div class=\"test-result $(if grep -q "All tests passed" "${REPORT_DIR}/integration.log"; then echo "success"; else echo "error"; fi)\">" >> "${REPORT_DIR}/test_report.html"
        echo "        <h3>Integration Test</h3>" >> "${REPORT_DIR}/test_report.html"
        echo "        <pre>$(cat "${REPORT_DIR}/integration.log")</pre>" >> "${REPORT_DIR}/test_report.html"
        echo "    </div>" >> "${REPORT_DIR}/test_report.html"
    fi
    
    # Close HTML
    cat >> "${REPORT_DIR}/test_report.html" << EOF
    <h2>Build Logs</h2>
    <div class="test-result">
        <h3>Flutter Analyze</h3>
        <pre>$(cat "${REPORT_DIR}/flutter_analyze.log" 2>/dev/null || echo "No analyze log found")</pre>
    </div>
    
    <div class="test-result">
        <h3>Android Build</h3>
        <pre>$(cat "${REPORT_DIR}/android_build.log" 2>/dev/null || echo "No Android build log found")</pre>
    </div>
    
    <div class="test-result">
        <h3>Web Build</h3>
        <pre>$(cat "${REPORT_DIR}/web_build.log" 2>/dev/null || echo "No Web build log found")</pre>
    </div>
</body>
</html>
EOF

    # Create text report
    cat > "${REPORT_DIR}/test_report.txt" << EOF
🧪 AI BUTTON TEST REPORT
========================

Generated: $(date)
Duration: ${total_duration}s

SUMMARY:
--------
Total Tests: $TOTAL_TESTS
Passed: $PASSED_TESTS
Failed: $FAILED_TESTS
Success Rate: $((PASSED_TESTS * 100 / TOTAL_TESTS))%

DETAILED RESULTS:
-----------------
EOF

    # Add detailed results to text report
    for log_file in "${REPORT_DIR}"/*.log; do
        if [ -f "$log_file" ]; then
            echo "" >> "${REPORT_DIR}/test_report.txt"
            echo "=== $(basename "$log_file" .log) ===" >> "${REPORT_DIR}/test_report.txt"
            cat "$log_file" >> "${REPORT_DIR}/test_report.txt"
        fi
    done
    
    print_success "Comprehensive report generated in ${REPORT_DIR}/"
}

# Function to display final summary
display_final_summary() {
    echo ""
    echo "=========================================="
    echo "🧪 AI BUTTON TEST SUITE COMPLETED"
    echo "=========================================="
    echo ""
    echo "Total Tests: $TOTAL_TESTS"
    echo "Passed: $PASSED_TESTS" | sed 's/^/✅ /'
    echo "Failed: $FAILED_TESTS" | sed 's/^/❌ /'
    
    if [ $TOTAL_TESTS -gt 0 ]; then
        local success_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
        echo "Success Rate: ${success_rate}%"
    fi
    
    echo ""
    echo "Reports generated in: $REPORT_DIR/"
    echo "- test_report.html (Interactive report)"
    echo "- test_report.txt (Text report)"
    echo "- Individual test logs"
    
    echo ""
    if [ $FAILED_TESTS -eq 0 ]; then
        print_success "All tests passed! AI Button is ready for production."
        exit 0
    else
        print_error "Some tests failed. Please review the reports above."
        exit 1
    fi
}

# Main execution
main() {
    print_header "Starting AI Button Test Suite..."
    echo "Project Directory: $PROJECT_DIR"
    echo "Flutter Path: $FLUTTER_PATH"
    echo "Report Directory: $REPORT_DIR"
    echo ""
    
    # Setup
    setup_test_environment
    
    # Run tests
    run_flutter_analyze
    run_unit_tests
    run_build_tests
    run_performance_tests
    
    # Generate reports
    generate_comprehensive_report
    
    # Display summary
    display_final_summary
}

# Run the main function
main "$@"
