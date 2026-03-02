import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  String _currentLanguage = 'ro';
  
  // Setări TTS
  double _speechRate = 0.5;
  double _volume = 1.0;
  double _pitch = 1.0;
  
  // NOU: Debouncing pentru a evita frame skip-urile
  Timer? _speakDebounceTimer;
  String? _lastSpokenText;
  static const Duration _debounceDelay = Duration(milliseconds: 300);

  Future<void> initialize({String language = 'ro'}) async {
    if (_isInitialized) return;
    
    try {
      _currentLanguage = language;
      
      // Configurare de bază
      await _flutterTts.setLanguage(_currentLanguage);
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setVolume(_volume);
      await _flutterTts.setPitch(_pitch);
      
      // Configurări specifice pentru platforme
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _flutterTts.setEngine("com.google.android.tts");
        // NOU: Dezactivăm awaitSpeakCompletion pentru a evita blocarea thread-ului principal
        await _flutterTts.awaitSpeakCompletion(false);
      }
      
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _flutterTts.setSharedInstance(true);
        await _flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [IosTextToSpeechAudioCategoryOptions.allowBluetooth],
        );
      }
      
      // Setează callback-uri
      _flutterTts.setStartHandler(() {
        debugPrint("TTS Started");
      });
      
      _flutterTts.setCompletionHandler(() {
        debugPrint("TTS Completed");
      });
      
      _flutterTts.setErrorHandler((msg) {
        debugPrint("TTS Error: $msg");
      });
      
      _isInitialized = true;
      debugPrint("TTS Service initialized with language: $_currentLanguage");
      
    } catch (e) {
      debugPrint("TTS initialization error: $e");
    }
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    // NOU: Debouncing pentru a evita frame skip-urile
    if (_speakDebounceTimer?.isActive == true) {
      _speakDebounceTimer?.cancel();
    }
    
    // Dacă același text a fost spus recent, nu-l repetăm
    if (_lastSpokenText == text) {
      return;
    }
    
    _speakDebounceTimer = Timer(_debounceDelay, () async {
      try {
        _lastSpokenText = text;
        await _flutterTts.speak(text);
        debugPrint("TTS Speaking: $text");
      } catch (e) {
        debugPrint("TTS Speak error: $e");
      }
    });
  }

  Future<void> stop() async {
    try {
      _speakDebounceTimer?.cancel();
      await _flutterTts.stop();
    } catch (e) {
      debugPrint("TTS Stop error: $e");
    }
  }

  Future<void> pause() async {
    try {
      await _flutterTts.pause();
    } catch (e) {
      debugPrint("TTS Pause error: $e");
    }
  }

  // Setări pentru limbă
  Future<void> setLanguage(String language) async {
    if (_currentLanguage == language) return;
    
    _currentLanguage = language;
    try {
      await _flutterTts.setLanguage(_currentLanguage);
      debugPrint("TTS Language changed to: $_currentLanguage");
    } catch (e) {
      debugPrint("TTS Language change error: $e");
    }
  }

  // Setări pentru viteză
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.0, 1.0);
    try {
      await _flutterTts.setSpeechRate(_speechRate);
    } catch (e) {
      debugPrint("TTS Speech rate error: $e");
    }
  }

  // Setări pentru volum
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    try {
      await _flutterTts.setVolume(_volume);
    } catch (e) {
      debugPrint("TTS Volume error: $e");
    }
  }

  // Setări pentru pitch
  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    try {
      await _flutterTts.setPitch(_pitch);
    } catch (e) {
      debugPrint("TTS Pitch error: $e");
    }
  }

  // Verifică dacă TTS-ul este disponibil
  Future<bool> isLanguageAvailable(String language) async {
    try {
      final languages = await _flutterTts.getLanguages;
      return languages.contains(language);
    } catch (e) {
      debugPrint("TTS Language check error: $e");
      return false;
    }
  }

  // Obține lista de limbi disponibile
  Future<List<String>> getAvailableLanguages() async {
    try {
      final languages = await _flutterTts.getLanguages;
      return List<String>.from(languages);
    } catch (e) {
      debugPrint("TTS Get languages error: $e");
      return [];
    }
  }

  // Obține lista de voci disponibile
  Future<List<Map<String, String>>> getAvailableVoices() async {
    try {
      final voices = await _flutterTts.getVoices;
      return List<Map<String, String>>.from(voices);
    } catch (e) {
      debugPrint("TTS Get voices error: $e");
      return [];
    }
  }

  // Setează vocea specifică
  Future<void> setVoice(Map<String, String> voice) async {
    try {
      await _flutterTts.setVoice(voice);
    } catch (e) {
      debugPrint("TTS Set voice error: $e");
    }
  }

  // Getteri pentru setările actuale
  String get currentLanguage => _currentLanguage;
  double get speechRate => _speechRate;
  double get volume => _volume;
  double get pitch => _pitch;
  bool get isInitialized => _isInitialized;

  // Verifică dacă TTS-ul vorbește acum
  Future<bool> get isSpeaking async {
    try {
      // flutter_tts 4.2.3 nu mai are isSpeaking getter
      // Returnăm false ca fallback
      return false;
    } catch (e) {
      debugPrint("TTS isSpeaking error: $e");
      return false;
    }
  }

  // NOU: Cleanup la dispose
  void dispose() {
    _speakDebounceTimer?.cancel();
    _flutterTts.stop();
  }
}