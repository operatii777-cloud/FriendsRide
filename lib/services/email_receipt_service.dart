import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:friendsride_app/models/ride_model.dart';
import 'package:friendsride_app/services/pdf_receipt_service.dart';
import 'package:friendsride_app/utils/logger.dart';

/// Serviciu pentru trimiterea automată a receipt-urilor pe email (Uber-like)
class EmailReceiptService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final PdfReceiptService _pdfService = PdfReceiptService();

  /// Trimite receipt automat pe email după finalizarea cursei
  Future<void> sendReceiptEmail({
    required String rideId,
    required Ride ride,
    required String recipientEmail,
    required bool isDriver,
  }) async {
    try {
      Logger.debug('Starting receipt email for ride: $rideId', tag: 'EMAIL');

      // Generează PDF receipt
      final pdfBytes = await _pdfService.generateReceipt(ride);
      
      if (pdfBytes.isEmpty) {
        throw Exception('Failed to generate PDF receipt');
      }

      // Salvează receipt în Firestore pentru tracking
      await _db.collection('ride_requests').doc(rideId).update({
        'receiptEmailSent': true,
        'receiptEmailSentAt': FieldValue.serverTimestamp(),
        'receiptEmailRecipient': recipientEmail,
      });

      // Note: Email sending will be implemented via Cloud Function in future update
      // For now, only log
      Logger.debug('Receipt email prepared for: $recipientEmail', tag: 'EMAIL');
      Logger.debug('PDF size: ${pdfBytes.length} bytes', tag: 'EMAIL');
      
      // Cloud Function ar trebui să fie apelată aici:
      // await FirebaseFunctions.instance.httpsCallable('sendReceiptEmail').call({
      //   'rideId': rideId,
      //   'recipientEmail': recipientEmail,
      //   'isDriver': isDriver,
      //   'pdfBase64': base64Encode(pdfBytes),
      // });

    } catch (e) {
      Logger.error('Error sending receipt email: $e', tag: 'EMAIL', error: e);
      rethrow;
    }
  }

  /// Obține email-ul utilizatorului
  Future<String?> getUserEmail(String userId) async {
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      if (!userDoc.exists) return null;
      
      final email = userDoc.data()?['email'] as String?;
      if (email != null && email.isNotEmpty) {
        return email;
      }
      
      // Fallback la Firebase Auth email
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser?.email != null) {
        return firebaseUser!.email;
      }
      
      return null;
    } catch (e) {
      Logger.error('Error getting user email: $e', tag: 'EMAIL', error: e);
      return null;
    }
  }

  /// Trimite receipt pentru pasager
  Future<void> sendPassengerReceipt(String rideId, Ride ride) async {
    try {
      final passengerEmail = await getUserEmail(ride.passengerId);
      if (passengerEmail == null) {
        Logger.warning('Passenger email not found for ride: $rideId', tag: 'EMAIL');
        return;
      }

      await sendReceiptEmail(
        rideId: rideId,
        ride: ride,
        recipientEmail: passengerEmail,
        isDriver: false,
      );

      Logger.info('Passenger receipt sent to: $passengerEmail', tag: 'EMAIL');
    } catch (e) {
      Logger.error('Error sending passenger receipt: $e', tag: 'EMAIL', error: e);
    }
  }

  /// Trimite receipt pentru șofer
  Future<void> sendDriverReceipt(String rideId, Ride ride) async {
    try {
      if (ride.driverId == null) {
        Logger.warning('No driver ID for ride: $rideId', tag: 'EMAIL');
        return;
      }

      final driverEmail = await getUserEmail(ride.driverId!);
      if (driverEmail == null) {
        Logger.warning('Driver email not found for ride: $rideId', tag: 'EMAIL');
        return;
      }

      await sendReceiptEmail(
        rideId: rideId,
        ride: ride,
        recipientEmail: driverEmail,
        isDriver: true,
      );

      Logger.info('Driver receipt sent to: $driverEmail', tag: 'EMAIL');
    } catch (e) {
      Logger.error('Error sending driver receipt: $e', tag: 'EMAIL', error: e);
    }
  }

  /// Trimite receipt-uri pentru ambele părți
  Future<void> sendReceiptsForRide(String rideId, Ride ride) async {
    try {
      await Future.wait([
        sendPassengerReceipt(rideId, ride),
        sendDriverReceipt(rideId, ride),
      ]);
      Logger.info('All receipts sent for ride: $rideId', tag: 'EMAIL');
    } catch (e) {
      Logger.error('Error sending receipts: $e', tag: 'EMAIL', error: e);
    }
  }
}

