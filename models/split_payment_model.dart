import 'package:cloud_firestore/cloud_firestore.dart';

/// Model pentru split payment (împărțirea costului între pasageri) - Uber-like
enum SplitPaymentStatus {
  pending,      // Așteaptă confirmare
  accepted,     // Acceptat de toți participanții
  rejected,     // Refuzat de unul dintre participanți
  completed,    // Toate plățile finalizate
  cancelled,    // Anulat
}

class SplitPayment {
  final String id;
  final String rideId;
  final String initiatorId; // ID-ul pasagerului care a inițiat split-ul
  final double totalAmount;
  final int numberOfSplits;
  final double amountPerPerson;
  final List<SplitPaymentParticipant> participants;
  final Timestamp createdAt;
  final Timestamp? expiresAt;
  final SplitPaymentStatus status;
  final String? shareLink; // Link pentru partajare

  const SplitPayment({
    required this.id,
    required this.rideId,
    required this.initiatorId,
    required this.totalAmount,
    required this.numberOfSplits,
    required this.amountPerPerson,
    required this.participants,
    required this.createdAt,
    this.expiresAt,
    required this.status,
    this.shareLink,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rideId': rideId,
      'initiatorId': initiatorId,
      'totalAmount': totalAmount,
      'numberOfSplits': numberOfSplits,
      'amountPerPerson': amountPerPerson,
      'participants': participants.map((p) => p.toMap()).toList(),
      'createdAt': createdAt,
      if (expiresAt != null) 'expiresAt': expiresAt,
      'status': status.name,
      if (shareLink != null) 'shareLink': shareLink,
    };
  }

  factory SplitPayment.fromMap(Map<String, dynamic> map) {
    return SplitPayment(
      id: map['id'] ?? '',
      rideId: map['rideId'] ?? '',
      initiatorId: map['initiatorId'] ?? '',
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      numberOfSplits: map['numberOfSplits'] ?? 2,
      amountPerPerson: (map['amountPerPerson'] as num?)?.toDouble() ?? 0.0,
      participants: (map['participants'] as List<dynamic>?)
              ?.map((p) => SplitPaymentParticipant.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: map['createdAt'] ?? Timestamp.now(),
      expiresAt: map['expiresAt'],
      status: SplitPaymentStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'pending'),
        orElse: () => SplitPaymentStatus.pending,
      ),
      shareLink: map['shareLink'],
    );
  }

  /// Verifică dacă toți participanții au acceptat
  bool get allParticipantsAccepted {
    return participants.every((p) => p.hasAccepted);
  }

  /// Verifică dacă toate plățile au fost finalizate
  bool get allPaymentsCompleted {
    return participants.every((p) => p.hasPaid);
  }
}

class SplitPaymentParticipant {
  final String userId;
  final String? displayName;
  final String? email;
  final String? phoneNumber;
  final bool hasAccepted;
  final bool hasPaid;
  final Timestamp? acceptedAt;
  final Timestamp? paidAt;
  final String? paymentMethodId; // ID-ul metodei de plată folosite

  const SplitPaymentParticipant({
    required this.userId,
    this.displayName,
    this.email,
    this.phoneNumber,
    this.hasAccepted = false,
    this.hasPaid = false,
    this.acceptedAt,
    this.paidAt,
    this.paymentMethodId,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      if (displayName != null) 'displayName': displayName,
      if (email != null) 'email': email,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      'hasAccepted': hasAccepted,
      'hasPaid': hasPaid,
      if (acceptedAt != null) 'acceptedAt': acceptedAt,
      if (paidAt != null) 'paidAt': paidAt,
      if (paymentMethodId != null) 'paymentMethodId': paymentMethodId,
    };
  }

  factory SplitPaymentParticipant.fromMap(Map<String, dynamic> map) {
    return SplitPaymentParticipant(
      userId: map['userId'] ?? '',
      displayName: map['displayName'],
      email: map['email'],
      phoneNumber: map['phoneNumber'],
      hasAccepted: map['hasAccepted'] ?? false,
      hasPaid: map['hasPaid'] ?? false,
      acceptedAt: map['acceptedAt'],
      paidAt: map['paidAt'],
      paymentMethodId: map['paymentMethodId'],
    );
  }
}

