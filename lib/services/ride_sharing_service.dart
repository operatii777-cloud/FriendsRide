import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:friendsride_app/models/ride_sharing_model.dart';
import 'package:friendsride_app/services/firestore_service.dart';
import 'dart:math' as math;

/// Serviciu pentru ride sharing (călătorie partajată) - Uber-like
class RideSharingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Creează o cerere de ride sharing
  Future<RideShare?> createRideShareRequest({
    required String rideId,
    required String pickupAddress,
    required String destinationAddress,
    required double pickupLatitude,
    required double pickupLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
    required double originalCost,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final rideShare = RideShare(
        id: _db.collection('ride_shares').doc().id,
        rideId: rideId,
        passengerId: userId,
        pickupAddress: pickupAddress,
        destinationAddress: destinationAddress,
        pickupLatitude: pickupLatitude,
        pickupLongitude: pickupLongitude,
        destinationLatitude: destinationLatitude,
        destinationLongitude: destinationLongitude,
        requestedAt: Timestamp.now(),
        status: 'pending',
        originalCost: originalCost,
      );

      await _db.collection('ride_shares').doc(rideShare.id).set(rideShare.toMap());

      // Încearcă să facă match automat
      _tryMatchRideShare(rideShare);

      return rideShare;
    } catch (e) {
      debugPrint('⚠️ [RIDE_SHARING] Error creating ride share request: $e');
      return null;
    }
  }

  /// Încearcă să facă match pentru o cerere de ride sharing
  Future<void> _tryMatchRideShare(RideShare rideShare) async {
    try {
      // Caută alte cereri de ride sharing care pot fi match-uite
      final pendingShares = await _db
          .collection('ride_shares')
          .where('status', isEqualTo: 'pending')
          .where('passengerId', isNotEqualTo: rideShare.passengerId)
          .get();

      for (var doc in pendingShares.docs) {
        final otherShare = RideShare.fromMap(doc.data());
        
        // Verifică dacă rutele sunt compatibile
        if (_areRoutesCompatible(rideShare, otherShare)) {
          // Creează match
          await _createMatch(rideShare, otherShare);
          break; // Un match per cerere
        }
      }
    } catch (e) {
      debugPrint('⚠️ [RIDE_SHARING] Error trying to match ride share: $e');
    }
  }

  /// Verifică dacă două rute sunt compatibile pentru sharing
  bool _areRoutesCompatible(RideShare share1, RideShare share2) {
    return areRoutesCompatible(share1, share2);
  }

  /// Public static version for testing and external use
  static bool areRoutesCompatible(RideShare share1, RideShare share2) {
    // Calculează distanța între pickup points
    final pickupDistance = _distanceBetween(
      share1.pickupLatitude,
      share1.pickupLongitude,
      share2.pickupLatitude,
      share2.pickupLongitude,
    );

    // Calculează distanța între destination points
    final destinationDistance = _distanceBetween(
      share1.destinationLatitude,
      share1.destinationLongitude,
      share2.destinationLatitude,
      share2.destinationLongitude,
    );

    return pickupDistance < 2.0 && destinationDistance < 2.0;
  }

  static double _distanceBetween(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) * math.cos(lat2 * math.pi / 180) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  /// Creează un match între două cereri de ride sharing
  Future<void> _createMatch(RideShare share1, RideShare share2) async {
    try {
      // Calculează costul partajat (reducere de 30% pentru fiecare pasager)
      final sharedCost1 = share1.originalCost! * 0.7;
      final sharedCost2 = share2.originalCost! * 0.7;

      // Actualizează statusul pentru ambele cereri
      await _db.collection('ride_shares').doc(share1.id).update({
        'status': 'matched',
        'matchedRideId': share2.rideId,
        'sharedCost': sharedCost1,
        'matchedAt': Timestamp.now(),
      });

      await _db.collection('ride_shares').doc(share2.id).update({
        'status': 'matched',
        'matchedRideId': share1.rideId,
        'sharedCost': sharedCost2,
        'matchedAt': Timestamp.now(),
      });

      // ✅ NOU: Trimite mesaje de sistem pentru ambele curse
      try {
        final firestoreService = FirestoreService();
        await firestoreService.sendSystemMessage(
          share1.rideId,
          '🎉 Cursă partajată găsită! Costul tău: ${sharedCost1.toStringAsFixed(2)} RON (economie de ${(share1.originalCost! - sharedCost1).toStringAsFixed(2)} RON)',
        );
        await firestoreService.sendSystemMessage(
          share2.rideId,
          '🎉 Cursă partajată găsită! Costul tău: ${sharedCost2.toStringAsFixed(2)} RON (economie de ${(share2.originalCost! - sharedCost2).toStringAsFixed(2)} RON)',
        );
      } catch (e) {
        debugPrint('⚠️ [RIDE_SHARING] Error sending system messages: $e');
      }

      debugPrint('✅ [RIDE_SHARING] Match created between ${share1.id} and ${share2.id}');
    } catch (e) {
      debugPrint('⚠️ [RIDE_SHARING] Error creating match: $e');
    }
  }

  /// Obține ride share pentru o cursă
  Future<RideShare?> getRideShareForRide(String rideId) async {
    try {
      final snapshot = await _db
          .collection('ride_shares')
          .where('rideId', isEqualTo: rideId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return RideShare.fromMap(snapshot.docs.first.data());
    } catch (e) {
      debugPrint('⚠️ [RIDE_SHARING] Error getting ride share: $e');
      return null;
    }
  }

  /// Anulează o cerere de ride sharing
  Future<void> cancelRideShare(String rideShareId) async {
    try {
      await _db.collection('ride_shares').doc(rideShareId).update({
        'status': 'cancelled',
      });
    } catch (e) {
      debugPrint('⚠️ [RIDE_SHARING] Error cancelling ride share: $e');
    }
  }

  /// Stream pentru ride share updates
  Stream<RideShare?> getRideShareStream(String rideId) {
    return _db
        .collection('ride_shares')
        .where('rideId', isEqualTo: rideId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return RideShare.fromMap(snapshot.docs.first.data());
    });
  }
}

