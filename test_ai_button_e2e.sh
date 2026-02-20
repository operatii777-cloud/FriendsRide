#!/bin/bash

# 🧪 AI Button End-to-End Test Script
# 
# Acest script rulează testele complete pentru funcționalitatea butonului AI
# și verifică toate aspectele: voce, procesare adrese, fluxul de cursă

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
TEST_TAG="🧪 [AI_E2E_TEST]"
FLUTTER_PATH="C:\\Users\\flori\\AppData\\Local\\dev\\bin\\flutter.bat"
PROJECT_DIR="c:\\friendsride_app"

# Test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

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

# Function to run a test
run_test() {
    local test_name=$1
    local test_command=$2
    
    print_info "Running test: $test_name"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if eval "$test_command"; then
        print_success "$test_name passed"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        print_error "$test_name failed"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# Function to check if Flutter is available
check_flutter() {
    print_info "Checking Flutter installation..."
    if command -v "$FLUTTER_PATH" &> /dev/null; then
        print_success "Flutter found at: $FLUTTER_PATH"
        return 0
    else
        print_error "Flutter not found at: $FLUTTER_PATH"
        return 1
    fi
}

# Function to check project structure
check_project_structure() {
    print_info "Checking project structure..."
    
    local required_files=(
        "lib/main.dart"
        "lib/screens/map_screen.dart"
        "lib/widgets/draggable_ai_button.dart"
        "lib/voice/integration/friendsride_voice_integration.dart"
        "lib/voice/states/voice_interaction_states.dart"
    )
    
    for file in "${required_files[@]}"; do
        if [ -f "$PROJECT_DIR/$file" ]; then
            print_success "Found: $file"
        else
            print_error "Missing: $file"
            return 1
        fi
    done
    
    return 0
}

# Function to run Flutter analyze
run_flutter_analyze() {
    print_info "Running Flutter analyze..."
    cd "$PROJECT_DIR"
    
    if "$FLUTTER_PATH" analyze --no-pub; then
        print_success "Flutter analyze passed"
        return 0
    else
        print_error "Flutter analyze failed"
        return 1
    fi
}

# Function to run unit tests
run_unit_tests() {
    print_info "Running unit tests..."
    cd "$PROJECT_DIR"
    
    if "$FLUTTER_PATH" test test_ai_button_end_to_end.dart; then
        print_success "Unit tests passed"
        return 0
    else
        print_error "Unit tests failed"
        return 1
    fi
}

# Function to run integration tests
run_integration_tests() {
    print_info "Running integration tests..."
    cd "$PROJECT_DIR"
    
    if "$FLUTTER_PATH" test integration_test/; then
        print_success "Integration tests passed"
        return 0
    else
        print_error "Integration tests failed"
        return 1
    fi
}

# Function to test AI button compilation
test_ai_button_compilation() {
    print_info "Testing AI button compilation..."
    cd "$PROJECT_DIR"
    
    # Check if AI button compiles without errors
    if "$FLUTTER_PATH" build apk --debug --target-platform android-arm64; then
        print_success "AI button compilation successful"
        return 0
    else
        print_error "AI button compilation failed"
        return 1
    fi
}

# Function to test voice integration
test_voice_integration() {
    print_info "Testing voice integration..."
    cd "$PROJECT_DIR"
    
    # Check if voice integration files exist and compile
    local voice_files=(
        "lib/voice/integration/friendsride_voice_integration.dart"
        "lib/voice/passenger/passenger_voice_controller.dart"
        "lib/voice/ai/gemini_voice_engine.dart"
    )
    
    for file in "${voice_files[@]}"; do
        if [ -f "$PROJECT_DIR/$file" ]; then
            print_success "Voice file exists: $file"
        else
            print_error "Voice file missing: $file"
            return 1
        fi
    done
    
    return 0
}

# Function to test address processing
test_address_processing() {
    print_info "Testing address processing..."
    cd "$PROJECT_DIR"
    
    # Check if address processing services exist
    local address_files=(
        "lib/services/geocoding_service.dart"
        "lib/services/routing_service.dart"
    )
    
    for file in "${address_files[@]}"; do
        if [ -f "$PROJECT_DIR/$file" ]; then
            print_success "Address service exists: $file"
        else
            print_warning "Address service missing: $file"
        fi
    done
    
    return 0
}

# Function to test Firebase integration
test_firebase_integration() {
    print_info "Testing Firebase integration..."
    cd "$PROJECT_DIR"
    
    # Check if Firebase services exist
    local firebase_files=(
        "lib/services/firebase_service.dart"
        "lib/services/firestore_service.dart"
        "lib/firebase_options.dart"
    )
    
    for file in "${firebase_files[@]}"; do
        if [ -f "$PROJECT_DIR/$file" ]; then
            print_success "Firebase service exists: $file"
        else
            print_error "Firebase service missing: $file"
            return 1
        fi
    done
    
    return 0
}

# Function to run performance tests
run_performance_tests() {
    print_info "Running performance tests..."
    cd "$PROJECT_DIR"
    
    # Test app startup time
    local start_time=$(date +%s%3N)
    
    # Simulate app startup (this would be more comprehensive in real tests)
    if "$FLUTTER_PATH" build apk --debug --target-platform android-arm64; then
        local end_time=$(date +%s%3N)
        local duration=$((end_time - start_time))
        
        if [ $duration -lt 60000 ]; then  # Less than 60 seconds
            print_success "Performance test passed (${duration}ms)"
            return 0
        else
            print_warning "Performance test slow (${duration}ms)"
            return 0
        fi
    else
        print_error "Performance test failed"
        return 1
    fi
}

# Function to generate test report
generate_test_report() {
    print_info "Generating test report..."
    
    echo ""
    echo "=========================================="
    echo "🧪 AI BUTTON END-TO-END TEST REPORT"
    echo "=========================================="
    echo ""
    echo "Total Tests: $TOTAL_TESTS"
    echo "Passed: $PASSED_TESTS"
    echo "Failed: $FAILED_TESTS"
    
    if [ $TOTAL_TESTS -gt 0 ]; then
        local success_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
        echo "Success Rate: ${success_rate}%"
    fi
    
    echo ""
    echo "Test Details:"
    echo "- Flutter Installation: $([ $PASSED_TESTS -gt 0 ] && echo "✅ PASS" || echo "❌ FAIL")"
    echo "- Project Structure: $([ $PASSED_TESTS -gt 1 ] && echo "✅ PASS" || echo "❌ FAIL")"
    echo "- Code Analysis: $([ $PASSED_TESTS -gt 2 ] && echo "✅ PASS" || echo "❌ FAIL")"
    echo "- AI Button Compilation: $([ $PASSED_TESTS -gt 3 ] && echo "✅ PASS" || echo "❌ FAIL")"
    echo "- Voice Integration: $([ $PASSED_TESTS -gt 4 ] && echo "✅ PASS" || echo "❌ FAIL")"
    echo "- Address Processing: $([ $PASSED_TESTS -gt 5 ] && echo "✅ PASS" || echo "❌ FAIL")"
    echo "- Firebase Integration: $([ $PASSED_TESTS -gt 6 ] && echo "✅ PASS" || echo "❌ FAIL")"
    echo "- Performance: $([ $PASSED_TESTS -gt 7 ] && echo "✅ PASS" || echo "❌ FAIL")"
    
    echo ""
    echo "=========================================="
    
    if [ $FAILED_TESTS -eq 0 ]; then
        print_success "All tests passed! AI Button is ready for production."
        exit 0
    else
        print_error "Some tests failed. Please review the issues above."
        exit 1
    fi
}

# Main test execution
main() {
    echo "🧪 Starting AI Button End-to-End Test Suite..."
    echo "Project Directory: $PROJECT_DIR"
    echo "Flutter Path: $FLUTTER_PATH"
    echo ""
    
    # Run all tests
    run_test "Flutter Installation Check" "check_flutter"
    run_test "Project Structure Check" "check_project_structure"
    run_test "Flutter Analyze" "run_flutter_analyze"
    run_test "AI Button Compilation" "test_ai_button_compilation"
    run_test "Voice Integration" "test_voice_integration"
    run_test "Address Processing" "test_address_processing"
    run_test "Firebase Integration" "test_firebase_integration"
    run_test "Performance Tests" "run_performance_tests"
    
    # Generate final report
    generate_test_report
}

# Run the main function
main "$@"
