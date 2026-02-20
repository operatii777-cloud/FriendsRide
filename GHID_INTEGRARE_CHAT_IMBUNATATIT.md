# 📱 GHID INTEGRARE - CHAT ÎMBUNĂTĂȚIT

## 📋 PREGĂTIRE

### Fișiere Create:
1. ✅ `lib/models/chat_message_model.dart` - Model îmbunătățit
2. ✅ `lib/models/quick_reply_model.dart` - Model pentru mesaje rapide
3. ✅ `lib/widgets/chat/chat_message_bubble.dart` - Widget bule moderne
4. ✅ `lib/widgets/chat/quick_replies_widget.dart` - Widget mesaje rapide
5. ✅ `lib/widgets/chat/typing_indicator_widget.dart` - Widget typing indicator

### Servicii Actualizate:
1. ✅ `lib/services/firestore_service.dart` - Metode noi pentru chat

---

## 🔧 PAȘI DE INTEGRARE

### Pasul 1: Înlocuiește UI-ul Chat-ului Existente

**Fișier:** `lib/screens/active_ride_screen.dart`

**Înlocuiește:**
```dart
// Vechiul cod (linia ~3684-3739)
return ListView.builder(
  reverse: true,
  shrinkWrap: true,
  itemCount: messages.length,
  itemBuilder: (context, index) {
    final doc = messages[index];
    final msg = doc.data();
    final isMe = msg['senderId'] == _currentUserId;
    final timestamp = msg['timestamp'] as Timestamp?;
    
    return Container(
      // ... bule simple
    );
  },
);
```

**Cu:**
```dart
// Noul cod
import 'package:friendsride_app/widgets/chat/chat_message_bubble.dart';
import 'package:friendsride_app/widgets/chat/typing_indicator_widget.dart';
import 'package:friendsride_app/models/chat_message_model.dart';

// În builder:
return Column(
  children: [
    // Typing indicator
    TypingIndicatorWidget(
      rideId: widget.rideId,
      otherUserName: _otherUserName,
    ),
    // Mesaje
    Expanded(
      child: ListView.builder(
        reverse: true,
        shrinkWrap: true,
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final doc = messages[index];
          final msg = ChatMessage.fromMap(doc.data());
          final isMe = msg.senderId == _currentUserId;
          
          return ChatMessageBubble(
            message: msg,
            isMe: isMe,
            senderName: isMe ? null : _otherUserName,
            senderAvatar: null, // TODO: Obține avatar din user profile
          );
        },
      ),
    ),
  ],
);
```

---

### Pasul 2: Adaugă Mesaje Rapide (Quick Replies)

**Fișier:** `lib/screens/active_ride_screen.dart`

**Adaugă înainte de input-ul de chat:**
```dart
import 'package:friendsride_app/widgets/chat/quick_replies_widget.dart';

// În _buildIntegratedChatField, înainte de input:
QuickRepliesWidget(
  rideId: widget.rideId,
  isDriver: _currentUserId == _previousRide?.driverId,
  onQuickReplySent: () {
    // Opțional: feedback când mesajul rapid este trimis
    HapticFeedback.lightImpact();
  },
),
```

---

### Pasul 3: Adaugă Typing Indicator în Input

**Fișier:** `lib/screens/active_ride_screen.dart`

**Adaugă în `_chatController` listener:**
```dart
Timer? _typingTimer;

void _onChatTextChanged(String text) {
  // Setează typing indicator
  _firestoreService.setTypingIndicator(widget.rideId, true);
  
  // Anulează timer-ul anterior
  _typingTimer?.cancel();
  
  // Setează typing = false după 3 secunde de inactivitate
  _typingTimer = Timer(const Duration(seconds: 3), () {
    _firestoreService.setTypingIndicator(widget.rideId, false);
  });
}

// În initState sau _startChatListening:
_chatController.addListener(() {
  _onChatTextChanged(_chatController.text);
});

// În dispose:
_typingTimer?.cancel();
```

---

### Pasul 4: Marchează Mesajele ca Citite

**Fișier:** `lib/screens/active_ride_screen.dart`

**Adaugă când chat-ul este deschis:**
```dart
void _startChatListening() {
  // ... cod existent ...
  
  // Marchează toate mesajele ca citite când chat-ul este deschis
  _firestoreService.markAllMessagesAsRead(widget.rideId);
  
  // Sau pentru fiecare mesaj nou:
  _chatSubscription = _firestoreService.getChatMessages(widget.rideId).listen((snapshot) {
    // ... cod existent ...
    
    // Marchează mesajele noi ca citite
    for (final doc in snapshot.docs) {
      final msg = ChatMessage.fromMap(doc.data());
      if (msg.senderId != _currentUserId && msg.status != MessageStatus.read) {
        _firestoreService.markMessageAsRead(widget.rideId, doc.id);
      }
    }
  });
}
```

---

### Pasul 5: Actualizează Trimiterea Mesajelor

**Fișier:** `lib/screens/active_ride_screen.dart`

**Actualizează `_sendMessage()`:**
```dart
void _sendMessage() {
  final messageText = _chatController.text.trim();
  if (messageText.isEmpty) return;

  try {
    // Setează typing = false
    _firestoreService.setTypingIndicator(widget.rideId, false);
    _typingTimer?.cancel();
    
    // Trimite mesajul
    unawaited(_firestoreService.sendChatMessage(
      widget.rideId,
      messageText,
      // quickReplyId: null, // Sau ID-ul dacă este mesaj rapid
      // locationData: null, // Sau datele dacă este mesaj cu locație
    ));
    
    _chatController.clear();
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();
    
    // Resetează badge-ul
    if (mounted) {
      setState(() {
        _unreadMessageCount = 0;
      });
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Eroare la trimiterea mesajului: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

---

### Pasul 6: Trimite Mesaje de Sistem

**Fișier:** `lib/screens/active_ride_screen.dart` sau `lib/services/firestore_service.dart`

**Exemplu când șoferul ajunge:**
```dart
void _handleDriverArrived() {
  _firestoreService.updateRideStatus(widget.rideId, 'arrived');
  
  // Trimite mesaj de sistem
  _firestoreService.sendSystemMessage(
    widget.rideId,
    'Șoferul a ajuns la locația de preluare',
  );
}
```

**Exemplu când cursa începe:**
```dart
void _handleRideStarted() {
  _firestoreService.updateRideStatus(widget.rideId, 'in_progress');
  
  // Trimite mesaj de sistem
  _firestoreService.sendSystemMessage(
    widget.rideId,
    'Cursa a început',
  );
}
```

---

## ✅ VERIFICARE

### Checklist:
- [ ] UI-ul chat-ului folosește `ChatMessageBubble`
- [ ] Mesajele rapide sunt afișate deasupra input-ului
- [ ] Typing indicator funcționează
- [ ] Mesajele sunt marcate ca citite
- [ ] Mesajele de sistem sunt trimise pentru evenimente importante
- [ ] Read receipts sunt afișate corect
- [ ] Timestamps relative funcționează

---

## 🐛 TROUBLESHOOTING

### Problema: Mesajele nu se afișează corect
**Soluție:** Verifică că folosești `ChatMessage.fromMap()` pentru a converti datele.

### Problema: Typing indicator nu funcționează
**Soluție:** Verifică că apelezi `setTypingIndicator()` când utilizatorul scrie.

### Problema: Read receipts nu se actualizează
**Soluție:** Verifică că apelezi `markMessageAsRead()` sau `markAllMessagesAsRead()`.

### Problema: Mesajele rapide nu se trimit
**Soluție:** Verifică că `QuickRepliesWidget` are `rideId` și `isDriver` setate corect.

---

**Document creat:** 2025-01-XX  
**Status:** Gata pentru integrare

