import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // Comentat temporar

// Existing FriendsRide services
import '../../services/firestore_service.dart';
// import '../../services/pricing_service.dart'; // Comentat temporar
import '../../models/ride_model.dart';
import '../../models/voice_models.dart';

// New Voice AI System
import '../states/voice_interaction_states.dart';
import '../passenger/passenger_voice_controller.dart';


/// 🎯 FriendsRide Voice Integration - Sistemul vocal complet integrat cu aplicația
/// 
/// Caracteristici:
/// - Integrare perfectă cu serviciile existente FriendsRide
/// - Gemini AI pentru procesarea comenzilor vocale
/// - Flow complet pentru ride sharing end-to-end
/// - State management sincronizat cu UI-ul
class FriendsRideVoiceIntegration extends ChangeNotifier {
  // 🧠 Componentele AI vocale (lazy init)
  PassengerVoiceController? _voiceController;
  
  // 🚗 Serviciile FriendsRide existente
  final FirestoreService _firestoreService = FirestoreService();
  // final PricingService _pricingService = PricingService(); // Comentat temporar

  
  // 🎯 Starea curentă a sistemului vocal
  VoiceConversationContext _currentContext = VoiceConversationContext(
    rideState: RideFlowState.idle,
    processingState: VoiceProcessingState.idle,
            currentEmotion: VoiceEmotion.friendly,
    conversationHistory: [],
    availableDrivers: [],
    lastInteractionTime: DateTime.now(),
    lastConfidenceLevel: 1.0,
  );
  
  // 🚀 Starea inițializării
  bool _isInitialized = false;
  bool _isInitializing = false;
  
  // 🎤 Starea interacțiunii vocale
  bool _isVoiceActive = false;
  final bool _isListening = false;
  final bool _isSpeaking = false;

  // 🎧 Continuous listening state
  bool _isContinuousListeningActive = false;
  Timer? _continuousListeningTimer;
  // bool _isFirstInteraction = true; // not used currently

  // 🔁 Voice → UI event bridge
  String? _voiceDestination;
  String? _voicePickup;
  bool _hasNewVoiceDestination = false;
  bool _hasNewVoicePickup = false;
  
  // 🚗 Datele cursei curente
  RideRequest? _currentRideRequest;
  RideOffer? _currentRideOffer;
  Ride? _currentRide;
  
  // 🎯 Callback pentru navigare (comentat temporar)
  // Function(String)? _navigationCallback;
  
  // 🎯 Constructor
  FriendsRideVoiceIntegration();
  
  /// 🚀 Inițializează toate componentele vocale
  Future<void> _initializeComponents() async {
    if (_isInitializing || _isInitialized) return;
    
    try {
      _isInitializing = true;
      debugPrint('🎯 [FRIENDSRIDE_VOICE] Initializing components...');
      
      // ✅ Inițializez controller-ul vocal cu toate dependințele
      _voiceController = PassengerVoiceController(
        firestoreService: _firestoreService,
      );
      await _voiceController!.initialize();
      debugPrint('🎯 [FRIENDSRIDE_VOICE] ✅ Voice controller initialized');
      
      // 🎯 În final: Setez callback-urile
      _setupCallbacks();
      
      _isInitialized = true;
      _isInitializing = false;
      
      debugPrint('🎯 [FRIENDSRIDE_VOICE] ✅ All components initialized successfully');
      
    } catch (e) {
      debugPrint('🎯 [FRIENDSRIDE_VOICE] ❌ Initialization error: $e');
      _isInitializing = false;
      _isInitialized = false;
    }
  }

  /// 🚀 Public warm-up API for lazy background initialization
  Future<void> warmUp() async {
    try {
      await _initializeComponents();
    } catch (e) {
      debugPrint('🎯 [FRIENDSRIDE_VOICE] warmUp error: $e');
    }
  }
  
  /// 🎯 Setez callback-urile pentru toate componentele
  void _setupCallbacks() {
    // 🎤 Periodic bridge: sync conversation, processing state, and address events
    Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (!_isInitialized || !_isVoiceActive || _voiceController == null) return;
      try {
        // Sync history
        final history = _voiceController!.conversationHistory;
        if (history.isNotEmpty && history != _currentContext.conversationHistory) {
          _currentContext = _currentContext.copyWith(
            conversationHistory: history,
            lastInteractionTime: DateTime.now(),
          );
          notifyListeners();
        }

        // Sync processing state
        final p = _voiceController!.processingState;
        if (p != _currentContext.processingState) {
          _currentContext = _currentContext.copyWith(
            processingState: p,
            lastInteractionTime: DateTime.now(),
          );
          notifyListeners();
        }

        // Address events
        final dest = _voiceController!.destinationAddressForUI;
        if (dest != null && dest != _voiceDestination) {
          _voiceDestination = dest;
          _hasNewVoiceDestination = true;
          notifyListeners();
        }
        final pick = _voiceController!.pickupAddressForUI;
        if (pick != null && pick != _voicePickup) {
          _voicePickup = pick;
          _hasNewVoicePickup = true;
          notifyListeners();
        }
      } catch (_) {}
    });
  }

  /// 🎯 Setează callback-ul pentru navigare
  void setNavigationCallback(Function(String) callback) {
          // _navigationCallback = callback; // Comentat temporar
  }
  
    // 🎤 Callback-urile sunt gestionate de controller-ul vocal
  
  // 🎤 Contextul este gestionat de controller-ul vocal
  
  // 🚀 Procesarea input-ului vocal este gestionată de controller-ul vocal
  
  // 📝 Contextul este actualizat automat de controller-ul vocal
  
  // 🎯 Starea cursei este gestionată de controller-ul vocal
  
  // 🚗 Integrarea cu serviciile FriendsRide este gestionată de controller-ul vocal
  
    // 🎯 Destinația confirmată este gestionată de controller-ul vocal
  
  // 🚗 Șoferii găsiți sunt gestionați de controller-ul vocal
  
  // 🚗 Toate aceste operații sunt gestionate de controller-ul vocal
  
  /// 🎯 Gestionează erorile
  void _handleError(String error) {
    debugPrint('🎯 [FRIENDSRIDE_VOICE] ❌ Error: $error');
    
    _currentContext = _currentContext.copyWith(
      rideState: RideFlowState.error,
      processingState: VoiceProcessingState.error,
      lastInteractionTime: DateTime.now(),
    );
    
    notifyListeners();
  }
  
  /// 🎤 Începe interacțiunea vocală
  Future<void> startVoiceInteraction() async {
    if (!_isInitialized) {
      await _initializeComponents();
    }
    
    try {
      debugPrint('🎯 [FRIENDSRIDE_VOICE] Starting voice interaction...');
      
      _isVoiceActive = true;
      // _isFirstInteraction = true;

      // Instant greeting in UI (AUTONOM)
      const greetingMessage = 'Salutare! Sunt asistentul vocal FriendsRide. Spune-mi doar unde vrei să mergi și mă ocup eu de tot - caut șoferi, calculez prețul și fac rezervarea. Unde doriți să mergeți?';
      _currentContext = _currentContext.copyWith(
        conversationHistory: [..._currentContext.conversationHistory, 'AI: $greetingMessage'],
        rideState: RideFlowState.listeningForInitialCommand,
        processingState: VoiceProcessingState.speaking,
        currentEmotion: VoiceEmotion.friendly,
        lastInteractionTime: DateTime.now(),
      );
      notifyListeners();

      // TTS + initial listen
      await _voiceController!.startContinuousConversation();

      // Start continuous loop
      await _startContinuousListening();

      // Actualizează contextul
      _currentContext = _currentContext.copyWith(
        rideState: RideFlowState.listeningForInitialCommand,
        processingState: VoiceProcessingState.listening,
        currentEmotion: VoiceEmotion.friendly,
        lastInteractionTime: DateTime.now(),
      );

      notifyListeners();
      
    } catch (e) {
      debugPrint('🎯 [FRIENDSRIDE_VOICE] ❌ Start voice interaction error: $e');
      _handleError(e.toString());
    }
  }
  
  /// 🛑 Oprește interacțiunea vocală
  Future<void> stopVoiceInteraction() async {
    try {
      debugPrint('🎯 [FRIENDSRIDE_VOICE] Stopping voice interaction...');
      
      _isVoiceActive = false;
      await _stopContinuousListening();
      
      // Verifică dacă componentele sunt inițializate înainte să le oprești
      if (_isInitialized && _voiceController != null) {
        _voiceController!.reset();
      }
      
      _currentContext = _currentContext.copyWith(
        rideState: RideFlowState.idle,
        processingState: VoiceProcessingState.idle,
        lastInteractionTime: DateTime.now(),
      );
      
      notifyListeners();
      
    } catch (e) {
      debugPrint('🎯 [FRIENDSRIDE_VOICE] ❌ Stop voice interaction error: $e');
      // În caz de eroare, forțează resetarea
      _currentContext = _currentContext.copyWith(
        rideState: RideFlowState.idle,
        processingState: VoiceProcessingState.idle,
        lastInteractionTime: DateTime.now(),
      );
      notifyListeners();
    }
  }

  /// 🔁 Continuous listening loop: relaunch listen sessions when idle (CORECTAT)
  Future<void> _startContinuousListening() async {
    if (_isContinuousListeningActive) return;
    _isContinuousListeningActive = true;
    _continuousListeningTimer?.cancel();
    _continuousListeningTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!_isContinuousListeningActive || !_isVoiceActive || _voiceController == null) {
        timer.cancel();
        return;
      }
      try {
        final state = _currentContext.processingState;
        // CORECTAT: Verifică doar starea idle, nu waiting (care poate fi folosită pentru sincronizare)
        if (state == VoiceProcessingState.idle) {
          // CORECTAT: Verifică dacă VoiceOrchestrator nu este deja în proces de ascultare sau vorbire
          final voiceOrchestrator = _voiceController!.voiceOrchestrator;
          if (voiceOrchestrator.isAvailable) {
            debugPrint('🎯 [FRIENDSRIDE_VOICE] Auto-starting listening (state: $state)');
            _currentContext = _currentContext.copyWith(
              processingState: VoiceProcessingState.listening,
              lastInteractionTime: DateTime.now(),
            );
            notifyListeners();
            await _voiceController!.listenOnce(timeoutSeconds: 30, pauseForSeconds: 3, localeId: 'ro_RO');
          } else {
            debugPrint('🎯 [FRIENDSRIDE_VOICE] VoiceOrchestrator not available (listening: ${voiceOrchestrator.isListening}, speaking: ${voiceOrchestrator.isSpeaking})');
          }
        }
      } catch (e) {
        debugPrint('🎯 [FRIENDSRIDE_VOICE] Continuous listening error: $e');
      }
    });
  }

  Future<void> _stopContinuousListening() async {
    _isContinuousListeningActive = false;
    _continuousListeningTimer?.cancel();
    _continuousListeningTimer = null;
  }
  
  // 🎯 Reset-ul sistemului vocal este gestionat de controller-ul vocal
  
    // 📍 Locația curentă și calculul prețului sunt gestionate de controller-ul vocal
  
  // 🔍 Căutarea șoferilor și crearea ride-ului sunt gestionate de controller-ul vocal
  
  // 🎤 Getters pentru UI
  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;
  bool get isVoiceActive => _isVoiceActive;
  bool get isContinuousListeningActive => _isContinuousListeningActive;
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  String? get voiceDestination => _voiceDestination;
  String? get voicePickup => _voicePickup;
  bool get hasNewVoiceDestination => _hasNewVoiceDestination;
  bool get hasNewVoicePickup => _hasNewVoicePickup;

  /// Mark voice events as processed
  void markVoiceEventsProcessed() {
    _hasNewVoiceDestination = false;
    _hasNewVoicePickup = false;
  }

  /// Update booking progress into chat
  void updateBookingProgress(String message) {
    _currentContext = _currentContext.copyWith(
      conversationHistory: [..._currentContext.conversationHistory, 'AI: $message'],
      lastInteractionTime: DateTime.now(),
    );
    notifyListeners();
  }
  
  /// 🎯 Obține contextul curent
  VoiceConversationContext get currentContext => _currentContext;
  
  /// 🚗 Obține ride request-ul curent
  RideRequest? get currentRideRequest => _currentRideRequest;
  
  /// 🚗 Obține ride offer-ul curent
  RideOffer? get currentRideOffer => _currentRideOffer;
  
  /// 🚗 Obține ride-ul curent
  Ride? get currentRide => _currentRide;
  
  /// 🚗 Gestionează cererea de cursă
  Future<void> handleRideRequest(Map<String, dynamic> rideData) async {
    try {
      debugPrint('🎯 [FRIENDSRIDE_VOICE] Handling ride request...');
      
      if (_voiceController != null) {
        await _voiceController!.processVoiceInput('confirm ride request');
      }
      
      // Actualizează contextul
      _currentContext = _currentContext.copyWith(
        rideState: RideFlowState.listeningForInitialCommand,
        lastInteractionTime: DateTime.now(),
      );
      notifyListeners();
      
    } catch (e) {
      debugPrint('🎯 [FRIENDSRIDE_VOICE] ❌ Ride request error: $e');
      _handleError(e.toString());
    }
  }
  
  /// 📍 Procesează comanda de locație
  Future<void> processLocationCommand(String locationCommand) async {
    try {
      debugPrint('🎯 [FRIENDSRIDE_VOICE] Processing location command: $locationCommand');
      
      if (_voiceController != null) {
        await _voiceController!.processVoiceInput(locationCommand);
      }
      
      // Actualizează contextul
      _currentContext = _currentContext.copyWith(
        rideState: RideFlowState.listeningForInitialCommand,
        lastInteractionTime: DateTime.now(),
      );
      notifyListeners();
      
    } catch (e) {
      debugPrint('🎯 [FRIENDSRIDE_VOICE] ❌ Location command error: $e');
      _handleError(e.toString());
    }
  }
  
  /// 🔄 Execută fluxul complet de cursă
  Future<void> executeRideFlow() async {
    try {
      debugPrint('🎯 [FRIENDSRIDE_VOICE] Executing ride flow...');
      
      if (_voiceController != null) {
        await _voiceController!.processVoiceInput('execute ride flow');
      }
      
      // Actualizează contextul
      _currentContext = _currentContext.copyWith(
        rideState: RideFlowState.listeningForInitialCommand,
        lastInteractionTime: DateTime.now(),
      );
      notifyListeners();
      
    } catch (e) {
      debugPrint('🎯 [FRIENDSRIDE_VOICE] ❌ Ride flow execution error: $e');
      _handleError(e.toString());
    }
  }

  /// 🧹 Cleanup
  @override
  void dispose() {
    // VoiceOrchestrator-ul este gestionat de controller-ul vocal
    _voiceController?.dispose();
    // TTS-ul este gestionat de controller-ul vocal
    super.dispose();
  }
}

/// 🎯 Provider pentru FriendsRide Voice Integration
class FriendsRideVoiceIntegrationProvider extends ChangeNotifierProvider<FriendsRideVoiceIntegration> {
  FriendsRideVoiceIntegrationProvider({
    super.key,
    super.child,
  }) : super(
    create: (context) => FriendsRideVoiceIntegration(),
  );
  
  }
