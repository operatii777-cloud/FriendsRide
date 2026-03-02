import 'package:cloud_firestore/cloud_firestore.dart';

/// Model pentru programul de loialitate (Uber-like)
enum LoyaltyTier {
  bronze,   // Nivel 1
  silver,   // Nivel 2
  gold,     // Nivel 3
  platinum, // Nivel 4
  diamond,  // Nivel 5
}

class LoyaltyProgram {
  final String userId;
  final LoyaltyTier currentTier;
  final int points;
  final int totalRides;
  final double totalSpent;
  final Timestamp? tierUpgradedAt;
  final Timestamp? lastRideAt;

  const LoyaltyProgram({
    required this.userId,
    required this.currentTier,
    required this.points,
    required this.totalRides,
    required this.totalSpent,
    this.tierUpgradedAt,
    this.lastRideAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'currentTier': currentTier.name,
      'points': points,
      'totalRides': totalRides,
      'totalSpent': totalSpent,
      if (tierUpgradedAt != null) 'tierUpgradedAt': tierUpgradedAt,
      if (lastRideAt != null) 'lastRideAt': lastRideAt,
    };
  }

  factory LoyaltyProgram.fromMap(Map<String, dynamic> map) {
    return LoyaltyProgram(
      userId: map['userId'] ?? '',
      currentTier: LoyaltyTier.values.firstWhere(
        (e) => e.name == (map['currentTier'] ?? 'bronze'),
        orElse: () => LoyaltyTier.bronze,
      ),
      points: map['points'] ?? 0,
      totalRides: map['totalRides'] ?? 0,
      totalSpent: (map['totalSpent'] as num?)?.toDouble() ?? 0.0,
      tierUpgradedAt: map['tierUpgradedAt'],
      lastRideAt: map['lastRideAt'],
    );
  }

  /// Calculează tier-ul bazat pe points și rides
  static LoyaltyTier calculateTier(int points, int totalRides) {
    if (points >= 10000 || totalRides >= 500) {
      return LoyaltyTier.diamond;
    } else if (points >= 5000 || totalRides >= 250) {
      return LoyaltyTier.platinum;
    } else if (points >= 2000 || totalRides >= 100) {
      return LoyaltyTier.gold;
    } else if (points >= 500 || totalRides >= 25) {
      return LoyaltyTier.silver;
    } else {
      return LoyaltyTier.bronze;
    }
  }

  /// Calculează points pentru o cursă
  static int calculatePointsForRide(double rideCost) {
    // 1 point per 1 RON cheltuit
    return rideCost.round();
  }

  /// Beneficii pentru fiecare tier
  Map<String, dynamic> get tierBenefits {
    switch (currentTier) {
      case LoyaltyTier.bronze:
        return {
          'name': 'Bronze',
          'discount': 0.0,
          'prioritySupport': false,
          'freeCancellations': 0,
        };
      case LoyaltyTier.silver:
        return {
          'name': 'Silver',
          'discount': 0.05, // 5% discount
          'prioritySupport': false,
          'freeCancellations': 1,
        };
      case LoyaltyTier.gold:
        return {
          'name': 'Gold',
          'discount': 0.10, // 10% discount
          'prioritySupport': true,
          'freeCancellations': 3,
        };
      case LoyaltyTier.platinum:
        return {
          'name': 'Platinum',
          'discount': 0.15, // 15% discount
          'prioritySupport': true,
          'freeCancellations': 5,
        };
      case LoyaltyTier.diamond:
        return {
          'name': 'Diamond',
          'discount': 0.20, // 20% discount
          'prioritySupport': true,
          'freeCancellations': 10,
        };
    }
  }
}

