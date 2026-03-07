import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RidePassengerTracking extends StatelessWidget {
  final bool isPassengerTrackingMode;
  final double currentSpeed;
  final Duration? pickupEta;
  final Duration? destinationEta;
  final DateTime? pickupArrivalTime;
  final DateTime? destinationArrivalTime;
  final double? pickupDistanceKm;
  final double? destinationDistanceKm;
  final bool shouldShowDriverMarker;
  final String? routeTrafficSummary;

  const RidePassengerTracking({
    super.key,
    required this.isPassengerTrackingMode,
    required this.currentSpeed,
    required this.shouldShowDriverMarker,
    this.pickupEta,
    this.destinationEta,
    this.pickupArrivalTime,
    this.destinationArrivalTime,
    this.pickupDistanceKm,
    this.destinationDistanceKm,
    this.routeTrafficSummary,
  });

  @override
  Widget build(BuildContext context) {
    // Only show for passengers in tracking mode
    if (!isPassengerTrackingMode) {
      return const SizedBox.shrink();
    }
    
    // Show driver marker status for debugging
    debugPrint('🎯 Should show driver marker: $shouldShowDriverMarker');
    
    final speedKmh = currentSpeed * 3.6;
    
    return Positioned(
      top: 100,
      left: 16,
      right: 16,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Driver info
              CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                child: Icon(
                  Icons.drive_eta,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Șoferul tău',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      speedKmh > 1 ? 'Se deplasează: ${speedKmh.toStringAsFixed(0)} km/h' : 'Stă pe loc',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              
              // ETA info for passenger
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Până la preluare',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    pickupEta != null ? '${pickupEta!.inMinutes} min' : '—',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    pickupDistanceKm != null
                        ? '${pickupDistanceKm!.toStringAsFixed(1)} km'
                        : '—',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (pickupArrivalTime != null)
                    Text(
                      'Ridicare ~${DateFormat.Hm().format(pickupArrivalTime!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 12),
                  const Text(
                    'Până la destinație',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    destinationEta != null ? '${destinationEta!.inMinutes} min' : '—',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    destinationDistanceKm != null
                        ? '${destinationDistanceKm!.toStringAsFixed(1)} km'
                        : '—',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (destinationArrivalTime != null)
                    Text(
                      'Sosire ~${DateFormat.Hm().format(destinationArrivalTime!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (routeTrafficSummary != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        routeTrafficSummary!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
