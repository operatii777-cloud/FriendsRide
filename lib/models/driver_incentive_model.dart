import 'package:cloud_firestore/cloud_firestore.dart';

/// Model pentru incentives și bonuses pentru șoferi (Uber-like)
enum IncentiveType {
  quest,        // Quest (ex: "Fă 10 curse în weekend")
  streak,        // Streak bonus (consecutive rides)
  surge,         // Surge bonus
  guaranteed,    // Guaranteed earnings
  referral,      // Referral bonus
  achievement,   // Achievement bonus
}

class DriverIncentive {
  final String id;
  final String driverId;
  final IncentiveType type;
  final String title;
  final String description;
  final double reward; // Recompensa în RON
  final Timestamp startDate;
  final Timestamp endDate;
  final int? targetRides; // Numărul de curse necesare
  final int? currentProgress; // Progresul curent
  final bool isCompleted;
  final Timestamp? completedAt;
  final double? earnedAmount; // Suma câștigată

  const DriverIncentive({
    required this.id,
    required this.driverId,
    required this.type,
    required this.title,
    required this.description,
    required this.reward,
    required this.startDate,
    required this.endDate,
    this.targetRides,
    this.currentProgress,
    this.isCompleted = false,
    this.completedAt,
    this.earnedAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driverId': driverId,
      'type': type.name,
      'title': title,
      'description': description,
      'reward': reward,
      'startDate': startDate,
      'endDate': endDate,
      if (targetRides != null) 'targetRides': targetRides,
      if (currentProgress != null) 'currentProgress': currentProgress,
      'isCompleted': isCompleted,
      if (completedAt != null) 'completedAt': completedAt,
      if (earnedAmount != null) 'earnedAmount': earnedAmount,
    };
  }

  factory DriverIncentive.fromMap(Map<String, dynamic> map) {
    return DriverIncentive(
      id: map['id'] ?? '',
      driverId: map['driverId'] ?? '',
      type: IncentiveType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'quest'),
        orElse: () => IncentiveType.quest,
      ),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      reward: (map['reward'] as num?)?.toDouble() ?? 0.0,
      startDate: map['startDate'] ?? Timestamp.now(),
      endDate: map['endDate'] ?? Timestamp.now(),
      targetRides: map['targetRides'] as int?,
      currentProgress: map['currentProgress'] as int?,
      isCompleted: map['isCompleted'] ?? false,
      completedAt: map['completedAt'],
      earnedAmount: (map['earnedAmount'] as num?)?.toDouble(),
    );
  }

  double get progressPercentage {
    if (targetRides == null || targetRides == 0) return 0.0;
    if (currentProgress == null) return 0.0;
    return (currentProgress! / targetRides!).clamp(0.0, 1.0);
  }

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate.toDate()) && 
           now.isBefore(endDate.toDate()) && 
           !isCompleted;
  }
}

