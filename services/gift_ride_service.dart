import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GiftRideService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Oferă o cursă cadou unui alt utilizator
  Future<bool> sendGiftRide(String recipientUserId, double amount) async {
    final senderId = _auth.currentUser?.uid;
    if (senderId == null) throw Exception('User not authenticated');
    await _db.collection('gift_rides').add({
      'senderId': senderId,
      'recipientUserId': recipientUserId,
      'amount': amount,
      'timestamp': DateTime.now().toIso8601String(),
    });
    return true;
  }

  /// Verifică dacă utilizatorul are o cursă cadou disponibilă
  Future<double?> checkGiftRideBalance() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    final gifts = await _db.collection('gift_rides').where('recipientUserId', isEqualTo: userId).get();
    double total = 0;
    for (var doc in gifts.docs) {
      total += (doc.data()['amount'] ?? 0);
    }
    return total > 0 ? total : null;
  }
}
