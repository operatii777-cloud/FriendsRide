import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:friendsride_app/models/gift_ride_model.dart';
import 'package:uuid/uuid.dart';

/// Serviciu pentru trimiterea și revendicarea curselor cadou
class GiftRideService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const int _expiryDays = 365;

  /// Trimite un gift ride unui destinatar
  Future<GiftRide?> sendGiftRide({
    required String recipientName,
    String? recipientEmail,
    String? recipientPhone,
    required double amount,
    String? message,
  }) async {
    try {
      final senderId = _auth.currentUser?.uid;
      if (senderId == null) throw Exception('User not authenticated');

      if (recipientEmail == null && recipientPhone == null) {
        throw Exception('Provide email or phone for recipient');
      }

      final id = const Uuid().v4();
      final code = _generateGiftCode();

      final gift = GiftRide(
        id: id,
        senderId: senderId,
        recipientEmail: recipientEmail,
        recipientPhone: recipientPhone,
        recipientName: recipientName,
        amount: amount,
        message: message,
        code: code,
        status: GiftRideStatus.pending,
        createdAt: Timestamp.now(),
        expiresAt: Timestamp.fromDate(
          DateTime.now().add(const Duration(days: _expiryDays)),
        ),
      );

      await _db.collection('gift_rides').doc(id).set(gift.toMap());
      debugPrint('✅ [GIFT_RIDE] Gift ride sent: $id (code: $code)');
      return gift;
    } catch (e) {
      debugPrint('⚠️ [GIFT_RIDE] Error sending gift ride: $e');
      return null;
    }
  }

  /// Revendică un gift ride folosind codul
  Future<GiftRide?> claimGiftRide(String code, String userId) async {
    try {
      final snapshot = await _db
          .collection('gift_rides')
          .where('code', isEqualTo: code.toUpperCase())
          .where('status', isEqualTo: GiftRideStatus.pending.name)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint('⚠️ [GIFT_RIDE] Code not found or already used: $code');
        return null;
      }

      final doc = snapshot.docs.first;
      final gift = GiftRide.fromMap(doc.data());

      if (!gift.isValid) {
        debugPrint('⚠️ [GIFT_RIDE] Gift ride expired: ${gift.id}');
        await _db.collection('gift_rides').doc(gift.id).update({
          'status': GiftRideStatus.expired.name,
        });
        return null;
      }

      await _db.collection('gift_rides').doc(gift.id).update({
        'status': GiftRideStatus.claimed.name,
        'claimedAt': Timestamp.now(),
        'claimedByUserId': userId,
      });

      debugPrint('✅ [GIFT_RIDE] Gift ride claimed: ${gift.id} by $userId');
      return gift.copyWith(
        status: GiftRideStatus.claimed,
        claimedAt: Timestamp.now(),
        claimedByUserId: userId,
      );
    } catch (e) {
      debugPrint('⚠️ [GIFT_RIDE] Error claiming gift ride: $e');
      return null;
    }
  }

  /// Obține cursele cadou trimise de utilizator
  Future<List<GiftRide>> getUserSentGifts(String userId) async {
    try {
      final snapshot = await _db
          .collection('gift_rides')
          .where('senderId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => GiftRide.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('⚠️ [GIFT_RIDE] Error getting sent gifts: $e');
      return [];
    }
  }

  /// Obține cursele cadou primite de utilizator
  Future<List<GiftRide>> getUserReceivedGifts(String userId) async {
    try {
      final snapshot = await _db
          .collection('gift_rides')
          .where('claimedByUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => GiftRide.fromMap(doc.data()))
          .toSet()
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('⚠️ [GIFT_RIDE] Error getting received gifts: $e');
      return [];
    }
  }

  /// Anulează un gift ride (doar expeditorul poate face asta)
  Future<bool> cancelGiftRide(String giftId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final doc = await _db.collection('gift_rides').doc(giftId).get();
      if (!doc.exists) return false;

      final gift = GiftRide.fromMap(doc.data()!);
      if (gift.senderId != userId) return false;
      if (gift.status != GiftRideStatus.pending) return false;

      await _db.collection('gift_rides').doc(giftId).update({
        'status': GiftRideStatus.cancelled.name,
      });

      debugPrint('✅ [GIFT_RIDE] Gift ride cancelled: $giftId');
      return true;
    } catch (e) {
      debugPrint('⚠️ [GIFT_RIDE] Error cancelling gift ride: $e');
      return false;
    }
  }

  /// Generează un cod unic pentru gift ride folosind UUID
  String _generateGiftCode() {
    final uuid = const Uuid().v4().replaceAll('-', '').toUpperCase();
    return 'GFT${uuid.substring(0, 6)}';
  }

  User? get currentUser => _auth.currentUser;
}
