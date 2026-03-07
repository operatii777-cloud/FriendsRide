import 'dart:async';
import 'package:flutter/material.dart';
import 'package:friendsride_app/theme/app_colors.dart';
import 'package:friendsride_app/theme/app_text_styles.dart';

/// Widget de acceptare/declinare cursă cu cronometru de numărătoare inversă.
/// Afișat șoferului când primește o cerere de cursă.
class AcceptanceTimerWidget extends StatefulWidget {
  final String pickupAddress;
  final String destinationAddress;
  final double fare;
  final double distanceKm;
  final int timerSeconds;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const AcceptanceTimerWidget({
    super.key,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.fare,
    required this.distanceKm,
    this.timerSeconds = 30,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<AcceptanceTimerWidget> createState() => _AcceptanceTimerWidgetState();
}

class _AcceptanceTimerWidgetState extends State<AcceptanceTimerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;
  late Timer _timer;
  late int _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.timerSeconds;
    _animController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.timerSeconds),
    )..forward();

    _animation = Tween<double>(begin: 1.0, end: 0.0)
        .animate(_animController);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        t.cancel();
        widget.onDecline();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _timer.cancel();
    super.dispose();
  }

  Color get _timerColor {
    if (_remaining > widget.timerSeconds * 0.6) return AppColors.secondary;
    if (_remaining > widget.timerSeconds * 0.3) return Colors.orange;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cerere nouă de cursă de la ${widget.pickupAddress} la ${widget.destinationAddress}. '
          'Tarif: ${widget.fare.toStringAsFixed(2)} RON. '
          'Timp rămas: $_remaining secunde.',
      liveRegion: true,
      child: Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timer bar
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: AnimatedBuilder(
              animation: _animation,
              builder: (_, __) => LinearProgressIndicator(
                value: _animation.value,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(_timerColor),
                minHeight: 6,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header + countdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Cerere nouă!', style: AppTextStyles.heading3),
                    _CountdownCircle(
                        remaining: _remaining, color: _timerColor),
                  ],
                ),
                const SizedBox(height: 20),

                // Route info
                _RouteRow(
                  icon: Icons.my_location,
                  color: AppColors.secondary,
                  label: 'Preluare',
                  address: widget.pickupAddress,
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 11),
                  child: SizedBox(
                    height: 24,
                    child: VerticalDivider(
                        thickness: 2, color: Color(0xFFE0E0E0)),
                  ),
                ),
                _RouteRow(
                  icon: Icons.location_on,
                  color: AppColors.error,
                  label: 'Destinație',
                  address: widget.destinationAddress,
                ),
                const SizedBox(height: 20),

                // Fare + distance
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _InfoChip(
                          icon: Icons.attach_money,
                          label:
                              '${widget.fare.toStringAsFixed(2)} RON'),
                      Container(
                          width: 1,
                          height: 30,
                          color: AppColors.border),
                      _InfoChip(
                          icon: Icons.straighten,
                          label:
                              '${widget.distanceKm.toStringAsFixed(1)} km'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        label: 'Refuză cererea de cursă',
                        button: true,
                        child: OutlinedButton(
                          onPressed: widget.onDecline,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: AppColors.error),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Refuză',
                              style: AppTextStyles.button
                                  .copyWith(color: AppColors.error)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: Semantics(
                        label: 'Acceptă cererea de cursă',
                        button: true,
                        child: ElevatedButton(
                          onPressed: widget.onAccept,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Acceptă',
                              style: AppTextStyles.button),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _CountdownCircle extends StatelessWidget {
  final int remaining;
  final Color color;
  const _CountdownCircle({required this.remaining, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
      ),
      alignment: Alignment.center,
      child: Text(
        '$remaining',
        style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String address;
  const _RouteRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
              Text(address,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 6),
        Text(label,
            style: AppTextStyles.bodyMedium
                .copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
