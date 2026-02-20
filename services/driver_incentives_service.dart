import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:friendsride_app/models/driver_incentive_model.dart';
import 'package:friendsride_app/utils/logger.dart';

/// Serviciu pentru incentives șofer (Uber-like)
class DriverIncentivesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Obține toate incentives-urile pentru un șofer
  Future<List<DriverIncentive>> getDriverIncentives(String driverId) async {
    try {
      final snapshot = await _db
          .collection('driver_incentives')
          .where('driverId', isEqualTo: driverId)
          .get();

      return snapshot.docs
          .map((doc) => DriverIncentive.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('⚠️ [INCENTIVES] Error getting driver incentives: $e');
      return [];
    }
  }

  /// Obține incentives-urile active pentru un șofer
  Future<List<DriverIncentive>> getActiveIncentives(String driverId) async {
    try {
      final allIncentives = await getDriverIncentives(driverId);
      return allIncentives.where((incentive) => incentive.isActive).toList();
    } catch (e) {
      debugPrint('⚠️ [INCENTIVES] Error getting active incentives: $e');
      return [];
    }
  }

  /// Actualizează progresul unui incentive
  Future<void> updateIncentiveProgress(
    String incentiveId,
    int newProgress,
  ) async {
    try {
      await _db.collection('driver_incentives').doc(incentiveId).update({
        'currentProgress': newProgress,
        if (newProgress >= 100) 'isCompleted': true,
        if (newProgress >= 100) 'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('⚠️ [INCENTIVES] Error updating incentive progress: $e');
    }
  }

  /// Stream pentru incentives-urile unui șofer
  Stream<List<DriverIncentive>> getDriverIncentivesStream(String driverId) {
    return _db
        .collection('driver_incentives')
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DriverIncentive.fromMap({'id': doc.id, ...doc.data()}))
          .toList();
    }).handleError((error) {
      debugPrint('⚠️ [INCENTIVES] Stream error: $error');
      return <DriverIncentive>[]; // Return empty list on error
    });
  }

  /// Actualizează progresul incentives după finalizarea unei curse
  Future<void> updateIncentivesAfterRideCompletion(String driverId) async {
    try {
      final activeIncentives = await getActiveIncentives(driverId);
      
      for (final incentive in activeIncentives) {
        if (incentive.type == IncentiveType.quest && incentive.targetRides != null) {
          // Increment progress for quests
          final newProgress = (incentive.currentProgress ?? 0) + 1;
          await updateIncentiveProgress(incentive.id, newProgress);
          
          // Check if quest is completed
          if (newProgress >= incentive.targetRides!) {
            await _completeIncentive(incentive.id, incentive.reward);
            Logger.info('Quest completed: ${incentive.title}', tag: 'DriverIncentives');
          }
        } else if (incentive.type == IncentiveType.streak) {
          // Update streak bonus
          await _updateStreakBonus(driverId, incentive.id);
        }
      }
    } catch (e) {
      Logger.error('Error updating incentives after ride completion', error: e, tag: 'DriverIncentives');
    }
  }

  /// Actualizează streak bonus pentru șofer
  Future<void> _updateStreakBonus(String driverId, String incentiveId) async {
    try {
      // Get driver's streak count
      final driverDoc = await _db.collection('users').doc(driverId).get();
      final currentStreak = (driverDoc.data()?['currentStreak'] as num?)?.toInt() ?? 0;
      final newStreak = currentStreak + 1;
      
      // Update driver streak
      await _db.collection('users').doc(driverId).update({
        'currentStreak': newStreak,
        'lastStreakUpdate': FieldValue.serverTimestamp(),
      });
      
      // Update incentive progress
      final incentiveDoc = await _db.collection('driver_incentives').doc(incentiveId).get();
      if (incentiveDoc.exists) {
        final incentive = DriverIncentive.fromMap({'id': incentiveId, ...incentiveDoc.data()!});
        if (incentive.targetRides != null && newStreak >= incentive.targetRides!) {
          await _completeIncentive(incentiveId, incentive.reward);
        } else {
          await _db.collection('driver_incentives').doc(incentiveId).update({
            'currentProgress': newStreak,
          });
        }
      }
      
      Logger.info('Streak updated: $newStreak', tag: 'DriverIncentives');
    } catch (e) {
      Logger.error('Error updating streak bonus', error: e, tag: 'DriverIncentives');
    }
  }

  /// Completează un incentive și atribuie recompensa
  Future<void> _completeIncentive(String incentiveId, double reward) async {
    try {
      await _db.collection('driver_incentives').doc(incentiveId).update({
        'isCompleted': true,
        'completedAt': FieldValue.serverTimestamp(),
        'earnedAmount': reward,
      });
      
      // Add reward to driver earnings
      final incentiveDoc = await _db.collection('driver_incentives').doc(incentiveId).get();
      if (incentiveDoc.exists) {
        final driverId = incentiveDoc.data()?['driverId'] as String?;
        if (driverId != null) {
          await _addRewardToEarnings(driverId, reward);
        }
      }
    } catch (e) {
      Logger.error('Error completing incentive', error: e, tag: 'DriverIncentives');
    }
  }

  /// Adaugă recompensa la câștigurile șoferului
  Future<void> _addRewardToEarnings(String driverId, double reward) async {
    try {
      final driverDoc = await _db.collection('users').doc(driverId).get();
      final currentEarnings = (driverDoc.data()?['totalEarnings'] as num?)?.toDouble() ?? 0.0;
      await _db.collection('users').doc(driverId).update({
        'totalEarnings': currentEarnings + reward,
        'incentiveEarnings': FieldValue.increment(reward),
      });
    } catch (e) {
      Logger.error('Error adding reward to earnings', error: e, tag: 'DriverIncentives');
    }
  }

  /// Creează quest automat pentru șofer
  Future<void> createQuestForDriver(String driverId, {
    required String title,
    required String description,
    required int targetRides,
    required double reward,
    required DateTime endDate,
  }) async {
    try {
      await _db.collection('driver_incentives').add({
        'driverId': driverId,
        'type': IncentiveType.quest.name,
        'title': title,
        'description': description,
        'reward': reward,
        'startDate': FieldValue.serverTimestamp(),
        'endDate': Timestamp.fromDate(endDate),
        'targetRides': targetRides,
        'currentProgress': 0,
        'isCompleted': false,
      });
      Logger.info('Quest created for driver: $driverId', tag: 'DriverIncentives');
    } catch (e) {
      Logger.error('Error creating quest', error: e, tag: 'DriverIncentives');
    }
  }

  /// Creează streak bonus pentru șofer
  Future<void> createStreakBonusForDriver(String driverId, {
    required int targetStreak,
    required double reward,
    required DateTime endDate,
  }) async {
    try {
      await _db.collection('driver_incentives').add({
        'driverId': driverId,
        'type': IncentiveType.streak.name,
        'title': 'Streak Bonus',
        'description': 'Fă $targetStreak curse consecutive',
        'reward': reward,
        'startDate': FieldValue.serverTimestamp(),
        'endDate': Timestamp.fromDate(endDate),
        'targetRides': targetStreak,
        'currentProgress': 0,
        'isCompleted': false,
      });
      Logger.info('Streak bonus created for driver: $driverId', tag: 'DriverIncentives');
    } catch (e) {
      Logger.error('Error creating streak bonus', error: e, tag: 'DriverIncentives');
    }
  }

  /// Verifică și aplică guaranteed earnings
  Future<void> checkGuaranteedEarnings(String driverId, double actualEarnings, DateTime periodStart, DateTime periodEnd) async {
    try {
      final guaranteedIncentives = await _db
          .collection('driver_incentives')
          .where('driverId', isEqualTo: driverId)
          .where('type', isEqualTo: IncentiveType.guaranteed.name)
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(periodEnd))
          .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(periodStart))
          .get();

      for (final doc in guaranteedIncentives.docs) {
        final incentive = DriverIncentive.fromMap({'id': doc.id, ...doc.data()});
        final guaranteedAmount = incentive.reward;
        
        if (actualEarnings < guaranteedAmount) {
          final difference = guaranteedAmount - actualEarnings;
          await _addRewardToEarnings(driverId, difference);
          Logger.info('Guaranteed earnings applied: $difference RON', tag: 'DriverIncentives');
        }
      }
    } catch (e) {
      Logger.error('Error checking guaranteed earnings', error: e, tag: 'DriverIncentives');
    }
  }
}

