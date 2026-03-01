import 'package:flutter/material.dart';
import 'package:friendsride_app/theme/app_colors.dart';
import 'package:friendsride_app/theme/app_text_styles.dart';

/// Widget pentru transparența prețurilor dinamice (surge pricing)
class SurgePricingTransparencyWidget extends StatelessWidget {
  final double multiplier;
  final String? reason;
  final int? estimatedMinutesUntilNormal;

  const SurgePricingTransparencyWidget({
    super.key,
    required this.multiplier,
    this.reason,
    this.estimatedMinutesUntilNormal,
  });

  @override
  Widget build(BuildContext context) {
    if (multiplier <= 1.0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surgeColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _surgeColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          _buildMultiplierBar(),
          const SizedBox(height: 12),
          _buildInfoRows(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _surgeColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.trending_up_rounded, color: _surgeColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Prețuri dinamice', style: AppTextStyles.headingSmall),
              Text(
                reason ?? 'Cerere mare în zona ta',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _surgeColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${multiplier.toStringAsFixed(1)}x',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMultiplierBar() {
    // Multiplier tipic: 1.0 – 3.0
    final progress = ((multiplier - 1.0) / 2.0).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Normal', style: AppTextStyles.labelSmall),
            Text('Maxim', style: AppTextStyles.labelSmall),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: AppColors.textDisabled.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(_surgeColor),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRows() {
    return Column(
      children: [
        _buildInfoRow(
          icon: Icons.info_outline,
          text: _surgeDescription,
        ),
        if (estimatedMinutesUntilNormal != null) ...[
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.timer_outlined,
            text: 'Prețurile revin la normal în ~$estimatedMinutesUntilNormal minute.',
          ),
        ],
        const SizedBox(height: 8),
        _buildInfoRow(
          icon: Icons.lightbulb_outline,
          text: 'Sfat: Așteptați câteva minute pentru un preț mai bun.',
        ),
      ],
    );
  }

  Widget _buildInfoRow({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: _surgeColor),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: AppTextStyles.bodySmall)),
      ],
    );
  }

  Color get _surgeColor {
    if (multiplier >= 2.5) return AppColors.error;
    if (multiplier >= 1.8) return AppColors.warning;
    return const Color(0xFFF57F17); // amber dark
  }

  String get _surgeDescription {
    if (multiplier >= 2.5) {
      return 'Cerere foarte mare! Prețurile sunt semnificativ mai ridicate decât normal.';
    } else if (multiplier >= 1.8) {
      return 'Cerere ridicată în zona ta. Prețul include un multiplicator de ${multiplier.toStringAsFixed(1)}x.';
    } else {
      return 'Cerere ușor crescută. Prețul este moderat mai mare decât normal.';
    }
  }
}
