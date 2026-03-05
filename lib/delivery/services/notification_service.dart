import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import 'package:friendsride_app/utils/logger.dart';

/// Service pentru gestionarea notificărilor delivery
class DeliveryNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Inițializează serviciul de notificări
  Future<void> initialize() async {
    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get FCM token
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _saveTokenToFirestore(newToken);
      });
    }
  }

  /// Salvează token-ul FCM în Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Salvează token-ul în documentul utilizatorului
      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Salvează și în colecția de tokens pentru notificări
      await _firestore.collection('fcm_tokens').doc(user.uid).set({
        'userId': user.uid,
        'token': token,
        'updatedAt': FieldValue.serverTimestamp(),
        'platform': 'mobile', // sau 'web' dacă e web
      }, SetOptions(merge: true));
    } catch (e) {
      // Log error but don't throw
      Logger.error('Error saving FCM token: $e', error: e);
    }
  }

  /// Trimite notificare push
  Future<void> sendPushNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // Create notification in Firestore
    await createNotification(
      userId: userId,
      type: type,
      title: title,
      body: body,
      data: data,
    );

    // Send push notification via Cloud Messaging
    // This will be handled by Cloud Functions
    // For now, we just create the notification in Firestore
  }

  /// Creează notificare în Firestore
  Future<void> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final notification = DeliveryNotification(
      id: _firestore.collection('delivery_notifications').doc().id,
      userId: userId,
      type: type,
      title: title,
      body: body,
      data: data,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('delivery_notifications')
        .doc(notification.id)
        .set(notification.toFirestore());
  }

  /// Obține notificările pentru un utilizator
  Stream<List<DeliveryNotification>> getUserNotifications(String userId) {
    return _firestore
        .collection('delivery_notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DeliveryNotification.fromFirestore(doc))
            .toList());
  }

  /// Marchează notificarea ca citită
  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection('delivery_notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  /// Marchează toate notificările ca citite
  Future<void> markAllAsRead(String userId) async {
    final batch = _firestore.batch();
    final notifications = await _firestore
        .collection('delivery_notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in notifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  /// Șterge notificarea
  Future<void> deleteNotification(String notificationId) async {
    await _firestore
        .collection('delivery_notifications')
        .doc(notificationId)
        .delete();
  }

  /// Obține numărul de notificări necitite
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('delivery_notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Helper: Creează notificare pentru comandă creată
  Future<void> notifyOrderCreated({
    required String customerId,
    required String orderId,
    required String restaurantName,
  }) async {
    await sendPushNotification(
      userId: customerId,
      type: NotificationType.orderCreated,
      title: 'Comandă plasată',
      body: 'Comanda ta la $restaurantName a fost plasată cu succes!',
      data: {'orderId': orderId, 'type': 'orderCreated'},
    );
  }

  /// Helper: Creează notificare pentru comandă acceptată
  Future<void> notifyOrderAccepted({
    required String customerId,
    required String orderId,
    required String restaurantName,
  }) async {
    await sendPushNotification(
      userId: customerId,
      type: NotificationType.orderAccepted,
      title: 'Comandă acceptată',
      body: '$restaurantName a acceptat comanda ta!',
      data: {'orderId': orderId, 'type': 'orderAccepted'},
    );
  }

  /// Helper: Creează notificare pentru comandă gata
  Future<void> notifyOrderReady({
    required String customerId,
    required String orderId,
    required String restaurantName,
  }) async {
    await sendPushNotification(
      userId: customerId,
      type: NotificationType.orderReady,
      title: 'Comandă gata',
      body: 'Comanda ta de la $restaurantName este gata pentru livrare!',
      data: {'orderId': orderId, 'type': 'orderReady'},
    );
  }

  /// Helper: Creează notificare pentru curier asignat
  Future<void> notifyCourierAssigned({
    required String customerId,
    required String orderId,
    required String courierName,
  }) async {
    await sendPushNotification(
      userId: customerId,
      type: NotificationType.courierAssigned,
      title: 'Curier asignat',
      body: '$courierName va livra comanda ta!',
      data: {'orderId': orderId, 'type': 'courierAssigned'},
    );
  }

  /// Helper: Creează notificare pentru comandă în drum
  Future<void> notifyOrderOnTheWay({
    required String customerId,
    required String orderId,
    required String courierName,
  }) async {
    await sendPushNotification(
      userId: customerId,
      type: NotificationType.orderOnTheWay,
      title: 'Comandă în drum',
      body: '$courierName este în drum cu comanda ta!',
      data: {'orderId': orderId, 'type': 'orderOnTheWay'},
    );
  }

  /// Helper: Creează notificare pentru comandă livrată
  Future<void> notifyOrderDelivered({
    required String customerId,
    required String orderId,
  }) async {
    await sendPushNotification(
      userId: customerId,
      type: NotificationType.orderDelivered,
      title: 'Comandă livrată',
      body: 'Comanda ta a fost livrată cu succes! Te rugăm să lași un review.',
      data: {'orderId': orderId, 'type': 'orderDelivered'},
    );
  }

  /// Helper: Creează notificare pentru comandă nouă (restaurant)
  Future<void> notifyRestaurantNewOrder({
    required String restaurantId,
    required String orderId,
    required double total,
  }) async {
    await sendPushNotification(
      userId: restaurantId,
      type: NotificationType.orderCreated,
      title: 'Comandă nouă',
      body: 'Ai primit o comandă nouă de ${total.toStringAsFixed(2)} RON',
      data: {'orderId': orderId, 'type': 'orderCreated', 'total': total},
    );
  }

  /// Helper: Creează notificare pentru comandă disponibilă (curier)
  Future<void> notifyCourierNewOrder({
    required String courierId,
    required String orderId,
    required double total,
    required double distance,
  }) async {
    await sendPushNotification(
      userId: courierId,
      type: NotificationType.orderCreated,
      title: 'Comandă disponibilă',
      body: 'Comandă nouă disponibilă: ${total.toStringAsFixed(2)} RON, ${distance.toStringAsFixed(1)} km',
      data: {
        'orderId': orderId,
        'type': 'orderCreated',
        'total': total,
        'distance': distance,
      },
    );
  }
}

