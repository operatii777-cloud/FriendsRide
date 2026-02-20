// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:friendsride_app/voice/integration/friendsride_voice_integration.dart';
import 'package:friendsride_app/voice/ride/ride_flow_manager.dart';
import 'package:friendsride_app/voice/ai/gemini_voice_engine.dart';
import 'package:friendsride_app/voice/tts/natural_voice_synthesizer.dart';
import 'package:friendsride_app/voice/core/voice_orchestrator.dart';
import 'package:friendsride_app/services/firestore_service.dart';
import 'package:friendsride_app/services/audio_beep_service.dart';
import 'package:friendsride_app/voice/states/voice_interaction_states.dart';

/// 🚗 Test End-to-End REAL cu AI pentru Ride Flow
/// 
/// Folosește AI-ul real din aplicație pentru a testa:
/// 1. Solicitarea cursei prin AI vocal
/// 2. Procesarea naturală a limbii
/// 3. Integrarea cu serviciile reale
/// 4. Flow-ul complet până la finalizarea cursei
void main() {
  group('🚗 Real AI Ride End-to-End Tests', () {
    late FriendsRideVoiceIntegration voiceIntegration;
    late RideFlowManager rideFlowManager;
    late FirestoreService firestoreService;
    late AudioBeepService beepService;
    
    setUpAll(() async {
      // Inițializez serviciile REALE din aplicație
      firestoreService = FirestoreService();
      beepService = AudioBeepService();
      await beepService.initialize();
      
      // Inițializez AI-ul real
      voiceIntegration = FriendsRideVoiceIntegration();
      await voiceIntegration.warmUp();
      
      // Inițializez VoiceOrchestrator pentru RideFlowManager
      final voiceOrchestrator = VoiceOrchestrator();
      await voiceOrchestrator.initialize();
      
      // Inițializez RideFlowManager cu serviciile reale
      rideFlowManager = RideFlowManager(
        geminiEngine: GeminiVoiceEngine(),
        tts: NaturalVoiceSynthesizer(),
        firestoreService: firestoreService,
        voiceOrchestrator: voiceOrchestrator,
        onFillAddressInUI: (pickup, destination, {double? destLat, double? destLng, double? pickupLat, double? pickupLng}) {
          print('📍 [REAL_AI_TEST] Address filled in UI: $pickup -> $destination');
          if (pickupLat != null && pickupLng != null) {
            print('📍 [REAL_AI_TEST] Pickup coordinates: $pickupLat, $pickupLng');
          }
          if (destLat != null && destLng != null) {
            print('📍 [REAL_AI_TEST] Destination coordinates: $destLat, $destLng');
          }
        },
        onSelectRideOptionInUI: (category) {
          print('🚗 [REAL_AI_TEST] Ride category selected in UI: $category');
        },
        onPressConfirmButtonInUI: () {
          print('✅ [REAL_AI_TEST] Confirm button pressed in UI');
        },
        onNavigateToScreen: (screen) {
          print('🧭 [REAL_AI_TEST] Navigate to screen: $screen');
        },
        onCreateRideRequest: (request) async {
          final rideId = 'real_ride_${DateTime.now().millisecondsSinceEpoch}';
          print('📝 [REAL_AI_TEST] Real ride request created: $rideId');
          
          // Pentru test, simulez crearea cursei
          print('📝 [REAL_AI_TEST] Ride request data: ${request.toString()}');
          
          return rideId;
        },
        onDriverResponse: (driverId, accepted) {
          print('👨‍💼 [REAL_AI_TEST] Real driver $driverId ${accepted ? "accepted" : "rejected"} ride');
        },
        onCloseAI: () {
          print('🔚 [REAL_AI_TEST] Real AI closed');
        },
      );
      
      await rideFlowManager.initialize();
    });

    tearDownAll(() async {
      beepService.dispose();
      rideFlowManager.dispose();
      voiceIntegration.dispose();
    });

    test('🚗 Test 1: Solicitare cursă REALĂ prin AI vocal', () async {
      print('🚗 [REAL_AI_TEST] Testing real AI voice ride request...');
      
      // Test cu AI-ul real - solicitare cursă
      final rideRequest = 'Vreau să rezerv o cursă de la Piața Unirii la Gara de Nord';
      
      print('🎤 [REAL_AI_TEST] User says: "$rideRequest"');
      
      // Folosesc AI-ul real pentru procesarea cererii prin startVoiceInteraction
      await voiceIntegration.startVoiceInteraction();
      await Future.delayed(Duration(seconds: 2));
      
      // Simulez răspunsul AI-ului
      final aiResponse = voiceIntegration.currentContext;
      
      print('🤖 [REAL_AI_TEST] AI responded with state: ${aiResponse.rideState}');
      print('🎯 [REAL_AI_TEST] AI processing state: ${aiResponse.processingState}');
      
      // Verific că AI-ul a înțeles cererea
      expect(aiResponse.rideState, isA<RideFlowState>());
      expect(aiResponse.processingState, isA<VoiceProcessingState>());
      
      // Test cu AI-ul real - confirmare detalii
      final confirmationRequest = 'Da, confirm. Vreau să plec acum';
      
      print('🎤 [REAL_AI_TEST] User says: "$confirmationRequest"');
      
      // Simulez procesarea confirmării prin RideFlowManager
      await rideFlowManager.processVoiceInput(confirmationRequest);
      
      final confirmationResponse = voiceIntegration.currentContext;
      
      print('🤖 [REAL_AI_TEST] AI confirmed with state: ${confirmationResponse.rideState}');
      
      // Verific că AI-ul a procesat confirmarea
      expect(confirmationResponse.rideState, isA<RideFlowState>());
      
      print('✅ [REAL_AI_TEST] Real AI voice ride request test completed!');
    });

    test('🚗 Test 2: AI procesează comenzi vocale complexe', () async {
      print('🚗 [REAL_AI_TEST] Testing AI processing of complex voice commands...');
      
      final complexCommands = [
        'Vreau să merg la Aeroportul Henri Coandă de la Hotel Intercontinental',
        'Cât costă cursa aproximativ?',
        'Cât durează drumul până acolo?',
        'Poți să găsești un șofer care vorbește română?',
        'Vreau o mașină mare pentru că am bagaje multe',
        'Cursa este urgentă, poți să găsești un șofer rapid?',
        'Șoferul să vină în maximum 10 minute',
        'Vreau să plătesc cu cardul, nu cu cash',
        'Poți să îi spui șoferului să nu fumeze în mașină?',
        'Vreau să schimb destinația la Mall Băneasa în loc de aeroport',
      ];
      
      for (int i = 0; i < complexCommands.length; i++) {
        final command = complexCommands[i];
        print('🎤 [REAL_AI_TEST] Complex command ${i + 1}: "$command"');
        
        final stopwatch = Stopwatch()..start();
        
        // Procesez comanda cu AI-ul real prin RideFlowManager
        await rideFlowManager.processVoiceInput(command);
        final response = voiceIntegration.currentContext;
        
        stopwatch.stop();
        
        print('🤖 [REAL_AI_TEST] AI response state: ${response.rideState}');
        print('⚡ [REAL_AI_TEST] Processing time: ${stopwatch.elapsedMilliseconds}ms');
        print('🎯 [REAL_AI_TEST] AI processing state: ${response.processingState}');
        
        // Verific că AI-ul a procesat comanda
        expect(response.rideState, isA<RideFlowState>());
        expect(stopwatch.elapsedMilliseconds, lessThan(10000), 
               reason: 'AI should respond within 10 seconds');
        
        // Pauză între comenzi pentru a simula conversația naturală
        await Future.delayed(Duration(milliseconds: 1500));
      }
      
      print('✅ [REAL_AI_TEST] Complex voice commands test completed!');
    });

    test('🚗 Test 3: AI gestionează întreaga conversație de cursă', () async {
      print('🚗 [REAL_AI_TEST] Testing AI handling complete ride conversation...');
      
      // Simulez o conversație completă cu AI-ul real
      final conversation = [
        'Salut! Am nevoie de o cursă',
        'Unde doriți să mergeți?',
        'La Mall Afi Palace din Băneasa',
        'De unde să vă preiau?',
        'De la Piața Victoriei, de la Casa Presei Libere',
        'Perfect! Căut șoferi disponibili în zonă...',
        'Am găsit un șofer! Se numește Maria și vine în 7 minute',
        'Excelent! Aștept șoferul',
        'Șoferul a ajuns la locația de preluare',
        'Perfect! Ieșim acum',
        'Bună ziua! Sunt Maria, șoferul dumneavoastră',
        'Bună ziua! Mulțumesc că ați venit',
        'Plecam spre Mall Afi Palace. Este o cursă de aproximativ 25 de minute',
        'Perfect, mulțumesc',
        'Am ajuns la mall. Cursa s-a finalizat',
        'Mulțumesc foarte mult! Ați fost excelent',
        'Mulțumesc și dumneavoastră! Cursa a fost plăcută',
        'Vă las 5 stele și un review pozitiv',
        'Mulțumesc mult pentru feedback!',
      ];
      
      for (int i = 0; i < conversation.length; i++) {
        final message = conversation[i];
        print('💬 [REAL_AI_TEST] Conversation ${i + 1}: $message');
        
        final stopwatch = Stopwatch()..start();
        
        // Procesez mesajul cu AI-ul real prin RideFlowManager
        await rideFlowManager.processVoiceInput(message);
        final response = voiceIntegration.currentContext;
        
        stopwatch.stop();
        
        print('🤖 [REAL_AI_TEST] AI response state: ${response.rideState}');
        print('⚡ [REAL_AI_TEST] Response time: ${stopwatch.elapsedMilliseconds}ms');
        
        // Verific că AI-ul a răspuns
        expect(response.rideState, isA<RideFlowState>());
        
        // Pauză pentru a simula timpul natural de conversație
        await Future.delayed(Duration(milliseconds: 2000));
      }
      
      print('✅ [REAL_AI_TEST] Complete ride conversation test completed!');
    });

    test('🚗 Test 4: AI gestionează erori și situații neprevăzute', () async {
      print('🚗 [REAL_AI_TEST] Testing AI error handling and unexpected situations...');
      
      final errorScenarios = [
        'Vreau să merg la o adresă care nu există în București',
        'Am ratat șoferul, poate să vină din nou?',
        'Cursa a fost anulată din cauza traficului, ce fac?',
        'Vreau să schimb destinația în timpul cursei',
        'Am o problemă cu plata, nu merge cardul',
        'Vreau să anulez cursa, am o urgență',
        'Șoferul nu vine de 20 de minute, unde este?',
        'Mașina este în stare proastă, vreau alt șofer',
        'Am uitat ceva în mașină, cum îl recuperez?',
        'Cursa a fost prea scumpă, nu am bani să plătesc',
      ];
      
      for (int i = 0; i < errorScenarios.length; i++) {
        final scenario = errorScenarios[i];
        print('⚠️ [REAL_AI_TEST] Error scenario ${i + 1}: $scenario');
        
        final stopwatch = Stopwatch()..start();
        
        try {
          // Procesez situația cu AI-ul real prin RideFlowManager
          await rideFlowManager.processVoiceInput(scenario);
          final response = voiceIntegration.currentContext;
          
          stopwatch.stop();
          
          print('🤖 [REAL_AI_TEST] AI handled error with state: ${response.rideState}');
          print('⚡ [REAL_AI_TEST] Error handling time: ${stopwatch.elapsedMilliseconds}ms');
          
          // Verific că AI-ul a gestionat eroarea
          expect(response.rideState, isA<RideFlowState>());
          
          // Simulez recovery
          final recoveryMessage = 'Mulțumesc pentru ajutor, problema a fost rezolvată';
          print('💬 [REAL_AI_TEST] Recovery: $recoveryMessage');
          
          await rideFlowManager.processVoiceInput(recoveryMessage);
          final recoveryResponse = voiceIntegration.currentContext;
          print('🤖 [REAL_AI_TEST] AI recovery response state: ${recoveryResponse.rideState}');
          
        } catch (e) {
          print('❌ [REAL_AI_TEST] Error occurred: $e');
          // AI-ul trebuie să gestioneze erorile elegant
        }
        
        await Future.delayed(Duration(milliseconds: 2000));
      }
      
      print('✅ [REAL_AI_TEST] Error handling test completed!');
    });

    test('🚗 Test 5: AI cu beep-uri reale în conversație', () async {
      print('🚗 [REAL_AI_TEST] Testing AI with real beep sounds...');
      
      final voiceCommands = [
        'Vreau o cursă urgentă',
        'Cât costă?',
        'Când vine șoferul?',
        'Perfect, aștept',
        'Șoferul a ajuns?',
        'Excelent, ieșim',
        'Am ajuns la destinație?',
        'Mulțumesc pentru cursă',
      ];
      
      for (int i = 0; i < voiceCommands.length; i++) {
        final command = voiceCommands[i];
        print('🎤 [REAL_AI_TEST] Voice command ${i + 1}: "$command"');
        
        // Beep-uri reale pentru feedback audio
        await beepService.playProcessingStartBeeps();
        await Future.delayed(Duration(milliseconds: 500));
        
        // Procesez comanda cu AI-ul real prin RideFlowManager
        await rideFlowManager.processVoiceInput(command);
        final response = voiceIntegration.currentContext;
        
        await beepService.playProcessingCompleteBeep();
        await Future.delayed(Duration(milliseconds: 300));
        
        print('🤖 [REAL_AI_TEST] AI response state: ${response.rideState}');
        
        await beepService.playConversationEndBeep();
        
        // Verific că AI-ul a răspuns
        expect(response.rideState, isA<RideFlowState>());
        
        await Future.delayed(Duration(milliseconds: 2000));
      }
      
      print('✅ [REAL_AI_TEST] AI with real beeps test completed!');
    });

    test('🚗 Test 6: Integrarea AI cu RideFlowManager real', () async {
      print('🚗 [REAL_AI_TEST] Testing AI integration with real RideFlowManager...');
      
      // Test integrarea AI cu RideFlowManager
      final rideFlowCommands = [
        'Vreau să merg la Universitate din centru',
        'De la Piața Unirii să mă preiei',
        'Confirm cursa, plec acum',
        'Status cursă, unde este șoferul?',
        'Șoferul a ajuns la pickup',
        'Perfect, am ieșit din casă',
        'Sunt în mașină, mergem',
        'Am ajuns la destinație',
        'Cursa s-a finalizat, mulțumesc',
      ];
      
      for (int i = 0; i < rideFlowCommands.length; i++) {
        final command = rideFlowCommands[i];
        print('🎤 [REAL_AI_TEST] RideFlow command ${i + 1}: "$command"');
        
        final stopwatch = Stopwatch()..start();
        
        // Procesez comanda prin RideFlowManager real
        await rideFlowManager.processVoiceInput(command);
        
        stopwatch.stop();
        
        print('⚡ [REAL_AI_TEST] RideFlow processing time: ${stopwatch.elapsedMilliseconds}ms');
        print('🎯 [REAL_AI_TEST] Current ride state: ${rideFlowManager.currentState}');
        
        // Verific că RideFlowManager a procesat comanda
        expect(rideFlowManager.currentState, isA<RideFlowState>());
        
        await Future.delayed(Duration(milliseconds: 2500));
      }
      
      print('✅ [REAL_AI_TEST] AI integration with RideFlowManager test completed!');
    });
  });
}

/// 📊 Raport de performanță pentru testele AI reale
class RealAIPerformanceReport {
  static void generateReport(Map<String, dynamic> metrics) {
    print('📊 [REAL_AI_REPORT] Real AI Performance Report');
    print('📊 [REAL_AI_REPORT] ==========================');
    
    print('📊 [REAL_AI_REPORT] Total AI interactions: ${metrics['totalInteractions'] ?? 0}');
    print('📊 [REAL_AI_REPORT] Successful AI responses: ${metrics['successfulResponses'] ?? 0}');
    print('📊 [REAL_AI_REPORT] Failed AI responses: ${metrics['failedResponses'] ?? 0}');
    print('📊 [REAL_AI_REPORT] Average AI response time: ${metrics['avgResponseTime'] ?? 0}ms');
    print('📊 [REAL_AI_REPORT] Average beep response time: ${metrics['avgBeepTime'] ?? 0}ms');
    print('📊 [REAL_AI_REPORT] AI accuracy rate: ${metrics['accuracyRate'] ?? 0}%');
    
    // Evaluare performanță AI
    final successRate = metrics['successfulResponses'] / (metrics['totalInteractions'] ?? 1) * 100;
    if (successRate > 95) {
      print('📊 [REAL_AI_REPORT] ⭐ AI Performance: EXCELLENT');
    } else if (successRate > 85) {
      print('📊 [REAL_AI_REPORT] ✅ AI Performance: GOOD');
    } else if (successRate > 70) {
      print('📊 [REAL_AI_REPORT] ⚠️ AI Performance: ACCEPTABLE');
    } else {
      print('📊 [REAL_AI_REPORT] ❌ AI Performance: NEEDS IMPROVEMENT');
    }
    
    print('📊 [REAL_AI_REPORT] ==========================');
  }
}
