import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class ReferralService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Generează un cod referral unic
  Future<String> generateReferralCode() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    final code = _createCode();
    await _db.collection('referrals').doc(code).set({
      'userId': userId,
      'createdAt': DateTime.now().toIso8601String(),
    });
    return code;
  }

  /// Validează un cod referral și atribuie bonus
  Future<bool> validateReferralCode(String code) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    final doc = await _db.collection('referrals').doc(code).get();
    if (!doc.exists) return false;
    final data = doc.data();
    if (data == null || data['userId'] == userId) return false; // Nu poți folosi propriul cod
    // Atribuie bonus ambilor utilizatori
    await _db.collection('referral_bonuses').add({
      'referrerId': data['userId'],
      'newUserId': userId,
      'timestamp': DateTime.now().toIso8601String(),
      'bonusAmount': 20,
    });
    return true;
  }

  String _createCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    return List.generate(6, (i) => chars[rand.nextInt(chars.length)]).join();
  }
}
