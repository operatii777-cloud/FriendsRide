// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:friendsride_app/voice/integration/friendsride_voice_integration.dart';

/// 🚗 Test Simplificat AI Real pentru Ride Flow
/// 
/// Testează funcționalitatea de bază a AI-ului real din aplicație
void main() {
  group('🚗 Real AI Simple Tests', () {
    late FriendsRideVoiceIntegration voiceIntegration;
    
    setUpAll(() async {
      // Inițializez AI-ul real
      voiceIntegration = FriendsRideVoiceIntegration();
      await voiceIntegration.warmUp();
    });

    tearDownAll(() async {
      voiceIntegration.dispose();
    });

    test('🚗 Test 1: Inițializarea AI-ului real', () async {
      print('🚗 [SIMPLE_AI_TEST] Testing real AI initialization...');
      
      // Verific că AI-ul este inițializat
      expect(voiceIntegration.isInitialized, isTrue);
      expect(voiceIntegration.currentContext, isNotNull);
      
      print('✅ [SIMPLE_AI_TEST] Real AI initialized successfully!');
    });

    test('🚗 Test 2: Pornirea interacțiunii vocale', () async {
      print('🚗 [SIMPLE_AI_TEST] Testing voice interaction start...');
      
      // Pornesc interacțiunea vocală
      await voiceIntegration.startVoiceInteraction();
      
      // Verific că interacțiunea vocală este activă
      expect(voiceIntegration.isVoiceActive, isTrue);
      
      // Verific contextul
      final context = voiceIntegration.currentContext;
      expect(context.rideState, isNotNull);
      expect(context.processingState, isNotNull);
      
      print('✅ [SIMPLE_AI_TEST] Voice interaction started successfully!');
      
      // Oprește interacțiunea vocală
      await voiceIntegration.stopVoiceInteraction();
      expect(voiceIntegration.isVoiceActive, isFalse);
      
      print('✅ [SIMPLE_AI_TEST] Voice interaction stopped successfully!');
    });

    test('🚗 Test 3: Testarea contextului AI', () async {
      print('🚗 [SIMPLE_AI_TEST] Testing AI context...');
      
      // Verific contextul inițial
      final context = voiceIntegration.currentContext;
      
      print('🎯 [SIMPLE_AI_TEST] Initial ride state: ${context.rideState}');
      print('🎯 [SIMPLE_AI_TEST] Initial processing state: ${context.processingState}');
      print('🎯 [SIMPLE_AI_TEST] Initial emotion: ${context.currentEmotion}');
      print('🎯 [SIMPLE_AI_TEST] Conversation history length: ${context.conversationHistory.length}');
      
      // Verific că contextul este valid
      expect(context.rideState, isNotNull);
      expect(context.processingState, isNotNull);
      expect(context.currentEmotion, isNotNull);
      expect(context.conversationHistory, isA<List<String>>());
      
      print('✅ [SIMPLE_AI_TEST] AI context test completed successfully!');
    });

    test('🚗 Test 4: Testarea callback-urilor AI', () async {
      print('🚗 [SIMPLE_AI_TEST] Testing AI callbacks...');
      
      // Testez callback-ul pentru procesarea comenzilor de locație
      await voiceIntegration.processLocationCommand('Vreau să merg la Gara de Nord');
      
      // Testez callback-ul pentru gestionarea cererilor de cursă
      await voiceIntegration.handleRideRequest({
        'pickup': 'Piața Unirii',
        'destination': 'Gara de Nord',
        'passengerId': 'test_passenger',
      });
      
      // Testez callback-ul pentru executarea fluxului de cursă
      await voiceIntegration.executeRideFlow();
      
      print('✅ [SIMPLE_AI_TEST] AI callbacks test completed successfully!');
    });

    test('🚗 Test 5: Testarea performanței AI', () async {
      print('🚗 [SIMPLE_AI_TEST] Testing AI performance...');
      
      final stopwatch = Stopwatch()..start();
      
      // Testez performanța inițializării
      final initStart = DateTime.now();
      await voiceIntegration.warmUp();
      final initEnd = DateTime.now();
      final initTime = initEnd.difference(initStart).inMilliseconds;
      
      // Testez performanța pornirii interacțiunii vocale
      final startStart = DateTime.now();
      await voiceIntegration.startVoiceInteraction();
      final startEnd = DateTime.now();
      final startTime = startEnd.difference(startStart).inMilliseconds;
      
      // Testez performanța opririi interacțiunii vocale
      final stopStart = DateTime.now();
      await voiceIntegration.stopVoiceInteraction();
      final stopEnd = DateTime.now();
      final stopTime = stopEnd.difference(stopStart).inMilliseconds;
      
      stopwatch.stop();
      
      print('📊 [SIMPLE_AI_TEST] Performance Results:');
      print('📊 [SIMPLE_AI_TEST] - Initialization time: ${initTime}ms');
      print('📊 [SIMPLE_AI_TEST] - Start voice interaction time: ${startTime}ms');
      print('📊 [SIMPLE_AI_TEST] - Stop voice interaction time: ${stopTime}ms');
      print('📊 [SIMPLE_AI_TEST] - Total test time: ${stopwatch.elapsedMilliseconds}ms');
      
      // Verific că performanța este acceptabilă
      expect(initTime, lessThan(5000), reason: 'Initialization should be under 5 seconds');
      expect(startTime, lessThan(3000), reason: 'Start voice interaction should be under 3 seconds');
      expect(stopTime, lessThan(2000), reason: 'Stop voice interaction should be under 2 seconds');
      
      print('✅ [SIMPLE_AI_TEST] AI performance test completed successfully!');
    });
  });
}

/// 📊 Raport simplu pentru testele AI
class SimpleAIReport {
  static void generateReport(Map<String, dynamic> metrics) {
    print('📊 [SIMPLE_AI_REPORT] Simple AI Test Report');
    print('📊 [SIMPLE_AI_REPORT] ====================');
    
    print('📊 [SIMPLE_AI_REPORT] Tests run: ${metrics['testsRun'] ?? 0}');
    print('📊 [SIMPLE_AI_REPORT] Tests passed: ${metrics['testsPassed'] ?? 0}');
    print('📊 [SIMPLE_AI_REPORT] Tests failed: ${metrics['testsFailed'] ?? 0}');
    print('📊 [SIMPLE_AI_REPORT] Average initialization time: ${metrics['avgInitTime'] ?? 0}ms');
    print('📊 [SIMPLE_AI_REPORT] Average voice start time: ${metrics['avgStartTime'] ?? 0}ms');
    print('📊 [SIMPLE_AI_REPORT] Average voice stop time: ${metrics['avgStopTime'] ?? 0}ms');
    
    // Evaluare performanță
    final successRate = metrics['testsPassed'] / (metrics['testsRun'] ?? 1) * 100;
    if (successRate == 100) {
      print('📊 [SIMPLE_AI_REPORT] ⭐ All tests PASSED!');
    } else if (successRate > 80) {
      print('📊 [SIMPLE_AI_REPORT] ✅ Most tests passed');
    } else {
      print('📊 [SIMPLE_AI_REPORT] ❌ Some tests failed');
    }
    
    print('📊 [SIMPLE_AI_REPORT] ====================');
  }
}
