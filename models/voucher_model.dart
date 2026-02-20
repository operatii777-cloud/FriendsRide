import 'package:cloud_firestore/cloud_firestore.dart';

enum DiscountType { percentage, fixedAmount }

class Voucher {
  final String id;
  final String code;
  final String description;
  final double value;
  final DiscountType type;
  final Timestamp expiryDate;

  Voucher({
    required this.id,
    required this.code,
    required this.description,
    required this.value,
    required this.type,
    required this.expiryDate,
  });
}
