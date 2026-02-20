import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:friendsride_app/models/chat_message_model.dart';
import 'package:friendsride_app/widgets/chat/voice_message_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

/// Widget pentru bubble-uri de mesaje în stil WhatsApp
/// Include: tail (triunghi), read receipts, timestamp, edited indicator
class WhatsAppMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final String? otherUserName;
  final VoidCallback? onLongPress;
  final VoidCallback? onReply;

  const WhatsAppMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.otherUserName,
    this.onLongPress,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          margin: EdgeInsets.only(
            top: 4,
            bottom: 4,
            left: isMe ? 50 : 8,
            right: isMe ? 8 : 50,
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Stack(
            children: [
              // Bubble-ul principal cu tail
              CustomPaint(
                painter: WhatsAppBubblePainter(
                  isMe: isMe,
                  color: isMe 
                      ? const Color(0xFFDCF8C6) // Verde WhatsApp pentru mesajele mele
                      : Colors.white, // Alb pentru mesajele primite
                ),
                child: Container(
                  padding: const EdgeInsets.only(
                    top: 8,
                    bottom: 6,
                    left: 12,
                    right: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Conținut mesaj - text, voice, image sau gif
                      if (message.type == MessageType.voice && message.voiceUrl != null)
                        VoiceMessagePlayer(
                          audioUrl: message.voiceUrl!,
                          duration: message.voiceDuration ?? 0,
                          isMe: isMe,
                        )
                      else if (message.type == MessageType.gif && message.gifUrl != null)
                        _buildGifMessage(message.gifUrl!)
                      else if (message.type == MessageType.image && message.imageUrl != null)
                        _buildImageMessage(message.imageUrl!)
                      else
                        Text(
                          message.text,
                          style: TextStyle(
                            fontSize: 15,
                            color: isMe ? Colors.black87 : Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      
                      // Footer cu timestamp și read receipts
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Timestamp
                          Text(
                            _formatTimestamp(message.timestamp),
                            style: TextStyle(
                              fontSize: 11,
                              color: isMe 
                                  ? Colors.black54 
                                  : Colors.black54,
                            ),
                          ),
                          
                          // Read receipts (doar pentru mesajele mele)
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            _buildReadReceipt(context),
                          ],
                          
                          // Edited indicator
                          if (message.isEdited) ...[
                            const SizedBox(width: 4),
                            Text(
                              'Editat',
                              style: TextStyle(
                                fontSize: 10,
                                color: isMe 
                                    ? Colors.black54 
                                    : Colors.black54,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadReceipt(BuildContext context) {
    IconData icon;
    Color color;

    switch (message.status) {
      case MessageStatus.sending:
        icon = Icons.access_time;
        color = Colors.grey.shade400;
        break;
      case MessageStatus.sent:
        icon = Icons.done;
        color = Colors.grey.shade600;
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        color = Colors.grey.shade600;
        break;
      case MessageStatus.read:
        icon = Icons.done_all;
        color = const Color(0xFF4FC3F7); // Albastru WhatsApp pentru citit
        break;
    }

    return Icon(
      icon,
      size: 14,
      color: color,
    );
  }

  Widget _buildGifMessage(String gifUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: gifUrl,
        fit: BoxFit.cover,
        width: 200,
        height: 200,
        placeholder: (context, url) => Container(
          width: 200,
          height: 200,
          color: Colors.grey.shade200,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: 200,
          height: 200,
          color: Colors.grey.shade200,
          child: const Icon(Icons.error),
        ),
      ),
    );
  }

  Widget _buildImageMessage(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: 200,
        height: 200,
        placeholder: (context, url) => Container(
          width: 200,
          height: 200,
          color: Colors.grey.shade200,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: 200,
          height: 200,
          color: Colors.grey.shade200,
          child: const Icon(Icons.error),
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'acum';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return DateFormat('HH:mm').format(date);
    } else if (difference.inDays < 7) {
      return DateFormat('EEE HH:mm').format(date);
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    }
  }
}

/// CustomPainter pentru bubble-uri WhatsApp cu tail (triunghi)
class WhatsAppBubblePainter extends CustomPainter {
  final bool isMe;
  final Color color;

  WhatsAppBubblePainter({
    required this.isMe,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final radius = 8.0;
    final tailSize = 8.0;

    if (isMe) {
      // Bubble pentru mesajele mele (dreapta) - tail în stânga jos
      path.moveTo(radius, 0);
      path.lineTo(size.width - radius, 0);
      path.quadraticBezierTo(size.width, 0, size.width, radius);
      path.lineTo(size.width, size.height - radius - tailSize);
      path.quadraticBezierTo(size.width, size.height - tailSize, size.width - radius, size.height - tailSize);
      
      // Tail (triunghi) în stânga jos
      path.lineTo(tailSize, size.height - tailSize);
      path.lineTo(0, size.height);
      path.lineTo(0, size.height - tailSize);
      
      path.lineTo(0, radius);
      path.quadraticBezierTo(0, 0, radius, 0);
    } else {
      // Bubble pentru mesajele primite (stânga) - tail în dreapta jos
      path.moveTo(tailSize, 0);
      path.lineTo(size.width - radius, 0);
      path.quadraticBezierTo(size.width, 0, size.width, radius);
      path.lineTo(size.width, size.height - radius);
      path.quadraticBezierTo(size.width, size.height, size.width - radius, size.height);
      path.lineTo(radius, size.height);
      path.quadraticBezierTo(0, size.height, 0, size.height - radius);
      
      // Tail (triunghi) în dreapta jos
      path.lineTo(0, size.height - tailSize);
      path.lineTo(tailSize, size.height - tailSize);
      path.lineTo(tailSize, radius);
      path.quadraticBezierTo(tailSize, 0, tailSize + radius, 0);
    }

    path.close();
    canvas.drawPath(path, paint);

    // Shadow subtil
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawPath(path, shadowPaint);
  }

  @override
  bool shouldRepaint(WhatsAppBubblePainter oldDelegate) {
    return oldDelegate.isMe != isMe || oldDelegate.color != color;
  }
}

