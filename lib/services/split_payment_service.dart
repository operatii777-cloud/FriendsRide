import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:friendsride_app/models/split_payment_model.dart';
import 'package:friendsride_app/services/push_notification_service.dart';
import 'package:friendsride_app/utils/logger.dart';
import 'package:uuid/uuid.dart';

/// Serviciu pentru split payment (împărțirea costului între pasageri) - Uber-like
class SplitPaymentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  /// Creează un split payment pentru o cursă
  Future<SplitPayment?> createSplitPayment({
    required String rideId,
    required double totalAmount,
    required int numberOfSplits,
    List<String>? participantUserIds,
    List<String>? participantEmails,
    List<String>? participantPhoneNumbers,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final amountPerPerson = totalAmount / numberOfSplits;
      final splitId = _uuid.v4();
      
      // Generează link de partajare
      final shareLink = 'https://friendsride.app/split/$splitId';

      // Creează lista de participanți
      final participants = <SplitPaymentParticipant>[];
      
      // Adaugă inițiatorul ca primul participant (deja acceptat și plătit)
      participants.add(SplitPaymentParticipant(
        userId: userId,
        hasAccepted: true,
        hasPaid: true,
        acceptedAt: Timestamp.now(),
        paidAt: Timestamp.now(),
      ));

      // Adaugă ceilalți participanți
      for (int i = 0; i < numberOfSplits - 1; i++) {
        participants.add(SplitPaymentParticipant(
          userId: participantUserIds?[i] ?? '',
          email: participantEmails?[i],
          phoneNumber: participantPhoneNumbers?[i],
          hasAccepted: false,
          hasPaid: false,
        ));
      }

      final splitPayment = SplitPayment(
        id: splitId,
        rideId: rideId,
        initiatorId: userId,
        totalAmount: totalAmount,
        numberOfSplits: numberOfSplits,
        amountPerPerson: amountPerPerson,
        participants: participants,
        createdAt: Timestamp.now(),
        expiresAt: Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
        status: SplitPaymentStatus.pending,
        shareLink: shareLink,
      );

      await _db.collection('split_payments').doc(splitId).set(splitPayment.toMap());

      // Trimite notificări către participanți
      await _notifyParticipants(splitPayment);

      Logger.info('Split payment created: $splitId', tag: 'SplitPayment');
      return splitPayment;
    } catch (e) {
      Logger.error('Error creating split payment', error: e, tag: 'SplitPayment');
      return null;
    }
  }

  /// Acceptă un split payment de către un participant
  Future<bool> acceptSplitPayment(String splitPaymentId, String userId) async {
    try {
      final splitDoc = await _db.collection('split_payments').doc(splitPaymentId).get();
      if (!splitDoc.exists) {
        throw Exception('Split payment not found');
      }

      final splitData = splitDoc.data()!;
      final splitPayment = SplitPayment.fromMap({'id': splitPaymentId, ...splitData});

      // Găsește participantul
      final participantIndex = splitPayment.participants.indexWhere((p) => p.userId == userId);
      if (participantIndex == -1) {
        throw Exception('User is not a participant in this split payment');
      }

      // Actualizează participantul
      final updatedParticipants = List<SplitPaymentParticipant>.from(splitPayment.participants);
      updatedParticipants[participantIndex] = SplitPaymentParticipant(
        userId: updatedParticipants[participantIndex].userId,
        displayName: updatedParticipants[participantIndex].displayName,
        email: updatedParticipants[participantIndex].email,
        phoneNumber: updatedParticipants[participantIndex].phoneNumber,
        hasAccepted: true,
        hasPaid: updatedParticipants[participantIndex].hasPaid,
        acceptedAt: Timestamp.now(),
        paidAt: updatedParticipants[participantIndex].paidAt,
        paymentMethodId: updatedParticipants[participantIndex].paymentMethodId,
      );

      // Verifică dacă toți au acceptat
      final allAccepted = updatedParticipants.every((p) => p.hasAccepted);
      final newStatus = allAccepted ? SplitPaymentStatus.accepted : SplitPaymentStatus.pending;

      await _db.collection('split_payments').doc(splitPaymentId).update({
        'participants': updatedParticipants.map((p) => p.toMap()).toList(),
        'status': newStatus.name,
      });

      Logger.info('Split payment accepted by user: $userId', tag: 'SplitPayment');
      return true;
    } catch (e) {
      Logger.error('Error accepting split payment', error: e, tag: 'SplitPayment');
      return false;
    }
  }

  /// Marchează plata ca finalizată pentru un participant
  Future<bool> markPaymentCompleted(String splitPaymentId, String userId, String? paymentMethodId) async {
    try {
      final splitDoc = await _db.collection('split_payments').doc(splitPaymentId).get();
      if (!splitDoc.exists) {
        throw Exception('Split payment not found');
      }

      final splitData = splitDoc.data()!;
      final splitPayment = SplitPayment.fromMap({'id': splitPaymentId, ...splitData});

      // Găsește participantul
      final participantIndex = splitPayment.participants.indexWhere((p) => p.userId == userId);
      if (participantIndex == -1) {
        throw Exception('User is not a participant in this split payment');
      }

      // Actualizează participantul
      final updatedParticipants = List<SplitPaymentParticipant>.from(splitPayment.participants);
      updatedParticipants[participantIndex] = SplitPaymentParticipant(
        userId: updatedParticipants[participantIndex].userId,
        displayName: updatedParticipants[participantIndex].displayName,
        email: updatedParticipants[participantIndex].email,
        phoneNumber: updatedParticipants[participantIndex].phoneNumber,
        hasAccepted: updatedParticipants[participantIndex].hasAccepted,
        hasPaid: true,
        acceptedAt: updatedParticipants[participantIndex].acceptedAt,
        paidAt: Timestamp.now(),
        paymentMethodId: paymentMethodId,
      );

      // Verifică dacă toate plățile sunt finalizate
      final allPaid = updatedParticipants.every((p) => p.hasPaid);
      final newStatus = allPaid ? SplitPaymentStatus.completed : SplitPaymentStatus.accepted;

      await _db.collection('split_payments').doc(splitPaymentId).update({
        'participants': updatedParticipants.map((p) => p.toMap()).toList(),
        'status': newStatus.name,
      });

      Logger.info('Payment completed by user: $userId', tag: 'SplitPayment');
      return true;
    } catch (e) {
      Logger.error('Error marking payment as completed', error: e, tag: 'SplitPayment');
      return false;
    }
  }

  /// Obține split payment pentru o cursă
  Future<SplitPayment?> getSplitPaymentForRide(String rideId) async {
    try {
      final snapshot = await _db
          .collection('split_payments')
          .where('rideId', isEqualTo: rideId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return SplitPayment.fromMap({'id': snapshot.docs.first.id, ...snapshot.docs.first.data()});
    } catch (e) {
      Logger.error('Error getting split payment', error: e, tag: 'SplitPayment');
      return null;
    }
  }

  /// Obține split payment după ID
  Future<SplitPayment?> getSplitPaymentById(String splitPaymentId) async {
    try {
      final doc = await _db.collection('split_payments').doc(splitPaymentId).get();
      if (!doc.exists) return null;
      return SplitPayment.fromMap({'id': doc.id, ...doc.data()!});
    } catch (e) {
      Logger.error('Error getting split payment by ID', error: e, tag: 'SplitPayment');
      return null;
    }
  }

  /// Anulează un split payment
  Future<bool> cancelSplitPayment(String splitPaymentId) async {
    try {
      await _db.collection('split_payments').doc(splitPaymentId).update({
        'status': SplitPaymentStatus.cancelled.name,
      });
      Logger.info('Split payment cancelled: $splitPaymentId', tag: 'SplitPayment');
      return true;
    } catch (e) {
      Logger.error('Error cancelling split payment', error: e, tag: 'SplitPayment');
      return false;
    }
  }

  /// Stream pentru split payment updates
  Stream<SplitPayment?> getSplitPaymentStream(String splitPaymentId) {
    return _db
        .collection('split_payments')
        .doc(splitPaymentId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return SplitPayment.fromMap({'id': snapshot.id, ...snapshot.data()!});
    });
  }

  /// Trimite notificări către participanți
  Future<void> _notifyParticipants(SplitPayment splitPayment) async {
    try {
      // ✅ IMPLEMENTED: Integrare cu PushNotificationService
      final pushService = PushNotificationService();
      if (!pushService.isInitialized) {
        await pushService.initialize();
      }
      
      for (final participant in splitPayment.participants) {
        if (participant.userId != splitPayment.initiatorId) {
          Logger.info('Notifying participant ${participant.userId} about split payment ${splitPayment.id}', tag: 'SplitPayment');
          
          // Get participant FCM token
          final participantDoc = await _db.collection('users').doc(participant.userId).get();
          final fcmToken = participantDoc.data()?['fcmToken'] as String?;
          
          if (fcmToken != null) {
            // Send notification via Cloud Function or direct FCM
            try {
              await pushService.functions.httpsCallable('sendSplitPaymentNotification').call({
                'token': fcmToken,
                'splitPaymentId': splitPayment.id,
                'rideId': splitPayment.rideId,
                'amountPerPerson': splitPayment.amountPerPerson,
                'totalAmount': splitPayment.totalAmount,
                'numberOfSplits': splitPayment.numberOfSplits,
              });
              Logger.info('Split payment notification sent to ${participant.userId}', tag: 'SplitPayment');
            } catch (e) {
              Logger.error('Error sending split payment notification', error: e, tag: 'SplitPayment');
            }
          } else {
            Logger.warning('No FCM token found for participant ${participant.userId}', tag: 'SplitPayment');
          }
        }
      }
    } catch (e) {
      Logger.error('Error notifying participants', error: e, tag: 'SplitPayment');
    }
  }
}

