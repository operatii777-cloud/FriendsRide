import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:friendsride_app/models/loyalty_program_model.dart';
import 'package:friendsride_app/models/ride_model.dart';
import 'package:friendsride_app/utils/logger.dart';

/// Serviciu pentru programul de loialitate (Uber-like)
class LoyaltyProgramService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Obține programul de loialitate pentru utilizator
  Future<LoyaltyProgram?> getLoyaltyProgram(String userId) async {
    try {
      final doc = await _db.collection('loyalty_programs').doc(userId).get();
      if (!doc.exists) {
        // Creează program nou dacă nu există
        return await _createLoyaltyProgram(userId);
      }
      return LoyaltyProgram.fromMap(doc.data()!);
    } catch (e) {
      Logger.error('Error getting loyalty program: $e', tag: 'LOYALTY', error: e);
      return null;
    }
  }

  /// Creează un program de loialitate nou
  Future<LoyaltyProgram> _createLoyaltyProgram(String userId) async {
    final program = LoyaltyProgram(
      userId: userId,
      currentTier: LoyaltyTier.bronze,
      points: 0,
      totalRides: 0,
      totalSpent: 0.0,
    );

    await _db.collection('loyalty_programs').doc(userId).set(program.toMap());
    return program;
  }

  /// Actualizează programul de loialitate după o cursă
  Future<void> updateLoyaltyAfterRide(String userId, Ride ride) async {
    try {
      final program = await getLoyaltyProgram(userId);
      if (program == null) return;

      final pointsEarned = LoyaltyProgram.calculatePointsForRide(ride.totalCost);
      final newPoints = program.points + pointsEarned;
      final newTotalRides = program.totalRides + 1;
      final newTotalSpent = program.totalSpent + ride.totalCost;
      
      final newTier = LoyaltyProgram.calculateTier(newPoints, newTotalRides);
      final tierUpgraded = newTier != program.currentTier;

      await _db.collection('loyalty_programs').doc(userId).update({
        'points': newPoints,
        'totalRides': newTotalRides,
        'totalSpent': newTotalSpent,
        'currentTier': newTier.name,
        if (tierUpgraded) 'tierUpgradedAt': FieldValue.serverTimestamp(),
        'lastRideAt': FieldValue.serverTimestamp(),
      });

      if (tierUpgraded) {
        Logger.info('User upgraded to ${newTier.name} tier!', tag: 'LOYALTY');
      }
    } catch (e) {
      Logger.error('Error updating loyalty after ride: $e', tag: 'LOYALTY', error: e);
    }
  }

  /// Stream pentru programul de loialitate
  Stream<LoyaltyProgram?> getLoyaltyProgramStream(String userId) {
    return _db
        .collection('loyalty_programs')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return LoyaltyProgram.fromMap(doc.data()!);
    });
  }
}

