import 'package:flutter/material.dart';

class SubscriptionPlan {
  final String title;
  final String description;
  final double pricePerMonth;
  final List<String> benefits;
  final Color cardColor;
  final bool isRecommended;

  SubscriptionPlan({
    required this.title,
    required this.description,
    required this.pricePerMonth,
    required this.benefits,
    this.cardColor = Colors.white,
    this.isRecommended = false,
  });
}
