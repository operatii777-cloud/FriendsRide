import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Programează o notificare pentru o cursă viitoare
  Future<void> scheduleRideNotification(String rideId, DateTime scheduledTime) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    await _db.collection('ride_notifications').add({
      'userId': userId,
      'rideId': rideId,
      'scheduledTime': scheduledTime.toIso8601String(),
      'sent': false,
    });
  }

  /// Marchează notificarea ca trimisă
  Future<void> markNotificationSent(String notificationId) async {
    await _db.collection('ride_notifications').doc(notificationId).update({'sent': true});
  }

  /// Obține notificările programate pentru utilizator
  Future<List<Map<String, dynamic>>> getScheduledNotifications() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    final query = await _db.collection('ride_notifications').where('userId', isEqualTo: userId).where('sent', isEqualTo: false).get();
    return query.docs.map((doc) => doc.data()).toList();
  }
}
