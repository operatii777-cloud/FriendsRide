import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Model pentru apel VoIP
class VoipCall {
  final String id;
  final String phoneNumber;
  final String contactName;
  final String? dialNumber;
  final DateTime startTime;
  DateTime? endTime;
  bool isMuted;
  bool isSpeakerOn;
  CallStatus status;

  VoipCall({
    required this.id,
    required this.phoneNumber,
    required this.contactName,
    this.dialNumber,
    required this.startTime,
    this.endTime,
    this.isMuted = false,
    this.isSpeakerOn = false,
    this.status = CallStatus.connecting,
  });

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }
}

enum CallStatus { connecting, connected, ended }

class VoipService {
  static final VoipService _instance = VoipService._internal();
  factory VoipService() => _instance;
  VoipService._internal();

  VoipCall? _activeCall;
  Timer? _callTimer;
  Function(VoipCall)? onCallUpdate;

  // Simulare conectare apel
  Future<bool> startCall({
    required String phoneNumber,
    required String contactName,
    required BuildContext context,
    String? dialNumber,
  }) async {
    try {
      // Verifică dacă există deja un apel activ
      if (_activeCall != null) {
        return false;
      }

      // Creează apel nou
      _activeCall = VoipCall(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        phoneNumber: phoneNumber,
        contactName: contactName,
        dialNumber: dialNumber,
        startTime: DateTime.now(),
      );

      // Afișează UI-ul de apel
      _showCallUI(context);

      // Simulează conectarea după 2 secunde
      _callTimer = Timer(const Duration(seconds: 2), () {
        if (_activeCall != null) {
          _activeCall!.status = CallStatus.connected;
          onCallUpdate?.call(_activeCall!);
        }
      });

      return true;
    } catch (e) {
      debugPrint('VoIP Error: $e');
      return false;
    }
  }

  void _showCallUI(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _VoipCallDialog(service: this);
      },
    );
  }

  void toggleMute() {
    if (_activeCall != null) {
      _activeCall!.isMuted = !_activeCall!.isMuted;
      HapticFeedback.selectionClick();
      onCallUpdate?.call(_activeCall!);
    }
  }

  void toggleSpeaker() {
    if (_activeCall != null) {
      _activeCall!.isSpeakerOn = !_activeCall!.isSpeakerOn;
      HapticFeedback.selectionClick();
      onCallUpdate?.call(_activeCall!);
    }
  }

  void endCall() {
    if (_activeCall != null) {
      _activeCall!.endTime = DateTime.now();
      _activeCall!.status = CallStatus.ended;
      HapticFeedback.heavyImpact();
      
      final call = _activeCall!;
      _activeCall = null;
      _callTimer?.cancel();
      
      onCallUpdate?.call(call);
    }
  }

  VoipCall? get activeCall => _activeCall;

  void dispose() {
    _callTimer?.cancel();
    _activeCall = null;
  }
}

// UI pentru apel VoIP
class _VoipCallDialog extends StatefulWidget {
  final VoipService service;

  const _VoipCallDialog({required this.service});

  @override
  State<_VoipCallDialog> createState() => _VoipCallDialogState();
}

class _VoipCallDialogState extends State<_VoipCallDialog> {
  Timer? _durationTimer;

  @override
  void initState() {
    super.initState();
    _startDurationTimer();
    
    widget.service.onCallUpdate = (call) {
      if (mounted) {
        setState(() {});
        if (call.status == CallStatus.ended) {
          Navigator.of(context).pop();
        }
      }
    };
  }

  void _startDurationTimer() {
    try {
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        try {
          if (mounted && widget.service.activeCall?.status == CallStatus.connected) {
            setState(() {});
          }
        } catch (e) {
          debugPrint('❌ Error in duration timer callback: $e');
          timer.cancel();
        }
      });
    } catch (e) {
      debugPrint('❌ Error starting duration timer: $e');
    }
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final call = widget.service.activeCall;
    if (call == null) return const SizedBox.shrink();

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            
            // Contact name
            Text(
              call.contactName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            
            // Phone number
            Text(
              call.phoneNumber,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            
            // Call status/duration
            Text(
              call.status == CallStatus.connecting
                  ? 'Se conectează...'
                  : _formatDuration(call.duration),
              style: TextStyle(
                color: call.status == CallStatus.connecting
                    ? Colors.grey.shade500
                    : Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 40),
            
            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Mute button
                _CallControlButton(
                  icon: call.isMuted ? Icons.mic_off : Icons.mic,
                  label: call.isMuted ? 'Unmute' : 'Mute',
                  isActive: call.isMuted,
                  onTap: widget.service.toggleMute,
                ),
                
                // Speaker button
                _CallControlButton(
                  icon: call.isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                  label: 'Difuzor',
                  isActive: call.isSpeakerOn,
                  onTap: widget.service.toggleSpeaker,
                ),
              ],
            ),
            const SizedBox(height: 40),
            
            // End call button
            GestureDetector(
              onTap: widget.service.endCall,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.call_end, color: Colors.white, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'Închide',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Buton control pentru apel
class _CallControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _CallControlButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.grey.shade800,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.grey.shade900 : Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}