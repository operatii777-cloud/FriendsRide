import 'package:cloud_firestore/cloud_firestore.dart';

/// Model pentru promoții și coduri promoționale (Uber-like)
enum PromotionType {
  percentage,    // Discount procentual
  fixedAmount,   // Discount fix în RON
  freeRide,      // Cursă gratuită
  credit,        // Credit în aplicație
}

enum PromotionStatus {
  active,
  expired,
  used,
  cancelled,
}

class Promotion {
  final String id;
  final String code;
  final String title;
  final String description;
  final PromotionType type;
  final double value; // Procent sau sumă fixă
  final double? minRideAmount; // Suma minimă pentru a aplica promoția
  final int? maxUses; // Numărul maxim de utilizări
  final int? maxUsesPerUser; // Numărul maxim de utilizări per utilizator
  final Timestamp startDate;
  final Timestamp endDate;
  final PromotionStatus status;
  final List<String>? applicableCategories; // Categorii de curse aplicabile
  final bool isFirstRideOnly; // Doar pentru prima cursă
  final double? maxDiscountAmount; // Discount maxim în RON (pentru procentual)

  const Promotion({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.type,
    required this.value,
    this.minRideAmount,
    this.maxUses,
    this.maxUsesPerUser,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.applicableCategories,
    this.isFirstRideOnly = false,
    this.maxDiscountAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'title': title,
      'description': description,
      'type': type.name,
      'value': value,
      if (minRideAmount != null) 'minRideAmount': minRideAmount,
      if (maxUses != null) 'maxUses': maxUses,
      if (maxUsesPerUser != null) 'maxUsesPerUser': maxUsesPerUser,
      'startDate': startDate,
      'endDate': endDate,
      'status': status.name,
      if (applicableCategories != null) 'applicableCategories': applicableCategories,
      'isFirstRideOnly': isFirstRideOnly,
      if (maxDiscountAmount != null) 'maxDiscountAmount': maxDiscountAmount,
    };
  }

  factory Promotion.fromMap(Map<String, dynamic> map) {
    return Promotion(
      id: map['id'] ?? '',
      code: map['code'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: PromotionType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'percentage'),
        orElse: () => PromotionType.percentage,
      ),
      value: (map['value'] as num?)?.toDouble() ?? 0.0,
      minRideAmount: (map['minRideAmount'] as num?)?.toDouble(),
      maxUses: map['maxUses'] as int?,
      maxUsesPerUser: map['maxUsesPerUser'] as int?,
      startDate: map['startDate'] ?? Timestamp.now(),
      endDate: map['endDate'] ?? Timestamp.now(),
      status: PromotionStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'active'),
        orElse: () => PromotionStatus.active,
      ),
      applicableCategories: (map['applicableCategories'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      isFirstRideOnly: map['isFirstRideOnly'] ?? false,
      maxDiscountAmount: (map['maxDiscountAmount'] as num?)?.toDouble(),
    );
  }

  /// Calculează discount-ul pentru o sumă dată
  double calculateDiscount(double rideAmount) {
    if (minRideAmount != null && rideAmount < minRideAmount!) {
      return 0.0;
    }

    double discount = 0.0;

    switch (type) {
      case PromotionType.percentage:
        discount = rideAmount * (value / 100);
        if (maxDiscountAmount != null && discount > maxDiscountAmount!) {
          discount = maxDiscountAmount!;
        }
        break;
      case PromotionType.fixedAmount:
        discount = value;
        if (discount > rideAmount) {
          discount = rideAmount;
        }
        break;
      case PromotionType.freeRide:
        discount = rideAmount;
        break;
      case PromotionType.credit:
        discount = 0.0; // Credit-ul se aplică separat
        break;
    }

    return discount;
  }

  /// Verifică dacă promoția este validă
  bool get isValid {
    final now = DateTime.now();
    return status == PromotionStatus.active &&
        now.isAfter(startDate.toDate()) &&
        now.isBefore(endDate.toDate());
  }
}

