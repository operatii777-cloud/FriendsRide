import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:friendsride_app/services/firestore_service.dart';
import 'package:friendsride_app/models/chat_message_model.dart';
import 'package:friendsride_app/theme/app_colors.dart';

/// Widget pentru butonul de înregistrare voice message
class VoiceRecordButton extends StatefulWidget {
  final String rideId;
  final VoidCallback? onRecordingComplete;
  final VoidCallback? onError;

  const VoiceRecordButton({
    super.key,
    required this.rideId,
    this.onRecordingComplete,
    this.onError,
  });

  @override
  State<VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends State<VoiceRecordButton> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isUploading = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _durationTimer;
  String? _audioPath;

  @override
  void dispose() {
    _durationTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<bool> _checkPermissions() async {
    final micPermission = await Permission.microphone.status;
    if (!micPermission.isGranted) {
      final result = await Permission.microphone.request();
      if (!result.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permisiunea pentru microfon este necesară pentru înregistrare.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }
    }
    return true;
  }

  Future<void> _startRecording() async {
    if (!await _checkPermissions()) return;

    try {
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _audioPath = '${directory.path}/voice_message_$timestamp.m4a';

      if (await _audioRecorder.hasPermission()) {
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: _audioPath!,
        );

        setState(() {
          _isRecording = true;
          _recordingDuration = Duration.zero;
        });

        _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _recordingDuration = Duration(seconds: timer.tick);
            });
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Error starting recording: $e');
      if (mounted) {
        widget.onError?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la începerea înregistrării: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording(bool send) async {
    if (!_isRecording) return;

    _durationTimer?.cancel();
    final path = await _audioRecorder.stop();
    
    setState(() {
      _isRecording = false;
    });

    if (path == null || path.isEmpty) {
      debugPrint('❌ No audio file recorded');
      return;
    }

    if (!send) {
      // Anulează înregistrarea - șterge fișierul
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('❌ Error deleting cancelled recording: $e');
      }
      return;
    }

    // Trimite mesajul vocal
    await _uploadAndSendVoiceMessage(path);
  }

  Future<void> _uploadAndSendVoiceMessage(String audioPath) async {
    setState(() {
      _isUploading = true;
    });

    try {
      final file = File(audioPath);
      if (!await file.exists()) {
        throw Exception('Fișierul audio nu există');
      }

      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) { // 10MB limit
        throw Exception('Fișierul audio este prea mare (max 10MB)');
      }

      // Upload la Firebase Storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('voice_messages')
          .child('${widget.rideId}_$timestamp.m4a');

      final uploadTask = await storageRef.putFile(
        file,
        SettableMetadata(
          contentType: 'audio/m4a',
          customMetadata: {
            'rideId': widget.rideId,
            'recordedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      final duration = _recordingDuration.inSeconds;

      // Trimite mesajul în chat
      await FirestoreService().sendChatMessage(
        widget.rideId,
        '🎤 Mesaj vocal',
        type: MessageType.voice,
        voiceUrl: downloadUrl,
        voiceDuration: duration,
      );

      // Șterge fișierul local
      try {
        await file.delete();
      } catch (e) {
        debugPrint('⚠️ Error deleting local file: $e');
      }

      if (mounted) {
        widget.onRecordingComplete?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mesaj vocal trimis!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error uploading voice message: $e');
      if (mounted) {
        widget.onError?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la trimiterea mesajului vocal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isUploading) {
      return const SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_isRecording) {
      return GestureDetector(
        onLongPressEnd: (_) => _stopRecording(true),
        onLongPressUp: () => _stopRecording(false),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mic, color: Colors.white, size: 20),
              Text(
                _formatDuration(_recordingDuration),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onLongPress: _startRecording,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.mic,
          color: AppColors.primary,
          size: 20,
        ),
      ),
    );
  }
}

