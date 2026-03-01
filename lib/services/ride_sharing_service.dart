import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:friendsride_app/models/ride_sharing_model.dart';
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
    // Calculează distanța între pickup points
    final pickupDistance = _calculateDistance(
      share1.pickupLatitude,
      share1.pickupLongitude,
      share2.pickupLatitude,
      share2.pickupLongitude,
    );

    // Calculează distanța între destination points
    final destinationDistance = _calculateDistance(
      share1.destinationLatitude,
      share1.destinationLongitude,
      share2.destinationLatitude,
      share2.destinationLongitude,
    );

    // Rutele sunt compatibile dacă:
    // - Pickup points sunt la mai puțin de 2km unul de altul
    // - Destination points sunt la mai puțin de 2km unul de altul
    // - Sau dacă unul dintre pickup/destination este aproape de celălalt
    return pickupDistance < 2.0 && destinationDistance < 2.0;
  }

  /// Calculează distanța între două puncte (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) => degrees * math.pi / 180;

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
        await _db.collection('ride_system_messages').add({
          'rideId': share1.rideId,
          'message': '🎉 Cursă partajată găsită! Costul tău: ${sharedCost1.toStringAsFixed(2)} RON (economie de ${(share1.originalCost! - sharedCost1).toStringAsFixed(2)} RON)',
          'createdAt': Timestamp.now(),
        });
        await _db.collection('ride_system_messages').add({
          'rideId': share2.rideId,
          'message': '🎉 Cursă partajată găsită! Costul tău: ${sharedCost2.toStringAsFixed(2)} RON (economie de ${(share2.originalCost! - sharedCost2).toStringAsFixed(2)} RON)',
          'createdAt': Timestamp.now(),
        });
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

  // ---- Criterii avansate de matching ----

  static const double _maxDetourPercentage = 0.30; // 30% detour maxim
  static const int _timeWindowMinutes = 15; // ± 15 minute fereastră de timp

  /// Verifică dacă două cereri sunt compatibile folosind criterii avansate
  bool _areRoutesCompatibleAdvanced(
    RideShare share1,
    RideShare share2, {
    Map<String, dynamic>? prefs1,
    Map<String, dynamic>? prefs2,
  }) {
    // 1. Distanță pickup
    final pickupDistance = _calculateDistance(
      share1.pickupLatitude,
      share1.pickupLongitude,
      share2.pickupLatitude,
      share2.pickupLongitude,
    );

    // 2. Distanță destinație
    final destDistance = _calculateDistance(
      share1.destinationLatitude,
      share1.destinationLongitude,
      share2.destinationLatitude,
      share2.destinationLongitude,
    );

    if (pickupDistance >= 2.0 || destDistance >= 2.0) return false;

    // 3. Detour check: distanța suplimentară față de ruta directă nu depășește _maxDetourPercentage
    // Calculăm distanța reală cu detour (pickup la pickup2, destinație la destinație2)
    // vs distanța directă (pickup la destinație)
    final baseDist1 = _calculateDistance(
      share1.pickupLatitude,
      share1.pickupLongitude,
      share1.destinationLatitude,
      share1.destinationLongitude,
    );
    // Ruta combinată: share1.pickup -> share2.pickup -> share2.destination -> share1.destination
    final combinedDist = pickupDistance +
        _calculateDistance(
          share2.pickupLatitude,
          share2.pickupLongitude,
          share2.destinationLatitude,
          share2.destinationLongitude,
        ) +
        destDistance;
    final detourRatio = baseDist1 > 0 ? (combinedDist - baseDist1) / baseDist1 : 0.0;
    if (detourRatio > _maxDetourPercentage) return false;

    // 4. Fereastră de timp (dacă requestedAt este disponibil)
    final timeDiff = share1.requestedAt.toDate()
        .difference(share2.requestedAt.toDate())
        .inMinutes
        .abs();
    if (timeDiff > _timeWindowMinutes) return false;

    // 5. Preferințe pasager (fumător / animale)
    if (prefs1 != null && prefs2 != null) {
      final smoker1 = prefs1['smoker'] as bool? ?? false;
      final smoker2 = prefs2['smoker'] as bool? ?? false;
      final pets1 = prefs1['petFriendly'] as bool? ?? false;
      final pets2 = prefs2['petFriendly'] as bool? ?? false;

      // Dacă unul fumează și celălalt nu – incompatibili
      if (smoker1 != smoker2) return false;
      // Dacă unul are animale și celălalt nu acceptă – incompatibili
      if (pets1 && !pets2) return false;
    }

    return true;
  }

  /// Calculează scorul de potrivire (mai mare = mai bun)
  double _computeMatchScore(RideShare share1, RideShare share2) {
    double score = 100.0;

    final pickupDist = _calculateDistance(
      share1.pickupLatitude,
      share1.pickupLongitude,
      share2.pickupLatitude,
      share2.pickupLongitude,
    );
    final destDist = _calculateDistance(
      share1.destinationLatitude,
      share1.destinationLongitude,
      share2.destinationLatitude,
      share2.destinationLongitude,
    );

    // Penalizare distanță (max -40 puncte)
    score -= (pickupDist / 2.0) * 20;
    score -= (destDist / 2.0) * 20;

    // Penalizare diferență timp (max -20 puncte)
    final timeDiff = share1.requestedAt.toDate()
        .difference(share2.requestedAt.toDate())
        .inMinutes
        .abs();
    score -= (timeDiff / _timeWindowMinutes) * 20;

    return score.clamp(0.0, 100.0);
  }

  /// Găsește cel mai bun match pentru o cerere de ride sharing
  Future<RideShare?> findBestMatch(RideShare request) async {
    try {
      final pendingShares = await _db
          .collection('ride_shares')
          .where('status', isEqualTo: 'pending')
          .where('passengerId', isNotEqualTo: request.passengerId)
          .get();

      RideShare? bestCandidate;
      double bestScore = -1;

      for (final doc in pendingShares.docs) {
        final candidate = RideShare.fromMap(doc.data());
        if (!_areRoutesCompatibleAdvanced(request, candidate)) continue;

        final score = _computeMatchScore(request, candidate);
        if (score > bestScore) {
          bestScore = score;
          bestCandidate = candidate;
        }
      }

      debugPrint(
        bestCandidate != null
            ? '✅ [RIDE_SHARING] Best match: ${bestCandidate.id} (score: $bestScore)'
            : '⚠️ [RIDE_SHARING] No best match found for ${request.id}',
      );
      return bestCandidate;
    } catch (e) {
      debugPrint('⚠️ [RIDE_SHARING] Error finding best match: $e');
      return null;
    }
  }
}

