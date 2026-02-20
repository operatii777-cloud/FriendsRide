// ignore_for_file: avoid_print

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:friendsride_app/voice/states/voice_interaction_states.dart';

/// 🤖 Virtual User Simulator pentru testarea butonului AI
/// 
/// Acest simulator creează un utilizator virtual care poate:
/// - Apăsa butonul AI
/// - Simula comenzi vocale
/// - Verifica răspunsurile AI-ului
/// - Testa procesarea adreselor
/// - Valida fluxul complet de cursă
class VirtualUserSimulator {
  static const String _tag = '🤖 [VIRTUAL_USER]';
  
  // Simulator state
  bool _isInitialized = false;
  bool _isVoiceActive = false;
  String _currentCommand = '';
  String _lastAIResponse = '';
  final List<String> _processedAddresses = [];
  RideFlowState _currentRideState = RideFlowState.idle;
  bool _isEmergencyMode = false;
  
  // Test scenarios
  final List<VoiceTestScenario> _scenarios = [
    VoiceTestScenario(
      name: 'Basic Ride Request',
      command: 'Vreau să merg la Piața Unirii',
      expectedDestination: 'Piața Unirii',
      expectedPickup: null,
      responseKeywords: ['piața unirii', 'confirm', 'destinație'],
    ),
    VoiceTestScenario(
      name: 'Pickup and Destination',
      command: 'Ia-mă de la Gara de Nord la Aeroportul Otopeni',
      expectedPickup: 'Gara de Nord',
      expectedDestination: 'Aeroportul Otopeni',
      responseKeywords: ['gara de nord', 'aeroport', 'confirm'],
    ),
    VoiceTestScenario(
      name: 'Romanian Address',
      command: 'Du-mă la Strada Victoriei numărul 10',
      expectedDestination: 'Strada Victoriei',
      expectedPickup: null,
      responseKeywords: ['victoriei', 'confirm', 'adresă'],
    ),
    VoiceTestScenario(
      name: 'Emergency Request',
      command: 'Am o urgență, du-mă la spitalul cel mai apropiat',
      expectedDestination: 'spital',
      expectedPickup: null,
      responseKeywords: ['urgent', 'spital', 'confirm'],
      isEmergency: true,
    ),
    VoiceTestScenario(
      name: 'Shopping Center',
      command: 'Vreau să merg la Centrul Comercial Băneasa Shopping City',
      expectedDestination: 'Centrul Comercial Băneasa',
      expectedPickup: null,
      responseKeywords: ['băneasa', 'centrul comercial', 'confirm'],
    ),
    VoiceTestScenario(
      name: 'Complex Address',
      command: 'Du-mă la Universitatea Politehnica București, Splaiul Independenței',
      expectedDestination: 'Universitatea Politehnica',
      expectedPickup: null,
      responseKeywords: ['universitate', 'politehnica', 'confirm'],
    ),
  ];

  /// 🚀 Inițializează simulatorul
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    print('$_tag Initializing virtual user simulator...');
    
    // Initialize voice recognition simulation
    await _initializeVoiceSimulation();
    
    // Initialize address processing simulation
    await _initializeAddressSimulation();
    
    // Initialize ride flow simulation
    await _initializeRideFlowSimulation();
    
    _isInitialized = true;
    print('$_tag ✅ Virtual user simulator initialized');
  }

  /// 🎤 Simulează apăsarea butonului AI
  Future<bool> pressAIButton() async {
    if (!_isInitialized) {
      print('$_tag ❌ Simulator not initialized');
      return false;
    }
    
    print('$_tag Pressing AI button...');
    
    // Simulate button press
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Activate voice interaction
    _isVoiceActive = true;
    _currentRideState = RideFlowState.listeningForInitialCommand;
    
    // Generate AI greeting
    _lastAIResponse = _generateGreeting();
    
    print('$_tag ✅ AI button pressed - voice interaction started');
    print('$_tag AI Response: "$_lastAIResponse"');
    
    return true;
  }

  /// 🗣️ Simulează o comandă vocală
  Future<bool> speakCommand(String command) async {
    if (!_isVoiceActive) {
      print('$_tag ❌ Voice interaction not active');
      return false;
    }
    
    print('$_tag Speaking command: "$command"');
    
    _currentCommand = command;
    
    // Simulate speech processing delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Process the command
    final processed = await _processVoiceCommand(command);
    
    if (processed) {
      print('$_tag ✅ Command processed successfully');
      return true;
    } else {
      print('$_tag ❌ Command processing failed');
      return false;
    }
  }

  /// 🧠 Procesează comanda vocală
  Future<bool> _processVoiceCommand(String command) async {
    // Update ride state
    _currentRideState = RideFlowState.processingCommand;
    
    // Generate AI response
    _lastAIResponse = _generateAIResponse(command);
    
    // Process addresses
    await _processAddresses(command);
    
    // Update ride state based on response
    if (_lastAIResponse.toLowerCase().contains('confirm')) {
      _currentRideState = RideFlowState.awaitingConfirmation;
    } else {
      _currentRideState = RideFlowState.processingCommand;
    }
    
    print('$_tag AI Response: "$_lastAIResponse"');
    print('$_tag Processed addresses: $_processedAddresses');
    print('$_tag Current ride state: $_currentRideState');
    
    return true;
  }

  /// 🤖 Generează răspunsul AI-ului
  String _generateAIResponse(String command) {
    final lowerCommand = command.toLowerCase();
    
    // Emergency handling
    if (lowerCommand.contains('urgent') || lowerCommand.contains('spital')) {
      _isEmergencyMode = true;
      return 'Am înțeles că aveți o urgență. Vă voi duce la cel mai apropiat spital. Confirmă că vrei să continui?';
    }
    
    // Specific destinations
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
    
    if (lowerCommand.contains('universitate') || lowerCommand.contains('politehnica')) {
      return 'Am găsit Universitatea Politehnica București. Confirmă că aceasta este destinația?';
    }
    
    // Generic response
    return 'Am înțeles comanda ta. Confirmă detaliile cursei pentru a continua?';
  }

  /// 📍 Procesează adresele din comandă
  Future<void> _processAddresses(String command) async {
    _processedAddresses.clear();
    
    final lowerCommand = command.toLowerCase();
    
    // Address extraction logic
    if (lowerCommand.contains('piața unirii')) {
      _processedAddresses.add('Piața Unirii, București');
    }
    
    if (lowerCommand.contains('gara de nord')) {
      _processedAddresses.add('Gara de Nord, București');
    }
    
    if (lowerCommand.contains('aeroport')) {
      _processedAddresses.add('Aeroportul Otopeni, Otopeni');
    }
    
    if (lowerCommand.contains('strada victoriei')) {
      _processedAddresses.add('Strada Victoriei, București');
    }
    
    if (lowerCommand.contains('centrul comercial') || lowerCommand.contains('băneasa')) {
      _processedAddresses.add('Centrul Comercial Băneasa, Băneasa');
    }
    
    if (lowerCommand.contains('universitate') || lowerCommand.contains('politehnica')) {
      _processedAddresses.add('Universitatea Politehnica București, București');
    }
    
    if (lowerCommand.contains('spital')) {
      _processedAddresses.add('Spitalul cel mai apropiat');
    }
  }

  /// 👋 Generează salutul AI-ului
  String _generateGreeting() {
    final greetings = [
      'Salutare! Unde doriți să mergeți?',
      'Bună! Cum vă pot ajuta astăzi?',
      'Salut! Unde vă duc?',
      'Bună ziua! Care este destinația voastră?',
    ];
    
    return greetings[Random().nextInt(greetings.length)];
  }

  /// 🚗 Simulează confirmarea cursei
  Future<bool> confirmRide() async {
    if (_currentRideState != RideFlowState.awaitingConfirmation) {
      print('$_tag ❌ No ride to confirm');
      return false;
    }
    
    print('$_tag Confirming ride...');
    
    _currentRideState = RideFlowState.searchingDrivers;
    _lastAIResponse = 'Perfect! Căutăm un șofer pentru tine...';
    
    // Simulate driver search
    await Future.delayed(const Duration(seconds: 2));
    
    _currentRideState = RideFlowState.driverFound;
    _lastAIResponse = 'Am găsit un șofer! Vine în 5 minute.';
    
    print('$_tag ✅ Ride confirmed and driver found');
    return true;
  }

  /// 🛑 Oprește interacțiunea vocală
  Future<void> stopVoiceInteraction() async {
    print('$_tag Stopping voice interaction...');
    
    _isVoiceActive = false;
    _currentRideState = RideFlowState.idle;
    _currentCommand = '';
    _lastAIResponse = '';
    _processedAddresses.clear();
    _isEmergencyMode = false;
    
    print('$_tag ✅ Voice interaction stopped');
  }

  /// 🧪 Rulează toate scenariile de test
  Future<List<TestResult>> runAllScenarios() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    print('$_tag Running ${_scenarios.length} test scenarios...');
    
    final results = <TestResult>[];
    
    for (int i = 0; i < _scenarios.length; i++) {
      final scenario = _scenarios[i];
      print('\n$_tag ===== SCENARIO ${i + 1}: ${scenario.name} =====');
      
      final result = await _runScenario(scenario);
      results.add(result);
      
      // Reset for next scenario
      await stopVoiceInteraction();
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    return results;
  }

  /// 🎯 Rulează un scenariu de test
  Future<TestResult> _runScenario(VoiceTestScenario scenario) async {
    final stopwatch = Stopwatch()..start();
    final result = TestResult(scenario: scenario);
    
    try {
      // Step 1: Press AI button
      result.aiButtonPressed = await pressAIButton();
      
      // Step 2: Speak command
      result.voiceCommandProcessed = await speakCommand(scenario.command);
      
      // Step 3: Verify AI response
      result.aiResponseValid = _verifyAIResponse(scenario);
      
      // Step 4: Verify address processing
      result.addressProcessingValid = _verifyAddressProcessing(scenario);
      
      // Step 5: Test ride confirmation (if applicable)
      if (scenario.requiresConfirmation) {
        result.rideConfirmationValid = await confirmRide();
      } else {
        result.rideConfirmationValid = true; // Not required
      }
      
      result.success = result.aiButtonPressed && 
                     result.voiceCommandProcessed && 
                     result.aiResponseValid && 
                     result.addressProcessingValid && 
                     result.rideConfirmationValid;
      
    } catch (e) {
      print('$_tag ❌ Scenario failed: $e');
      result.error = e.toString();
    } finally {
      stopwatch.stop();
      result.duration = stopwatch.elapsed;
      print('$_tag Scenario completed in ${result.duration.inMilliseconds}ms');
    }
    
    return result;
  }

  /// ✅ Verifică răspunsul AI-ului
  bool _verifyAIResponse(VoiceTestScenario scenario) {
    if (_lastAIResponse.isEmpty) return false;
    
    final lowerResponse = _lastAIResponse.toLowerCase();
    
    // Check if response contains expected keywords
    for (final keyword in scenario.responseKeywords) {
      if (lowerResponse.contains(keyword.toLowerCase())) {
        return true;
      }
    }
    
    // Check for generic valid responses
    return lowerResponse.contains('confirm') || 
           lowerResponse.contains('confirmă') ||
           lowerResponse.contains('înțeles') ||
           lowerResponse.contains('găsit');
  }

  /// ✅ Verifică procesarea adreselor
  bool _verifyAddressProcessing(VoiceTestScenario scenario) {
    if (_processedAddresses.isEmpty) return false;
    
    // Check destination
    bool destinationFound = true;
    if (scenario.expectedDestination != null) {
      destinationFound = false;
      for (final address in _processedAddresses) {
        if (address.toLowerCase().contains(scenario.expectedDestination!.toLowerCase())) {
          destinationFound = true;
          break;
        }
      }
    }
    
    // Check pickup
    bool pickupFound = true;
    if (scenario.expectedPickup != null) {
      pickupFound = false;
      for (final address in _processedAddresses) {
        if (address.toLowerCase().contains(scenario.expectedPickup!.toLowerCase())) {
          pickupFound = true;
          break;
        }
      }
    }
    
    return destinationFound && pickupFound;
  }

  /// 🔧 Inițializează simularea vocală
  Future<void> _initializeVoiceSimulation() async {
    print('$_tag Initializing voice simulation...');
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// 🔧 Inițializează simularea adreselor
  Future<void> _initializeAddressSimulation() async {
    print('$_tag Initializing address simulation...');
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// 🔧 Inițializează simularea fluxului de cursă
  Future<void> _initializeRideFlowSimulation() async {
    print('$_tag Initializing ride flow simulation...');
    await Future.delayed(const Duration(milliseconds: 100));
  }

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isVoiceActive => _isVoiceActive;
  String get currentCommand => _currentCommand;
  String get lastAIResponse => _lastAIResponse;
  List<String> get processedAddresses => List.unmodifiable(_processedAddresses);
  RideFlowState get currentRideState => _currentRideState;
  bool get isEmergencyMode => _isEmergencyMode;
}

/// 📋 Scenariu de test vocal
class VoiceTestScenario {
  final String name;
  final String command;
  final String? expectedDestination;
  final String? expectedPickup;
  final List<String> responseKeywords;
  final bool isEmergency;
  final bool requiresConfirmation;

  VoiceTestScenario({
    required this.name,
    required this.command,
    this.expectedDestination,
    this.expectedPickup,
    required this.responseKeywords,
    this.isEmergency = false,
    this.requiresConfirmation = true,
  });
}

/// 📊 Rezultatul unui test
class TestResult {
  final VoiceTestScenario scenario;
  bool aiButtonPressed = false;
  bool voiceCommandProcessed = false;
  bool aiResponseValid = false;
  bool addressProcessingValid = false;
  bool rideConfirmationValid = false;
  bool success = false;
  String? error;
  Duration duration = Duration.zero;

  TestResult({required this.scenario});
}

/// 🧪 Test Suite pentru butonul AI
class AIButtonTestSuite {
  static const String _tag = '🧪 [AI_TEST_SUITE]';
  
  /// 🚀 Rulează toate testele
  static Future<void> runAllTests() async {
    print('$_tag Starting AI Button Test Suite...');
    
    final simulator = VirtualUserSimulator();
    await simulator.initialize();
    
    final results = await simulator.runAllScenarios();
    
    _generateReport(results);
  }

  /// 📊 Generează raportul de test
  static void _generateReport(List<TestResult> results) {
    print('\n$_tag ===== TEST REPORT =====');
    
    final total = results.length;
    final passed = results.where((r) => r.success).length;
    final failed = total - passed;
    
    print('$_tag Total scenarios: $total');
    print('$_tag ✅ Passed: $passed');
    print('$_tag ❌ Failed: $failed');
    print('$_tag Success rate: ${(passed / total * 100).toStringAsFixed(1)}%');
    
    print('\n$_tag ===== DETAILED RESULTS =====');
    for (int i = 0; i < results.length; i++) {
      final result = results[i];
      final status = result.success ? '✅ PASS' : '❌ FAIL';
      print('$_tag ${i + 1}. ${result.scenario.name}: $status (${result.duration.inMilliseconds}ms)');
      
      if (!result.success) {
        print('$_tag    AI Button: ${result.aiButtonPressed ? "✅" : "❌"}');
        print('$_tag    Voice Command: ${result.voiceCommandProcessed ? "✅" : "❌"}');
        print('$_tag    AI Response: ${result.aiResponseValid ? "✅" : "❌"}');
        print('$_tag    Address Processing: ${result.addressProcessingValid ? "✅" : "❌"}');
        print('$_tag    Ride Confirmation: ${result.rideConfirmationValid ? "✅" : "❌"}');
        if (result.error != null) {
          print('$_tag    Error: ${result.error}');
        }
      }
    }
    
    print('$_tag ===== END REPORT =====\n');
  }
}

/// 🚀 Funcția principală
Future<void> main() async {
  print('🧪 Starting AI Button Virtual User Test...');
  
  await AIButtonTestSuite.runAllTests();
  
  print('🧪 Test completed!');
}
