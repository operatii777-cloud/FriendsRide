import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:friendsride_app/models/promotion_model.dart';
import 'package:friendsride_app/utils/logger.dart';

/// Serviciu pentru gestionarea promoțiilor și voucher-urilor (Uber-like)
class PromotionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Validează și aplică un cod promoțional
  Future<Map<String, dynamic>> validateAndApplyPromotion({
    required String code,
    required double rideAmount,
    String? category,
    bool isFirstRide = false,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return {
          'success': false,
          'message': 'Utilizatorul nu este autentificat',
        };
      }

      // Caută promoția în Firestore
      final promotionSnapshot = await _db
          .collection('promotions')
          .where('code', isEqualTo: code.toUpperCase())
          .limit(1)
          .get();

      if (promotionSnapshot.docs.isEmpty) {
        return {
          'success': false,
          'message': 'Cod promoțional invalid',
        };
      }

      final docData = promotionSnapshot.docs.first.data();
      final promotion = Promotion.fromMap({
        'id': promotionSnapshot.docs.first.id,
        ...docData,
      });

      // Verifică validitatea promoției
      if (!promotion.isValid) {
        return {
          'success': false,
          'message': 'Cod promoțional expirat sau inactiv',
        };
      }

      // Verifică dacă este doar pentru prima cursă
      if (promotion.isFirstRideOnly && !isFirstRide) {
        return {
          'success': false,
          'message': 'Acest cod este valabil doar pentru prima cursă',
        };
      }

      // Verifică categoriile aplicabile
      if (promotion.applicableCategories != null &&
          category != null &&
          !promotion.applicableCategories!.contains(category)) {
        return {
          'success': false,
          'message': 'Acest cod nu este aplicabil pentru categoria selectată',
        };
      }

      // Verifică numărul maxim de utilizări
      if (promotion.maxUses != null) {
        final usesCount = await _getPromotionUsesCount(promotion.id);
        if (usesCount >= promotion.maxUses!) {
          return {
            'success': false,
            'message': 'Cod promoțional epuizat',
          };
        }
      }

      // Verifică numărul maxim de utilizări per utilizator
      if (promotion.maxUsesPerUser != null) {
        final userUsesCount = await _getUserPromotionUsesCount(userId, promotion.id);
        if (userUsesCount >= promotion.maxUsesPerUser!) {
          return {
            'success': false,
            'message': 'Ai folosit deja acest cod de ${promotion.maxUsesPerUser} ori',
          };
        }
      }

      // Calculează discount-ul
      final discount = promotion.calculateDiscount(rideAmount);
      final finalAmount = rideAmount - discount;

      // Salvează utilizarea promoției
      await _recordPromotionUse(userId, promotion.id, discount);

      return {
        'success': true,
        'message': 'Cod promoțional aplicat cu succes',
        'promotion': promotion,
        'discount': discount,
        'finalAmount': finalAmount,
      };
    } catch (e) {
      Logger.error('Error validating promotion', error: e, tag: 'PromotionService');
      return {
        'success': false,
        'message': 'Eroare la validarea codului promoțional',
      };
    }
  }

  /// Obține numărul de utilizări ale unei promoții
  Future<int> _getPromotionUsesCount(String promotionId) async {
    try {
      final snapshot = await _db
          .collection('promotion_uses')
          .where('promotionId', isEqualTo: promotionId)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      Logger.error('Error getting promotion uses count', error: e, tag: 'PromotionService');
      return 0;
    }
  }

  /// Obține numărul de utilizări ale unei promoții de către un utilizator
  Future<int> _getUserPromotionUsesCount(String userId, String promotionId) async {
    try {
      final snapshot = await _db
          .collection('promotion_uses')
          .where('promotionId', isEqualTo: promotionId)
          .where('userId', isEqualTo: userId)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      Logger.error('Error getting user promotion uses count', error: e, tag: 'PromotionService');
      return 0;
    }
  }

  /// Înregistrează utilizarea unei promoții
  Future<void> _recordPromotionUse(String userId, String promotionId, double discount) async {
    try {
      await _db.collection('promotion_uses').add({
        'userId': userId,
        'promotionId': promotionId,
        'discount': discount,
        'usedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      Logger.error('Error recording promotion use', error: e, tag: 'PromotionService');
    }
  }

  /// Obține promoțiile active pentru un utilizator
  Future<List<Promotion>> getActivePromotions({String? category}) async {
    try {
      final now = Timestamp.now();
      Query<Map<String, dynamic>> query = _db
          .collection('promotions')
          .where('status', isEqualTo: 'active')
          .where('startDate', isLessThanOrEqualTo: now)
          .where('endDate', isGreaterThanOrEqualTo: now);

      if (category != null) {
        query = query.where('applicableCategories', arrayContains: category);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            return Promotion.fromMap({
              'id': doc.id,
              ...data,
            });
          })
          .toList();
    } catch (e) {
      Logger.error('Error getting active promotions', error: e, tag: 'PromotionService');
      return [];
    }
  }

  /// Obține istoricul promoțiilor folosite de un utilizator
  Future<List<Map<String, dynamic>>> getUserPromotionHistory() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final snapshot = await _db
          .collection('promotion_uses')
          .where('userId', isEqualTo: userId)
          .orderBy('usedAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      Logger.error('Error getting user promotion history', error: e, tag: 'PromotionService');
      return [];
    }
  }

  /// Validează un cod promoțional fără a-l aplica.
  /// Returnează [true] și mesaj de succes dacă codul este valid și activ,
  /// sau [false] și mesaj de eroare în caz contrar.
  Future<Map<String, dynamic>> validatePromoCode({
    required String code,
    String? category,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return {'valid': false, 'message': 'Utilizatorul nu este autentificat'};
      }

      final snapshot = await _db
          .collection('promotions')
          .where('code', isEqualTo: code.toUpperCase())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return {'valid': false, 'message': 'Cod promoțional inexistent'};
      }

      final docData = snapshot.docs.first.data();
      final promotion = Promotion.fromMap({'id': snapshot.docs.first.id, ...docData});

      if (!promotion.isValid) {
        return {'valid': false, 'message': 'Cod expirat sau inactiv'};
      }

      if (promotion.applicableCategories != null &&
          category != null &&
          !promotion.applicableCategories!.contains(category)) {
        return {'valid': false, 'message': 'Codul nu este aplicabil pentru această categorie'};
      }

      if (promotion.maxUses != null) {
        final usesCount = await _getPromotionUsesCount(promotion.id);
        if (usesCount >= promotion.maxUses!) {
          return {'valid': false, 'message': 'Cod promoțional epuizat'};
        }
      }

      if (promotion.maxUsesPerUser != null) {
        final userUsesCount = await _getUserPromotionUsesCount(userId, promotion.id);
        if (userUsesCount >= promotion.maxUsesPerUser!) {
          return {
            'valid': false,
            'message': 'Ai folosit deja acest cod de ${promotion.maxUsesPerUser} ori'
          };
        }
      }

      return {
        'valid': true,
        'message': 'Cod valid: ${promotion.title}',
        'promotion': promotion,
      };
    } catch (e) {
      Logger.error('Error validating promo code', error: e, tag: 'PromotionService');
      return {'valid': false, 'message': 'Eroare la validarea codului'};
    }
  }

  /// Aplică direct un cod promoțional la o sumă dată și returnează
  /// suma finală după discount. Salvează utilizarea în Firestore.
  Future<Map<String, dynamic>> applyPromotion({
    required String code,
    required double rideAmount,
    String? category,
    bool isFirstRide = false,
  }) async {
    return validateAndApplyPromotion(
      code: code,
      rideAmount: rideAmount,
      category: category,
      isFirstRide: isFirstRide,
    );
  }
}

