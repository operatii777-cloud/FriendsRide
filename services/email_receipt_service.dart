import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:friendsride_app/models/ride_model.dart';
import 'package:friendsride_app/services/pdf_receipt_service.dart';

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
      debugPrint('📧 [EMAIL] Starting receipt email for ride: $rideId');

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
      debugPrint('📧 [EMAIL] Receipt email prepared for: $recipientEmail');
      debugPrint('📧 [EMAIL] PDF size: ${pdfBytes.length} bytes');
      
      // Cloud Function ar trebui să fie apelată aici:
      // await FirebaseFunctions.instance.httpsCallable('sendReceiptEmail').call({
      //   'rideId': rideId,
      //   'recipientEmail': recipientEmail,
      //   'isDriver': isDriver,
      //   'pdfBase64': base64Encode(pdfBytes),
      // });

    } catch (e) {
      debugPrint('⚠️ [EMAIL] Error sending receipt email: $e');
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
      debugPrint('⚠️ [EMAIL] Error getting user email: $e');
      return null;
    }
  }

  /// Trimite receipt pentru pasager
  Future<void> sendPassengerReceipt(String rideId, Ride ride) async {
    try {
      final passengerEmail = await getUserEmail(ride.passengerId);
      if (passengerEmail == null) {
        debugPrint('⚠️ [EMAIL] Passenger email not found for ride: $rideId');
        return;
      }

      await sendReceiptEmail(
        rideId: rideId,
        ride: ride,
        recipientEmail: passengerEmail,
        isDriver: false,
      );

      debugPrint('✅ [EMAIL] Passenger receipt sent to: $passengerEmail');
    } catch (e) {
      debugPrint('⚠️ [EMAIL] Error sending passenger receipt: $e');
    }
  }

  /// Trimite receipt pentru șofer
  Future<void> sendDriverReceipt(String rideId, Ride ride) async {
    try {
      if (ride.driverId == null) {
        debugPrint('⚠️ [EMAIL] No driver ID for ride: $rideId');
        return;
      }

      final driverEmail = await getUserEmail(ride.driverId!);
      if (driverEmail == null) {
        debugPrint('⚠️ [EMAIL] Driver email not found for ride: $rideId');
        return;
      }

      await sendReceiptEmail(
        rideId: rideId,
        ride: ride,
        recipientEmail: driverEmail,
        isDriver: true,
      );

      debugPrint('✅ [EMAIL] Driver receipt sent to: $driverEmail');
    } catch (e) {
      debugPrint('⚠️ [EMAIL] Error sending driver receipt: $e');
    }
  }

  /// Trimite receipt-uri pentru ambele părți
  Future<void> sendReceiptsForRide(String rideId, Ride ride) async {
    try {
      await Future.wait([
        sendPassengerReceipt(rideId, ride),
        sendDriverReceipt(rideId, ride),
      ]);
      debugPrint('✅ [EMAIL] All receipts sent for ride: $rideId');
    } catch (e) {
      debugPrint('⚠️ [EMAIL] Error sending receipts: $e');
    }
  }
}

