import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:friendsride_app/utils/logger.dart';

/// 🔔 Serviciu pentru beep-uri audio în conversațiile AI
/// 
/// Caracteristici:
/// - Beep după conversația AI (utilizatorul să știe când să răspundă)
/// - Două beep-uri scurte când AI procesează informația
/// - Sunete personalizabile și configurabile
class AudioBeepService {
  static final AudioBeepService _instance = AudioBeepService._internal();
  factory AudioBeepService() => _instance;
  AudioBeepService._internal();

  bool _isInitialized = false;
  bool _isPlaying = false;

  // 🎵 Tipuri de beep-uri (pentru viitoare implementări cu fișiere audio)
  // static const String _beepSingle = 'sounds/beep_single.wav';
  // static const String _beepDouble = 'sounds/beep_double.wav';
  // static const String _beepProcessing = 'sounds/beep_processing.wav';

  /// 🚀 Inițializează serviciul de beep-uri
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      Logger.info('Initializing beep service...', tag: 'AUDIO_BEEP');

      // Pentru moment, folosim beep-uri simulate
      // În viitor, aici se vor configura fișierele audio reale

      _isInitialized = true;
      Logger.info('Beep service initialized successfully', tag: 'AUDIO_BEEP');

    } catch (e) {
      Logger.error('Initialization error: $e', tag: 'AUDIO_BEEP', error: e);
      _isInitialized = false;
      rethrow;
    }
  }

  /// 🔔 Beep când AI-ul ÎNCEPE să asculte
  /// Utilizatorul știe că ACUM poate vorbi
  /// Sunet: BEEP SCURT ASCENDENT (600Hz → 900Hz, 150ms)
  Future<void> playListeningStartBeep() async {
    if (!_isInitialized) await initialize();

    try {
      Logger.info('ACUM POȚI VORBI - ascult...', tag: 'AUDIO_BEEP');
      
      // Beep ascendent scurt = "te ascult acum"
      await _playSystemBeep(frequency: 600, duration: 100);
      await Future.delayed(Duration(milliseconds: 50));
      await _playSystemBeep(frequency: 900, duration: 150);
      
      Logger.info('Listening start beep played', tag: 'AUDIO_BEEP');
      
    } catch (e) {
      Logger.error('Error playing listening start beep: $e', tag: 'AUDIO_BEEP', error: e);
    }
  }

  /// 🔔 Beep lung după conversația AI
  /// Utilizatorul știe că AI-ul a terminat și acum trebuie să răspundă
  /// Sunet: UN BEEP LUNG (800Hz, 400ms)
  Future<void> playConversationEndBeep() async {
    if (!_isInitialized) await initialize();

    try {
      Logger.error('→ AI a terminat de vorbit - ACUM VORBIȚI DVS!', tag: 'AUDIO_BEEP');
      
      if (_isPlaying) {
        _isPlaying = false;
      }

      // UN BEEP LUNG pentru a indica "Acum e rândul dvs să vorbiți"
      await _playSystemBeep(frequency: 800, duration: 400); // Mai lung (400ms)
      
      Logger.info('Conversation end beep played (User turn to speak)', tag: 'AUDIO_BEEP');

    } catch (e) {
      Logger.error('Conversation end beep error: $e', tag: 'AUDIO_BEEP', error: e);
      await _playFallbackBeep();
    }
  }

  /// 🔔🔔 Două beep-uri scurte când AI procesează informația
  /// Utilizatorul știe că AI-ul a primit și procesează informația
  /// Sunet: DOUĂ BEEP-URI SCURTE (1000Hz + 1200Hz, 100ms fiecare)
  Future<void> playProcessingStartBeeps() async {
    if (!_isInitialized) await initialize();

    try {
      Logger.error('→ AI a înțeles - PROCESEZ...', tag: 'AUDIO_BEEP');
      
      if (_isPlaying) {
        _isPlaying = false;
      }

      // Primul beep scurt
      await _playSystemBeep(frequency: 1000, duration: 100); // Mai scurt (100ms)
      await Future.delayed(Duration(milliseconds: 80)); // Pauză scurtă
      
      // Al doilea beep scurt (mai înalt)
      await _playSystemBeep(frequency: 1200, duration: 100); // Mai scurt (100ms)
      
      Logger.info('Processing start beeps played (AI is thinking)', tag: 'AUDIO_BEEP');

    } catch (e) {
      Logger.error('Processing start beeps error: $e', tag: 'AUDIO_BEEP', error: e);
      await _playFallbackBeep();
    }
  }

  /// 🔔 Beep pentru confirmarea procesării complete
  /// AI-ul a terminat de procesat și va vorbi din nou
  /// Sunet: UN BEEP MEDIU (1400Hz, 200ms)
  Future<void> playProcessingCompleteBeep() async {
    if (!_isInitialized) await initialize();

    try {
      Logger.warning('→ AI a procesat - ACUM VORBEȘTE AI', tag: 'AUDIO_BEEP');
      
      if (_isPlaying) {
        _isPlaying = false;
      }

      // UN BEEP MEDIU pentru a indica "AI va vorbi acum"
      await _playSystemBeep(frequency: 1400, duration: 200); // Mai scurt (200ms)
      
      Logger.info('Processing complete beep played (AI will speak)', tag: 'AUDIO_BEEP');

    } catch (e) {
      Logger.error('Processing complete beep error: $e', tag: 'AUDIO_BEEP', error: e);
      await _playFallbackBeep();
    }
  }

  /// 🔔 Beep pentru erori
  Future<void> playErrorBeep() async {
    if (!_isInitialized) await initialize();

    try {
      Logger.error('Playing error beep...', tag: 'AUDIO_BEEP');
      
      if (_isPlaying) {
        // Oprește beep-ul curent dacă este în curs
        _isPlaying = false;
      }

      // Beep scăzut pentru erori
      await _playSystemBeep(frequency: 400, duration: 500);
      
      Logger.error('Error beep played', tag: 'AUDIO_BEEP');

    } catch (e) {
      Logger.error('Error beep error: $e', tag: 'AUDIO_BEEP', error: e);
      await _playFallbackBeep();
    }
  }

  /// 🎵 Joacă beep-ul sistem cu frecvența și durata specificate
  Future<void> _playSystemBeep({
    required int frequency,
    required int duration,
  }) async {
    try {
      _isPlaying = true;

      // Pentru Android/iOS, folosește beep-ul sistem
      if (Platform.isAndroid || Platform.isIOS) {
        // Încearcă să rulezi beep-ul prin comanda sistem
        if (Platform.isAndroid) {
          await _playAndroidBeep(frequency, duration);
        } else if (Platform.isIOS) {
          await _playIOSBeep(frequency, duration);
        }
      } else {
        // Pentru desktop, folosește beep-ul sistem
        await _playDesktopBeep(frequency, duration);
      }

      _isPlaying = false;

    } catch (e) {
      Logger.error('System beep error: $e', tag: 'AUDIO_BEEP', error: e);
      _isPlaying = false;
      await _playFallbackBeep();
    }
  }

  /// 🤖 Beep pentru Android
  Future<void> _playAndroidBeep(int frequency, int duration) async {
    try {
      // Pentru Android, folosește beep-ul sistem prin canalul platform
      // Aceasta va fi implementată prin un plugin nativ dacă este necesar
      Logger.info('Playing Android beep: ${frequency}Hz for ${duration}ms', tag: 'AUDIO_BEEP');
      
      // Simulează beep-ul prin pauză (pentru moment)
      await Future.delayed(Duration(milliseconds: duration));
      
    } catch (e) {
      Logger.error('Android beep error: $e', tag: 'AUDIO_BEEP', error: e);
    }
  }

  /// 🍎 Beep pentru iOS
  Future<void> _playIOSBeep(int frequency, int duration) async {
    try {
      // Pentru iOS, folosește beep-ul sistem
      Logger.info('Playing iOS beep: ${frequency}Hz for ${duration}ms', tag: 'AUDIO_BEEP');
      
      // Simulează beep-ul prin pauză (pentru moment)
      await Future.delayed(Duration(milliseconds: duration));
      
    } catch (e) {
      Logger.error('iOS beep error: $e', tag: 'AUDIO_BEEP', error: e);
    }
  }

  /// 💻 Beep pentru desktop
  Future<void> _playDesktopBeep(int frequency, int duration) async {
    try {
      // Pentru desktop, folosește beep-ul sistem prin stdout
      Logger.info('Playing desktop beep: ${frequency}Hz for ${duration}ms', tag: 'AUDIO_BEEP');
      
      // Simulează beep-ul prin pauză (pentru moment)
      await Future.delayed(Duration(milliseconds: duration));
      
    } catch (e) {
      Logger.error('Desktop beep error: $e', tag: 'AUDIO_BEEP', error: e);
    }
  }

  /// 🔄 Beep de fallback pentru când alte metode eșuează
  Future<void> _playFallbackBeep() async {
    try {
      Logger.warning('Playing fallback beep...', tag: 'AUDIO_BEEP');
      
      // Simulează un beep prin pauză
      await Future.delayed(Duration(milliseconds: 200));
      
    } catch (e) {
      Logger.error('Fallback beep error: $e', tag: 'AUDIO_BEEP', error: e);
    }
  }

  /// 🛑 Oprește toate beep-urile
  Future<void> stopAllBeeps() async {
    try {
      if (_isPlaying) {
        _isPlaying = false;
        Logger.info('All beeps stopped', tag: 'AUDIO_BEEP');
      }
    } catch (e) {
      Logger.error('Stop beeps error: $e', tag: 'AUDIO_BEEP', error: e);
    }
  }

  /// 🎯 Verifică dacă serviciul e inițializat
  bool get isInitialized => _isInitialized;

  /// 🎯 Verifică dacă joacă un beep
  bool get isPlaying => _isPlaying;

  /// 🧹 Cleanup
  void dispose() {
    stopAllBeeps();
  }
}
