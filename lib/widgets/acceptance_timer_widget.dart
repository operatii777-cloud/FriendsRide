import 'dart:async';
import 'package:flutter/material.dart';
import 'package:friendsride_app/theme/app_colors.dart';
import 'package:friendsride_app/theme/app_text_styles.dart';

/// Widget countdown timer pentru acceptarea curselor de către șofer
class AcceptanceTimerWidget extends StatefulWidget {
  final int durationSeconds;
  final VoidCallback onAccepted;
  final VoidCallback onDeclined;
  final String? pickupAddress;
  final String? destinationAddress;
  final double? estimatedFare;

  const AcceptanceTimerWidget({
    super.key,
    this.durationSeconds = 30,
    required this.onAccepted,
    required this.onDeclined,
    this.pickupAddress,
    this.destinationAddress,
    this.estimatedFare,
  });

  @override
  State<AcceptanceTimerWidget> createState() => _AcceptanceTimerWidgetState();
}

class _AcceptanceTimerWidgetState extends State<AcceptanceTimerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Timer _timer;
  late int _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.durationSeconds;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.durationSeconds),
    )..forward();

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _remaining--);
      if (_remaining <= 0) {
        t.cancel();
        widget.onDeclined();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel();
    super.dispose();
  }

  Color get _timerColor {
    if (_remaining > widget.durationSeconds * 0.5) return AppColors.success;
    if (_remaining > widget.durationSeconds * 0.25) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final progress = _remaining / widget.durationSeconds;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildTimer(progress),
          const SizedBox(height: 16),
          if (widget.pickupAddress != null || widget.destinationAddress != null)
            _buildRideInfo(),
          const SizedBox(height: 20),
          _buildButtons(),
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
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.directions_car, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cursă nouă!', style: AppTextStyles.headingMedium),
              Text('Acceptați sau refuzați cererea',
                  style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimer(double progress) {
    return Center(
      child: SizedBox(
        width: 100,
        height: 100,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
                backgroundColor: AppColors.textDisabled.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(_timerColor),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_remaining',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _timerColor,
                  ),
                ),
                Text('sec', style: AppTextStyles.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          if (widget.pickupAddress != null)
            _buildAddressRow(
              icon: Icons.trip_origin,
              color: AppColors.primary,
              label: 'Preluare',
              address: widget.pickupAddress!,
            ),
          if (widget.pickupAddress != null && widget.destinationAddress != null)
            const SizedBox(height: 6),
          if (widget.destinationAddress != null)
            _buildAddressRow(
              icon: Icons.location_on,
              color: AppColors.error,
              label: 'Destinație',
              address: widget.destinationAddress!,
            ),
          if (widget.estimatedFare != null) ...[
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tarif estimat:', style: AppTextStyles.bodySmall),
                Text(
                  '${widget.estimatedFare!.toStringAsFixed(2)} RON',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddressRow({
    required IconData icon,
    required Color color,
    required String label,
    required String address,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.labelSmall),
              Text(address, style: AppTextStyles.bodySmall,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              _timer.cancel();
              widget.onDeclined();
            },
            icon: const Icon(Icons.close),
            label: const Text('Refuză'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: () {
              _timer.cancel();
              widget.onAccepted();
            },
            icon: const Icon(Icons.check),
            label: const Text('Acceptă'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: AppTextStyles.buttonLarge,
            ),
          ),
        ),
      ],
    );
  }
}
