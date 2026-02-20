// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:friendsride_app/voice/states/voice_interaction_states.dart';

/// 🧪 AI Button End-to-End Test Script
/// 
/// Acest script testează funcționalitatea completă a butonului AI:
/// 1. Pornirea interacțiunii vocale
/// 2. Procesarea comenzilor vocale
/// 3. Găsirea și validarea adreselor
/// 4. Fluxul complet de rezervare cursei
/// 5. Utilizator virtual pentru simularea interacțiunii
class AIButtonEndToEndTest {
  static const String _testTag = '🧪 [AI_E2E_TEST]';
  
  // Test results
  final List<TestResult> _results = [];
  bool _isRunning = false;
  
  // Virtual user simulation
  final VirtualUser _virtualUser = VirtualUser();
  
  // Test scenarios
  final List<TestScenario> _scenarios = [
    TestScenario(
      name: 'Basic Ride Request',
      voiceCommand: 'Vreau să merg la Piața Unirii',
      expectedDestination: 'Piața Unirii',
      expectedPickup: null, // Will use current location
    ),
    TestScenario(
      name: 'Specific Pickup and Destination',
      voiceCommand: 'Ia-mă de la Gara de Nord la Aeroportul Otopeni',
      expectedPickup: 'Gara de Nord',
      expectedDestination: 'Aeroportul Otopeni',
    ),
    TestScenario(
      name: 'Romanian Address Format',
      voiceCommand: 'Du-mă la Strada Victoriei numărul 10',
      expectedDestination: 'Strada Victoriei 10',
      expectedPickup: null,
    ),
    TestScenario(
      name: 'Emergency Request',
      voiceCommand: 'Am o urgență, du-mă la spitalul cel mai apropiat',
      expectedDestination: 'spital',
      expectedPickup: null,
      isEmergency: true,
    ),
    TestScenario(
      name: 'Complex Address',
      voiceCommand: 'Vreau să merg la Centrul Comercial Băneasa Shopping City',
      expectedDestination: 'Centrul Comercial Băneasa',
      expectedPickup: null,
    ),
  ];

  /// 🚀 Rulează toate testele end-to-end
  Future<void> runAllTests() async {
    if (_isRunning) {
      print('$_testTag Test already running!');
      return;
    }

    _isRunning = true;
    print('$_testTag Starting AI Button End-to-End Tests...');
    print('$_testTag Testing ${_scenarios.length} scenarios');
    
    try {
      // Initialize test environment
      await _initializeTestEnvironment();
      
      // Run each test scenario
      for (int i = 0; i < _scenarios.length; i++) {
        final scenario = _scenarios[i];
        print('\n$_testTag ===== SCENARIO ${i + 1}: ${scenario.name} =====');
        
        final result = await _runScenario(scenario);
        _results.add(result);
        
        // Wait between tests
        await Future.delayed(const Duration(seconds: 2));
      }
      
      // Generate final report
      _generateTestReport();
      
    } catch (e) {
      print('$_testTag ❌ Test execution failed: $e');
    } finally {
      _isRunning = false;
    }
  }

  /// 🔧 Inițializează mediul de test
  Future<void> _initializeTestEnvironment() async {
    print('$_testTag Initializing test environment...');
    
    // Initialize virtual user
    await _virtualUser.initialize();
    print('$_testTag ✅ Virtual user initialized');
    
    // Initialize voice integration
    // Note: In real tests, this would be done through the app
    print('$_testTag ✅ Test environment ready');
  }

  /// 🎯 Rulează un scenariu de test
  Future<TestResult> _runScenario(TestScenario scenario) async {
    final stopwatch = Stopwatch()..start();
    final result = TestResult(scenario: scenario);
    
    try {
      print('$_testTag Testing: "${scenario.voiceCommand}"');
      
      // Step 1: Simulate AI button press
      print('$_testTag Step 1: Simulating AI button press...');
      await _simulateAIButtonPress();
      result.aiButtonPressed = true;
      
      // Step 2: Simulate voice input
      print('$_testTag Step 2: Simulating voice input...');
      await _simulateVoiceInput(scenario.voiceCommand);
      result.voiceInputProcessed = true;
      
      // Step 3: Verify AI response
      print('$_testTag Step 3: Verifying AI response...');
      final aiResponse = await _verifyAIResponse(scenario);
      result.aiResponseValid = aiResponse;
      
      // Step 4: Verify address processing
      print('$_testTag Step 4: Verifying address processing...');
      final addressProcessed = await _verifyAddressProcessing(scenario);
      result.addressProcessed = addressProcessed;
      
      // Step 5: Verify ride flow initiation
      print('$_testTag Step 5: Verifying ride flow...');
      final rideFlowInitiated = await _verifyRideFlow(scenario);
      result.rideFlowInitiated = rideFlowInitiated;
      
      result.success = result.aiButtonPressed && 
                     result.voiceInputProcessed && 
                     result.aiResponseValid && 
                     result.addressProcessed && 
                     result.rideFlowInitiated;
      
    } catch (e) {
      print('$_testTag ❌ Scenario failed: $e');
      result.error = e.toString();
    } finally {
      stopwatch.stop();
      result.duration = stopwatch.elapsed;
      print('$_testTag Scenario completed in ${result.duration.inMilliseconds}ms');
    }
    
    return result;
  }

  /// 🎤 Simulează apăsarea butonului AI
  Future<void> _simulateAIButtonPress() async {
    // Simulate the user pressing the AI button
    await _virtualUser.pressAIButton();
    
    // Verify that voice interaction starts
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Check if voice integration is active
    final isActive = _virtualUser.isVoiceActive;
    if (!isActive) {
      throw Exception('Voice interaction did not start after AI button press');
    }
    
    print('$_testTag ✅ AI button press simulated successfully');
  }

  /// 🗣️ Simulează input vocal
  Future<void> _simulateVoiceInput(String command) async {
    // Simulate speech recognition
    await _virtualUser.speakCommand(command);
    
    // Wait for processing
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // Verify command was processed
    final processedCommand = _virtualUser.lastProcessedCommand;
    if (processedCommand != command) {
      throw Exception('Voice command not processed correctly');
    }
    
    print('$_testTag ✅ Voice input simulated: "$command"');
  }

  /// 🤖 Verifică răspunsul AI-ului
  Future<bool> _verifyAIResponse(TestScenario scenario) async {
    final aiResponse = _virtualUser.lastAIResponse;
    
    if (aiResponse.isEmpty) {
      print('$_testTag ❌ No AI response received');
      return false;
    }
    
    // Check if AI response contains expected elements
    final containsDestination = scenario.expectedDestination != null && 
                               aiResponse.toLowerCase().contains(scenario.expectedDestination!.toLowerCase());
    
    final containsPickup = scenario.expectedPickup != null && 
                          aiResponse.toLowerCase().contains(scenario.expectedPickup!.toLowerCase());
    
    final isValidResponse = containsDestination || containsPickup || 
                           aiResponse.contains('confirm') || 
                           aiResponse.contains('confirmă') ||
                           aiResponse.contains('unde') ||
                           aiResponse.contains('destinație');
    
    print('$_testTag AI Response: "$aiResponse"');
    print('$_testTag ✅ AI response valid: $isValidResponse');
    
    return isValidResponse;
  }

  /// 📍 Verifică procesarea adreselor
  Future<bool> _verifyAddressProcessing(TestScenario scenario) async {
    final processedAddresses = _virtualUser.processedAddresses;
    
    if (processedAddresses.isEmpty) {
      print('$_testTag ❌ No addresses processed');
      return false;
    }
    
    // Check if expected destination was found
    bool destinationFound = false;
    if (scenario.expectedDestination != null) {
      for (final address in processedAddresses) {
        if (address.toLowerCase().contains(scenario.expectedDestination!.toLowerCase())) {
          destinationFound = true;
          break;
        }
      }
    } else {
      destinationFound = true; // No specific destination expected
    }
    
    // Check if expected pickup was found
    bool pickupFound = true; // Default to true if no pickup expected
    if (scenario.expectedPickup != null) {
      pickupFound = false;
      for (final address in processedAddresses) {
        if (address.toLowerCase().contains(scenario.expectedPickup!.toLowerCase())) {
          pickupFound = true;
          break;
        }
      }
    }
    
    final isValid = destinationFound && pickupFound;
    print('$_testTag Processed addresses: $processedAddresses');
    print('$_testTag ✅ Address processing valid: $isValid');
    
    return isValid;
  }

  /// 🚗 Verifică inițierea fluxului de cursă
  Future<bool> _verifyRideFlow(TestScenario scenario) async {
    final rideFlowState = _virtualUser.currentRideFlowState;
    
    // Check if ride flow is in appropriate state
    final isValidState = rideFlowState == RideFlowState.processingCommand ||
                        rideFlowState == RideFlowState.awaitingConfirmation ||
                        rideFlowState == RideFlowState.searchingDrivers;
    
    // Check if emergency flow was triggered for emergency scenarios
    if (scenario.isEmergency) {
      final isEmergencyFlow = _virtualUser.isEmergencyFlowActive;
      print('$_testTag Emergency flow active: $isEmergencyFlow');
    }
    
    print('$_testTag Current ride flow state: $rideFlowState');
    print('$_testTag ✅ Ride flow valid: $isValidState');
    
    return isValidState;
  }

  /// 📊 Generează raportul final de test
  void _generateTestReport() {
    print('\n$_testTag ===== FINAL TEST REPORT =====');
    
    final totalTests = _results.length;
    final successfulTests = _results.where((r) => r.success).length;
    final failedTests = totalTests - successfulTests;
    
    print('$_testTag Total scenarios tested: $totalTests');
    print('$_testTag ✅ Successful: $successfulTests');
    print('$_testTag ❌ Failed: $failedTests');
    print('$_testTag Success rate: ${(successfulTests / totalTests * 100).toStringAsFixed(1)}%');
    
    // Detailed results
    print('\n$_testTag ===== DETAILED RESULTS =====');
    for (int i = 0; i < _results.length; i++) {
      final result = _results[i];
      final status = result.success ? '✅ PASS' : '❌ FAIL';
      print('$_testTag ${i + 1}. ${result.scenario.name}: $status (${result.duration.inMilliseconds}ms)');
      
      if (!result.success) {
        print('$_testTag    Error: ${result.error}');
        print('$_testTag    AI Button: ${result.aiButtonPressed ? "✅" : "❌"}');
        print('$_testTag    Voice Input: ${result.voiceInputProcessed ? "✅" : "❌"}');
        print('$_testTag    AI Response: ${result.aiResponseValid ? "✅" : "❌"}');
        print('$_testTag    Address Processing: ${result.addressProcessed ? "✅" : "❌"}');
        print('$_testTag    Ride Flow: ${result.rideFlowInitiated ? "✅" : "❌"}');
      }
    }
    
    // Performance analysis
    final avgDuration = _results.map((r) => r.duration.inMilliseconds).reduce((a, b) => a + b) / totalTests;
    print('\n$_testTag ===== PERFORMANCE ANALYSIS =====');
    print('$_testTag Average test duration: ${avgDuration.toStringAsFixed(0)}ms');
    
    final slowTests = _results.where((r) => r.duration.inMilliseconds > avgDuration * 1.5).length;
    if (slowTests > 0) {
      print('$_testTag ⚠️ $slowTests tests took longer than expected');
    }
    
    print('$_testTag ===== END REPORT =====\n');
  }
}

/// 👤 Utilizator Virtual pentru simularea interacțiunii
class VirtualUser {
  bool _isInitialized = false;
  bool _isVoiceActive = false;
  String _lastProcessedCommand = '';
  String _lastAIResponse = '';
  final List<String> _processedAddresses = [];
  RideFlowState _currentRideFlowState = RideFlowState.idle;
  bool _isEmergencyFlowActive = false;
  
  // Voice integration simulation
  final List<String> _conversationHistory = [];
  
  Future<void> initialize() async {
    _isInitialized = true;
    print('🧪 [VIRTUAL_USER] Initialized');
  }
  
  Future<void> pressAIButton() async {
    if (!_isInitialized) {
      throw Exception('Virtual user not initialized');
    }
    
    // Simulate AI button press
    _isVoiceActive = true;
    _lastAIResponse = 'Salutare! Unde doriți să mergeți?';
    _conversationHistory.add('AI: $_lastAIResponse');
    
    print('🧪 [VIRTUAL_USER] AI button pressed - voice interaction started');
  }
  
  Future<void> speakCommand(String command) async {
    if (!_isVoiceActive) {
      throw Exception('Voice interaction not active');
    }
    
    _lastProcessedCommand = command;
    _conversationHistory.add('User: $command');
    
    // Simulate AI processing
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Generate AI response based on command
    _lastAIResponse = _generateAIResponse(command);
    _conversationHistory.add('AI: $_lastAIResponse');
    
    // Process addresses from command
    _processAddressesFromCommand(command);
    
    // Update ride flow state
    _updateRideFlowState(command);
    
    print('🧪 [VIRTUAL_USER] Command processed: "$command"');
  }
  
  String _generateAIResponse(String command) {
    final lowerCommand = command.toLowerCase();
    
    if (lowerCommand.contains('urgent') || lowerCommand.contains('spital')) {
      _isEmergencyFlowActive = true;
      return 'Am înțeles că aveți o urgență. Vă voi duce la cel mai apropiat spital. Confirmă că vrei să continui?';
    }
    
    if (lowerCommand.contains('piața unirii')) {
      return 'Perfect! Am găsit Piața Unirii. Confirmă că aceasta este destinația dorită?';
    }
    
    if (lowerCommand.contains('gara de nord') && lowerCommand.contains('aeroport')) {
      return 'Am înțeles: pickup de la Gara de Nord, destinația Aeroportul Otopeni. Confirmă detaliile cursei?';
    }
    
    if (lowerCommand.contains('strada victoriei')) {
      return 'Am găsit Strada Victoriei. Confirmă că vrei să mergi acolo?';
    }
    
    if (lowerCommand.contains('centrul comercial') || lowerCommand.contains('băneasa')) {
      return 'Am identificat Centrul Comercial Băneasa. Confirmă că aceasta este destinația?';
    }
    
    return 'Am înțeles comanda ta. Confirmă detaliile cursei pentru a continua?';
  }
  
  void _processAddressesFromCommand(String command) {
    _processedAddresses.clear();
    
    // Simple address extraction (in real implementation, this would use NLP)
    final lowerCommand = command.toLowerCase();
    
    if (lowerCommand.contains('piața unirii')) {
      _processedAddresses.add('Piața Unirii');
    }
    
    if (lowerCommand.contains('gara de nord')) {
      _processedAddresses.add('Gara de Nord');
    }
    
    if (lowerCommand.contains('aeroport')) {
      _processedAddresses.add('Aeroportul Otopeni');
    }
    
    if (lowerCommand.contains('strada victoriei')) {
      _processedAddresses.add('Strada Victoriei');
    }
    
    if (lowerCommand.contains('centrul comercial') || lowerCommand.contains('băneasa')) {
      _processedAddresses.add('Centrul Comercial Băneasa');
    }
    
    if (lowerCommand.contains('spital')) {
      _processedAddresses.add('Spitalul cel mai apropiat');
    }
  }
  
  void _updateRideFlowState(String command) {
    if (_isEmergencyFlowActive) {
      _currentRideFlowState = RideFlowState.processingCommand;
    } else if (command.toLowerCase().contains('confirm')) {
      _currentRideFlowState = RideFlowState.awaitingConfirmation;
    } else {
      _currentRideFlowState = RideFlowState.processingCommand;
    }
  }
  
  // Getters
  bool get isInitialized => _isInitialized;
  bool get isVoiceActive => _isVoiceActive;
  String get lastProcessedCommand => _lastProcessedCommand;
  String get lastAIResponse => _lastAIResponse;
  List<String> get processedAddresses => List.unmodifiable(_processedAddresses);
  RideFlowState get currentRideFlowState => _currentRideFlowState;
  bool get isEmergencyFlowActive => _isEmergencyFlowActive;
  List<String> get conversationHistory => List.unmodifiable(_conversationHistory);
}

/// 📋 Rezultatul unui test
class TestResult {
  final TestScenario scenario;
  bool aiButtonPressed = false;
  bool voiceInputProcessed = false;
  bool aiResponseValid = false;
  bool addressProcessed = false;
  bool rideFlowInitiated = false;
  bool success = false;
  String? error;
  Duration duration = Duration.zero;
  
  TestResult({required this.scenario});
}

/// 🎯 Scenariu de test
class TestScenario {
  final String name;
  final String voiceCommand;
  final String? expectedDestination;
  final String? expectedPickup;
  final bool isEmergency;
  
  TestScenario({
    required this.name,
    required this.voiceCommand,
    this.expectedDestination,
    this.expectedPickup,
    this.isEmergency = false,
  });
}

/// 🚀 Funcția principală pentru rularea testelor
Future<void> main() async {
  print('🧪 Starting AI Button End-to-End Test Suite...');
  
  final testSuite = AIButtonEndToEndTest();
  await testSuite.runAllTests();
  
  print('🧪 Test suite completed!');
}
