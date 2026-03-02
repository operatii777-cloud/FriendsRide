import 'package:flutter/material.dart';
import 'package:friendsride_app/theme/app_colors.dart';
import 'package:friendsride_app/theme/app_text_styles.dart';

/// Widget transparent care explică multiplicatorul de preț de vârf (surge pricing).
/// Ascuns automat când multiplier <= 1.0
class SurgePricingTransparencyWidget extends StatelessWidget {
  /// Multiplicatorul curent (ex: 1.0, 1.5, 2.0, 3.0)
  final double multiplier;
  final String? reason;
  final bool showDetails;

  const SurgePricingTransparencyWidget({
    super.key,
    required this.multiplier,
    this.reason,
    this.showDetails = true,
  });

  bool get _isSurge => multiplier > 1.0;

  Color get _surgeColor {
    if (multiplier < 1.5) return Colors.orange.shade600;
    if (multiplier < 2.0) return Colors.deepOrange;
    return AppColors.error;
  }

  String get _surgeLabel {
    if (multiplier < 1.5) return 'Cerere ușor crescută';
    if (multiplier < 2.0) return 'Cerere ridicată';
    if (multiplier < 3.0) return 'Cerere foarte ridicată';
    return 'Cerere extremă';
  }

  String get _surgeDescription {
    if (!_isSurge) return '';
    if (multiplier < 1.5) {
      return 'Prețul este ușor mai mare decât de obicei datorită cererii.';
    }
    if (multiplier < 2.0) {
      return 'Cererea de curse este ridicată în zona ta. Prețul revine la normal în scurt timp.';
    }
    return 'Cerere foarte mare de curse. Poți aștepta sau confirmi prețul actual.';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSurge) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surgeColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _surgeColor.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Icon(Icons.trending_up, color: _surgeColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _surgeLabel,
                  style: AppTextStyles.bodyLarge
                      .copyWith(color: _surgeColor, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _surgeColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '×${multiplier.toStringAsFixed(1)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress bar
          _SurgeBar(multiplier: multiplier, color: _surgeColor),

          if (showDetails) ...[
            const SizedBox(height: 12),
            Text(
              reason ?? _surgeDescription,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _SurgeBar extends StatelessWidget {
  final double multiplier;
  final Color color;
  static const double _maxMultiplier = 4.0;

  const _SurgeBar({required this.multiplier, required this.color});

  @override
  Widget build(BuildContext context) {
    final fraction = ((multiplier - 1.0) / (_maxMultiplier - 1.0)).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: fraction,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange, color],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Normal',
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.textHint)),
            Text('×${_maxMultiplier.toStringAsFixed(0)}+',
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.textHint)),
          ],
        ),
      ],
    );
  }
}
