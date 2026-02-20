import 'package:flutter/material.dart';
import 'package:friendsride_app/models/ride_model.dart';
import 'package:friendsride_app/services/pricing_service.dart';
import 'package:friendsride_app/theme/app_text_styles.dart';

/// Widget îmbunătățit pentru estimare preț (Uber-like)
/// Afișează prețurile pentru toate categoriile cu comparație vizuală
class EnhancedPriceEstimateWidget extends StatelessWidget {
  final Map<RideCategory, Map<String, double>> faresByCategory;
  final RideCategory selectedCategory;
  final double distanceInKm;
  final double durationInMinutes;
  final Function(RideCategory) onCategorySelected;
  final bool showComparison;

  const EnhancedPriceEstimateWidget({
    super.key,
    required this.faresByCategory,
    required this.selectedCategory,
    required this.distanceInKm,
    required this.durationInMinutes,
    required this.onCategorySelected,
    this.showComparison = true,
  });

  @override
  Widget build(BuildContext context) {
    if (faresByCategory.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.1).round()),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.attach_money,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Flexible(
                  flex: 1,
                  child: Text(
                    'Estimare Preț',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // Distance and Duration - wrapped in Flexible to prevent overflow
                Flexible(
                  fit: FlexFit.loose,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildInfoChip(
                        context,
                        Icons.route,
                        '${distanceInKm.toStringAsFixed(1)} km',
                      ),
                      const SizedBox(width: 3),
                      _buildInfoChip(
                        context,
                        Icons.access_time,
                        '${durationInMinutes.round()} min',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Price breakdown
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selected category price (highlighted)
                _buildSelectedCategoryCard(context),
                
                if (showComparison) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Compară cu alte categorii:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Other categories
                  ...RideCategory.values
                      .where((cat) => cat != selectedCategory)
                      .map((category) => _buildCategoryComparisonCard(
                            context,
                            category,
                            faresByCategory[category],
                          )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedCategoryCard(BuildContext context) {
    final fare = faresByCategory[selectedCategory];
    if (fare == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withAlpha((255 * 0.3).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Icon(
                      _getCategoryIcon(selectedCategory),
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        selectedCategory.displayName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: Text(
                  '${fare['totalCost']?.toStringAsFixed(2) ?? '0.00'} RON',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPriceBreakdown(context, fare),
        ],
      ),
    );
  }

  Widget _buildCategoryComparisonCard(
    BuildContext context,
    RideCategory category,
    Map<String, double>? fare,
  ) {
    if (fare == null) return const SizedBox.shrink();

    final selectedFare = faresByCategory[selectedCategory];
    final priceDifference = (fare['totalCost'] ?? 0) - (selectedFare?['totalCost'] ?? 0);
    final isCheaper = priceDifference < 0;

    return InkWell(
      onTap: () => onCategorySelected(category),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withAlpha((255 * 0.3).round()),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getCategoryIcon(category),
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                    Text(
                      category.displayName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                    ),
                  if (priceDifference != 0)
                    Text(
                      isCheaper
                          ? '${priceDifference.abs().toStringAsFixed(2)} RON mai ieftin'
                          : '${priceDifference.toStringAsFixed(2)} RON mai scump',
                      style: TextStyle(
                        fontSize: 11,
                        color: isCheaper ? Colors.green : Colors.orange,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '${fare['totalCost']?.toStringAsFixed(2) ?? '0.00'} RON',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.visible,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceBreakdown(BuildContext context, Map<String, double> fare) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBreakdownRow(
          context,
          'Tarif de bază',
          fare['baseFare'] ?? 0,
        ),
        _buildBreakdownRow(
          context,
          'Distanță (${distanceInKm.toStringAsFixed(1)} km)',
          (fare['totalCost'] ?? 0) - (fare['baseFare'] ?? 0) - (fare['stopsFee'] ?? 0),
        ),
        if (fare['stopsFee'] != null && (fare['stopsFee'] ?? 0) > 0)
          _buildBreakdownRow(
            context,
            'Opriri (${(fare['stopsCount'] ?? 0).toInt()} × ${PricingService.getStopFee().toStringAsFixed(2)} RON)',
            fare['stopsFee'] ?? 0,
          ),
        const Divider(height: 24),
        _buildBreakdownRow(
          context,
          'TOTAL',
          fare['totalCost'] ?? 0,
          isTotal: true,
        ),
      ],
    );
  }

  Widget _buildBreakdownRow(
    BuildContext context,
    String label,
    double value, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child:               Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 15 : 13,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.visible,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${value.toStringAsFixed(2)} RON',
              style: TextStyle(
                fontSize: isTotal ? 16 : 13,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.visible,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 2),
          Text(
            text,
            style: AppTextStyles.labelSmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.visible,
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(RideCategory category) {
    switch (category) {
      case RideCategory.standard:
        return Icons.directions_car;
      case RideCategory.family:
        return Icons.family_restroom;
      case RideCategory.energy:
        return Icons.eco;
      case RideCategory.best:
        return Icons.star;
    }
  }
}

