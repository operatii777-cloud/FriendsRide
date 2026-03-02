import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

/// Simple voice service to replace speech_to_text
class SimpleVoiceService {
  static final SimpleVoiceService _instance = SimpleVoiceService._internal();
  factory SimpleVoiceService() => _instance;
  SimpleVoiceService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  /// Initialize the voice service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _flutterTts.setLanguage("ro-RO");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      _isInitialized = true;
    } catch (e) {
      debugPrint('Voice service initialization failed: $e');
    }
  }

  /// Speak text
  Future<void> speak(String text) async {
    if (!_isInitialized) await initialize();
    
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('Speech failed: $e');
    }
  }

  /// Stop speaking
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('Stop speech failed: $e');
    }
  }

  /// Set language
  Future<void> setLanguage(String languageCode) async {
    try {
      await _flutterTts.setLanguage(languageCode);
    } catch (e) {
      debugPrint('Language setting failed: $e');
    }
  }

  /// Set speech rate
  Future<void> setSpeechRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate);
    } catch (e) {
      debugPrint('Speech rate setting failed: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _flutterTts.stop();
  }
}
