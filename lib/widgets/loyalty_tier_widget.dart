import 'package:flutter/material.dart';
import 'package:friendsride_app/models/loyalty_program_model.dart';

/// Widget pentru afișarea tier-ului de loialitate (Uber-like)
class LoyaltyTierWidget extends StatelessWidget {
  final LoyaltyProgram loyaltyProgram;

  const LoyaltyTierWidget({
    super.key,
    required this.loyaltyProgram,
  });

  @override
  Widget build(BuildContext context) {
    final benefits = loyaltyProgram.tierBenefits;
    
    return Semantics(
      label: 'Program loialitate: nivel ${benefits['name']}, ${loyaltyProgram.points} puncte',
      child: Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getTierColor(loyaltyProgram.currentTier),
            _getTierColor(loyaltyProgram.currentTier).withAlpha((255 * 0.7).round()),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.2).round()),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    benefits['name'] as String,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${loyaltyProgram.points} points',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              Semantics(
                label: 'Insignă nivel ${benefits['name']}',
                child: Icon(
                  _getTierIcon(loyaltyProgram.currentTier),
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((255 * 0.2).round()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Beneficii',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                _buildBenefitItem(
                  context,
                  'Discount',
                  '${((benefits['discount'] as double) * 100).toStringAsFixed(0)}%',
                  Icons.local_offer,
                ),
                if (benefits['prioritySupport'] as bool)
                  _buildBenefitItem(
                    context,
                    'Suport Prioritar',
                    'Da',
                    Icons.support_agent,
                  ),
                _buildBenefitItem(
                  context,
                  'Anulări Gratuite',
                  '${benefits['freeCancellations']}',
                  Icons.cancel_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildProgressToNextTier(context),
        ],
      ),
    ),
    );
  }

  Widget _buildBenefitItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressToNextTier(BuildContext context) {
    final nextTier = _getNextTier(loyaltyProgram.currentTier);
    if (nextTier == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha((255 * 0.2).round()),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.star, color: Colors.amber, size: 20),
            SizedBox(width: 8),
            Text(
              'Ai atins nivelul maxim!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    final pointsNeeded = _getPointsForTier(nextTier) - loyaltyProgram.points;
    final progress = (loyaltyProgram.points / _getPointsForTier(nextTier)).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Următorul nivel: ${_getTierName(nextTier)}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            Text(
              '$pointsNeeded points rămase',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withAlpha((255 * 0.3).round()),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Color _getTierColor(LoyaltyTier tier) {
    switch (tier) {
      case LoyaltyTier.bronze:
        return Colors.brown;
      case LoyaltyTier.silver:
        return Colors.grey;
      case LoyaltyTier.gold:
        return Colors.amber;
      case LoyaltyTier.platinum:
        return Colors.blueGrey;
      case LoyaltyTier.diamond:
        return Colors.cyan;
    }
  }

  IconData _getTierIcon(LoyaltyTier tier) {
    switch (tier) {
      case LoyaltyTier.bronze:
        return Icons.looks_one;
      case LoyaltyTier.silver:
        return Icons.looks_two;
      case LoyaltyTier.gold:
        return Icons.star;
      case LoyaltyTier.platinum:
        return Icons.stars;
      case LoyaltyTier.diamond:
        return Icons.diamond;
    }
  }

  String _getTierName(LoyaltyTier tier) {
    switch (tier) {
      case LoyaltyTier.bronze:
        return 'Bronze';
      case LoyaltyTier.silver:
        return 'Silver';
      case LoyaltyTier.gold:
        return 'Gold';
      case LoyaltyTier.platinum:
        return 'Platinum';
      case LoyaltyTier.diamond:
        return 'Diamond';
    }
  }

  LoyaltyTier? _getNextTier(LoyaltyTier currentTier) {
    switch (currentTier) {
      case LoyaltyTier.bronze:
        return LoyaltyTier.silver;
      case LoyaltyTier.silver:
        return LoyaltyTier.gold;
      case LoyaltyTier.gold:
        return LoyaltyTier.platinum;
      case LoyaltyTier.platinum:
        return LoyaltyTier.diamond;
      case LoyaltyTier.diamond:
        return null;
    }
  }

  int _getPointsForTier(LoyaltyTier tier) {
    switch (tier) {
      case LoyaltyTier.bronze:
        return 0;
      case LoyaltyTier.silver:
        return 500;
      case LoyaltyTier.gold:
        return 2000;
      case LoyaltyTier.platinum:
        return 5000;
      case LoyaltyTier.diamond:
        return 10000;
    }
  }
}

