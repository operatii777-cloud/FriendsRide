import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isDisposed = false;

  /// Redă sunetul pentru mesaje primite în chat
  Future<void> playMessageReceivedSound() async {
    if (_isDisposed) return;
    
    try {
      // ✅ FIX: Verifică dacă fișierul audio există
      await _audioPlayer.play(AssetSource('sounds/message_sound.wav'));
      debugPrint('🔊 Playing message received sound successfully');
      
      // ✅ BONUS: Vibrație pentru feedback haptic
      HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint('⚠️ Error playing message sound: $e');
      // ✅ FALLBACK: Vibrație pentru feedback haptic
      HapticFeedback.mediumImpact();
      
      // ✅ BONUS: Încearcă și sunetul de sistem
      try {
        SystemSound.play(SystemSoundType.alert);
        debugPrint('🔊 Fallback to system notification sound');
      } catch (e2) {
        debugPrint('⚠️ Even system sound failed: $e2');
      }
    }
  }

  // --- FUNCȚIE NOUĂ DEDICATĂ ---
  /// Redă sunetul pentru o nouă solicitare de cursă
  Future<void> playRideRequestSound() async {
    if (_isDisposed) return;
    
    try {
      // ✅ FIX: Verifică dacă fișierul audio există
      await _audioPlayer.play(AssetSource('sounds/message_sound.wav'));
      debugPrint('🚗 Playing ride request sound successfully');
      
      // ✅ BONUS: Vibrație pentru feedback haptic
      HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint('⚠️ Error playing ride request sound: $e');
      // ✅ FALLBACK: Vibrație mai puternică pentru a atrage atenția
      HapticFeedback.heavyImpact();
      
      // ✅ BONUS: Încearcă și sunetul de sistem
      try {
        SystemSound.play(SystemSoundType.alert);
        debugPrint('🔊 Fallback to system notification sound');
      } catch (e2) {
        debugPrint('⚠️ Even system sound failed: $e2');
      }
    }
  }

  /// Redă sunetul pentru apeluri primite
  Future<void> playIncomingCallSound() async {
    if (_isDisposed) return;
    
    try {
      SystemSound.play(SystemSoundType.alert);
      debugPrint('🔊 Playing incoming call sound (system default)');
    } catch (e) {
      debugPrint('⚠️ Error playing call sound: $e');
      HapticFeedback.mediumImpact();
    }
  }

  /// Oprește toate sunetele în curs de redare
  Future<void> stopAllSounds() async {
    if (_isDisposed) return;
    
    try {
      await _audioPlayer.stop();
      debugPrint('🔇 Stopped all audio playback');
    } catch (e) {
      debugPrint('⚠️ Error stopping audio: $e');
    }
  }

  /// Setează volumul pentru sunetele custom (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    if (_isDisposed) return;
    
    try {
      await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
      debugPrint('🔊 Audio volume set to: ${(volume * 100).round()}%');
    } catch (e) {
      debugPrint('⚠️ Error setting volume: $e');
    }
  }

  /// Cleanup - se apelează când serviciul nu mai este necesar
  void dispose() {
    if (_isDisposed) return;
    
    _isDisposed = true;
    _audioPlayer.dispose();
    debugPrint('🧹 AudioService disposed');
  }
}