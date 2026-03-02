import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:geocoding/geocoding.dart' as geocoding; // ✅ FIX: Adăugat pentru locationFromAddress (serviciul nativ)
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' show Point, Position;
import 'package:shared_preferences/shared_preferences.dart';
import '../ai/gemini_voice_engine.dart';
import '../tts/natural_voice_synthesizer.dart' as tts;
import '../states/voice_interaction_states.dart';
import '../core/voice_orchestrator.dart';
import '../../services/firestore_service.dart';
import '../../services/audio_beep_service.dart';
import '../../services/geocoding_service.dart' as geocoding_svc;
import '../../models/ride_model.dart';
import '../../screens/searching_for_driver_screen.dart';
import '../../utils/deprecated_apis_fix.dart';
import '../../services/pricing_service.dart';
import '../../services/routing_service.dart';
import '../../utils/input_validator.dart';
import '../../services/bucharest_locations_database.dart';
import '../utils/voice_translations.dart';

/// ✅ Helper: Obține limba curentă din SharedPreferences
Future<String> _getCurrentLanguageCode() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('locale');
    return code ?? 'ro'; // Default română
  } catch (e) {
    debugPrint('🚗 [RIDE_FLOW] Error getting language: $e');
    return 'ro'; // Default română
  }
}

/// 🚗 Ride Flow Manager - Gestionează flow-ul complet al cursei ca Gemini Voice
/// 
/// Caracteristici:
/// - Flow natural și rapid
/// - Integrare perfectă cu Gemini AI
/// - Gestionarea stărilor conversației
/// - Procesarea instantanee a comenzilor
class RideFlowManager {
  final GeminiVoiceEngine _geminiEngine;
  final tts.NaturalVoiceSynthesizer _tts;
  final FirestoreService _firestoreService;
  final VoiceOrchestrator _voiceOrchestrator; // 🎯 NOU - pentru continuarea conversației
  final AudioBeepService _beepService = AudioBeepService(); // 🔔 NOU - pentru beep-uri
  final Stream<Ride> Function(String rideId) _rideStreamOverride;
  final PricingService _pricingService = PricingService();
  final RoutingService _routingService = RoutingService();
  
  // 🎯 Starea curentă a cursei
  RideFlowState _currentState = RideFlowState.idle;
  
  // 🚗 Datele cursei
  String? _destination;
  String? _pickup;
  double? _estimatedPrice;
  List<String> _availableDrivers = [];
  String? _pendingDriverId;
  String? _currentRideId; // ✅ NOU: ID-ul cursei curente pentru confirmarea șoferului
  StreamSubscription<Ride>? _rideStatusSubscription;
  Timer? _driverResponseTimeout;
  double? _calculatedDistanceKm;
  double? _calculatedDurationMinutes;
  Map<String, double>? _fareBreakdown;
  RideCategory _currentRideCategory = RideCategory.standard;
  
  // 📍 Coordonate GPS reale
  double? _pickupLatitude;
  double? _pickupLongitude;
  double? _destinationLatitude;
  double? _destinationLongitude;
  
  // 🗣️ Ultimul mesaj rostit pentru UI
  String _lastSpokenMessage = '';
  // String? _selectedDriver; // ❌ Necesar pentru viitoare implementări
  
  // 🎤 Contextul conversației
  final List<String> _conversationHistory = [];
  
  // ✅ NAVIGATION GUARD: Previne navigare duplicată
  bool _isNavigating = false;
  
  // 🎯 Callback-uri abstracte pentru acțiuni în UI - fără cunoștințe despre widget-uri
  // ✅ FIX: Adăugăm coordonatele opționale pentru a folosi coordonatele deja geocodate din UI
  final Function(String pickup, String destination, {double? pickupLat, double? pickupLng, double? destLat, double? destLng}) onFillAddressInUI;
  final Function(RideCategory category) onSelectRideOptionInUI;
  final Function() onPressConfirmButtonInUI;
  final Function(Widget screen) onNavigateToScreen;
  final Function(Map<String, dynamic> rideRequest) onCreateRideRequest;
  final Function(String driverId, bool accepted) onDriverResponse;
  final Function() onCloseAI;
  
  // 🎯 Callback pentru navigare și acțiuni UI (păstrat pentru compatibilitate)
  // Acest câmp este folosit în cazuri speciale de navigare
  // Note: Special navigation will be implemented when needed
  // Currently commented to avoid warnings
  // Function(String, Map<String, dynamic>)? _navigationCallback;

  // void setNavigationCallback(Function(String, Map<String, dynamic>) callback) {
  //   _navigationCallback = callback;
  // }
  
      RideFlowManager({
      required GeminiVoiceEngine geminiEngine,
      required tts.NaturalVoiceSynthesizer tts,
      required FirestoreService firestoreService,
      required VoiceOrchestrator voiceOrchestrator,
      Stream<Ride> Function(String rideId)? rideStreamProvider,
      // ✅ Callback-uri pentru acțiuni în UI
      required this.onFillAddressInUI,
      required this.onSelectRideOptionInUI,
      required this.onPressConfirmButtonInUI,
      required this.onNavigateToScreen,
      required this.onCreateRideRequest,
      required this.onDriverResponse,
      required this.onCloseAI,
    }) : _geminiEngine = geminiEngine,
         _tts = tts,
         _firestoreService = firestoreService,
         _voiceOrchestrator = voiceOrchestrator,
         _rideStreamOverride = rideStreamProvider ?? ((rideId) => firestoreService.getRideStream(rideId));
  
  /// 🚀 Inițializează managerul
  Future<void> initialize() async {
    try {
      debugPrint('🚗 [RIDE_FLOW] Initializing...');
      debugPrint('🚗 [RIDE_FLOW] TTS: ${_tts.toString()}');
      debugPrint('🚗 [RIDE_FLOW] VoiceOrchestrator: ${_voiceOrchestrator.toString()}');
      
      // ✅ FIX: Obțin limba curentă și o setez în TTS la inițializare
      final languageCode = await _getCurrentLanguageCode();
      await _tts.initialize(languageCode: languageCode);
      await _tts.setLanguage(languageCode); // ✅ FIX: Asigur că limba este setată
      debugPrint('🚗 [RIDE_FLOW] ✅ TTS initialized successfully with language: $languageCode');
      
      // 🔔 Inițializez serviciul de beep-uri
      await _beepService.initialize();
      debugPrint('🚗 [RIDE_FLOW] ✅ Beep service initialized successfully');
      
      debugPrint('🚗 [RIDE_FLOW] ✅ RideFlowManager initialized successfully');
    } catch (e) {
      debugPrint('🚗 [RIDE_FLOW] ❌ Initialization error: $e');
      rethrow;
    }
  }
  
  /// 🎤 Procesează input-ul vocal și gestionează flow-ul
  Future<void> processVoiceInput(String userInput) async {
    try {
      debugPrint('🚗 [RIDE_FLOW] Processing: "$userInput"');
      
      // 🧹 CURĂȚ INPUT-UL DE CE SPUNE AI-UL (elimină echo-ul TTS-ului)
      String cleanedInput = _cleanInputFromTTS(userInput);
      debugPrint('🚗 [RIDE_FLOW] Cleaned input: "$cleanedInput"');
      
      // 📝 Adaug la istoric
      _addToHistory('User: $cleanedInput');
      
      // 🧠 Construiesc contextul pentru Gemini
      final context = VoiceContext(
        destination: _destination,
        pickup: _pickup,
        conversationState: _currentState.toString(),
        conversationHistory: _conversationHistory,
      );
      
      // 🚀 Procesez cu Gemini AI (cu input curățat!)
      // ✅ NOU: Obțin limba curentă și o pasez la Gemini
      final languageCode = await _getCurrentLanguageCode();
      final response = await _geminiEngine.processVoiceInput(cleanedInput, context, languageCode: languageCode);
      
      // 🔔 Beep pentru confirmarea procesării
      _beepService.playProcessingCompleteBeep();
      
      // 📝 Adaug răspunsul la istoric
      _addToHistory('AI: ${response.message ?? "Răspuns procesat"}');
      
      // 🎯 Gestionez răspunsul și actualizez flow-ul
      await _handleGeminiResponse(response);
      
      debugPrint('🚗 [RIDE_FLOW] ✅ Input processed successfully');
      
    } catch (e) {
      debugPrint('🚗 [RIDE_FLOW] ❌ Error: $e');
      await _handleError(e.toString());
    }
  }
  
  /// 🧹 Curăță input-ul de ceea ce spune AI-ul (elimină echo-ul TTS)
  String _cleanInputFromTTS(String userInput) {
    final input = userInput.trim();
    
    // ✅ FIX: Verifică mai întâi dacă input-ul conține o adresă cunoscută din baza de date
    // Dacă da, păstrează-l aproape intact (doar elimină frazele AI-ului de la început)
    final locationCheck = BucharestLocationsDatabase.findLocation(input);
    if (locationCheck != null) {
      debugPrint('🧹 [RIDE_FLOW] ✅ Found location in database, preserving address: ${locationCheck['name']}');
      // Dacă e o locație cunoscută, doar elimină frazele AI-ului de la început
      return _removeOnlyAIPhrasesFromStart(input);
    }
    
    // ✅ FIX: Verifică și părți din input (poate adresa e în mijloc, cu fraza AI-ului la început)
    // Ex: "Salut unde doriți să mergeți Aleea Barajul Dunării nr 10"
    // Elimină "Salut unde doriți să mergeți" și verifică dacă rămâne o locație cunoscută
    final tempCleaned = _removeOnlyAIPhrasesFromStart(input);
    if (tempCleaned != input && tempCleaned.length >= 5) {
      final tempLocationCheck = BucharestLocationsDatabase.findLocation(tempCleaned);
      if (tempLocationCheck != null) {
        debugPrint('🧹 [RIDE_FLOW] ✅ Found location in database after removing AI phrases: ${tempLocationCheck['name']}');
        return tempCleaned;
      }
    }
    
    // 🎯 Lista de fraze comune pe care le spune AI-ul
    final aiPhrases = [
      'salut, unde doriți să mergeți',
      'salut unde doriți să mergeți',
      'unde doriți să mergeți',
      'am înțeles că doriți să mergeți la',
      'am înțeles ca doriti sa mergeti la',
      'confirmați',
      'confirmati',
      'perfect',
      'excelent',
      'caut șoferi',
      'caut soferi',
    ];
    
    // 🔍 Elimin frazele AI-ului din input (doar dacă sunt la început)
    String cleaned = input;
    for (final phrase in aiPhrases) {
      final lowerCleaned = cleaned.toLowerCase();
      final lowerPhrase = phrase.toLowerCase();
      
      // Verifică dacă fraza AI-ului este la începutul input-ului
      if (lowerCleaned.startsWith(lowerPhrase)) {
        // Elimină doar dacă e la început
        final afterPhrase = cleaned.substring(phrase.length).trim();
        // ✅ FIX: Verifică dacă după eliminarea frazei AI-ului rămâne o adresă validă
        if (afterPhrase.length >= 5) { // Adresă minimă de 5 caractere
          cleaned = afterPhrase;
          debugPrint('🧹 [RIDE_FLOW] Removed AI phrase from start: "$phrase" → "$cleaned"');
          break; // Oprim după prima potrivire
        } else {
          // Dacă rămâne prea puțin, păstrează originalul
          debugPrint('🧹 [RIDE_FLOW] ⚠️ Removing "$phrase" would leave too little, keeping original');
          break;
        }
      } else if (lowerCleaned.contains(lowerPhrase)) {
        // ✅ FIX: Verifică dacă input-ul conține cuvinte cheie de adresă SAU e suficient de lung
        // Dacă da, NU elimină frazele AI-ului din mijloc (ar putea fi parte din adresă)
        final addressKeywords = ['aleea', 'alee', 'strada', 'stradă', 'bulevardul', 'bulevard', 'nr', 'număr', 'bloc', 'scara', 
                                 'barajul', 'baraj', 'dunării', 'dunarii', 'sadului', 'sad', 'gara', 'autogara', 'spitalul',
                                 'piata', 'piața', 'mall', 'centru', 'aeroport', 'str.', 'bd.', 'calea', 'sos.', 'soseaua',
                                 'cartier', 'sector', 'judet', 'județ', 'comuna', 'satul', 'sat', 'localitatea', 'localitate'];
        final hasAddressKeywords = addressKeywords.any((keyword) => lowerCleaned.contains(keyword));
        
        // ✅ FIX: Dacă input-ul e suficient de lung (>15 caractere), probabil e o adresă completă
        final isLongEnoughForAddress = cleaned.length > 15;
        
        if (hasAddressKeywords || isLongEnoughForAddress) {
          // Input-ul conține cuvinte de adresă SAU e suficient de lung → probabil e o adresă completă
          // NU elimină frazele AI-ului din mijloc (ar putea distruge adresa)
          debugPrint('🧹 [RIDE_FLOW] ⚠️ Input contains address keywords or is long enough (${cleaned.length} chars), skipping middle phrase removal to preserve address');
        } else {
          // Dacă fraza e în mijloc și NU conține cuvinte de adresă, o elimin
          final index = lowerCleaned.indexOf(lowerPhrase);
          if (index > 0 && index < cleaned.length - phrase.length) {
            // Verifică dacă după eliminare rămâne o adresă validă (minim 5 caractere)
            final before = cleaned.substring(0, index).trim();
            final after = cleaned.substring(index + phrase.length).trim();
            final combined = '$before $after'.trim();
            
            if (combined.length >= 5) {
              cleaned = combined;
              debugPrint('🧹 [RIDE_FLOW] Removed AI phrase from middle: "$phrase" → "$cleaned"');
            } else {
              debugPrint('🧹 [RIDE_FLOW] ⚠️ Removing "$phrase" from middle would leave too little, keeping original');
            }
          }
        }
      }
    }
    
    // 🧹 Elimin cuvinte de început comune (doar dacă nu e o adresă completă)
    final prefixes = ['la ', 'in ', 'spre ', 'către '];
    for (final prefix in prefixes) {
      if (cleaned.toLowerCase().startsWith(prefix)) {
        // Verifică dacă după prefix există o adresă validă (mai mult de 5 caractere)
        final afterPrefix = cleaned.substring(prefix.length).trim();
        if (afterPrefix.length > 5) {
          cleaned = afterPrefix;
          debugPrint('🧹 [RIDE_FLOW] Removed prefix: "$prefix" → "$cleaned"');
          break;
        }
      }
    }
    
    // ✅ Returnez inputul curățat (dacă e valid) sau originalul
    // Dacă curățarea a eliminat prea mult, păstrez originalul
    if (cleaned.length < 5 && userInput.length > 15) {
      debugPrint('🧹 [RIDE_FLOW] ⚠️ Cleaning removed too much (${cleaned.length} chars), keeping original (${userInput.length} chars)');
      return userInput;
    }
    
    // ✅ Verifică dacă adresa curățată este o locație cunoscută
    final cleanedLocationCheck = BucharestLocationsDatabase.findLocation(cleaned);
    if (cleanedLocationCheck != null) {
      debugPrint('🧹 [RIDE_FLOW] ✅ Cleaned address found in database: ${cleanedLocationCheck['name']}');
      return cleaned;
    }
    
    return cleaned.isNotEmpty && cleaned.length > 2 ? cleaned : userInput;
  }
  
  /// 🧹 Elimină doar frazele AI-ului de la început (pentru adrese cunoscute)
  String _removeOnlyAIPhrasesFromStart(String input) {
    final lowerInput = input.toLowerCase();
    final aiPhrases = [
      'salut, unde doriți să mergeți',
      'salut unde doriți să mergeți',
      'unde doriți să mergeți',
    ];
    
    for (final phrase in aiPhrases) {
      if (lowerInput.startsWith(phrase.toLowerCase())) {
        final after = input.substring(phrase.length).trim();
        if (after.length >= 5) {
          return after;
        }
      }
    }
    
    return input;
  }
  
  /// 🎯 Gestionează răspunsul de la Gemini și actualizează flow-ul
  Future<void> _handleGeminiResponse(GeminiVoiceResponse response) async {
    try {
      debugPrint('🚗 [RIDE_FLOW] Handling Gemini response: ${response.type}');
      
      switch (response.type) {
        case 'destination':
          await _handleDestinationResponse(response);
          break;
        case 'destination_confirmed':
          await _handleDestinationConfirmedResponse(response);
          break;
        case 'confirmation':
          await _handleConfirmationResponse(response);
          break;
        case 'ride_request':
          await _handleRideRequestResponse(response);
          break;
        case 'driver_selection':
          await _handleDriverSelectionResponse(response);
          break;
        case 'price_confirmation':
          await _handlePriceConfirmationResponse(response);
          break;
        case 'booking_finalization':
          await _handleBookingFinalizationResponse(response);
          break;
        case 'needs_clarification':
          await _handleClarificationRequest(response);
          break;
        // 🎯 NOU: Cazuri pentru confirmarea finală și opțiuni
        case 'final_confirmation':
          await _handleFinalRideConfirmation(response);
          break;
        case 'ride_confirmation': 
          await _handleFinalRideConfirmation(response);
          break;
        case 'confirm_ride':
          await _handleRideRequestResponse(response);
          break;
        // 🎯 NOU: Cazuri pentru opțiunile de cursă
        case 'ride_option':
          await _handleRideOptionSelection(response);
          break;
        case 'option_confirmation':
          await _handleRideOptionSelection(response);
          break;
        case 'driver_acceptance':
          await _handleDriverAcceptanceResponse(response);
          break;
        // 🎯 NOU: Cazuri pentru închiderea AI-ului
        case 'close_ai':
          await _handleCloseAI();
          break;
        case 'exit':
          await _handleCloseAI();
          break;
        case 'stop':
          await _handleCloseAI();
          break;
        case 'greeting':
          await _handleGreetingResponse(response);
          break;
        case 'rejection':
          await _handleRejectionResponse(response);
          break;
        default:
          await _handleUnknownResponse(response);
      }
      
    } catch (e) {
      debugPrint('🚗 [RIDE_FLOW] ❌ Response handling error: $e');
      await _handleError(e.toString());
    }
  }
  
  /// 🎯 ÎMBUNĂTĂȚIT: Gestionează răspunsul pentru destinație (cu preview preț)
  Future<void> _handleDestinationResponse(GeminiVoiceResponse response) async {
    if (response.destination != null) {
      // Verifică dacă e o destinație diferită de cea anterioară
      if (_destination != null && _destination != response.destination) {
        debugPrint('🎯 [RIDE_FLOW] Destination changed from $_destination to ${response.destination}');
      }
      
      _destination = response.destination;
      _currentState = RideFlowState.destinationConfirmed;
      
      // ✅ ACTUALIZEAZĂ UI-UL CU ADRESA ȘI COORDONATELE (dacă sunt disponibile)
      try {
        if (_destination != null && _destination!.isNotEmpty) {
          final pickup = _pickup ?? 'Locația curentă';
          onFillAddressInUI(
            pickup, 
            _destination!,
            pickupLat: _pickupLatitude,
            pickupLng: _pickupLongitude,
            destLat: _destinationLatitude,
            destLng: _destinationLongitude,
          );
          debugPrint('🎯 [RIDE_FLOW] ✅ UI updated with destination: $_destination');
          if (_destinationLatitude != null && _destinationLongitude != null) {
            debugPrint('🎯 [RIDE_FLOW] ✅ Coordinates also sent: $_destinationLatitude, $_destinationLongitude');
          }
        }
      } catch (e) {
        debugPrint('🚗 [RIDE_FLOW] ⚠️ UI update callback error: $e');
      }
      
      // ✅ CALCULEAZĂ PREȚUL ÎNAINTE DE CONFIRMARE
      await _calculateRealPrice();
      
      // ✅ MESAJ CU PREȚ PREVIEW
      final priceString = _estimatedPrice != null 
          ? '${_estimatedPrice!.toStringAsFixed(2)} lei'
          : 'un preț estimat';
      // ✅ FIX: Obțin limba curentă și mesajul tradus
      final languageCode = await _getCurrentLanguageCode();
      await _tts.setLanguage(languageCode);
      final confirmMessage = await VoiceTranslations.getDestinationWithPrice(_destination ?? '', priceString);
      _lastSpokenMessage = confirmMessage;
      await _tts.speakWithEmotion(confirmMessage, VoiceEmotion.confident);
      
      // ✅ AFIȘEAZĂ PREȚUL ÎN UI (dacă callback-ul este disponibil)
      try {
        // Callback pentru afișare preț în UI
        // onShowPricePreview?.call(_estimatedPrice ?? 0.0, _currentRideCategory);
      } catch (e) {
        debugPrint('🚗 [RIDE_FLOW] ⚠️ Price preview callback not available: $e');
      }
      
      _currentState = RideFlowState.awaitingConfirmation;
      await _startListeningForConfirmation();
      
    } else {
      await _handleClarificationRequest(response);
    }
  }
  
  /// 🎯 NOU: Pornește automat ascultarea pentru confirmare
  Future<void> _startListeningForConfirmation() async {
    try {
      debugPrint('🚗 [RIDE_FLOW] Preparing to start confirmation listening...');
      
      // ⚠️ VERIFICĂ DACĂ DEJA ASCULTĂ
      if (_voiceOrchestrator.isListening) {
        debugPrint('🚗 [RIDE_FLOW] ⚠️ Already listening - SKIPPING duplicate session');
        return;
      }
      
      // Oprește speaking dacă este activ
      if (_voiceOrchestrator.isSpeaking) {
        await _voiceOrchestrator.stopSpeaking();
      }
      
      // Așteaptă puțin să se termine TTS-ul complet
      await Future.delayed(Duration(milliseconds: 1500));
      
      // Verifică DIN NOU
      if (_voiceOrchestrator.isListening) {
        debugPrint('🚗 [RIDE_FLOW] ⚠️ Listening started elsewhere - SKIPPING');
        return;
      }
      
      debugPrint('🚗 [RIDE_FLOW] ✅ Starting confirmation listening...');
      
      // Pornește automat ascultarea pentru confirmare
      await _voiceOrchestrator.listen(
        timeoutSeconds: 30, // Mai mult timp pentru confirmare
        pauseForSeconds: 10,
      );
      
    } catch (e) {
      debugPrint('🚗 [RIDE_FLOW] ⚠️ Auto-listen error: $e');
    }
  }
  
  /// 🎯 Gestionează răspunsul de confirmare - CORECTAT
  Future<void> _handleConfirmationResponse(GeminiVoiceResponse response) async {
    try {
      debugPrint('🚗 [RIDE_FLOW] Handling confirmation response: "${response.message}"');
      debugPrint('🚗 [RIDE_FLOW] Response confidence: ${response.confidence}');
      debugPrint('🚗 [RIDE_FLOW] Current state before processing: $_currentState');
      debugPrint('🚗 [RIDE_FLOW] Pickup location: $_pickup');
      
      // Verifică dacă e răspuns pozitiv (da/confirm/etc)
      final isPositive = _isPositiveConfirmation(response.message ?? '');
      debugPrint('🚗 [RIDE_FLOW] Is positive confirmation: $isPositive');
      
      if (isPositive) {
        // ✅ RĂSPUNS POZITIV - CONTINUĂ CU FLOW-UL
        
        // 🎯 VERIFICĂ DACĂ SUNTEM ÎN CONFIRMAREA FINALĂ A RIDE-ULUI
        if (_currentState == RideFlowState.awaitingRideConfirmation) {
          debugPrint('🚗 [RIDE_FLOW] ✅ Final ride confirmation received - CREATING RIDE REQUEST');
          
          // Oprește ascultarea pentru a preveni bucla
          await _voiceOrchestrator.stopListening();
          
          // ✅ FIX: Confirmă și creează cererea de cursă cu mesaj tradus
          final languageCode = await _getCurrentLanguageCode();
          await _tts.setLanguage(languageCode);
          final confirmMessage = await VoiceTranslations.getFinalRideConfirmation();
          _lastSpokenMessage = confirmMessage;
          await _tts.speakWithEmotion(confirmMessage, VoiceEmotion.confident);
          
          // CREEAZĂ CEREREA DE CURSĂ (nu mai căuta șoferi din nou!)
          await _fillAddressAndNavigateToConfirmation();
          return; // IMPORTANT: Oprește execuția aici!
        }
        
        // Verifică contextul pentru confirmările anterioare (ÎNAINTE de a schimba starea)
        final isPickupConfirmation = _currentState == RideFlowState.awaitingConfirmation && _pickup != null;
        debugPrint('🚗 [RIDE_FLOW] Is pickup confirmation: $isPickupConfirmation');
        
        // Schimbă starea DOAR după ce am verificat contextul
        _currentState = RideFlowState.confirmationReceived;
        
        if (isPickupConfirmation) {
          // ✅ FIX: Confirmarea pickup-ului cu mesaj tradus
          final languageCode = await _getCurrentLanguageCode();
          await _tts.setLanguage(languageCode);
          final confirmMessage = await VoiceTranslations.getPickupConfirmation(_pickup ?? '');
          _lastSpokenMessage = confirmMessage;
          await _tts.speakWithEmotion(confirmMessage, VoiceEmotion.confident);
          debugPrint('🚗 [RIDE_FLOW] ✅ Pickup confirmed, proceeding to driver search');
          
          // Caută șoferi
          await _searchForDrivers();
        } else {
          // ✅ FIX: Confirmarea generală cu mesaj tradus
          final languageCode = await _getCurrentLanguageCode();
          await _tts.setLanguage(languageCode);
          final confirmMessage = await VoiceTranslations.getGeneralConfirmation();
          _lastSpokenMessage = confirmMessage;
          await _tts.speakWithEmotion(confirmMessage, VoiceEmotion.confident);
          debugPrint('🚗 [RIDE_FLOW] ✅ General confirmation received, proceeding to driver search');
          
          // Caută șoferi
          await _searchForDrivers();
        }
        
      } else {
        // ❌ RĂSPUNS NEGATIV SAU AMBIGUU - CERE CLARIFICARE
        debugPrint('🚗 [RIDE_FLOW] ❌ Negative or ambiguous response, asking for clarification');
        
        _currentState = RideFlowState.awaitingClarification;
        
        // ✅ FIX: Cere clarificare specifică cu mesaj tradus
        final languageCode = await _getCurrentLanguageCode();
        await _tts.setLanguage(languageCode);
        final clarifyMessage = await VoiceTranslations.getClarificationQuestion();
        _lastSpokenMessage = clarifyMessage;
        await _tts.speakWithEmotion(clarifyMessage, VoiceEmotion.calm);
        
        // Pornește ascultarea pentru clarificare
        await _startListeningForClarification();
      }
      
    } catch (e) {
      debugPrint('🚗 [RIDE_FLOW] ❌ Confirmation response error: $e');
      await _handleError('Eroare la procesarea confirmării: $e');
    }
  }
  
  /// 🚗 Caută șoferi disponibili
  Future<void> _searchForDrivers() async {
    _currentState = RideFlowState.searchingDrivers;
    
    // ✅ FIX: Obțin limba curentă și mesajul tradus
    final languageCode = await _getCurrentLanguageCode();
    await _tts.setLanguage(languageCode); // ✅ FIX: Asigur că limba este setată
    final searchingMessage = await VoiceTranslations.getSearchingDrivers();
    _lastSpokenMessage = searchingMessage;
    
    // ✅ FIX: Nu oprește listening - doar pune pe pauză temporar pentru a permite TTS-ului să vorbească
    // Flow-ul continuă fluid fără întreruperi
    await _voiceOrchestrator.pauseListening();
    
    await _tts.speakWithEmotion(searchingMessage, VoiceEmotion.calm);
    
    // ✅ FIX: Reia listening după ce TTS-ul termină de vorbit cu limba corectă
    final localeId = languageCode == 'en' ? 'en_US' : 'ro_RO';
    await _voiceOrchestrator.resumeListening(localeId: localeId);

    try {
      if (_pickupLatitude == null || _pickupLongitude == null) {
        await _getCurrentUserLocation();
      }

      if (_pickupLatitude == null || _pickupLongitude == null) {
        throw Exception('Locația de preluare nu este disponibilă.');
      }

      if (_estimatedPrice == null) {
        await _calculateRealPrice();
      }

      final pickupPoint = Point(
        coordinates: Position(_pickupLongitude!, _pickupLatitude!),
      );

      final etaResult = await _firestoreService.getNearestDriverEta(
        pickupPoint,
        _currentRideCategory,
      );

      // ✅ CORECTAT: Verifică dacă există șoferi disponibili
      if (etaResult == null) {
        debugPrint('🚗 [RIDE_FLOW] ❌ Nu sunt șoferi disponibili');
        _currentState = RideFlowState.idle;
        await _voiceOrchestrator.stopListening();
        await _handleNoDriverFound();
        return; // Ieșim din funcție, nu continuăm
      }

      _availableDrivers = [
        'Șofer ${etaResult.driverId} - ${etaResult.durationInMinutes} min',
      ];

      _currentState = RideFlowState.driversFound;
      final priceString = _estimatedPrice != null ? _estimatedPrice!.toStringAsFixed(2) : '—';
      final resultsMessage =
          'Am găsit un șofer la ${etaResult.durationInMinutes} minute, la ${etaResult.distanceInKm.toStringAsFixed(1)} kilometri distanță. '
          'Cursa costă aproximativ $priceString lei. Confirmăm rezervarea?';
      _lastSpokenMessage = resultsMessage;
      
      debugPrint('🚗 [RIDE_FLOW] 🗣️ Saying results message, will wait for TTS to complete...');
      
      await _voiceOrchestrator.stopListening();
      await _tts.speakWithEmotion(resultsMessage, VoiceEmotion.happy);
      
      debugPrint('🚗 [RIDE_FLOW] ✅ TTS completed, now setting state to awaitingRideConfirmation');
      _currentState = RideFlowState.awaitingRideConfirmation;

      await Future.delayed(Duration(milliseconds: 500));
      debugPrint('🚗 [RIDE_FLOW] Now starting final confirmation listening...');
      await _startListeningForFinalConfirmation();

    } catch (e) {
      debugPrint('🚗 [RIDE_FLOW] ❌ Driver search error: $e');
      // ✅ FIX: Obțin limba curentă și mesajul tradus
      final languageCode = await _getCurrentLanguageCode();
      await _tts.setLanguage(languageCode); // ✅ FIX: Setează limba înainte de a vorbi
      final errorMessage = await VoiceTranslations.getErrorCouldNotFindDrivers();
      await _handleError(errorMessage);
    }
  }
  
  /// 🎯 ÎMBUNĂTĂȚIT: Verifică dacă răspunsul e pozitiv cu detecție avansată
  bool _isPositiveConfirmation(String response) {
    final positive = [
      'da', 'yes', 'confirmă', 'confirm', 'perfect', 'ok', 'okay',
      'sigur', 'bine', 'exact', 'clar', 'înțeleg', 'înțeles', 'perfect',
      'continuă', 'continuă', 'procedează', 'merge', 'bun', 'buna',
      'adevărat', 'să', 'să mergem', 'să procedez',
      'accept', 'accepted', 'accepți', 'accepți', 'să mergem',
      'bine', 'buna', 'exact', 'clar', 'înțeleg', 'înțeles',
      'sigur', 'sure', 'definitely', 'absolutely', 'exactly',
      'right', 'true', 'yes', 'yep', 'yeah',
      'continuă', 'continue', 'proceed', 'go ahead', 'let\'s go',
      'merge', 'works', 'good', 'fine', 'alright', 'sounds good'
    ];
    
    final negative = [
      'nu', 'no', 'refuz', 'refuse', 'nu vreau', 'nu la', 'nu merg',
      'nu este', 'nu e', 'nu e corect', 'nu e bun', 'nu e bine',
      'greșit', 'incorect', 'nu confirm', 'nu accept',
      'nope', 'nah', 'not', 'don\'t', 'won\'t', 'can\'t',
      'wrong', 'incorrect', 'false', 'bad', 'no good',
      'stop', 'cancel', 'abort', 'never', 'nothing'
    ];
    
    final lowerResponse = response.toLowerCase().trim();
    
    debugPrint('🚗 [RIDE_FLOW] 🔍 Analyzing confirmation: "$lowerResponse"');
    
    // Verifică răspunsuri foarte scurte (probabil confirmări)
    if (lowerResponse.length <= 3) {
      if (positive.any((word) => lowerResponse.contains(word))) {
        debugPrint('🚗 [RIDE_FLOW] ✅ Short positive response: "$lowerResponse"');
        return true;
      }
      if (negative.any((word) => lowerResponse.contains(word))) {
        debugPrint('🚗 [RIDE_FLOW] ❌ Short negative response: "$lowerResponse"');
        return false;
      }
    }
    
    // Verifică răspunsuri cu "da" la început (foarte probabil confirmare)
    if (lowerResponse.startsWith('da') || lowerResponse.startsWith('yes')) {
      debugPrint('🚗 [RIDE_FLOW] ✅ Starts with confirmation: "$lowerResponse"');
      return true;
    }
    
    // Verifică răspunsuri cu "nu" la început (foarte probabil refuz)
    if (lowerResponse.startsWith('nu') || lowerResponse.startsWith('no')) {
      debugPrint('🚗 [RIDE_FLOW] ❌ Starts with refusal: "$lowerResponse"');
      return false;
    }
    
    // Verifică mai întâi răspunsurile negative cu scoring
    int negativeScore = 0;
    for (String neg in negative) {
      if (lowerResponse.contains(neg)) {
        negativeScore++;
        debugPrint('🚗 [RIDE_FLOW] ❌ Negative keyword: "$neg" in "$lowerResponse"');
      }
    }
    
    // Verifică răspunsurile pozitive cu scoring
    int positiveScore = 0;
    for (String pos in positive) {
      if (lowerResponse.contains(pos)) {
        positiveScore++;
        debugPrint('🚗 [RIDE_FLOW] ✅ Positive keyword: "$pos" in "$lowerResponse"');
      }
    }
    
    // Decizie bazată pe scoring
    if (positiveScore > negativeScore) {
      debugPrint('🚗 [RIDE_FLOW] ✅ Positive score wins: $positiveScore vs $negativeScore');
      return true;
    } else if (negativeScore > positiveScore) {
      debugPrint('🚗 [RIDE_FLOW] ❌ Negative score wins: $negativeScore vs $positiveScore');
      return false;
    }
    
    // Răspuns ambiguu
    debugPrint('🚗 [RIDE_FLOW] ❓ Ambiguous response: "$lowerResponse" (scores: pos=$positiveScore, neg=$negativeScore)');
    return false;
  }
  
  /// 🎯 Gestionează răspunsul pentru rezervarea cursei - INTEGRARE CU UI REAL
  Future<void> _handleRideRequestResponse(GeminiVoiceResponse response) async {
    if (response.confidence > 0.7) {
      // Verifică dacă e răspuns pozitiv pentru confirmarea finală
      if (_isPositiveConfirmation(response.message ?? '')) {
        
        // ✅ OPREȘTE ASCULTAREA - evită bucla
        await _voiceOrchestrator.stop();
        
        _currentState = RideFlowState.confirmationReceived;
        
        // 🎯 COMPLETEAZĂ ADRESA ÎN UI ȘI NAVIGHEAZĂ LA CONFIRMARE
        await _fillAddressAndNavigateToConfirmation();
        
      } else {
        // Răspuns negativ - cere din nou destinația
        await _askForNewDestination();
      }
    } else {
      await _handleClarificationRequest(response);
    }
  }
  
  /// 🎯 Gestionează selecția șoferului
  Future<void> _handleDriverSelectionResponse(GeminiVoiceResponse response) async {
    // 🚗 Logica pentru selecția șoferului
    _currentState = RideFlowState.driverSelected;
  }
  
  /// 🎯 Gestionează confirmarea prețului
  Future<void> _handlePriceConfirmationResponse(GeminiVoiceResponse response) async {
    // 💰 Logica pentru confirmarea prețului
    _currentState = RideFlowState.priceConfirmed;
  }
  
  /// 🎯 Gestionează finalizarea rezervării
  Future<void> _handleBookingFinalizationResponse(GeminiVoiceResponse response) async {
    // ✅ Logica pentru finalizarea rezervării
    _currentState = RideFlowState.bookingFinalized;
  }
  
  /// 🎯 Gestionează cererea de clarificare
  Future<void> _handleClarificationRequest(GeminiVoiceResponse response) async {
    if (response.clarificationQuestion != null) {
      _lastSpokenMessage = response.clarificationQuestion!;
      await _tts.speakWithEmotion(response.clarificationQuestion!, VoiceEmotion.calm);
      _currentState = RideFlowState.awaitingClarification;
      
      // 🎯 NOU: Continuă să asculte pentru clarificare
      await _startListeningForClarification();
    } else {
      // ✅ FIX: Dacă nu are întrebare de clarificare, cere din nou destinația cu mesaj tradus
      final languageCode = await _getCurrentLanguageCode();
      await _tts.setLanguage(languageCode); // ✅ FIX: Asigur că limba este setată
      final retryMessage = await VoiceTranslations.getPleaseSpecifyDestination();
      _lastSpokenMessage = retryMessage;
      await _tts.speakWithEmotion(retryMessage, VoiceEmotion.calm);
      _currentState = RideFlowState.listeningForInitialCommand;
      await _startListeningForClarification();
    }
  }
  
  /// 🎯 Gestionează răspunsuri necunoscute
  Future<void> _handleUnknownResponse(GeminiVoiceResponse response) async {
    debugPrint('🚗 [RIDE_FLOW] ⚠️ Unknown response type: ${response.type}');
    
    // ✅ FIX: Obțin limba curentă și mesajul tradus
    final languageCode = await _getCurrentLanguageCode();
    await _tts.setLanguage(languageCode); // ✅ FIX: Asigur că limba este setată
    final unknownMessage = await VoiceTranslations.getDidNotUnderstandRepeatDestination();
    _lastSpokenMessage = unknownMessage;
    
    // 🛑 Oprește ascultarea înainte de TTS
    await _voiceOrchestrator.stopListening();
    
    await _tts.speakWithEmotion(unknownMessage, VoiceEmotion.calm);
    
    // 🎤 Pornește IMEDIAT ascultarea după TTS
    await Future.delayed(Duration(milliseconds: 800));
    await _voiceOrchestrator.listen(
      timeoutSeconds: 30,
      pauseForSeconds: 10,
    );
  }
  
  /// 🎯 Gestionează salutări
  Future<void> _handleGreetingResponse(GeminiVoiceResponse response) async {
    debugPrint('🚗 [RIDE_FLOW] Handling greeting response');
    
    // ✅ FIX: Obțin limba curentă și mesajul tradus
    final languageCode = await _getCurrentLanguageCode();
    await _tts.setLanguage(languageCode); // ✅ FIX: Asigur că limba este setată înainte de a vorbi
    final greetingMessage = await VoiceTranslations.getGreeting();
    _lastSpokenMessage = greetingMessage;
    
    // ✅ FIX: Nu oprește listening - doar pune pe pauză temporar pentru flow continuu
    await _voiceOrchestrator.pauseListening();
    
    await _tts.speakWithEmotion(greetingMessage, VoiceEmotion.friendly);
    
    // ✅ FIX: Reia listening după ce TTS-ul termină de vorbit (flow continuu)
    final localeId = languageCode == 'en' ? 'en_US' : 'ro_RO';
    await _voiceOrchestrator.resumeListening(
      localeId: localeId,
      timeoutSeconds: 30,
      pauseForSeconds: 10,
    );
  }
  
  /// 🎯 Gestionează răspunsul de respingere (când utilizatorul refuză sau cere clarificare)
  Future<void> _handleRejectionResponse(GeminiVoiceResponse response) async {
    debugPrint('🚗 [RIDE_FLOW] Handling rejection response: ${response.message}');
    
    // Dacă există o întrebare de clarificare, o folosim
    if (response.clarificationQuestion != null) {
      _lastSpokenMessage = response.clarificationQuestion!;
      await _tts.speakWithEmotion(response.clarificationQuestion!, VoiceEmotion.calm);
      _currentState = RideFlowState.awaitingClarification;
      
      // Continuă să asculte pentru clarificare
      await _startListeningForClarification();
    } else {
      // Dacă nu există întrebare, cere din nou destinația
      // ✅ FIX: Obțin limba curentă și mesajul tradus
      final languageCode = await _getCurrentLanguageCode();
      await _tts.setLanguage(languageCode);
      final retryMessage = await VoiceTranslations.getPleaseSpecifyDestination();
      _lastSpokenMessage = retryMessage;
      await _tts.speakWithEmotion(retryMessage, VoiceEmotion.calm);
      _currentState = RideFlowState.listeningForInitialCommand;
      
      // Pornește ascultarea pentru destinație
      await Future.delayed(const Duration(milliseconds: 800));
      await _voiceOrchestrator.listen(
        timeoutSeconds: 30,
        pauseForSeconds: 5,
      );
    }
  }
  
  /// 🎯 ÎMBUNĂTĂȚIT: Gestionează erorile cu feedback UI și TTS
  Future<void> _handleError(String error) async {
    debugPrint('🚗 [RIDE_FLOW] ❌ Error: $error');
    
    // ✅ FIX: Setează limba înainte de a vorbi
    final languageCode = await _getCurrentLanguageCode();
    await _tts.setLanguage(languageCode);
    
    // ✅ MESAJ DE EROARE PRIETENOS (tradus)
    final errorMessage = error.isNotEmpty 
        ? error 
        : (languageCode == 'en' 
            ? 'I\'m sorry, I encountered a problem. Please try again.' 
            : 'Îmi pare rău, am întâmpinat o problemă. Vă rog să încercați din nou.');
    
    _lastSpokenMessage = errorMessage;
    
    // ✅ TTS pentru feedback vocal
    await _tts.speakWithEmotion(errorMessage, VoiceEmotion.calm);
    
    // ✅ UI feedback prin callback (dacă este disponibil)
    // Notă: onShowError este un callback opțional care poate fi setat din UI
    try {
      // Callback pentru afișare eroare în UI (dacă este implementat)
      // onShowError?.call(errorMessage);
    } catch (e) {
      debugPrint('🚗 [RIDE_FLOW] ⚠️ Error callback not available: $e');
    }
    
    _currentState = RideFlowState.error;
  }
  

  
  /// 📝 Adaugă la istoricul conversației
  void _addToHistory(String message) {
    _conversationHistory.add(message);
    if (_conversationHistory.length > 20) {
      _conversationHistory.removeAt(0);
    }
  }

  /// 📝 Expune istoricul conversației pentru UI (copie)
  List<String> get conversationHistoryCopy => List<String>.from(_conversationHistory);

  /// 🗣️ Adaugă un mesaj AI în istoric (pentru salut/indicii UI)
  void addAiMessage(String message) {
    _addToHistory('AI: $message');
  }
  
  /// 🎯 Obține starea curentă
  RideFlowState get currentState => _currentState;
  
  /// 🚗 Obține destinația
  String? get destination => _destination;
  
  /// 🚗 Obține pickup-ul
  String? get pickup => _pickup;
  
  /// 💰 Obține prețul estimat
  double? get estimatedPrice => _estimatedPrice;

  double? get calculatedDistanceKm => _calculatedDistanceKm;

  double? get calculatedDurationMinutes => _calculatedDurationMinutes;

  Map<String, double>? get fareBreakdown => _fareBreakdown;

  RideCategory get currentRideCategory => _currentRideCategory;
  
  /// 🚗 Obține șoferii disponibili
  List<String> get availableDrivers => _availableDrivers;
  
  /// 📝 Obține istoricul conversației (read-only)
  List<String> get conversationHistory => List.unmodifiable(_conversationHistory);
  
  /// 🗣️ Obține ultimul mesaj rostit
  String get lastSpokenMessage => _lastSpokenMessage;
  
  /// 🎯 NOU: Pornește automat ascultarea pentru clarificare
  Future<void> _startListeningForClarification() async {
    try {
      // Așteaptă puțin să se termine TTS-ul complet
      await Future.delayed(Duration(milliseconds: 1500));
      
      debugPrint('🚗 [RIDE_FLOW] Auto-starting clarification listening...');
      
      // Pornește automat ascultarea pentru clarificare
      await _voiceOrchestrator.listen(
        timeoutSeconds: 30, // Timp suficient pentru clarificare
        pauseForSeconds: 10,
      );
      
    } catch (e) {
      debugPrint('🚗 [RIDE_FLOW] ⚠️ Auto-listen for clarification error: $e');
    }
  }




  /// ❌ Anulează rezervarea
  /// 🎯 ACEASTĂ FUNCȚIE SE FOLOSEȘTE DOAR LA ACTIVAREA BUTONULUI "ANULEAZĂ" DIN UI
  /// 🚫 NU SE APEAZĂ AUTOMAT - DOAR CÂND USER-UL APASĂ BUTONUL
  Future<void> _cancelRideBooking() async {
    _currentState = RideFlowState.idle;
    // ✅ FIX: Obțin limba curentă și mesajul tradus
    final languageCode = await _getCurrentLanguageCode();
    await _tts.setLanguage(languageCode);
    final cancelMessage = languageCode == 'en' 
        ? 'I understand. The reservation has been cancelled. Can I help you with anything else?'
        : 'Înțeleg. Rezervarea a fost anulată. Vă pot ajuta cu altceva?';
    _lastSpokenMessage = cancelMessage;
    await _tts.speakWithEmotion(cancelMessage, VoiceEmotion.calm);
  }

  /// 🎯 SINCRONIZAT: Completează adresa și navighează DIRECT la SearchingForDriverScreen (ca fluxul manual)
  /// ✅ NAVIGATION GUARD: Previne navigare duplicată
  Future<void> _fillAddressAndNavigateToConfirmation() async {
    // ✅ NAVIGATION GUARD: Verifică dacă deja navigăm
    if (_isNavigating) {
      debugPrint('🚗 [RIDE_FLOW] ⚠️ Navigation already in progress, skipping duplicate call');
      return;
    }
    
    _isNavigating = true;
    
    try {
      debugPrint('🚗 [RIDE_FLOW] Filling address and navigating DIRECTLY to SearchingForDriverScreen...');
      
      // 🗣️ Anunță că completează adresele și trimite solicitarea
      // ✅ NOU: Folosește traducere
      final message = await VoiceTranslations.getCompletingAddresses();
      await _tts.speakWithEmotion(message, VoiceEmotion.confident);
      
      // ✅ 1. Salvează starea internă
      final currentLocation = await _getCurrentUserLocation();
      _pickup = _pickup ?? currentLocation;
      debugPrint('🚗 [RIDE_FLOW] Current user location: $currentLocation');
      
      // ✅ 2. Validează adresele (ca fluxul manual)
      // ✅ SECURITY: Validate addresses before processing
      if (_pickup != null) {
        final pickupValidation = InputValidator.validateAddress(_pickup!);
        if (!pickupValidation.isValid) {
          await _handleError(pickupValidation.error ?? 'Adresa de preluare nu este validă.');
          return;
        }
      }
      
      if (_destination != null) {
        final destValidation = InputValidator.validateAddress(_destination!);
        if (!destValidation.isValid) {
          await _handleError(destValidation.error ?? 'Adresa de destinație nu este validă.');
          return;
        }
      }
      
      // ✅ SECURITY: Validate coordinates
      if (_pickupLatitude != null && _pickupLongitude != null) {
        final coordValidation = InputValidator.validateCoordinates(_pickupLatitude, _pickupLongitude);
        if (!coordValidation.isValid) {
          await _handleError(coordValidation.error ?? 'Coordonatele de preluare nu sunt valide.');
          return;
        }
      }
      
      if (_destinationLatitude != null && _destinationLongitude != null) {
        final coordValidation = InputValidator.validateCoordinates(_destinationLatitude, _destinationLongitude);
        if (!coordValidation.isValid) {
          await _handleError(coordValidation.error ?? 'Coordonatele de destinație nu sunt valide.');
          return;
        }
      }
      
      if (!await _validateAddresses()) {
        await _handleError('Adresele nu sunt valide. Vă rog să specificați din nou.');
        return;
      }
      
      // ✅ 3. Calculează prețul real (ca fluxul manual) cu timeout
      try {
        await _calculateRealPrice().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('Calcularea prețului a durat prea mult. Vă rog să reîncercați.');
          },
        );
      } catch (e) {
        debugPrint('🚗 [RIDE_FLOW] ❌ Price calculation timeout or error: $e');
        // Continuă cu preț default dacă calcularea eșuează
        _estimatedPrice = _estimatedPrice ?? 15.0;
      }
      
      // ✅ 4. Creează obiectul Ride complet (ca fluxul manual)
      final rideRequest = await _createCompleteRideRequest();
      
      // ✅ 5. Trimite direct la Firebase (ca fluxul manual) cu error handling
      String? rideId;
      try {
        rideId = await onCreateRideRequest(rideRequest).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('Crearea cursei a durat prea mult. Vă rog să reîncercați.');
          },
        );
      } catch (e) {
        debugPrint('🚗 [RIDE_FLOW] ❌ Error creating ride request: $e');
        await _handleError('Nu am putut crea cursa: ${e.toString()}');
        return; // Oprește execuția dacă crearea cursei eșuează
      }
      
      if (rideId == null || rideId.isEmpty) {
        debugPrint('🚗 [RIDE_FLOW] ❌ Ride ID is null or empty');
        await _handleError('Nu am putut crea cursa. ID-ul cursei este invalid.');
        return;
      }
      
      // ✅ NOU: Salvează rideId pentru confirmarea ulterioară a șoferului
      _currentRideId = rideId;
      
      // ✅ 6. Navighează DIRECT la SearchingForDriverScreen (ca fluxul manual)
      try {
        final searchingScreen = SearchingForDriverScreen(rideId: rideId);
        onNavigateToScreen(searchingScreen);
        debugPrint('🚗 [RIDE_FLOW] ✅ Ride request sent directly to Firebase, navigating to SearchingForDriverScreen');
      } catch (e) {
        debugPrint('🚗 [RIDE_FLOW] ❌ Navigation error: $e');
        await _handleError('Nu am putut naviga la ecranul de căutare șoferi: ${e.toString()}');
      }
      
    } catch (e) {
      debugPrint('🚗 [RIDE_FLOW] ❌ Fill address error: $e');
      await _handleError('Eroare la completarea adreselor: ${e.toString()}');
    }
  }

  /// 🎯 ÎMBUNĂTĂȚIT: Validează adresele complet (coordonate, distanță, validitate)
  Future<bool> _validateAddresses() async {
    try {
      // ✅ VALIDARE ADRESE TEXT
      if (_pickup == null || _destination == null) {
        await _handleError('Lipsește punctul de plecare sau destinația. Vă rog să specificați ambele.');
        return false;
      }
      
      if (_pickup!.isEmpty || _destination!.isEmpty) {
        await _handleError('Adresele nu pot fi goale. Vă rog să specificați adresele complete.');
        return false;
      }
      
      // ✅ VALIDARE COORDONATE
      if (_pickupLatitude == null || _pickupLongitude == null) {
        await _handleError('Coordonatele punctului de plecare nu sunt disponibile. Vă rog să reîncercați.');
        return false;
      }
      
      if (_destinationLatitude == null || _destinationLongitude == null) {
        await _handleError('Coordonatele destinației nu sunt disponibile. Vă rog să reîncercați.');
        return false;
      }
      
      // ✅ VALIDARE COORDONATE VALIDE (lat: -90..90, lng: -180..180)
      if (_pickupLatitude! < -90 || _pickupLatitude! > 90 ||
          _pickupLongitude! < -180 || _pickupLongitude! > 180) {
        await _handleError('Coordonatele punctului de plecare sunt invalide.');
        return false;
      }
      
      if (_destinationLatitude! < -90 || _destinationLatitude! > 90 ||
          _destinationLongitude! < -180 || _destinationLongitude! > 180) {
        await _handleError('Coordonatele destinației sunt invalide.');
        return false;
      }
      
      // ✅ VALIDARE DISTANȚĂ MINIMĂ (100 metri)
      final distanceKm = _calculateDistance();
      if (distanceKm < 0.1) {
        await _handleError('Distanța este prea mică. Distanța minimă este 100 metri. Vă rog să alegeți o destinație mai departe.');
        return false;
      }
      
      // ✅ VALIDARE DISTANȚĂ MAXIMĂ (200 km)
      if (distanceKm > 200) {
        await _handleError('Distanța este prea mare. Distanța maximă este 200 km. Vă rog să alegeți o destinație mai aproape.');
        return false;
      }
      
      debugPrint('🚗 [RIDE_FLOW] ✅ Addresses validated: pickup=$_pickup, destination=$_destination, distance=${distanceKm.toStringAsFixed(2)}km');
      return true;
    } catch (e) {
      debugPrint('🚗 [RIDE_FLOW] ❌ Address validation error: $e');
      await _handleError('Eroare la validarea adreselor: $e');
      return false;
    }
  }

  /// 🎯 ÎMBUNĂTĂȚIT: Calculează prețul real bazat pe rută și categorii (cu preview și progress)
  Future<void> _calculateRealPrice() async {
    try {
      // ✅ FEEDBACK PROGRESS
      _lastSpokenMessage = 'Se calculează prețul...';
      
      if (_pickupLatitude == null || _pickupLongitude == null) {
        await _getCurrentUserLocation();
      }

      if (_pickupLatitude == null || _pickupLongitude == null) {
        throw Exception('Pickup coordinates unavailable');
      }

      if (_destinationLatitude == null || _destinationLongitude == null) {
        debugPrint('🚗 [RIDE_FLOW] ⚠️ Destination coordinates missing, falling back to distance estimation');
      }
      
      // ✅ FEEDBACK PROGRESS - Calculare rută
      _lastSpokenMessage = 'Se calculează ruta...';

      final pickupPoint = Point(
        coordinates: Position(_pickupLongitude!, _pickupLatitude!),
      );
      final destinationPoint = (_destinationLongitude != null && _destinationLatitude != null)
          ? Point(
              coordinates: Position(_destinationLongitude!, _destinationLatitude!),
            )
          : null;

      double distanceKm = _calculateDistance();
      double durationMinutes = 15.0;

      if (destinationPoint != null) {
        try {
          final routeData = await _routingService.getRoute([pickupPoint, destinationPoint]);
          if (routeData != null) {
            final routes = routeData['routes'] as List<dynamic>?;
            if (routes != null && routes.isNotEmpty) {
              final firstRoute = routes.first as Map<String, dynamic>;
              final rawDistance = firstRoute['distance'] as num?;
              final rawDuration = firstRoute['duration'] as num?;
              if (rawDistance != null) {
                distanceKm = rawDistance.toDouble() / 1000.0;
              }
              if (rawDuration != null) {
                durationMinutes = rawDuration.toDouble() / 60.0;
              }
            }
          }
        } catch (e) {
          debugPrint('🚗 [RIDE_FLOW] ⚠️ Routing service error: $e');
        }
      }

      _calculatedDistanceKm = distanceKm;
      _calculatedDurationMinutes = durationMinutes;

      _fareBreakdown = _pricingService.calculateFare(
        distanceInKm: distanceKm,
        durationInMinutes: durationMinutes,
        category: _currentRideCategory,
      );

      _estimatedPrice = _fareBreakdown?['totalCost'];

      debugPrint(
        '🚗 [RIDE_FLOW] ✅ Price calculated: ${_estimatedPrice?.toStringAsFixed(2)} lei '
        '(distance: ${distanceKm.toStringAsFixed(2)} km, duration: ${durationMinutes.toStringAsFixed(1)} min, category: $_currentRideCategory)',
      );
    } catch (e) {
      debugPrint('🚗 [RIDE_FLOW] ❌ Price calculation error: $e');
      _fareBreakdown = null;
      _estimatedPrice = 15.0; // Preț default
      _calculatedDistanceKm = null;
      _calculatedDurationMinutes = null;
    }
  }

  /// 🎯 NOUĂ METODĂ: Calculează distanța REALĂ folosind coordonate GPS și formula Haversine
  double _calculateDistance() {
    try {
      // Verifică dacă avem coordonate pentru pickup și destinație
      if (_pickupLatitude == null || _pickupLongitude == null) {
        debugPrint('🌍 [DISTANCE] ⚠️ Missing pickup coordinates - using default 5km');
        return 5.0;
      }
      
      if (_destinationLatitude == null || _destinationLongitude == null) {
        debugPrint('🌍 [DISTANCE] ⚠️ Missing destination coordinates - using default 5km');
        return 5.0;
      }
      
      // ✅ Calculează distanța REALĂ folosind formula Haversine
      final distance = _calculateHaversineDistance(
        _pickupLatitude!,
        _pickupLongitude!,
        _destinationLatitude!,
        _destinationLongitude!,
      );
      
      debugPrint('🌍 [DISTANCE] ✅ Calculated REAL distance: ${distance.toStringAsFixed(2)} km');
      debugPrint('   From: ($_pickupLatitude, $_pickupLongitude)');
      debugPrint('   To: ($_destinationLatitude, $_destinationLongitude)');
      
      return distance;
      
    } catch (e) {
      debugPrint('🌍 [DISTANCE] ❌ Calculation error: $e');
      return 5.0; // Fallback la 5 km
    }
  }
  
  /// 📐 Formula Haversine pentru calcul distanță între două coordonate GPS
  double _calculateHaversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Raza Pământului în km
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final distance = earthRadius * c;
    
    return distance; // Distanța în km
  }
  
  /// 📐 Convertește grade în radiani
  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }
  
  /// 🧠 Întreabă Gemini AI pentru o adresă mai clară și coordonate GPS când geocoding-ul eșuează
  /// Returnează un Map cu 'address' (adresa clarificată) și opțional 'latitude' și 'longitude' (dacă Gemini AI le oferă)
  /// Sau null dacă Gemini AI nu poate ajuta
  Future<Map<String, dynamic>?> _askGeminiForClarifiedAddress(String originalAddress) async {
    try {
      debugPrint('🧠 [GEMINI_GEOCODE] Asking Gemini AI for clarified address and coordinates: $originalAddress');
      
      // ✅ FIX: Folosește metoda directă de clarificare a adresei și obținere coordonate (fără logica de conversație)
      final result = await _geminiEngine.clarifyAddressForGeocoding(originalAddress);
      
      if (result != null && result['address'] != null) {
        debugPrint('🧠 [GEMINI_GEOCODE] ✅ Gemini AI clarified address: ${result['address']}');
        if (result['latitude'] != null && result['longitude'] != null) {
          debugPrint('🧠 [GEMINI_GEOCODE] ✅ Gemini AI also provided coordinates: ${result['latitude']}, ${result['longitude']}');
        }
        return result;
      } else {
        debugPrint('🧠 [GEMINI_GEOCODE] ⚠️ Gemini AI could not clarify address');
        return null;
      }
      
    } catch (e) {
      debugPrint('🧠 [GEMINI_GEOCODE] ❌ Error asking Gemini AI: $e');
      return null;
    }
  }
  
  /// 🗺️ Verifică destinațiile predefinite (rapid, fără API calls)
  /// Returnează coordonatele dacă destinația este cunoscută, altfel null
  Map<String, dynamic>? _getPredefinedDestinationCoordinates(String destination) {
    // ✅ FIX: Folosește baza de date locală extinsă pentru locații din București și Ilfov
    try {
      final location = BucharestLocationsDatabase.findLocation(destination);
      if (location != null) {
        debugPrint('🌍 [GPS] ✅ Found location in database: ${location['name']} (${location['category']})');
        return {
          'latitude': location['latitude'],
          'longitude': location['longitude'],
          'name': location['name'],
        };
      }
    } catch (e) {
      debugPrint('🌍 [GPS] ⚠️ Error searching location database: $e');
    }

    // ✅ Fallback: Lista de destinații cunoscute cu coordonatele exacte (pentru compatibilitate)
    final destinationCoordinates = {
      'Aeroportul Henri Coandă': {'latitude': 44.5721, 'longitude': 26.0691, 'name': 'Aeroportul Henri Coandă, Otopeni'},
      'Aeroportul Henri Coanda': {'latitude': 44.5721, 'longitude': 26.0691, 'name': 'Aeroportul Henri Coandă, Otopeni'},
      'Aeroport Otopeni': {'latitude': 44.5721, 'longitude': 26.0691, 'name': 'Aeroportul Henri Coandă, Otopeni'},
      'Aeroportul Otopeni': {'latitude': 44.5721, 'longitude': 26.0691, 'name': 'Aeroportul Henri Coandă, Otopeni'},
      'Otopeni': {'latitude': 44.5721, 'longitude': 26.0691, 'name': 'Aeroportul Henri Coandă, Otopeni'},
      'aeroport': {'latitude': 44.5721, 'longitude': 26.0691, 'name': 'Aeroportul Henri Coandă, Otopeni'},
      'Piața Victoriei': {'latitude': 44.4518, 'longitude': 26.0970, 'name': 'Piața Victoriei, București'},
      'Piața Victoriei, București': {'latitude': 44.4518, 'longitude': 26.0970, 'name': 'Piața Victoriei, București'},
      'Mall Băneasa': {'latitude': 44.5072, 'longitude': 26.0769, 'name': 'Mall Băneasa, București'},
      'Mall Băneasa, București': {'latitude': 44.5072, 'longitude': 26.0769, 'name': 'Mall Băneasa, București'},
      'Gara de Nord': {'latitude': 44.4478, 'longitude': 26.0758, 'name': 'Gara de Nord, București'},
      'Gara de Nord, București': {'latitude': 44.4478, 'longitude': 26.0758, 'name': 'Gara de Nord, București'},
      'Gara Nord': {'latitude': 44.4478, 'longitude': 26.0758, 'name': 'Gara de Nord, București'},
      'gara': {'latitude': 44.4478, 'longitude': 26.0758, 'name': 'Gara de Nord, București'},
      'Piața Universității': {'latitude': 44.4355, 'longitude': 26.1008, 'name': 'Piața Universității, București'},
      'Piața Universității, București': {'latitude': 44.4355, 'longitude': 26.1008, 'name': 'Piața Universității, București'},
      'Centrul Vechi': {'latitude': 44.4323, 'longitude': 26.0999, 'name': 'Centrul Vechi, București'},
      'Centrul Vechi, București': {'latitude': 44.4323, 'longitude': 26.0999, 'name': 'Centrul Vechi, București'},
      'Herastrau Park': {'latitude': 44.4684, 'longitude': 26.0831, 'name': 'Herastrau Park, București'},
      'Herastrau Park, București': {'latitude': 44.4684, 'longitude': 26.0831, 'name': 'Herastrau Park, București'},
      'Plaza Romania': {'latitude': 44.4486, 'longitude': 26.0188, 'name': 'Plaza Romania, București'},
      'Plaza Romania, București': {'latitude': 44.4486, 'longitude': 26.0188, 'name': 'Plaza Romania, București'},
      'Piața Unirii': {'latitude': 44.4268, 'longitude': 26.1025, 'name': 'Piața Unirii, București'},
      'Piața Unirii, București': {'latitude': 44.4268, 'longitude': 26.1025, 'name': 'Piața Unirii, București'},
      'piata unirii': {'latitude': 44.4268, 'longitude': 26.1025, 'name': 'Piața Unirii, București'},
      'centru': {'latitude': 44.4268, 'longitude': 26.1025, 'name': 'Centrul Bucureștiului'},
      'centrul': {'latitude': 44.4268, 'longitude': 26.1025, 'name': 'Centrul Bucureștiului'},
    };
    
    // Normalizează destinația pentru căutare (lowercase, fără diacritice opțional)
    final normalizedDestination = destination.toLowerCase().trim();
    
    // Caută destinația exactă sau parțială
    for (final entry in destinationCoordinates.entries) {
      final key = entry.key.toLowerCase();
      // Verifică dacă destinația conține cheia sau cheia conține destinația
      if (normalizedDestination.contains(key) || key.contains(normalizedDestination)) {
        debugPrint('🌍 [GPS] ✅ Found predefined destination: ${entry.key} -> ${entry.value['name']}');
        return entry.value;
      }
    }
    
    // Verifică și variante cu "plecări" sau "sosiri" (pentru aeroport)
    if (normalizedDestination.contains('aeroport') || normalizedDestination.contains('otopeni')) {
      if (normalizedDestination.contains('plecări') || normalizedDestination.contains('plecari') ||
          normalizedDestination.contains('sosiri') || normalizedDestination.contains('sosiri')) {
        debugPrint('🌍 [GPS] ✅ Found predefined destination: Aeroportul Henri Coandă (with terminal info)');
        return {'latitude': 44.5721, 'longitude': 26.0691, 'name': 'Aeroportul Henri Coandă, Otopeni'};
      }
    }
    
    return null; // Nu e predefinită
  }

  /// 🎯 ÎMBUNĂTĂȚIT: Creează obiectul Ride complet (ca fluxul manual) cu validări
  Future<Map<String, dynamic>> _createCompleteRideRequest() async {
    try {
      // ✅ FIX: Obține user ID real din Firebase Auth
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null || userId.isEmpty) {
        throw Exception('Utilizatorul nu este autentificat. Vă rog să vă logați.');
      }
      
      // ✅ FIX: Validează că avem coordonate valide (nu default)
      if (_pickupLatitude == null || _pickupLongitude == null) {
        throw Exception('Coordonatele pickup nu sunt disponibile. Vă rog să reîncercați.');
      }
      
      if (_destinationLatitude == null || _destinationLongitude == null) {
        throw Exception('Coordonatele destinației nu sunt disponibile. Vă rog să reîncercați.');
      }
      
      // ✅ FIX: Calculează distanța reală (nu default)
      final distance = _calculatedDistanceKm ?? _calculateDistance();
      if (distance < 0.1 || distance > 200) {
        throw Exception('Distanța calculată este invalidă: ${distance.toStringAsFixed(2)} km');
      }
      
      final rideRequest = <String, dynamic>{
        'id': '',
        'passengerId': userId, // ✅ FIX: User ID real, nu string gol
        'pickup': _pickup ?? '',
        'destination': _destination ?? '',
        'startAddress': _pickup ?? '',
        'destinationAddress': _destination ?? '',
        'distance': distance,
        'startLatitude': _pickupLatitude!,
        'startLongitude': _pickupLongitude!,
        'destinationLatitude': _destinationLatitude!,
        'destinationLongitude': _destinationLongitude!,
        'durationInMinutes': (_calculatedDurationMinutes ?? 15).round(),
        'baseFare': _fareBreakdown?['baseFare'] ?? 0.0,
        'perKmRate': _fareBreakdown?['perKmRate'] ?? 0.0,
        'perMinRate': _fareBreakdown?['perMinRate'] ?? 0.0,
        'totalCost': _estimatedPrice ?? 0.0,
        'estimatedPrice': _estimatedPrice ?? 0.0,
        'appCommission': _fareBreakdown?['appCommission'] ?? ((_estimatedPrice ?? 0.0) * 0.1),
        'driverEarnings': _fareBreakdown?['driverEarnings'] ?? ((_estimatedPrice ?? 0.0) * 0.9),
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'pending',
        'category': _currentRideCategory.name,
        'urgency': 'normal',
        'stops': [],
        'isScheduled': false,
        'scheduledPickupTime': null,
      };
      
      debugPrint('🚗 [RIDE_FLOW] ✅ Complete ride request created for user: $userId');
      return rideRequest;
    } catch (e) {
      debugPrint('🚗 [RIDE_FLOW] ❌ Ride request creation error: $e');
      rethrow;
    }
  }

  /// 🎯 NOUĂ METODĂ: Gestionează confirmarea adreselor din UI
  Future<void> handleAddressConfirmation() async {
    try {
      debugPrint('🚗 [RIDE_FLOW] Address confirmed from UI, showing ride options...');
      
      _currentState = RideFlowState.showingRideOptions;
      
      // 🗣️ Prezintă opțiunile vocale
      final optionsMessage = '''Vă arăt opțiunile disponibile:
      - Standard: Cel mai economic
      - Family: Pentru familii cu copii  
      - Energy: Mașini electrice
      - Best: Cel mai confortabil
      
      Care opțiune preferați?''';
      
      await _tts.speakWithEmotion(optionsMessage, VoiceEmotion.confident);
      
      // 🎯 PORNEȘTE ASCULTAREA DOAR PENTRU OPȚIUNI
      await _startListeningForRideOption();
      
    } catch (e) {
      debugPrint('🚗 [RIDE_FLOW] ❌ Address confirmation error: $e');
    }
  }

  /// 🎯 NOUĂ METODĂ: Ascultă pentru opțiunea de cursă
  Future<void> _startListeningForRideOption() async {
    try {
      await Future.delayed(Duration(milliseconds: 1000));
      debugPrint('🚗 [RIDE_FLOW] Listening for ride option selection...');
      
      _currentState = RideFlowState.awaitingRideOptionSelection;
      
      await _voiceOrchestrator.listen(
        timeoutSeconds: 30,
        pauseForSeconds: 5,
      );
      
    } catch (e) {
      debugPrint('🚗 [RIDE_FLOW] ⚠️ Ride option listening error: $e');
    }
  }

  /// 🎯 NOUĂ METODĂ: Gestionează selecția opțiunii de cursă
  Future<void> _handleRideOptionSelection(GeminiVoiceResponse response) async {
    try {
      // Extrage opțiunea din răspuns
      final option = _extractRideOption(response.message ?? '');
      
      if (option != null) {
        // ✅ OPREȘTE ASCULTAREA
        await _voiceOrchestrator.stop();
        
        _currentState = RideFlowState.rideOptionSelected;
        _currentRideCategory = option;
        
        // 🗣️ Confirmă opțiunea
        final confirmMessage = 'Ați ales opțiunea $option. Confirm selecția?';
        await _tts.speakWithEmotion(confirmMessage, VoiceEmotion.confident);
        
        // ✅ Emite comanda abstractă pentru selecția în UI
        onSelectRideOptionInUI(option);
        
        // 🎯 AȘTEAPTĂ CONFIRMAREA FINALĂ
        await _startListeningForFinalRideConfirmation();
        
      } else {
        await _handleClarificationRequest(response);
      }
      
    } catch (e) {
      debugPrint('🚗 [RIDE_FLOW] ❌ Ride option selection error: $e');
    }
  }

  /// 🎯 Extrage opțiunea de cursă din text
  RideCategory? _extractRideOption(String text) {
    final lowerText = text.toLowerCase();
    
    if (lowerText.contains('standard')) return RideCategory.standard;
    if (lowerText.contains('family')) return RideCategory.family;
    if (lowerText.contains('energy')) return RideCategory.energy;
    if (lowerText.contains('best')) return RideCategory.best;
    
    return null;
  }

  /// 🎯 NOUĂ METODĂ: Confirmarea finală a cursei
  Future<void> _startListeningForFinalRideConfirmation() async {
    try {
      await Future.delayed(Duration(milliseconds: 1000));
      _currentState = RideFlowState.awaitingFinalRideConfirmation;
      
      await _voiceOrchestrator.listen(
        timeoutSeconds: 30,
        pauseForSeconds: 5,
      );
      
    } catch (e) {
      debugPrint('🚗 [RIDE_FLOW] ⚠️ Final confirmation listening error: $e');
    }
  }

  /// 🎯 NOUĂ METODĂ: Gestionează confirmarea finală și trimite la Firebase
  Future<void> _handleFinalRideConfirmation(GeminiVoiceResponse response) async {
    if (_isPositiveConfirmation(response.message ?? '')) {
      // ✅ OPREȘTE ASCULTAREA DEFINITIV
      await _voiceOrchestrator.stop();
      
      _currentState = RideFlowState.sendingToFirebase;
      
      // ✅ FIX: Obțin limba curentă și mesajul tradus
      final languageCode = await _getCurrentLanguageCode();
      await _tts.setLanguage(languageCode);
      final message = await VoiceTranslations.getSendingRequestToDrivers();
      await _tts.speakWithEmotion(message, VoiceEmotion.happy);
      
              // ✅ Emite comanda abstractă pentru butonul de confirmare
        onPressConfirmButtonInUI();
        
        // 🔥 TRIMITE LA FIREBASE
        await _sendRideRequestToFirebase();
      
    } else {
      // 🎯 USER NU CONFIRMĂ - ANULEAZĂ REZERVAREA
      await _cancelRideBooking();
    }
  }



  /// 🎯 NOUĂ METODĂ: Cere din nou destinația
  Future<void> _askForNewDestination() async {
    _currentState = RideFlowState.listeningForInitialCommand;
    
    final message = 'Înțeleg că nu confirmați. Vă rog să specificați din nou unde doriți să mergeți.';
    await _tts.speakWithEmotion(message, VoiceEmotion.calm);
    
    // 🎯 PORNEȘTE ASCULTAREA PENTRU NOUA DESTINAȚIE
    await _startListeningForNewDestination();
  }

  /// 🎯 NOUĂ METODĂ: Ascultă pentru noua destinație
  Future<void> _startListeningForNewDestination() async {
    try {
      await Future.delayed(Duration(milliseconds: 1000));
      debugPrint('🚗 [RIDE_FLOW] Listening for new destination...');
      
      await _voiceOrchestrator.listen(
        timeoutSeconds: 30,
        pauseForSeconds: 5,
      );
      
    } catch (e) {
      debugPrint('🚗 [RIDE_FLOW] ⚠️ New destination listening error: $e');
    }
  }

  /// 🔥 NOUĂ METODĂ: Trimite solicitarea la Firebase
  /// 🎯 ACEASTĂ FUNCȚIE SE FOLOSEȘTE DOAR LA ACTIVAREA BUTONULUI "CONFIRMĂ REZERVAREA" DIN UI
  /// 🚫 NU SE APEAZĂ AUTOMAT - DOAR CÂND USER-UL APASĂ BUTONUL
  Future<void> _sendRideRequestToFirebase() async {
    try {
      _currentState = RideFlowState.waitingForDriverResponse;
      
      // 🔥 INTEGRARE: Construiește notele pasagerului din conversația AI
      final passengerNotes = _buildPassengerNotes();
      debugPrint('🚗 [RIDE_FLOW] Passenger notes: $passengerNotes');
      
      // 🔥 CREEAZĂ SOLICITAREA REALĂ ÎN FIREBASE
      final rideRequest = {
        'pickup': _pickup ?? await _getCurrentUserLocation(),
        'destination': _destination,
        'estimatedPrice': _estimatedPrice,
        'passengerNotes': passengerNotes,
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
        'passengerId': 'current_user_id', // Se va obține din Firebase Auth
        'rideType': 'standard', // Se va obține din selecția user-ului
      };
      
      debugPrint('🚗 [RIDE_FLOW] 🔥 Creating real Firebase ride request: $rideRequest');
      
      // ✅ Emite comanda abstractă pentru crearea solicitării
      final rideId = await onCreateRideRequest(rideRequest);
      debugPrint('🚗 [RIDE_FLOW] ✅ Ride request created with ID: $rideId');
      
      // ✅ NOU: Salvează rideId pentru confirmarea ulterioară a șoferului
      _currentRideId = rideId;
      
      // ✅ FIX: Obțin limba curentă și mesajul tradus
      final languageCode = await _getCurrentLanguageCode();
      await _tts.setLanguage(languageCode);
      final message = await VoiceTranslations.getRequestSentToDrivers();
      await _tts.speakWithEmotion(message, VoiceEmotion.confident);
      
      await _monitorRideAcceptance(rideId);
      
    } catch (e) {
      debugPrint('🚗 [RIDE_FLOW] ❌ Firebase sending error: $e');
      // ✅ FIX: Obțin limba curentă și mesajul tradus
      final languageCode = await _getCurrentLanguageCode();
      await _tts.setLanguage(languageCode); // ✅ FIX: Setează limba înainte de a vorbi
      final errorMessage = await VoiceTranslations.getErrorCouldNot('trimite solicitarea');
      await _handleError(errorMessage);
    }
  }

  Future<void> _handleDriverAccepted(Ride ride) async {
    try {
      _driverResponseTimeout?.cancel();
      _currentState = RideFlowState.driverFound;
      _pendingDriverId = ride.driverId;
      
      // ✅ NOU: Salvează rideId pentru confirmarea ulterioară a șoferului
      _currentRideId = ride.id;

      final driverDetails = _getDriverDetails(ride.driverId);
      final eta = _calculateETA();
      final driverName = driverDetails['name'] ?? 'Șoferul';
      final car = driverDetails['carModel'] ?? 'mașina';
      final carColor = driverDetails['carColor'] ?? '';
      final plate = driverDetails['licensePlate'] ?? '';

      // ✅ FIX: Obțin limba curentă și mesajul tradus
      final languageCode = await _getCurrentLanguageCode();
      await _tts.setLanguage(languageCode);
      final driverMessage = await VoiceTranslations.getDriverAcceptedMessage(driverName, car, carColor, plate, eta);
      final confirmQuestion = languageCode == 'en' 
          ? '\n\nDo you confirm that you want to continue with this driver?'
          : '\n\nConfirmați că doriți să continuați cu acest șofer?';
      final message = '$driverMessage$confirmQuestion';
      _lastSpokenMessage = message;
      await _tts.speakWithEmotion(message, VoiceEmotion.happy);
      await _startListeningForDriverAcceptance();
    } catch (e) {
      debugPrint('🚗 [RIDE_FLOW] ❌ Driver accepted error: $e');
    }
  }

  Future<void> _handleDriverDeclined(Ride ride) async {
    try {
      debugPrint('🚗 [RIDE_FLOW] Driver declined ride ${ride.id}');
      final message = 'Șoferul a refuzat cursa. Caut un alt șofer disponibil...';
      await _tts.speakWithEmotion(message, VoiceEmotion.calm);
      _currentState = RideFlowState.waitingForDriverResponse;
      onDriverResponse(ride.driverId ?? '', false);
    } catch (e) {
      debugPrint('🚗 [RIDE_FLOW] ❌ Driver declined handling error: $e');
    }
  }

  Future<void> _handleDriverEnRoute(Ride ride) async {
    try {
      _currentState = RideFlowState.driverEnRoute;
      final message = 'Șoferul este în drum către dumneavoastră și va ajunge în câteva minute.';
      await _tts.speakWithEmotion(message, VoiceEmotion.confident);
    } catch (e) {
      debugPrint('🚗 [RIDE_FLOW] ❌ Driver en route error: $e');
    }
  }

  Future<void> _handleDriverArrived(Ride ride) async {
    try {
      _currentState = RideFlowState.driverArrived;
      final message = 'Șoferul a ajuns la locația dumneavoastră! Vă rog să ieșiți pentru preluare.';
      await _tts.speakWithEmotion(message, VoiceEmotion.happy);
    } catch (e) {
      debugPrint('🚗 [RIDE_FLOW] ❌ Driver arrived error: $e');
    }
  }

  Future<void> _handleRideCompleted(Ride ride) async {
    try {
      _currentState = RideFlowState.rideCompleted;
      final message = 'Cursa s-a încheiat cu succes. Mulțumim că ați folosit FriendsRide!';
      await _tts.speakWithEmotion(message, VoiceEmotion.happy);
      await Future.delayed(const Duration(seconds: 2));
      await _handleCloseAI();
    } catch (e) {
      debugPrint('🚗 [RIDE_FLOW] ❌ Ride completed error: $e');
    }
  }

  Future<void> _startListeningForDriverAcceptance() async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      _currentState = RideFlowState.awaitingDriverAcceptance;
      await _voiceOrchestrator.listen(
        timeoutSeconds: 30,
        pauseForSeconds: 5,
      );
    } catch (e) {
      debugPrint('🚗 [RIDE_FLOW] ❌ Driver acceptance listening error: $e');
    }
  }

  Future<void> _handleDriverAcceptanceResponse(GeminiVoiceResponse response) async {
    await _voiceOrchestrator.stop();
    final driverId = _pendingDriverId ?? 'driver';

    if (_isPositiveConfirmation(response.message ?? '')) {
      _currentState = RideFlowState.rideAccepted;
      
      // ✅ FIX: Confirmă șoferul în Firestore când pasagerul confirmă
      if (_currentRideId != null && _currentRideId!.isNotEmpty) {
        try {
          await _firestoreService.passengerConfirmDriver(_currentRideId!);
          debugPrint('🚗 [RIDE_FLOW] ✅ Passenger confirmed driver in Firestore for ride: $_currentRideId');
        } catch (e) {
          debugPrint('🚗 [RIDE_FLOW] ⚠️ Error confirming driver in Firestore: $e');
          // Continuă chiar dacă confirmarea în Firestore eșuează
        }
      }
      
      // ✅ NOU: Folosește traducere
      final message = await VoiceTranslations.getDriverNotified();
      await _tts.speakWithEmotion(message, VoiceEmotion.happy);
      onDriverResponse(driverId, true);
    } else {
      _currentState = RideFlowState.driverRejected;
      final message = 'Înțeleg. Caut un alt șofer disponibil pentru dumneavoastră.';
      await _tts.speakWithEmotion(message, VoiceEmotion.calm);
      onDriverResponse(driverId, false);
    }
  }

  Future<void> _handleCloseAI() async {
    try {
      debugPrint('🚗 [RIDE_FLOW] 🚪 Closing AI...');

      _rideStatusSubscription?.cancel();
      _rideStatusSubscription = null;
      _driverResponseTimeout?.cancel();
      _driverResponseTimeout = null;
      _pendingDriverId = null;

      await _voiceOrchestrator.stop();

      _currentState = RideFlowState.idle;
      _destination = null;
      _pickup = null;
      _estimatedPrice = null;
      _availableDrivers = [];

      onCloseAI();

      debugPrint('🚗 [RIDE_FLOW] ✅ AI closed successfully');
    } catch (e) {
      debugPrint('🚗 [RIDE_FLOW] ❌ Close AI error: $e');
    }
  }



  /// 📝 Construiește notele pasagerului din conversația AI
  /// 🎯 ACEASTĂ FUNCȚIE SE FOLOSEȘTE DOAR LA CREAREA SOLICITĂRII ÎN FIREBASE
  /// 🚫 NU SE APEAZĂ AUTOMAT - DOAR CÂND SE TRIMITE SOLICITAREA
  String _buildPassengerNotes() {
    final notes = <String>[];
    
    // Adaugă informații din conversația vocală
    if (_conversationHistory.isNotEmpty) {
      notes.add('Solicitare vocală via AI Assistant');
    }
    
    if (_destination != null) {
      notes.add('Destinație confirmată vocal: $_destination');
    }
    
    if (_pickup != null) {
      notes.add('Pickup confirmat vocal: $_pickup');
    }
    
    return notes.join('. ');
  }

  /// 🔄 Monitorizează acceptarea cursei de către șofer
  /// 🎯 ACEASTĂ FUNCȚIE SE FOLOSEȘTE DOAR LA MONITORIZAREA STATUS-ULUI CURSEI ÎN FIREBASE
  /// 🚫 NU SE APEAZĂ AUTOMAT - DOAR CÂND SE MONITORIZEAZĂ CURSA
  Future<void> _monitorRideAcceptance(String rideId) async {
    try {
      debugPrint('🚗 [RIDE_FLOW] Monitoring ride acceptance for: $rideId');
      
      _rideStatusSubscription?.cancel();
      _rideStatusSubscription = _rideStreamOverride(rideId).listen((ride) {
        unawaited(_handleRideStatusUpdate(ride));
      }, onError: (error) {
        debugPrint('🚗 [RIDE_FLOW] ❌ Ride stream error: $error');
      });

      _driverResponseTimeout?.cancel();
      _driverResponseTimeout = Timer(const Duration(minutes: 5), () {
        if (_currentState == RideFlowState.waitingForDriverResponse ||
            _currentState == RideFlowState.driverFound) {
          _handleNoDriverFound();
        }
      });
      
    } catch (e) {
      debugPrint('🚗 [RIDE_FLOW] ❌ Monitoring error: $e');
    }
  }

  /// 🚗 Gestionează actualizările de status ale cursei
  Future<void> _handleRideStatusUpdate(Ride ride) async {
    debugPrint('🚗 [RIDE_FLOW] Ride status update: ${ride.status}');
    
    switch (ride.status) {
      case 'driver_found':
      case 'driver_accepted':
      case 'accepted':
        await _handleDriverAccepted(ride);
        break;
      case 'driver_rejected':
      case 'driver_declined':
        await _handleDriverDeclined(ride);
        break;
      case 'driver_en_route':
        await _handleDriverEnRoute(ride);
        break;
      case 'driver_arrived':
        await _handleDriverArrived(ride);
        break;
      case 'ride_started':
        await _handleRideStarted(ride);
        break;
      case 'ride_completed':
      case 'completed':
        await _handleRideCompleted(ride);
        break;
      case 'cancelled':
        await _handleRideCancelled(ride);
        break;
      default:
        break;
    }
  }

  /// 🚀 Cursa a început
  Future<void> _handleRideStarted(Ride ride) async {
    // ✅ FIX: Obțin limba curentă și mesajul tradus
    final languageCode = await _getCurrentLanguageCode();
    await _tts.setLanguage(languageCode);
    final message = await VoiceTranslations.getRideStartedEnjoyTrip();
    await _tts.speakWithEmotion(message, VoiceEmotion.happy);
  }

  /// ❌ Cursa anulată
  Future<void> _handleRideCancelled(Ride ride) async {
    final message = 'Cursa a fost anulată. Vă pot ajuta cu o nouă rezervare?';
    await _tts.speakWithEmotion(message, VoiceEmotion.calm);
    _resetRideFlow();
  }

  /// 😕 Niciun șofer găsit
  Future<void> _handleNoDriverFound() async {
    // ✅ NOU: Folosește traducere
    final message = await VoiceTranslations.getNoDriversAvailable();
    
    _lastSpokenMessage = message;
    await _voiceOrchestrator.stopListening();
    await _tts.speakWithEmotion(message, VoiceEmotion.calm);
    _currentState = RideFlowState.idle;
    
    debugPrint('🚗 [RIDE_FLOW] ❌ Mesaj "nu sunt șoferi" trimis utilizatorului');
  }

  /// ⏰ Calculează ETA-ul
  int _calculateETA() {
    // În implementarea reală, aceasta va veni din API-ul de tracking
    return 5; // Mock: 5 minute
  }

  /// 🔄 Resetează flow-ul pentru o nouă cursă
  void _resetRideFlow() {
    _destination = null;
    _pickup = null;
    _estimatedPrice = null;
    _availableDrivers.clear();
    _conversationHistory.clear();
    _currentState = RideFlowState.idle;
  }

  /// 📍 Obține locația curentă a utilizatorului
  /// 🎯 ACEASTĂ FUNCȚIE SE FOLOSEȘTE DOAR LA OBTINEREA LOCAȚIEI PENTRU FIREBASE
  /// 🚫 NU SE APEAZĂ AUTOMAT - DOAR CÂND SE CREEAZĂ SOLICITAREA
  /// 🌍 Obține locația curentă cu coordonate GPS reale
  Future<String> _getCurrentUserLocation() async {
    try {
      // ✅ Obține poziția GPS reală
      final position = await geolocator.Geolocator.getCurrentPosition(
        locationSettings: DeprecatedAPIsFix.createLocationSettings(
          accuracy: geolocator.LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      
      // Salvează coordonatele pentru calcul distanță
      _pickupLatitude = position.latitude;
      _pickupLongitude = position.longitude;
      
      debugPrint('🌍 [GPS] Pickup coordinates: $_pickupLatitude, $_pickupLongitude');
      
      // Convertește coordonatele în adresă
      final address = await geocoding_svc.GeocodingService().getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      return address ?? 'Locația curentă (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
      
    } catch (e) {
      debugPrint('🌍 [GPS] ❌ Error getting location: $e');
      // Fallback la București centru
      _pickupLatitude = 44.4268;
      _pickupLongitude = 26.1025;
      return 'Locația curentă';
    }
  }

  /// 🚗 Obține detaliile șoferului din ID
  Map<String, dynamic> _getDriverDetails(String? driverId) {
    if (driverId == null) {
      return {
        'name': 'necunoscut',
        'carModel': 'N/A',
        'carColor': '',
        'licensePlate': 'N/A',
        'rating': 0.0,
      };
    }
    
    // În implementarea reală, aceasta va veni din FirestoreService
    // Pentru moment, returnez date mock
    return {
      'name': 'Șofer $driverId',
      'carModel': 'Dacia Logan',
      'carColor': 'albă',
      'licensePlate': 'B 123 ABC',
      'rating': 4.8,
    };
  }

  /// 🎯 NOU: Pornește automat ascultarea pentru confirmarea finală
  Future<void> _startListeningForFinalConfirmation() async {
    try {
      debugPrint('🚗 [RIDE_FLOW] Preparing to start final confirmation listening...');
      
      // ⚠️ VERIFICĂ DACĂ DEJA ASCULTĂ - NU PORNI DIN NOU!
      if (_voiceOrchestrator.isListening) {
        debugPrint('🚗 [RIDE_FLOW] ⚠️ Already listening - SKIPPING duplicate listen session');
        return; // OPREȘTE AICI!
      }
      
      // 🎯 Oprește orice sesiune de speaking înainte
      if (_voiceOrchestrator.isSpeaking) {
        debugPrint('🚗 [RIDE_FLOW] Stopping speaking before listening...');
        await _voiceOrchestrator.stopSpeaking();
        // Așteaptă puțin după ce oprești speaking
        await Future.delayed(Duration(milliseconds: 500));
      }
      
      // 🎯 Delay mai scurt pentru că TTS deja s-a terminat înainte de acest apel
      await Future.delayed(Duration(milliseconds: 800));
      
      // ⚠️ VERIFICĂ DIN NOU - poate altcineva a pornit listening între timp
      if (_voiceOrchestrator.isListening) {
        debugPrint('🚗 [RIDE_FLOW] ⚠️ Someone else started listening - SKIPPING');
        return;
      }
      
      debugPrint('🚗 [RIDE_FLOW] ✅ Starting final confirmation listening NOW (state: $_currentState)');
      
      // ⚠️ VERIFICĂ STAREA ÎNAINTE DE A PORNI LISTENING
      if (_currentState != RideFlowState.awaitingRideConfirmation) {
        debugPrint('🚗 [RIDE_FLOW] ⚠️ Wrong state ($_currentState) - NOT starting listening');
        return;
      }
      
      // Pornește automat ascultarea pentru confirmarea finală
      await _voiceOrchestrator.listen(
        timeoutSeconds: 30, // Timp suficient pentru confirmare
        pauseForSeconds: 5, // Redus de la 10 la 5 pentru răspuns mai rapid
      );
      
    } catch (e) {
      debugPrint('🚗 [RIDE_FLOW] ⚠️ Auto-listen for final confirmation error: $e');
    }
  }

  /// 🎯 AUTONOM: Gestionează confirmarea destinației și procesează totul automat
  Future<void> _handleDestinationConfirmedResponse(GeminiVoiceResponse response) async {
    try {
      debugPrint('🚗 [RIDE_FLOW] AUTONOM: Handling destination confirmation: ${response.message}');
      
      // Salvează destinația confirmată
      _destination = response.destination ?? 'Destinație necunoscută';
      _currentState = RideFlowState.destinationConfirmed;
      
      // ✅ ACTUALIZEAZĂ UI-UL CU ADRESA ȘI COORDONATELE (dacă sunt disponibile)
      try {
        if (_destination != null && _destination!.isNotEmpty) {
          final pickup = _pickup ?? 'Locația curentă';
          onFillAddressInUI(
            pickup, 
            _destination!,
            pickupLat: _pickupLatitude,
            pickupLng: _pickupLongitude,
            destLat: _destinationLatitude,
            destLng: _destinationLongitude,
          );
          debugPrint('🎯 [RIDE_FLOW] ✅ UI updated with destination: $_destination');
          if (_destinationLatitude != null && _destinationLongitude != null) {
            debugPrint('🎯 [RIDE_FLOW] ✅ Coordinates also sent: $_destinationLatitude, $_destinationLongitude');
          }
        }
      } catch (e) {
        debugPrint('🚗 [RIDE_FLOW] ⚠️ UI update callback error: $e');
      }
      
      // 🗣️ Anunță că procesează totul automat
      // ✅ NOU: Folosește traducere
      final confirmMessage = await VoiceTranslations.getDestinationUnderstood();
      _lastSpokenMessage = confirmMessage;
      await _tts.speakWithEmotion(confirmMessage, VoiceEmotion.confident);
      
      // 🎯 AUTONOM: Procesează totul automat
      await _processRideRequestAutonomously();
      
    } catch (e) {
      debugPrint('🚗 [RIDE_FLOW] ❌ Destination confirmation error: $e');
      await _handleError('Eroare la confirmarea destinației: $e');
    }
  }

  /// 🎯 AUTONOM: Procesează complet cererea de cursă automat
  Future<void> _processRideRequestAutonomously() async {
    try {
      debugPrint('🚗 [RIDE_FLOW] AUTONOM: Starting autonomous ride processing...');
      
      // Pasul 1: Detectează locația curentă automat
      await _detectCurrentLocationAutonomously();
      
      // Pasul 2: Calculează prețul automat
      await _calculatePriceAutonomously();
      
      // Pasul 3: Caută șoferi automat
      await _searchDriversAutonomously();
      
      // Pasul 4: Selectează cel mai bun șofer automat
      await _selectBestDriverAutonomously();
      
      // Pasul 5: Confirmă automat și trimite cererea
      await _confirmAndSendRequestAutonomously();
      
      debugPrint('🚗 [RIDE_FLOW] AUTONOM: Ride processing completed successfully');
      
    } catch (e) {
      debugPrint('🚗 [RIDE_FLOW] ❌ Autonomous processing error: $e');
      await _handleError('Eroare la procesarea automată a cursei: $e');
    }
  }

  /// 🎯 AUTONOM: Detectează locația curentă automat
  Future<void> _detectCurrentLocationAutonomously() async {
    try {
      debugPrint('🚗 [RIDE_FLOW] AUTONOM: Detecting current location...');
      
      // ✅ FIX: Anunță utilizatorul că detectează locația (înainte de a face lucrul în background)
      final languageCode = await _getCurrentLanguageCode();
      await _tts.setLanguage(languageCode);
      final detectingMessage = await VoiceTranslations.getDetectingCurrentLocation();
      await _tts.speakWithEmotion(detectingMessage, VoiceEmotion.calm);
      
      // ✅ Obține GPS real și adresa
      final currentLocation = await _getCurrentUserLocation();
      _pickup = currentLocation;
      
      debugPrint('🚗 [RIDE_FLOW] AUTONOM: Current location detected: $_pickup');
      
      // ✅ Obține coordonatele destinației prin geocoding ÎMBUNĂTĂȚIT
      if (_destination != null && _destination!.isNotEmpty) {
        debugPrint('🚗 [RIDE_FLOW] AUTONOM: Geocoding destination: $_destination');
        
      // ✅ FIX: Anunță utilizatorul că verifică adresa destinației (înainte de a face lucrul în background)
      final langCode = await _getCurrentLanguageCode();
      await _tts.setLanguage(langCode);
      final verifyingMessage = await VoiceTranslations.getVerifyingDestination();
      await _tts.speakWithEmotion(verifyingMessage, VoiceEmotion.calm);
        
        // ✅ FIX: Verifică mai întâi destinațiile predefinite (rapid, fără API calls)
        final predefinedCoords = _getPredefinedDestinationCoordinates(_destination!);
        if (predefinedCoords != null) {
          _destinationLatitude = predefinedCoords['latitude'];
          _destinationLongitude = predefinedCoords['longitude'];
          debugPrint('🌍 [GPS] ✅ Destination found in predefined list: $_destinationLatitude, $_destinationLongitude');
          debugPrint('🌍 [GPS] Address: ${predefinedCoords['name']}');
          
          // Calculează distanța pentru feedback
          if (_pickupLatitude != null && _pickupLongitude != null) {
            final distanceKm = _calculateHaversineDistance(
              _pickupLatitude!,
              _pickupLongitude!,
              _destinationLatitude!,
              _destinationLongitude!,
            );
            debugPrint('🌍 [GPS] Distance to destination: ${distanceKm.toStringAsFixed(2)} km');
          }
        } else {
          // ✅ FIX: Folosește același serviciu ca AddressInputView (GeocodingService cu OSM Nominatim)
          // Acesta este serviciul care funcționează bine pentru autocomplete-ul adreselor
          // Folosește poziția curentă pentru context în geocoding
          final currentPos = geolocator.Position(
            latitude: _pickupLatitude!,
            longitude: _pickupLongitude!,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
          
          // ✅ PRIORITATE 1: GeocodingService (OSM Nominatim) - același serviciu ca AddressInputView
          List<geocoding_svc.AddressSuggestion> suggestions = [];
          
          // Încercare 1: Query original cu GeocodingService
          debugPrint('🌍 [GPS] ✅ Using GeocodingService (OSM Nominatim) - same as AddressInputView');
          suggestions = await geocoding_svc.GeocodingService().fetchSuggestions(
            _destination!,
            currentPos,
          );
          
          // Încercare 2: Dacă nu găsește, adaugă explicit "România"
          if (suggestions.isEmpty) {
            debugPrint('🌍 [GPS] Retry 1: Adding "România" to query');
            suggestions = await geocoding_svc.GeocodingService().fetchSuggestions(
              '$_destination, România',
              currentPos,
            );
          }
          
          // Încercare 3: Dacă tot nu găsește și e aproape de București, adaugă "București"
          if (suggestions.isEmpty) {
            final distanceToBucharest = _calculateHaversineDistance(
              _pickupLatitude!,
              _pickupLongitude!,
              44.4268, // București center
              26.1025,
            );
            if (distanceToBucharest < 50) { // < 50km de București
              debugPrint('🌍 [GPS] Retry 2: Adding "București" to query');
              suggestions = await geocoding_svc.GeocodingService().fetchSuggestions(
                '$_destination, București, România',
                currentPos,
              );
            }
          }
          
          // Încercare 4: Dacă e aproape de Ilfov/Bragadiru, încearcă cu "Ilfov"
          if (suggestions.isEmpty) {
            final distanceToBragadiru = _calculateHaversineDistance(
              _pickupLatitude!,
              _pickupLongitude!,
              44.3704, // Bragadiru center
              25.9661,
            );
            if (distanceToBragadiru < 20) { // < 20km de Bragadiru
              debugPrint('🌍 [GPS] Retry 3: Adding "Ilfov" to query');
              suggestions = await geocoding_svc.GeocodingService().fetchSuggestions(
                '$_destination, Ilfov, România',
                currentPos,
              );
            }
          }
          
          if (suggestions.isNotEmpty) {
            // 🎯 ÎMBUNĂTĂȚIRE CRITICĂ: Sortează după distanță și ia cea mai apropiată!
            suggestions.sort((a, b) {
              final distA = a.distanceMeters ?? double.infinity;
              final distB = b.distanceMeters ?? double.infinity;
              return distA.compareTo(distB);
            });
            
            final closest = suggestions.first;
            _destinationLatitude = closest.latitude;
            _destinationLongitude = closest.longitude;
            
            final distanceKm = (closest.distanceMeters ?? 0) / 1000;
            debugPrint('🌍 [GPS] ✅ Destination found via GeocodingService (OSM Nominatim): $_destinationLatitude, $_destinationLongitude');
            debugPrint('🌍 [GPS] Distance to destination: ${distanceKm.toStringAsFixed(2)} km');
            debugPrint('🌍 [GPS] Address: ${closest.description}');
          } else {
            // ✅ PRIORITATE 2: Dacă GeocodingService eșuează, încearcă locationFromAddress (serviciul nativ)
            debugPrint('🌍 [GPS] ⚠️ GeocodingService failed, trying locationFromAddress (native service)...');
            try {
              List<geocoding.Location> locations = await geocoding.locationFromAddress(_destination!);
              if (locations.isNotEmpty) {
                _destinationLatitude = locations.first.latitude;
                _destinationLongitude = locations.first.longitude;
                debugPrint('🌍 [GPS] ✅ Destination found via locationFromAddress: $_destinationLatitude, $_destinationLongitude');
                
                // Calculează distanța pentru feedback
                if (_pickupLatitude != null && _pickupLongitude != null) {
                  final distanceKm = _calculateHaversineDistance(
                    _pickupLatitude!,
                    _pickupLongitude!,
                    _destinationLatitude!,
                    _destinationLongitude!,
                  );
                  debugPrint('🌍 [GPS] Distance to destination: ${distanceKm.toStringAsFixed(2)} km');
                }
              } else {
                // ✅ PRIORITATE 3: Dacă locationFromAddress eșuează, încearcă cu "România" adăugat
                debugPrint('🌍 [GPS] ⚠️ locationFromAddress failed, retrying with "România"...');
                locations = await geocoding.locationFromAddress('$_destination, România');
                if (locations.isNotEmpty) {
                  _destinationLatitude = locations.first.latitude;
                  _destinationLongitude = locations.first.longitude;
                  debugPrint('🌍 [GPS] ✅ Destination found via locationFromAddress (with România): $_destinationLatitude, $_destinationLongitude');
                } else {
                  // ✅ PRIORITATE 4: Dacă tot eșuează, încearcă Gemini AI
                  debugPrint('🌍 [GPS] ⚠️ locationFromAddress failed, trying Gemini AI for address clarification and coordinates...');
                  
                  try {
                    final geminiResult = await _askGeminiForClarifiedAddress(_destination!);
                    
                    if (geminiResult != null && geminiResult['address'] != null) {
                      final clarifiedAddress = geminiResult['address'] as String;
                      final geminiLatitude = geminiResult['latitude'] as double?;
                      final geminiLongitude = geminiResult['longitude'] as double?;
                      
                      debugPrint('🌍 [GPS] ✅ Gemini AI suggested clearer address: $clarifiedAddress');
                      
                      // ✅ PRIORITATE 1: Dacă Gemini AI a oferit coordonate directe, folosește-le!
                      if (geminiLatitude != null && geminiLongitude != null) {
                        _destinationLatitude = geminiLatitude;
                        _destinationLongitude = geminiLongitude;
                        _destination = clarifiedAddress;
                        
                        // Calculează distanța pentru feedback
                        if (_pickupLatitude != null && _pickupLongitude != null) {
                          final distanceKm = _calculateHaversineDistance(
                            _pickupLatitude!,
                            _pickupLongitude!,
                            _destinationLatitude!,
                            _destinationLongitude!,
                          );
                          debugPrint('🌍 [GPS] ✅ Destination found with Gemini AI coordinates: $_destinationLatitude, $_destinationLongitude');
                          debugPrint('🌍 [GPS] Distance to destination: ${distanceKm.toStringAsFixed(2)} km');
                          debugPrint('🌍 [GPS] Address: $clarifiedAddress');
                        } else {
                          debugPrint('🌍 [GPS] ✅ Destination coordinates from Gemini AI: $_destinationLatitude, $_destinationLongitude');
                          debugPrint('🌍 [GPS] Address: $clarifiedAddress');
                        }
                      } else {
                        // ✅ PRIORITATE 2: Dacă Gemini AI nu a oferit coordonate, reîncearcă geocoding-ul cu adresa clarificată
                        debugPrint('🌍 [GPS] ⚠️ Gemini AI did not provide coordinates, retrying geocoding with clarified address...');
                        
                        // Reîncearcă geocoding-ul cu adresa clarificată de Gemini
                        suggestions = await geocoding_svc.GeocodingService().fetchSuggestions(
                          clarifiedAddress,
                          currentPos,
                        );
                        
                        // Dacă tot nu găsește, încearcă cu "România" adăugat
                        if (suggestions.isEmpty) {
                          suggestions = await geocoding_svc.GeocodingService().fetchSuggestions(
                            '$clarifiedAddress, România',
                            currentPos,
                          );
                        }
                        
                        // Dacă tot nu găsește, încearcă cu "București" adăugat
                        if (suggestions.isEmpty) {
                          final distanceToBucharest = _calculateHaversineDistance(
                            _pickupLatitude!,
                            _pickupLongitude!,
                            44.4268,
                            26.1025,
                          );
                          if (distanceToBucharest < 50) {
                            suggestions = await geocoding_svc.GeocodingService().fetchSuggestions(
                              '$clarifiedAddress, București, România',
                              currentPos,
                            );
                          }
                        }
                        
                        if (suggestions.isNotEmpty) {
                          // Sortează după distanță și ia cea mai apropiată
                          suggestions.sort((a, b) {
                            final distA = a.distanceMeters ?? double.infinity;
                            final distB = b.distanceMeters ?? double.infinity;
                            return distA.compareTo(distB);
                          });
                          
                          final closest = suggestions.first;
                          _destinationLatitude = closest.latitude;
                          _destinationLongitude = closest.longitude;
                          
                          // Actualizează destinația cu adresa clarificată
                          _destination = closest.description;
                          
                          final distanceKm = (closest.distanceMeters ?? 0) / 1000;
                          debugPrint('🌍 [GPS] ✅ Destination found with Gemini AI help (geocoding): $_destinationLatitude, $_destinationLongitude');
                          debugPrint('🌍 [GPS] Distance to destination: ${distanceKm.toStringAsFixed(2)} km');
                          debugPrint('🌍 [GPS] Address: ${closest.description}');
                        } else {
                          // Dacă nici cu Gemini AI nu găsește, anunță eroare
                          debugPrint('🌍 [GPS] ❌ ERROR: Could not geocode destination even with Gemini AI help!');
                          // ✅ NOU: Folosește traducere
                          final errorMsg = await VoiceTranslations.getAddressNotFound(_destination ?? '');
                          await _tts.speakWithEmotion(errorMsg, VoiceEmotion.calm);
                          return; // Oprește procesul
                        }
                      }
                    } else {
                      // Dacă Gemini AI nu poate ajuta, anunță eroare
                      debugPrint('🌍 [GPS] ❌ ERROR: Could not geocode destination after all retries!');
                      // ✅ FIX: Obțin limba curentă și mesajul tradus
                      final languageCode = await _getCurrentLanguageCode();
                      await _tts.setLanguage(languageCode);
                      final errorMsg = await VoiceTranslations.getAddressNotFound(_destination ?? '');
                      await _tts.speakWithEmotion(errorMsg, VoiceEmotion.calm);
                      return; // Oprește procesul
                    }
                  } catch (geminiError) {
                    debugPrint('🌍 [GPS] ❌ Error asking Gemini AI for clarification: $geminiError');
                    // Dacă Gemini AI eșuează, anunță eroare
                    final errorMsg = 'Îmi pare rău, nu am putut găsi adresa "$_destination". Vă rog să specificați o adresă mai clară sau un loc cunoscut.';
                    await _tts.speakWithEmotion(errorMsg, VoiceEmotion.calm);
                    return; // Oprește procesul
                  }
                }
              }
            } catch (e) {
              debugPrint('🌍 [GPS] ❌ Error in locationFromAddress: $e');
              // Dacă locationFromAddress eșuează, încearcă Gemini AI
              debugPrint('🌍 [GPS] ⚠️ locationFromAddress error, trying Gemini AI...');
              try {
                final geminiResult = await _askGeminiForClarifiedAddress(_destination!);
                if (geminiResult != null && geminiResult['address'] != null) {
                  final clarifiedAddress = geminiResult['address'] as String;
                  final geminiLatitude = geminiResult['latitude'] as double?;
                  final geminiLongitude = geminiResult['longitude'] as double?;
                  
                  if (geminiLatitude != null && geminiLongitude != null) {
                    _destinationLatitude = geminiLatitude;
                    _destinationLongitude = geminiLongitude;
                    _destination = clarifiedAddress;
                    debugPrint('🌍 [GPS] ✅ Destination found with Gemini AI coordinates: $_destinationLatitude, $_destinationLongitude');
                  } else {
                    debugPrint('🌍 [GPS] ❌ ERROR: Could not geocode destination after all retries!');
                    // ✅ FIX: Obțin limba curentă și mesajul tradus
                    final languageCode = await _getCurrentLanguageCode();
                    await _tts.setLanguage(languageCode);
                    final errorMsg = await VoiceTranslations.getAddressNotFound(_destination ?? '');
                    await _tts.speakWithEmotion(errorMsg, VoiceEmotion.calm);
                    return;
                  }
                } else {
                  debugPrint('🌍 [GPS] ❌ ERROR: Could not geocode destination after all retries!');
                  // ✅ FIX: Obțin limba curentă și mesajul tradus
                  final languageCode = await _getCurrentLanguageCode();
                  await _tts.setLanguage(languageCode);
                  final errorMsg = await VoiceTranslations.getAddressNotFound(_destination ?? '');
                  await _tts.speakWithEmotion(errorMsg, VoiceEmotion.calm);
                  return;
                }
              } catch (geminiError) {
                debugPrint('🌍 [GPS] ❌ Error asking Gemini AI: $geminiError');
                // ✅ FIX: Obțin limba curentă și mesajul tradus
                final languageCode = await _getCurrentLanguageCode();
                await _tts.setLanguage(languageCode);
                final errorMsg = await VoiceTranslations.getAddressNotFound(_destination ?? '');
                await _tts.speakWithEmotion(errorMsg, VoiceEmotion.calm);
                return;
              }
            }
          }
        }
      }
      
      // ✅ NU mai anunță coordonatele - doar confirmă locația
      // Anunțurile sunt simplificate mai jos
      
    } catch (e) {
      debugPrint('🚗 [RIDE_FLOW] ❌ Location detection error: $e');
      // Folosește o locație default
      _pickup = 'Locația curentă detectată automat';
      _pickupLatitude = 44.4268;
      _pickupLongitude = 26.1025;
    }
  }

  /// 🎯 AUTONOM: Calculează prețul automat
  Future<void> _calculatePriceAutonomously() async {
    try {
      debugPrint('🚗 [RIDE_FLOW] AUTONOM: Calculating price...');
      
      // ✅ FIX: Anunță utilizatorul că calculează prețul (înainte de a face lucrul în background)
      final languageCode = await _getCurrentLanguageCode();
      await _tts.setLanguage(languageCode);
      final calculatingMessage = await VoiceTranslations.getCalculatingPrice();
      await _tts.speakWithEmotion(calculatingMessage, VoiceEmotion.calm);
      
      // Calculează prețul real
      await _calculateRealPrice();
      
      debugPrint('🚗 [RIDE_FLOW] AUTONOM: Price calculated: $_estimatedPrice lei');
      
      // ✅ FIX: Obțin limba curentă și mesajul tradus
      final langCode = await _getCurrentLanguageCode();
      await _tts.setLanguage(langCode);
      final price = _estimatedPrice ?? 0.0;
      final message = await VoiceTranslations.getRidePrice(price);
      _lastSpokenMessage = message;
      await _tts.speakWithEmotion(message, VoiceEmotion.confident);
      
    } catch (e) {
      debugPrint('🚗 [RIDE_FLOW] ❌ Price calculation error: $e');
      _estimatedPrice = 15.0; // Preț default
    }
  }

  /// 🎯 AUTONOM: Caută șoferi automat
  Future<void> _searchDriversAutonomously() async {
    try {
      debugPrint('🚗 [RIDE_FLOW] AUTONOM: Searching for drivers...');
      
      // Anunță că caută șoferi
      // ✅ NOU: Folosește traducere
      final message = await VoiceTranslations.getSearchingDriversInArea();
      _lastSpokenMessage = message;
      await _tts.speakWithEmotion(message, VoiceEmotion.confident);
      
      // ✅ FIX: Folosește căutarea REALĂ de șoferi (nu simulare)
      if (_pickupLatitude == null || _pickupLongitude == null) {
        await _getCurrentUserLocation();
      }

      if (_pickupLatitude == null || _pickupLongitude == null) {
        throw Exception('Locația de preluare nu este disponibilă.');
      }

      final pickupPoint = Point(
        coordinates: Position(_pickupLongitude!, _pickupLatitude!),
      );

      // ✅ FIX: Caută șoferi reali disponibili folosind FirestoreService
      final etaResult = await _firestoreService.getNearestDriverEta(
        pickupPoint,
        _currentRideCategory,
      );

      // ✅ FIX: Verifică dacă există șoferi disponibili
      if (etaResult == null) {
        debugPrint('🚗 [RIDE_FLOW] AUTONOM: ❌ Nu sunt șoferi disponibili');
        _availableDrivers = [];
        await _handleNoDriverFound();
        return;
      }

      // ✅ FIX: Salvează informațiile despre șoferul găsit
      _availableDrivers = [
        'Șofer ${etaResult.driverId} - ${etaResult.durationInMinutes} min',
      ];
      _pendingDriverId = etaResult.driverId;
      
      debugPrint('🚗 [RIDE_FLOW] AUTONOM: ✅ Found driver: ${etaResult.driverId} (ETA: ${etaResult.durationInMinutes} min, Distance: ${etaResult.distanceInKm.toStringAsFixed(1)} km)');
      
      // Anunță rezultatul
      // ✅ NOU: Folosește traducere
      final foundMessage = await VoiceTranslations.getDriverFound(etaResult.durationInMinutes);
      _lastSpokenMessage = foundMessage;
      await _tts.speakWithEmotion(foundMessage, VoiceEmotion.confident);
      
    } catch (e) {
      debugPrint('🚗 [RIDE_FLOW] AUTONOM: ❌ Driver search error: $e');
      _availableDrivers = [];
      await _handleNoDriverFound();
    }
  }

  /// 🎯 AUTONOM: Selectează cel mai bun șofer automat
  Future<void> _selectBestDriverAutonomously() async {
    try {
      debugPrint('🚗 [RIDE_FLOW] AUTONOM: Selecting best driver...');
      
      if (_availableDrivers.isEmpty) {
        await _handleNoDriverFound();
        return;
      }
      
      // Selectează primul șofer (în aplicația reală ar folosi algoritmi de matching)
      final selectedDriver = _availableDrivers.first;
      
      debugPrint('🚗 [RIDE_FLOW] AUTONOM: Selected driver: $selectedDriver');
      
      // Anunță utilizatorul
      final message = 'Am selectat cel mai bun șofer pentru dumneavoastră.';
      _lastSpokenMessage = message;
      await _tts.speakWithEmotion(message, VoiceEmotion.confident);
      
    } catch (e) {
      debugPrint('🚗 [RIDE_FLOW] ❌ Driver selection error: $e');
      rethrow;
    }
  }

  /// 🎯 AUTONOM: Confirmă și trimite cererea automat
  Future<void> _confirmAndSendRequestAutonomously() async {
    try {
      debugPrint('🚗 [RIDE_FLOW] AUTONOM: Confirming and sending request...');
      
      // Anunță că trimite cererea
      final message = 'Trimit cererea către șofer...';
      _lastSpokenMessage = message;
      await _tts.speakWithEmotion(message, VoiceEmotion.confident);
      
      // Creează și trimite cererea
      final rideRequest = await _createCompleteRideRequest();
      final rideId = await onCreateRideRequest(rideRequest);
      
      // ✅ NOU: Salvează rideId pentru confirmarea ulterioară a șoferului
      _currentRideId = rideId;
      
      // Simulează răspunsul șoferului
      await Future.delayed(Duration(seconds: 3));
      
      // Anunță rezultatul final
      await _announceFinalResult();
      
      // Navighează la ecranul de căutare
      final searchingScreen = SearchingForDriverScreen(rideId: rideId);
      onNavigateToScreen(searchingScreen);
      
      debugPrint('🚗 [RIDE_FLOW] AUTONOM: Request sent successfully, ride ID: $rideId');
      
    } catch (e) {
      debugPrint('🚗 [RIDE_FLOW] ❌ Request confirmation error: $e');
      rethrow;
    }
  }

  /// 🎯 AUTONOM: Anunță rezultatul final utilizatorului
  Future<void> _announceFinalResult() async {
    try {
      // ✅ CORECTAT: Nu anunță rezultatul dacă nu există șoferi disponibili
      if (_availableDrivers.isEmpty) {
        debugPrint('🚗 [RIDE_FLOW] AUTONOM: Nu sunt șoferi disponibili, omițând anunțul final');
        await _handleNoDriverFound();
        return;
      }
      
      // Obține datele reale ale șoferului (dacă există)
      final selectedDriver = _availableDrivers.isNotEmpty ? _availableDrivers.first : null;
      final driverName = selectedDriver != null ? 'Șoferul' : 'Un șofer';
      final etaMinutes = 5; // Va fi actualizat cu date reale când sunt disponibile
      final price = _estimatedPrice ?? 15.0;
      final priceRounded = price.toStringAsFixed(2);
      
      // ✅ Mesajul final simplificat (fără coordonate, doar preț rotunjit)
      // ✅ NOU: Folosește traducere
      final finalMessage = await VoiceTranslations.getEverythingResolved(driverName, etaMinutes, estimatedPrice ?? 0.0);
      
      _lastSpokenMessage = finalMessage;
      await _tts.speakWithEmotion(finalMessage, VoiceEmotion.confident);
      
      debugPrint('🚗 [RIDE_FLOW] AUTONOM: Final result announced - Driver: $driverName, ETA: $etaMinutes min, Price: $priceRounded lei');
      
    } catch (e) {
      debugPrint('🚗 [RIDE_FLOW] ❌ Final announcement error: $e');
    }
  }
  
  /// 🎯 Obține locația GPS curentă și confirmă pickup-ul
  /// DEPRECATED: Această metodă nu mai este folosită în fluxul autonom
  // ignore: unused_element
  Future<void> _getCurrentLocationAndConfirm() async {
    try {
      debugPrint('🚗 [RIDE_FLOW] Getting current GPS location...');
      
      // Simulează obținerea locației GPS (în aplicația reală ar folosi Geolocator)
      // Pentru demo, folosim o locație fixă
      final currentLocation = 'Piața Unirii, București';
      _pickup = currentLocation;
      
      // Așteaptă puțin pentru efectul de "detectare"
      await Future.delayed(Duration(milliseconds: 2000));
      
      // 🗣️ Confirmă locația detectată și cere confirmarea
      final confirmMessage = 'Vă detectez la $currentLocation. Preluarea se face de la această locație?';
      _lastSpokenMessage = confirmMessage;
      await _tts.speakWithEmotion(confirmMessage, VoiceEmotion.confident);
      
      // Actualizează starea pentru confirmarea pickup-ului
      _currentState = RideFlowState.awaitingConfirmation;
      
      // Pornește ascultarea pentru confirmarea pickup-ului
      await _startListeningForPickupConfirmation();
      
    } catch (e) {
      debugPrint('🚗 [RIDE_FLOW] ❌ GPS location error: $e');
      await _handleError('Eroare la detectarea locației: $e');
    }
  }
  
  /// 🎯 Pornește ascultarea pentru confirmarea pickup-ului
  Future<void> _startListeningForPickupConfirmation() async {
    try {
      // Așteaptă puțin să se termine TTS-ul complet
      await Future.delayed(Duration(milliseconds: 1500));
      
      debugPrint('🚗 [RIDE_FLOW] Auto-starting pickup confirmation listening...');
      
      // Pornește automat ascultarea pentru confirmarea pickup-ului
      await _voiceOrchestrator.listen(
        timeoutSeconds: 30, // Timp suficient pentru confirmare
        pauseForSeconds: 10,
      );
      
    } catch (e) {
      debugPrint('🚗 [RIDE_FLOW] ⚠️ Auto-listen for pickup confirmation error: $e');
    }
  }

  /// 🛑 Oprește procesarea
  Future<void> stop() async {
    try {
      debugPrint('🚗 [RIDE_FLOW] Stopping...');
      await _tts.stop();
      _currentState = RideFlowState.idle;
      debugPrint('🚗 [RIDE_FLOW] ✅ Stopped successfully');
    } catch (e) {
      debugPrint('🚗 [RIDE_FLOW] ❌ Stop error: $e');
    }
  }
  
  /// 🧹 Cleanup - MEMORY LEAK PREVENTION
  void dispose() {
    // ✅ Cancel all subscriptions
    _rideStatusSubscription?.cancel();
    _rideStatusSubscription = null;
    
    // ✅ Cancel all timers
    _driverResponseTimeout?.cancel();
    _driverResponseTimeout = null;
    
    // ✅ Stop voice orchestrator
    try {
      _voiceOrchestrator.stop();
    } catch (e) {
      debugPrint('🚗 [RIDE_FLOW] Error stopping voice orchestrator: $e');
    }
    
    // ✅ Dispose TTS
    try {
      _tts.dispose();
    } catch (e) {
      debugPrint('🚗 [RIDE_FLOW] Error disposing TTS: $e');
    }
    
    // ✅ Dispose beep service
    try {
      _beepService.dispose();
    } catch (e) {
      debugPrint('🚗 [RIDE_FLOW] Error disposing beep service: $e');
    }
    
    // ✅ Clear conversation history to free memory
    _conversationHistory.clear();
    _availableDrivers.clear();
    
    // ✅ Reset state
    _currentState = RideFlowState.idle;
    _destination = null;
    _pickup = null;
    _estimatedPrice = null;
    _pendingDriverId = null;
    _lastSpokenMessage = '';
    _calculatedDistanceKm = null;
    _calculatedDurationMinutes = null;
    _fareBreakdown = null;
    _pickupLatitude = null;
    _pickupLongitude = null;
    _destinationLatitude = null;
    _destinationLongitude = null;
    
    debugPrint('🚗 [RIDE_FLOW] ✅ Dispose completed - all resources cleaned up');
  }
}
