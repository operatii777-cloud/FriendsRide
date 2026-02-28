import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../tts/natural_voice_synthesizer.dart' as synthesizer;
import '../states/voice_interaction_states.dart';
import '../../services/audio_beep_service.dart';

/// 🎤 Voice Orchestrator - Funcționează EXACT ca Gemini Voice
/// 
/// Caracteristici:
/// - STT perfect (Speech-to-Text)
/// - TTS natural (Text-to-Speech)
/// - Integrare perfectă cu Gemini AI
/// - Flow-ul conversației natural
/// - 🚀 SINGLETON: O singură instanță pentru performanță optimă
class VoiceOrchestrator {
  // 🚀 SINGLETON PATTERN - evită inițializări multiple
  static final VoiceOrchestrator _instance = VoiceOrchestrator._internal();
  factory VoiceOrchestrator() => _instance;
  VoiceOrchestrator._internal();

  // 🎤 Lazy-initialized services
  stt.SpeechToText? _speechToText;
  synthesizer.NaturalVoiceSynthesizer? _naturalTts;
  AudioBeepService? _beepService;
  
  stt.SpeechToText get speechToText => _speechToText ??= stt.SpeechToText();
  synthesizer.NaturalVoiceSynthesizer get naturalTts => _naturalTts ??= synthesizer.NaturalVoiceSynthesizer();
  AudioBeepService get beepService => _beepService ??= AudioBeepService();
  
  // 🎯 Starea curentă
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  
  // 🎤 Callback-uri pentru UI
  Function(String)? _onSpeechResult;
  Function(String)? _onSpeechError;
  Function(VoiceProcessingState)? _onStateChange;
  
  // 🎯 NOU: Callback pentru completarea TTS
  Function()? _onTtsCompleted;
  
  // 🎯 NOU: Manager-ul pentru conversația vocală
  VoiceConversationManager? _conversationManager;
  
  /// 🎤 Setez callback-ul pentru rezultatul speech
  void setSpeechResultCallback(Function(String) callback) {
    _onSpeechResult = callback;
  }
  
  /// 🎤 Setez callback-ul pentru erorile speech
  void setSpeechErrorCallback(Function(String) callback) {
    _onSpeechError = callback;
  }
  
  /// 🎤 Setez callback-ul pentru schimbările de stare
  void setStateChangeCallback(Function(VoiceProcessingState) callback) {
    _onStateChange = callback;
  }
  
  /// 🎯 NOU: Setez callback-ul pentru completarea TTS
  void setTtsCompletedCallback(Function() callback) {
    _onTtsCompleted = callback;
  }
  
  /// 🎯 NOU: Setez manager-ul pentru conversația vocală
  void setConversationManager(VoiceConversationManager manager) {
    _conversationManager = manager;
  }
  
  /// 🗣️ Getter public pentru motorul TTS
  synthesizer.NaturalVoiceSynthesizer get tts => naturalTts;
  
  /// 🚀 Inițializează orchestratorul (o singură dată pentru singleton)
  Future<void> initialize() async {
    // 🚀 SINGLETON: Evită re-inițializarea dacă deja e gata
    if (_isInitialized) return;
    
    try {
      debugPrint('🎤 [VOICE_ORCHESTRATOR] Initializing (singleton)...');
      
      // 🎤 Inițializez STT
      final sttAvailable = await speechToText.initialize(
        onError: (error) {
          _onSpeechError?.call(error.errorMsg);
        },
        onStatus: (status) {
          _updateState(_getStateFromStatus(status));
        },
      );
      
      if (!sttAvailable) {
        throw Exception('Speech recognition not available');
      }
      
      // 🗣️ Inițializez TTS natural
      await naturalTts.initialize();
      
      // 🔔 Inițializez serviciul de beep-uri
      await beepService.initialize();
      
      _isInitialized = true;
      debugPrint('🎤 [VOICE_ORCHESTRATOR] ✅ Initialized (singleton)');
      
    } catch (e) {
      debugPrint('🎤 [VOICE_ORCHESTRATOR] ❌ Initialization error: $e');
      _isInitialized = false;
      rethrow;
    }
  }
  
  /// 🎧 Ascultă input-ul vocal EXACT ca Gemini Voice
  Future<String?> listen({
    int timeoutSeconds = 15,
    int pauseForSeconds = 5,
    String localeId = 'ro_RO',
    bool partialResults = true,
  }) async {
    if (!_isInitialized) {
      debugPrint('🎤 [VOICE_ORCHESTRATOR] ⚠️ Not initialized, initializing now...');
      await initialize();
    }
    
    if (_isListening) {
      debugPrint('🎤 [VOICE_ORCHESTRATOR] ⚠️ Already listening, stopping current session...');
      await stopListening();
    }
    // Blocare: așteaptă ca TTS să termine (din orice instanță)
    int ttsWaitMs = 0;
    while (_isSpeaking || naturalTts.isSpeaking) {
      await Future.delayed(Duration(milliseconds: 100));
      ttsWaitMs += 100;
      if (ttsWaitMs > 5000) break; // Timeout 5s
    }
    // Buffer suplimentar post-TTS
    await Future.delayed(Duration(milliseconds: 300));
    
    // ✅ FIX: Also wait for the shared NaturalVoiceSynthesizer to finish if it
    // is currently speaking (e.g. called directly from RideFlowManager).
    if (naturalTts.isSpeaking) {
      debugPrint('🎤 [VOICE_ORCHESTRATOR] ⚠️ TTS still active, waiting for it to finish...');
      while (naturalTts.isSpeaking) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      // Wait an extra 300 ms after speech ends so the mic doesn't capture
      // the tail end of the TTS audio as user input.
      await Future.delayed(const Duration(milliseconds: 300));
    }
    
    try {
      _isListening = true;
      _updateState(VoiceProcessingState.listening);
      
      debugPrint('🎤 [VOICE_ORCHESTRATOR] Starting to listen with timeout: ${timeoutSeconds}s');
      
      // 🔔 BEEP de "acum te ascult" - utilizatorul știe când să vorbească
      await beepService.playListeningStartBeep();
      
      // 🎤 Încep să ascult cu parametrii optimizați
      await speechToText.listen(
        localeId: localeId,
        listenFor: Duration(seconds: timeoutSeconds),
        pauseFor: Duration(seconds: pauseForSeconds),
        // partialResults: partialResults, // ❌ Deprecated
        onResult: (result) {
          if (result.finalResult) {
            debugPrint('🎤 [VOICE_ORCHESTRATOR] Final result: "${result.recognizedWords}"');
            
            // 🔔🔔 Beep-uri duble când AI procesează informația
            beepService.playProcessingStartBeeps();
            
            _onSpeechResult?.call(result.recognizedWords);
          } else if (partialResults) {
            debugPrint('🎤 [VOICE_ORCHESTRATOR] Partial: "${result.recognizedWords}"');
          }
        },
      );
      
      // 🎯 Aștept să se termine sesiunea
      while (_isListening) {
        await Future.delayed(Duration(milliseconds: 100));
      }
      
      debugPrint('🎤 [VOICE_ORCHESTRATOR] ✅ Listening session completed');
      return null; // Rezultatul vine prin callback
      
    } catch (e) {
      debugPrint('🎤 [VOICE_ORCHESTRATOR] ❌ Listening error: $e');
      _isListening = false;
      _updateState(VoiceProcessingState.error);
      _onSpeechError?.call(e.toString());
      return null;
    }
  }
  
  /// 🗣️ Vorbește textul EXACT ca Gemini Voice
  Future<void> speak(String text, {VoiceEmotion emotion = VoiceEmotion.confident}) async {
    if (!_isInitialized) {
      debugPrint('🎤 [VOICE_ORCHESTRATOR] ⚠️ Not initialized, initializing now...');
      await initialize();
    }
    
    if (_isListening) {
      debugPrint('🎤 [VOICE_ORCHESTRATOR] ⚠️ Currently listening, stopping...');
      await stopListening();
    }
    if (_isSpeaking || naturalTts.isSpeaking) {
      debugPrint('🎤 [VOICE_ORCHESTRATOR] ⚠️ Already speaking (TTS), stopping current speech...');
      await stopSpeaking();
      int ttsWaitMs = 0;
      while (_isSpeaking || naturalTts.isSpeaking) {
        await Future.delayed(Duration(milliseconds: 100));
        ttsWaitMs += 100;
        if (ttsWaitMs > 5000) break;
      }
    }
    
    try {
      _isSpeaking = true;
      _updateState(VoiceProcessingState.speaking);
      
      debugPrint('🎤 [VOICE_ORCHESTRATOR] Speaking: "$text"');
      
      // 🗣️ Vorbește cu emoția specificată
      await naturalTts.speakWithEmotion(text, emotion);
      
      _isSpeaking = false;
      _updateState(VoiceProcessingState.idle);
      
      // 🎯 NOU: Notifică că TTS-ul s-a terminat
      _onTtsCompleted?.call();
      
      debugPrint('🎤 [VOICE_ORCHESTRATOR] ✅ Speech completed');
      
    } catch (e) {
      debugPrint('🎤 [VOICE_ORCHESTRATOR] ❌ Speech error: $e');
      _isSpeaking = false;
      _updateState(VoiceProcessingState.error);
      _onSpeechError?.call(e.toString());
    }
  }
  
  /// 🗣️ Vorbește textul cu prioritate înaltă
  Future<void> speakPriority(String text) async {
            await speak(text, emotion: VoiceEmotion.urgent);
  }
  
  /// 🗣️ Vorbește textul cu pauze naturale și sincronizare perfectă
  Future<void> speakWithNaturalPauses(String text) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (_isListening) {
      await stopListening();
    }
    
    if (_isSpeaking) {
      await stopSpeaking();
    }
    
    try {
      _isSpeaking = true;
      _updateState(VoiceProcessingState.speaking);
      
      debugPrint('🎤 [VOICE_ORCHESTRATOR] 🗣️ Speaking: "$text"');
      
      await naturalTts.speakWithNaturalPauses(text);
      
      _isSpeaking = false;
      _updateState(VoiceProcessingState.idle);
      
      debugPrint('🎤 [VOICE_ORCHESTRATOR] ✅ Speech completed, transitioning to listening...');
      
      // 🎯 NOU: Notifică că TTS-ul s-a terminat
      _onTtsCompleted?.call();
      
      // 🔔 Beep după conversația AI - utilizatorul știe că trebuie să răspundă
      beepService.playConversationEndBeep();
      
      // 🎯 AUTOMAT: Pornește ascultarea imediat după ce AI termină de vorbit
      await _startAutomaticListening();
      
    } catch (e) {
      debugPrint('🎤 [VOICE_ORCHESTRATOR] ❌ Natural pauses speech error: $e');
      _isSpeaking = false;
      _updateState(VoiceProcessingState.error);
    }
  }
  
  /// 🛑 Oprește ascultarea
  Future<void> stopListening() async {
    try {
      if (_isListening) {
        await speechToText.stop();
        _isListening = false;
        _updateState(VoiceProcessingState.idle);
        debugPrint('🎤 [VOICE_ORCHESTRATOR] Listening stopped');
      }
    } catch (e) {
      debugPrint('🎤 [VOICE_ORCHESTRATOR] ❌ Stop listening error: $e');
    }
  }
  
  /// 🛑 Oprește vorbirea
  Future<void> stopSpeaking() async {
    try {
      if (_isSpeaking) {
        await naturalTts.stop();
        _isSpeaking = false;
        _updateState(VoiceProcessingState.idle);
        debugPrint('🎤 [VOICE_ORCHESTRATOR] Speech stopped');
      }
    } catch (e) {
      debugPrint('🎤 [VOICE_ORCHESTRATOR] ❌ Stop speech error: $e');
    }
  }
  
  /// 🛑 Oprește tot
  Future<void> stop() async {
    await stopListening();
    await stopSpeaking();
    _updateState(VoiceProcessingState.idle);
  }
  
  /// ⏸️ Pune listening-ul pe pauză temporar (nu oprește complet)
  Future<void> pauseListening() async {
    try {
      if (_isListening) {
        await speechToText.stop();
        debugPrint('🎤 [VOICE_ORCHESTRATOR] Listening paused (temporarily)');
      }
    } catch (e) {
      debugPrint('🎤 [VOICE_ORCHESTRATOR] ❌ Pause listening error: $e');
    }
  }
  
  /// ▶️ Reia listening-ul după pauză
  Future<void> resumeListening({String localeId = 'ro_RO', int timeoutSeconds = 30, int pauseForSeconds = 10}) async {
    try {
      if (!_isListening) {
        _isListening = true;
        _updateState(VoiceProcessingState.listening);
        
        await speechToText.listen(
          localeId: localeId,
          listenFor: Duration(seconds: timeoutSeconds),
          pauseFor: Duration(seconds: pauseForSeconds),
          onResult: (result) {
            if (result.finalResult) {
              debugPrint('🎤 [VOICE_ORCHESTRATOR] Final result: "${result.recognizedWords}"');
              beepService.playProcessingStartBeeps();
              _onSpeechResult?.call(result.recognizedWords);
            }
          },
        );
        
        debugPrint('🎤 [VOICE_ORCHESTRATOR] Listening resumed');
      }
    } catch (e) {
      debugPrint('🎤 [VOICE_ORCHESTRATOR] ❌ Resume listening error: $e');
      _isListening = false;
      _updateState(VoiceProcessingState.idle);
    }
  }
  

  
  /// 🎯 Actualizează starea și notifică UI-ul
  void _updateState(VoiceProcessingState newState) {
    _onStateChange?.call(newState);
  }
  
  /// 🎯 Convertește status-ul STT în starea noastră
  VoiceProcessingState _getStateFromStatus(String status) {
    switch (status) {
      case 'listening':
        return VoiceProcessingState.listening;
      case 'notListening':
        return VoiceProcessingState.idle;
      case 'done':
        return VoiceProcessingState.idle;
      case 'error':
        return VoiceProcessingState.error;
      default:
        return VoiceProcessingState.idle;
    }
  }
  
  /// 🎯 Verifică dacă e inițializat
  bool get isInitialized => _isInitialized;
  
  /// 🎧 Verifică dacă ascultă
  bool get isListening => _isListening;
  
  /// 🗣️ Verifică dacă vorbește (include TTS)
  bool get isSpeaking => _isSpeaking || naturalTts.isSpeaking;
  
<<<<<<< HEAD
  /// 🎯 Verifică dacă e disponibil (blochează dacă TTS/STT activ)
=======
  /// 🎯 Verifică dacă e disponibil
  // ✅ FIX: Also check naturalTts.isSpeaking so the continuous-listen loop
  // does not start a new STT session while TTS (called from RideFlowManager)
  // is still playing back a response.
>>>>>>> 17be32b9bbe521f758ac88fcacde49deb5401cc8
  bool get isAvailable => _isInitialized && !_isListening && !_isSpeaking && !naturalTts.isSpeaking;
  
  /// 🎯 AUTOMAT: Pornește ascultarea imediat după TTS
  Future<void> _startAutomaticListening() async {
    try {
      debugPrint('🎤 [VOICE_ORCHESTRATOR] 🎧 Starting automatic listening after TTS...');
      
      // Așteaptă puțin pentru ca utilizatorul să proceseze mesajul
      await Future.delayed(Duration(milliseconds: 800));
      
      // Verifică dacă nu sunt deja în proces de ascultare
      if (!_isListening && !_isSpeaking) {
        await listen(
          timeoutSeconds: 30,
          localeId: 'ro_RO',
          pauseForSeconds: 3, // Pauză scurtă pentru detectarea tăcerii
        );
      }
    } catch (e) {
      debugPrint('🎤 [VOICE_ORCHESTRATOR] ❌ Auto-listen error: $e');
    }
  }

  /// 🎯 NOU: Pornește automat ascultarea pentru confirmare
  Future<void> startListeningForConfirmation({
    int timeoutSeconds = 30,
    String localeId = 'ro_RO',
  }) async {
    if (_conversationManager?.currentState == VoiceConversationState.waitingForConfirmation) {
      debugPrint('🎤 [VOICE_ORCHESTRATOR] Starting automatic listening for confirmation...');
      
      // Așteaptă puțin înainte de a porni ascultarea
      await Future.delayed(Duration(milliseconds: 500));
      
      // Pornește ascultarea
      await listen(
        timeoutSeconds: timeoutSeconds,
        localeId: localeId,
        pauseForSeconds: 10,
      );
    } else {
      debugPrint('🎤 [VOICE_ORCHESTRATOR] Not in confirmation state, skipping auto-listen');
    }
  }
  
  /// 🎤 Verifică dacă speech recognition-ul e disponibil
  Future<bool> isSpeechRecognitionAvailable() async {
    try {
      return await speechToText.initialize();
    } catch (e) {
      debugPrint('🎤 [VOICE_ORCHESTRATOR] ❌ Speech recognition check failed: $e');
      return false;
    }
  }
  
  /// 🧹 Cleanup callbacks (NU dispune serviciile - singleton partajat!)
  void dispose() {
    // 🚀 SINGLETON: Nu dispunem serviciile reale, doar curățăm callback-urile
    // Serviciile rămân active pentru alte părți ale aplicației
    _onSpeechResult = null;
    _onSpeechError = null;
    _onStateChange = null;
    _onTtsCompleted = null;
    _conversationManager = null;
    // NOTĂ: _speechToText, _naturalTts, _beepService NU se dispun - sunt partajate global
  }
  
  /// 🧹 Dispune complet singleton-ul (doar la închiderea aplicației)
  void disposeCompletely() {
    stop();
    _naturalTts?.dispose();
    _beepService?.dispose();
    _speechToText = null;
    _naturalTts = null;
    _beepService = null;
    _isInitialized = false;
    _onSpeechResult = null;
    _onSpeechError = null;
    _onStateChange = null;
    _onTtsCompleted = null;
    _conversationManager = null;
  }
}