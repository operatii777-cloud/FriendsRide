import 'package:flutter/material.dart';
import 'package:friendsride_app/voice/integration/friendsride_voice_integration.dart';
import 'package:friendsride_app/voice/states/voice_interaction_states.dart';
import 'package:friendsride_app/l10n/app_localizations.dart';

/// 🎤 Voice overlay widget extracted from MapScreen.
/// Displays voice interaction feedback with animated icons and state colours.
class MapVoiceOverlay extends StatefulWidget {
  final FriendsRideVoiceIntegration voiceIntegration;

  const MapVoiceOverlay({super.key, required this.voiceIntegration});

  @override
  State<MapVoiceOverlay> createState() => _MapVoiceOverlayState();
}

class _MapVoiceOverlayState extends State<MapVoiceOverlay> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = widget.voiceIntegration.currentContext.processingState;
    final voiceContext = widget.voiceIntegration.currentContext;

    // ✅ EXTRAGE INFORMAȚII DIN CONTEXT
    final lastAiMessage = _getLastAIResponse(voiceContext.conversationHistory);
    // Note: Destination and pickup will be extracted from voice controller when available
    // final destination = voiceIntegration.voiceDestination ?? '';
    // final pickup = voiceIntegration.voicePickup ?? '';
    // final estimatedPrice = 0.0;

    // Determină culoarea ecranului în funcție de stare
    Color backgroundColor;
    IconData icon;
    String statusText;
    String instructionText;

    switch (state) {
      case VoiceProcessingState.speaking:
        backgroundColor = Colors.green.shade600; // Fond verde mai clar, fără negru
        icon = Icons.volume_up;
        statusText = l10n.aiSpeaking;
        instructionText = lastAiMessage.isNotEmpty ? lastAiMessage : '🗣️ ${l10n.pleaseListenToResponse}';
        break;

      case VoiceProcessingState.listening:
        backgroundColor = Colors.red.shade600; // Fond roșu mai clar, fără negru
        icon = Icons.mic;
        statusText = l10n.aiListening;
        instructionText = '🎤 ${l10n.speakNow}';
        break;

      case VoiceProcessingState.thinking:
        backgroundColor = Colors.orange.shade600; // Fond portocaliu mai clar, fără negru
        icon = Icons.psychology;
        statusText = l10n.aiProcessing;
        instructionText = '🧠 ${l10n.processingInformation}';
        break;

      case VoiceProcessingState.waiting:
      case VoiceProcessingState.waitingForConfirmation:
        backgroundColor = Colors.blue.shade600; // Fond albastru mai clar, fără negru
        icon = Icons.hourglass_empty;
        statusText = l10n.waitingForResponse;
        instructionText = lastAiMessage.isNotEmpty ? lastAiMessage : '⏳ ${l10n.pleaseWait}';
        break;

      case VoiceProcessingState.idle:
      default:
        backgroundColor = Colors.blue.shade600; // Fond albastru mai clar, fără negru
        icon = Icons.mic_none;
        statusText = l10n.voiceAssistant;
        instructionText = l10n.pressButtonToStart;
        break;
    }

    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.padding.bottom;

    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomInset + 24,
      child: AnimatedScale(
        scale: 1,
        duration: const Duration(milliseconds: 200),
        child: Material(
          elevation: 12,
          borderRadius: BorderRadius.circular(24),
          color: backgroundColor, // Fond colorat solid, fără transparență care ar putea părea negru
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.95, end: 1.05),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeInOut,
                      builder: (context, scale, child) => Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(icon, size: 36, color: Colors.white),
                        ),
                      ),
                      onEnd: () {
                        if (mounted) setState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      statusText,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      instructionText,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.visible,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // ✅ AFIȘEAZĂ INFORMAȚII DESPRE CURSĂ (dacă sunt disponibile)
                    // Note: Will be enabled when voice context provides pickup/destination/price
                    // if (destination.isNotEmpty || pickup.isNotEmpty || estimatedPrice > 0)
                    //   Container(...)
                    if (widget.voiceIntegration.currentContext.conversationHistory.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(maxHeight: 72),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25), // Mai vizibil, nu negru
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.2),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            _getLastAIResponse(widget.voiceIntegration.currentContext.conversationHistory),
                            textAlign: TextAlign.center,
                            maxLines: 4,
                            overflow: TextOverflow.fade,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13, // Font puțin mai mare pentru lizibilitate
                              fontWeight: FontWeight.w500, // Puțin mai bold
                              height: 1.3,
                            ),
                          ),
                        ),
                      ),
                    if (widget.voiceIntegration.currentContext.conversationHistory.isNotEmpty)
                      const SizedBox(height: 16),
                    if (state == VoiceProcessingState.listening || state == VoiceProcessingState.speaking)
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.3, end: 1.0),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeInOut,
                        builder: (context, value, child) => Container(
                          width: 48,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: value),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        onEnd: () {
                          if (mounted) setState(() {});
                        },
                      ),
                    const SizedBox(height: 18),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        _buildColorLegendItem(Colors.green, 'AI vorbește'),
                        _buildColorLegendItem(Colors.red, 'Dvs. vorbiți'),
                        _buildColorLegendItem(Colors.orange, 'Procesează'),
                      ],
                    ),
                  ],
                ),
                if (state != VoiceProcessingState.listening && state != VoiceProcessingState.speaking)
                  Positioned(
                    top: -8,
                    right: -8,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () async {
                        debugPrint('🎤 DEBUG: Close button pressed');
                        try {
                          await widget.voiceIntegration.stopVoiceInteraction();
                        } catch (e) {
                          debugPrint('🎤 DEBUG: ❌ Eroare la oprirea voice interaction: $e');
                        }
                      },
                      tooltip: 'Închide asistent vocal',
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🎨 Element de legendă pentru culori - COMPACT
  Widget _buildColorLegendItem(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 0.5),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 Extrage ultimul răspuns AI din istoricul conversației
  String _getLastAIResponse(List<String> conversationHistory) {
    if (conversationHistory.isEmpty) {
      return 'Salutare! Unde doriți să mergeți?';
    }

    // Caută ultimul mesaj de la AI (începe cu "AI:")
    for (int i = conversationHistory.length - 1; i >= 0; i--) {
      final message = conversationHistory[i];
      if (message.startsWith('AI:')) {
        return message.substring(3).trim(); // Elimină "AI:" și spațiile
      }
    }

    return 'Salutare! Unde doriți să mergeți?';
  }

  // ✅ NOU: Metode helper pentru overlay-ul de voce
  static Widget _buildVoiceIcon(VoiceProcessingState state) {
    switch (state) {
      case VoiceProcessingState.listening:
        return Icon(Icons.mic, color: Colors.red, size: 64); // roșu când ascultă
      case VoiceProcessingState.thinking:
        return CircularProgressIndicator(color: Colors.white); // loading când procesează
      case VoiceProcessingState.speaking:
        return Icon(Icons.volume_up, color: Colors.green, size: 64); // verde când vorbește
      case VoiceProcessingState.waiting:
        return Icon(Icons.hourglass_empty, color: Colors.yellow, size: 64); // galben când așteaptă
      case VoiceProcessingState.waitingForConfirmation:
        return Icon(Icons.question_answer, color: Colors.purple, size: 64); // violet când așteaptă confirmarea
      case VoiceProcessingState.confirmationReceived:
        return Icon(Icons.check_circle, color: Colors.green, size: 64); // verde când confirmarea e primită
      case VoiceProcessingState.error:
        return Icon(Icons.error, color: Colors.red, size: 64); // roșu pentru eroare
      case VoiceProcessingState.idle:
        return Icon(Icons.mic_off, color: Colors.grey, size: 64);
    }
  }

  static String _getStatusText(VoiceProcessingState state) {
    switch (state) {
      case VoiceProcessingState.listening:
        return "Te ascult...";
      case VoiceProcessingState.thinking:
        return "Procesez...";
      case VoiceProcessingState.speaking:
        return "Îți răspund...";
      case VoiceProcessingState.waiting:
        return "Aștept...";
      case VoiceProcessingState.waitingForConfirmation:
        return "Aștept confirmarea...";
      case VoiceProcessingState.confirmationReceived:
        return "Confirmarea primită!";
      case VoiceProcessingState.error:
        return "Eroare - încearcă din nou";
      case VoiceProcessingState.idle:
        return "Apasă pentru a începe";
    }
  }

  /// 🎤 Construiește indicatorul pentru starea de procesare
  static Widget _buildProcessingStateIndicator(VoiceProcessingState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getStateColor(state).withAlpha(51),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getStateColor(state)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _getStateIcon(state),
          const SizedBox(width: 8),
          Text(
            _getStatusText(state),
            style: TextStyle(
              color: _getStateColor(state),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 🎨 Returnează culoarea pentru starea de procesare
  static Color _getStateColor(VoiceProcessingState state) {
    switch (state) {
      case VoiceProcessingState.listening:
        return Colors.red;
      case VoiceProcessingState.thinking:
        return Colors.orange;
      case VoiceProcessingState.speaking:
        return Colors.green;
      case VoiceProcessingState.waiting:
        return Colors.yellow;
      case VoiceProcessingState.waitingForConfirmation:
        return Colors.purple;
      case VoiceProcessingState.confirmationReceived:
        return Colors.green;
      case VoiceProcessingState.error:
        return Colors.red;
      case VoiceProcessingState.idle:
        return Colors.grey;
    }
  }

  /// 🎨 Returnează iconița pentru starea de procesare
  static Widget _getStateIcon(VoiceProcessingState state) {
    switch (state) {
      case VoiceProcessingState.listening:
        return const Icon(Icons.mic, color: Colors.red, size: 20);
      case VoiceProcessingState.thinking:
        return const Icon(Icons.psychology, color: Colors.orange, size: 20);
      case VoiceProcessingState.speaking:
        return const Icon(Icons.volume_up, color: Colors.green, size: 20);
      case VoiceProcessingState.waiting:
        return const Icon(Icons.hourglass_empty, color: Colors.yellow, size: 20);
      case VoiceProcessingState.waitingForConfirmation:
        return const Icon(Icons.question_answer, color: Colors.purple, size: 20);
      case VoiceProcessingState.confirmationReceived:
        return const Icon(Icons.check_circle, color: Colors.green, size: 20);
      case VoiceProcessingState.error:
        return const Icon(Icons.error, color: Colors.red, size: 20);
      case VoiceProcessingState.idle:
        return const Icon(Icons.mic_off, color: Colors.grey, size: 20);
    }
  }
}
