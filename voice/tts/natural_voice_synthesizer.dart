import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../states/voice_interaction_states.dart';

/// 🗣️ Natural Voice Synthesizer - Funcționează EXACT ca Gemini Voice TTS
/// 
/// Caracteristici:
/// - Vocea naturală și fluidă
/// - Răspuns instant (fără pauze)
/// - Procesare continuă a textului
/// - Integrare perfectă cu FriendsRide
class NaturalVoiceSynthesizer {
  final FlutterTts _flutterTts = FlutterTts();
  
  // 🎯 Configurații pentru vocea naturală
  static const String _defaultVoiceRo = 'ro-RO';
  static const String _defaultVoiceEn = 'en-US';
  String _currentLanguage = _defaultVoiceRo; // ✅ NOU: Limba curentă
  static const double _defaultRate = 0.5; // Viteza naturală
  static const double _defaultPitch = 1.0; // Pitch natural
  static const double _defaultVolume = 1.0; // Volum maxim
  
  // 🚀 Starea curentă
  bool _isSpeaking = false;
  bool _isInitialized = false;
  
  /// ✅ NOU: Setează limba pentru TTS
  Future<void> setLanguage(String languageCode) async {
    try {
      String ttsLanguage;
      if (languageCode == 'en') {
        ttsLanguage = _defaultVoiceEn;
      } else {
        ttsLanguage = _defaultVoiceRo; // Default română
      }
      
      if (_currentLanguage != ttsLanguage) {
        _currentLanguage = ttsLanguage;
        await _flutterTts.setLanguage(ttsLanguage);
        debugPrint('🗣️ [NATURAL_TTS] Language changed to: $ttsLanguage');
      }
    } catch (e) {
      debugPrint('🗣️ [NATURAL_TTS] ❌ Error setting language: $e');
    }
  }
  
  /// 🚀 Inițializează TTS-ul
  Future<void> initialize({String? languageCode}) async {
    try {
      debugPrint('🗣️ [NATURAL_TTS] Initializing...');
      
      // ✅ NOU: Setez limba dacă este specificată, altfel folosesc default
      if (languageCode != null) {
        await setLanguage(languageCode);
      } else {
        // 🎯 Setez limba română (default)
        await _flutterTts.setLanguage(_defaultVoiceRo);
        _currentLanguage = _defaultVoiceRo;
      }
      
      // 🎯 Setez parametrii pentru vocea naturală
      await _flutterTts.setSpeechRate(_defaultRate);
      await _flutterTts.setPitch(_defaultPitch);
      await _flutterTts.setVolume(_defaultVolume);
      
      // 🎯 Setez callback-urile
      _flutterTts.setStartHandler(() {
        debugPrint('🗣️ [NATURAL_TTS] Started speaking');
        _isSpeaking = true;
      });
      
      _flutterTts.setCompletionHandler(() {
        debugPrint('🗣️ [NATURAL_TTS] Finished speaking');
        _isSpeaking = false;
      });
      
      _flutterTts.setErrorHandler((msg) {
        debugPrint('🗣️ [NATURAL_TTS] ❌ Error: $msg');
        _isSpeaking = false;
      });
      
      _isInitialized = true;
      debugPrint('🗣️ [NATURAL_TTS] ✅ Initialized successfully');
      
    } catch (e) {
      debugPrint('🗣️ [NATURAL_TTS] ❌ Initialization error: $e');
      _isInitialized = false;
    }
  }
  
  /// 🗣️ Vorbește textul EXACT ca Gemini Voice
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      debugPrint('🗣️ [NATURAL_TTS] ⚠️ Not initialized, initializing now...');
      await initialize();
    }
    
    if (_isSpeaking) {
      debugPrint('🗣️ [NATURAL_TTS] ⚠️ Already speaking, stopping current speech...');
      await stop();
    }
    
    try {
      debugPrint('🗣️ [NATURAL_TTS] Speaking: "$text"');
      
      // 🚀 Trimit textul la TTS
      await _flutterTts.speak(text);
      
      // 🎯 Aștept să se termine
      while (_isSpeaking) {
        await Future.delayed(Duration(milliseconds: 100));
      }
      
      debugPrint('🗣️ [NATURAL_TTS] ✅ Speech completed');
      
    } catch (e) {
      debugPrint('🗣️ [NATURAL_TTS] ❌ Speech error: $e');
      _isSpeaking = false;
    }
  }
  
  /// 🗣️ Vorbește textul cu prioritate înaltă (pentru confirmări)
  Future<void> speakPriority(String text) async {
    if (_isSpeaking) {
      await stop();
    }
    
    // 🎯 Setez parametrii pentru confirmări (mai rapid)
    await _flutterTts.setSpeechRate(0.6);
    
    await speak(text);
    
    // 🎯 Restaurez parametrii normali
    await _flutterTts.setSpeechRate(_defaultRate);
  }
  
  /// 🗣️ Vorbește textul cu emoție (pentru răspunsuri importante)
  Future<void> speakWithEmotion(String text, VoiceEmotion emotion) async {
    if (_isSpeaking) {
      await stop();
    }
    
    // 🎯 Ajustez parametrii în funcție de emoție
    switch (emotion) {
      case VoiceEmotion.happy:
        await _flutterTts.setPitch(1.1);
        await _flutterTts.setSpeechRate(0.55);
        break;
      case VoiceEmotion.confident:
        await _flutterTts.setPitch(1.05);
        await _flutterTts.setSpeechRate(0.5);
        break;
      case VoiceEmotion.calm:
        await _flutterTts.setPitch(0.95);
        await _flutterTts.setSpeechRate(0.45);
        break;
      case VoiceEmotion.urgent:
        await _flutterTts.setPitch(1.15);
        await _flutterTts.setSpeechRate(0.65);
        break;
      case VoiceEmotion.curious:
        await _flutterTts.setPitch(1.08);
        await _flutterTts.setSpeechRate(0.52);
        break;
      case VoiceEmotion.friendly:
        await _flutterTts.setPitch(1.0);
        await _flutterTts.setSpeechRate(0.5);
        break;
      case VoiceEmotion.direct:
        await _flutterTts.setPitch(1.0);
        await _flutterTts.setSpeechRate(0.55);
        break;
    }
    
    await speak(text);
    
    // 🎯 Restaurez parametrii normali
    await _flutterTts.setPitch(_defaultPitch);
    await _flutterTts.setSpeechRate(_defaultRate);
  }
  
  /// 🗣️ Vorbește textul cu pauze naturale (pentru propoziții lungi)
  Future<void> speakWithNaturalPauses(String text) async {
    if (_isSpeaking) {
      await stop();
    }
    
    // 🎯 Împart textul în propoziții
    final sentences = _splitIntoSentences(text);
    
    for (final sentence in sentences) {
      if (sentence.trim().isNotEmpty) {
        await speak(sentence.trim());
        
        // 🎯 Pauză naturală între propoziții
        if (sentences.indexOf(sentence) < sentences.length - 1) {
          await Future.delayed(Duration(milliseconds: 300));
        }
      }
    }
  }
  
  /// 🛑 Oprește vorbirea
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
      debugPrint('🗣️ [NATURAL_TTS] Speech stopped');
    } catch (e) {
      debugPrint('🗣️ [NATURAL_TTS] ❌ Stop error: $e');
    }
  }
  
  /// 🎯 Verifică dacă vorbește
  bool get isSpeaking => _isSpeaking;
  
  /// 🎯 Verifică dacă e inițializat
  bool get isInitialized => _isInitialized;
  
  /// 📝 Împarte textul în propoziții naturale
  List<String> _splitIntoSentences(String text) {
    // 🎯 Regex pentru propoziții românești
    final sentenceRegex = RegExp(r'[.!?]+');
    return text.split(sentenceRegex);
  }
  
  /// 🧹 Cleanup
  void dispose() {
    stop();
    _flutterTts.setStartHandler(() {});
    _flutterTts.setCompletionHandler(() {});
    _flutterTts.setErrorHandler((msg) {});
  }
}


