import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/promo_code_model.dart';

/// Service pentru gestionarea promo codes
class PromoCodeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Validează un promo code
  Future<PromoCode?> validatePromoCode({
    required String code,
    required double orderValue,
    String? restaurantId,
  }) async {
    final promoCodeQuery = await _firestore
        .collection('promo_codes')
        .where('code', isEqualTo: code.toUpperCase())
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (promoCodeQuery.docs.isEmpty) {
      return null;
    }

    final promoCode = PromoCode.fromFirestore(promoCodeQuery.docs[0]);

    // Check validity
    if (!promoCode.isValid) {
      return null;
    }

    // Check restaurant applicability
    if (promoCode.applicableRestaurants != null &&
        restaurantId != null &&
        !promoCode.applicableRestaurants!.contains(restaurantId)) {
      return null;
    }

    // Check minimum order value
    if (promoCode.minOrderValue != null &&
        orderValue < promoCode.minOrderValue!) {
      return null;
    }

    return promoCode;
  }

  /// Aplică un promo code și incrementează utilizările
  Future<void> applyPromoCode(String promoCodeId) async {
    final doc = await _firestore.collection('promo_codes').doc(promoCodeId).get();
    final currentUses = (doc.data()?['currentUses'] as int? ?? 0);
    await _firestore.collection('promo_codes').doc(promoCodeId).update({
      'currentUses': currentUses + 1,
    });
  }

  /// Creează un promo code nou (admin only)
  Future<PromoCode> createPromoCode({
    required String code,
    required PromoCodeType type,
    required double value,
    double? minOrderValue,
    double? maxDiscount,
    required DateTime validFrom,
    required DateTime validUntil,
    int? maxUses,
    List<String>? applicableRestaurants,
  }) async {
    final promoCode = PromoCode(
      id: _firestore.collection('promo_codes').doc().id,
      code: code.toUpperCase(),
      type: type,
      value: value,
      minOrderValue: minOrderValue,
      maxDiscount: maxDiscount,
      validFrom: validFrom,
      validUntil: validUntil,
      maxUses: maxUses,
      applicableRestaurants: applicableRestaurants,
    );

    await _firestore
        .collection('promo_codes')
        .doc(promoCode.id)
        .set(promoCode.toFirestore());

    return promoCode;
  }

  /// Obține un promo code după cod
  Future<PromoCode?> getPromoCode(String code) async {
    try {
      final promoCodeQuery = await _firestore
          .collection('promo_codes')
          .where('code', isEqualTo: code.toUpperCase())
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (promoCodeQuery.docs.isEmpty) {
        return null;
      }

      return PromoCode.fromFirestore(promoCodeQuery.docs[0]);
    } catch (e) {
      return null;
    }
  }

  /// Obține toate promo codes active
  Stream<List<PromoCode>> getActivePromoCodes() {
    return _firestore
        .collection('promo_codes')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PromoCode.fromFirestore(doc))
            .where((code) => code.isValid)
            .toList());
  }

  /// Deactivează un promo code
  Future<void> deactivatePromoCode(String promoCodeId) async {
    await _firestore.collection('promo_codes').doc(promoCodeId).update({
      'isActive': false,
    });
  }
}

