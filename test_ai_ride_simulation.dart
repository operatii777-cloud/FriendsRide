import 'package:flutter_test/flutter_test.dart';
import 'package:friendsride_app/services/firestore_service.dart';
import 'package:friendsride_app/voice/passenger/passenger_voice_controller_adapter.dart';
import 'package:friendsride_app/voice/passenger/passenger_voice_controller.dart';
import 'package:friendsride_app/models/voice_models.dart';
import 'package:flutter/foundation.dart';
import 'package:friendsride_app/voice/states/voice_interaction_states.dart';

/// 🧪 Test pentru simularea unei curse complete cu AI
void main() {
  group('🧪 AI Ride Simulation End-to-End', () {
    late PassengerVoiceControllerAdapter controller;
    
    setUp(() {
      controller = PassengerVoiceControllerAdapter(controller: PassengerVoiceController(firestoreService: FirestoreService()));
    });
    
    tearDown(() {
      controller.dispose();
    });
    
    test('🚗 Simulare cursă completă: București → Aeroport', () async {
      debugPrint('\n🧪 Începe simularea cursei: București → Aeroport');
      
      // 1. Utilizatorul activează AI-ul
      debugPrint('1️⃣ Utilizatorul activează AI-ul...');
      controller.startVoiceInteraction();
      
      // Verifică starea inițială
      expect(controller.processingState, VoiceProcessingState.speaking);
      expect(controller.state, ConversationState.listeningForInitialCommand);
      
      // 2. Utilizatorul spune destinația
      debugPrint('2️⃣ Utilizatorul spune: "Vreau o cursă la aeroport"');
      // Folosește metoda publică pentru procesarea input-ului
      await controller.updateContextAndProcess('Vreau o cursă la aeroport');
      
      // Verifică procesarea destinației
      expect(controller.currentDestination, 'aeroport');
      expect(controller.state, ConversationState.confirmingPickup);
      
      // 3. AI-ul confirmă pickup-ul
      debugPrint('3️⃣ AI-ul confirmă pickup-ul...');
      // Folosește metoda publică pentru vorbire
      await controller.voice.speak('Am înțeles, la aeroport. Preluarea din locația curentă?');
      
      // 4. Utilizatorul confirmă pickup-ul
      debugPrint('4️⃣ Utilizatorul confirmă: "Da"');
      await controller.updateContextAndProcess('Da');
      
      // Verifică calcularea ofertei
      expect(controller.state, ConversationState.awaitingRideConfirmation);
      expect(controller.estimatedPrice, greaterThan(0.0));
      expect(controller.estimatedDuration.inMinutes, greaterThan(0));
      
      // 5. AI-ul prezintă oferta
      debugPrint('5️⃣ AI-ul prezintă oferta...');
      // Folosește metoda publică pentru generarea răspunsului
      final offerMessage = controller.aiResponse;
      await controller.voice.speak(offerMessage);
      
      // 6. Utilizatorul confirmă oferta
      debugPrint('6️⃣ Utilizatorul confirmă oferta: "Da, confirm"');
      await controller.updateContextAndProcess('Da, confirm');
      
      // Verifică confirmarea
      expect(controller.state, ConversationState.finalizingBooking);
      
      // 7. AI-ul finalizează rezervarea
      debugPrint('7️⃣ AI-ul finalizează rezervarea...');
      // Folosește metoda publică pentru finalizarea rezervării
      controller.finalizeRideBooking();
      
      // Verifică finalizarea
      expect(controller.state, ConversationState.providingFeedback);
      expect(controller.aiResponse, contains('gata'));
      
      debugPrint('✅ Simularea cursei completată cu succes!');
      debugPrint('📊 Rezultate finale:');
      debugPrint('   - Destinația: ${controller.currentDestination}');
      debugPrint('   - Preț estimat: ${controller.estimatedPrice.toStringAsFixed(2)} lei');
      debugPrint('   - Durată estimată: ${controller.estimatedDuration.inMinutes} minute');
      debugPrint('   - Starea finală: ${controller.state}');
      debugPrint('   - Răspunsul AI: ${controller.aiResponse}');
    });
    
    test('⏱️ Verificare timing-uri TTS optimizate', () async {
      debugPrint('\n⏱️ Testare timing-uri TTS...');
      
      final stopwatch = Stopwatch()..start();
      
      // Simulează un mesaj TTS
      await controller.voice.speak('Test mesaj TTS pentru verificarea timing-ului');
      
      final elapsed = stopwatch.elapsed;
      
      // Verifică că TTS-ul durează între 3.5 și 4.5 secunde (3s + 0.5s)
      expect(elapsed.inMilliseconds, greaterThan(3500));
      expect(elapsed.inMilliseconds, lessThan(4500));
      
      debugPrint('✅ Timing-ul TTS este optimizat: ${elapsed.inMilliseconds}ms');
    });
    
    test('🎤 Verificare flux conversational sincronizat', () async {
      debugPrint('\n🎤 Testare flux conversational...');
      
      // Verifică tranzițiile de stare
      expect(controller.state, ConversationState.idle);
      
      // Simulează o comandă
      await controller.updateContextAndProcess('Vreau o cursă la gara');
      
      // Verifică tranziția corectă
      expect(controller.currentDestination, 'gara');
      
      debugPrint('✅ Fluxul conversational este sincronizat corect');
    });
  });
}
