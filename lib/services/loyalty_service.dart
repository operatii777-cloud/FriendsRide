import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:friendsride_app/models/loyalty_program_model.dart';
import 'package:friendsride_app/utils/logger.dart';

/// Serviciu simplificat de loialitate – expune API clar pentru
/// adăugare/răscumpărare puncte și interogarea tierului curent.
///
/// Complementar cu [LoyaltyProgramService] (care gestionează fluxul
/// complet post-cursă); [LoyaltyService] este destinat operațiunilor
/// punctuale din UI (ex: reward manual, răscumpărare puncte în checkout).
class LoyaltyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ────────────────────────────────────────────────────────────────────────────
  // Puncte
  // ────────────────────────────────────────────────────────────────────────────

  /// Adaugă [points] puncte pentru utilizatorul autentificat (sau [userId]).
  ///
  /// Actualizează automat tier-ul dacă pragul este atins.
  /// Returnează noul total de puncte, sau `null` la eroare.
  Future<int?> addPoints(int points, {String? userId, String? reason}) async {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) {
      Logger.error('addPoints: user not authenticated', tag: 'LoyaltyService');
      return null;
    }
    if (points <= 0) return null;

    try {
      final ref = _db.collection('loyalty_programs').doc(uid);
      final doc = await ref.get();

      int currentPoints = 0;
      int totalRides = 0;
      double totalSpent = 0.0;

      if (doc.exists) {
        final data = doc.data()!;
        currentPoints = (data['points'] as num?)?.toInt() ?? 0;
        totalRides = (data['totalRides'] as num?)?.toInt() ?? 0;
        totalSpent = (data['totalSpent'] as num?)?.toDouble() ?? 0.0;
      }

      final newPoints = currentPoints + points;
      final newTier = LoyaltyProgram.calculateTier(newPoints, totalRides);

      await ref.set({
        'userId': uid,
        'points': newPoints,
        'totalRides': totalRides,
        'totalSpent': totalSpent,
        'currentTier': newTier.name,
        'lastUpdated': FieldValue.serverTimestamp(),
        if (reason != null) 'lastPointReason': reason,
      }, SetOptions(merge: true));

      Logger.info('addPoints: +$points for $uid (total: $newPoints)', tag: 'LoyaltyService');
      return newPoints;
    } catch (e) {
      Logger.error('addPoints failed: $e', error: e, tag: 'LoyaltyService');
      return null;
    }
  }

  /// Răscumpără [points] puncte (le scade din sold) pentru utilizatorul curent.
  ///
  /// Returnează `true` la succes, `false` dacă punctele sunt insuficiente sau
  /// la eroare.
  Future<bool> redeemPoints(int points, {String? userId, String? description}) async {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) return false;
    if (points <= 0) return false;

    try {
      final ref = _db.collection('loyalty_programs').doc(uid);
      final doc = await ref.get();

      if (!doc.exists) return false;

      final data = doc.data()!;
      final currentPoints = (data['points'] as num?)?.toInt() ?? 0;

      if (currentPoints < points) {
        Logger.info(
          'redeemPoints: insufficient points ($currentPoints < $points) for $uid',
          tag: 'LoyaltyService',
        );
        return false;
      }

      final newPoints = currentPoints - points;
      final totalRides = (data['totalRides'] as num?)?.toInt() ?? 0;
      final newTier = LoyaltyProgram.calculateTier(newPoints, totalRides);

      await ref.update({
        'points': newPoints,
        'currentTier': newTier.name,
        'lastUpdated': FieldValue.serverTimestamp(),
        if (description != null) 'lastRedemptionDescription': description,
      });

      // Audit trail pentru răscumpărări
      await _db.collection('loyalty_redemptions').add({
        'userId': uid,
        'pointsRedeemed': points,
        'description': description ?? 'Manual redemption',
        'redeemedAt': FieldValue.serverTimestamp(),
      });

      Logger.info('redeemPoints: -$points for $uid (remaining: $newPoints)', tag: 'LoyaltyService');
      return true;
    } catch (e) {
      Logger.error('redeemPoints failed: $e', error: e, tag: 'LoyaltyService');
      return false;
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Tier
  // ────────────────────────────────────────────────────────────────────────────

  /// Returnează tier-ul curent al utilizatorului ([LoyaltyTier]).
  ///
  /// Dacă nu există un document de loialitate, returnează [LoyaltyTier.bronze].
  Future<LoyaltyTier> getUserTier({String? userId}) async {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) return LoyaltyTier.bronze;

    try {
      final doc = await _db.collection('loyalty_programs').doc(uid).get();
      if (!doc.exists) return LoyaltyTier.bronze;

      final data = doc.data()!;
      final tierName = data['currentTier'] as String? ?? 'bronze';
      return LoyaltyTier.values.firstWhere(
        (t) => t.name == tierName,
        orElse: () => LoyaltyTier.bronze,
      );
    } catch (e) {
      Logger.error('getUserTier failed: $e', error: e, tag: 'LoyaltyService');
      return LoyaltyTier.bronze;
    }
  }

  /// Returnează numărul curent de puncte al utilizatorului.
  Future<int> getPointBalance({String? userId}) async {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) return 0;

    try {
      final doc = await _db.collection('loyalty_programs').doc(uid).get();
      if (!doc.exists) return 0;
      return (doc.data()!['points'] as num?)?.toInt() ?? 0;
    } catch (e) {
      Logger.error('getPointBalance failed: $e', error: e, tag: 'LoyaltyService');
      return 0;
    }
  }

  /// Stream în timp real al soldului de puncte pentru un utilizator.
  Stream<int> getPointBalanceStream({String? userId}) {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _db.collection('loyalty_programs').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return 0;
      return (doc.data()!['points'] as num?)?.toInt() ?? 0;
    });
  }
}
