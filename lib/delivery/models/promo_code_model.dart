import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipuri de promo codes
enum PromoCodeType {
  percentage, // Discount procentual
  fixed, // Discount fix (RON)
  freeDelivery, // Livrare gratuită
}

/// Model pentru promo codes
class PromoCode {
  final String id;
  final String code; // Codul promo (ex: "SUMMER2025")
  final PromoCodeType type;
  final double value; // Valoarea discount-ului (procent sau RON)
  final double? minOrderValue; // Valoare minimă comandă
  final double? maxDiscount; // Discount maxim (pentru procentual)
  final DateTime validFrom;
  final DateTime validUntil;
  final int? maxUses; // Număr maxim de utilizări
  final int currentUses; // Utilizări curente
  final List<String>? applicableRestaurants; // null = toate restaurantele
  final bool isActive;

  PromoCode({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    this.minOrderValue,
    this.maxDiscount,
    required this.validFrom,
    required this.validUntil,
    this.maxUses,
    this.currentUses = 0,
    this.applicableRestaurants,
    this.isActive = true,
  });

  factory PromoCode.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PromoCode(
      id: doc.id,
      code: data['code'] as String,
      type: _promoCodeTypeFromString(data['type'] as String),
      value: (data['value'] as num).toDouble(),
      minOrderValue: data['minOrderValue'] != null
          ? (data['minOrderValue'] as num).toDouble()
          : null,
      maxDiscount: data['maxDiscount'] != null
          ? (data['maxDiscount'] as num).toDouble()
          : null,
      validFrom: (data['validFrom'] as Timestamp).toDate(),
      validUntil: (data['validUntil'] as Timestamp).toDate(),
      maxUses: data['maxUses'] as int?,
      currentUses: data['currentUses'] as int? ?? 0,
      applicableRestaurants: data['applicableRestaurants'] != null
          ? List<String>.from(data['applicableRestaurants'] as List)
          : null,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'code': code,
      'type': _promoCodeTypeToString(type),
      'value': value,
      'minOrderValue': minOrderValue,
      'maxDiscount': maxDiscount,
      'validFrom': Timestamp.fromDate(validFrom),
      'validUntil': Timestamp.fromDate(validUntil),
      'maxUses': maxUses,
      'currentUses': currentUses,
      'applicableRestaurants': applicableRestaurants,
      'isActive': isActive,
    };
  }

  bool get isValid {
    final now = DateTime.now();
    return isActive &&
        now.isAfter(validFrom) &&
        now.isBefore(validUntil) &&
        (maxUses == null || currentUses < (maxUses ?? 0));
  }

  double calculateDiscount(double orderValue) {
    if (!isValid) {
      return 0.0;
    }

    if (minOrderValue != null && orderValue < minOrderValue!) {
      return 0.0;
    }

    switch (type) {
      case PromoCodeType.percentage:
        final discount = orderValue * (value / 100);
        if (maxDiscount != null && discount > maxDiscount!) {
          return maxDiscount!;
        }
        return discount;
      case PromoCodeType.fixed:
        return value > orderValue ? orderValue : value;
      case PromoCodeType.freeDelivery:
        return 0.0; // Will be handled separately
    }
  }

  static PromoCodeType _promoCodeTypeFromString(String value) {
    switch (value) {
      case 'percentage':
        return PromoCodeType.percentage;
      case 'fixed':
        return PromoCodeType.fixed;
      case 'freeDelivery':
        return PromoCodeType.freeDelivery;
      default:
        return PromoCodeType.percentage;
    }
  }

  static String _promoCodeTypeToString(PromoCodeType type) {
    switch (type) {
      case PromoCodeType.percentage:
        return 'percentage';
      case PromoCodeType.fixed:
        return 'fixed';
      case PromoCodeType.freeDelivery:
        return 'freeDelivery';
    }
  }
}

