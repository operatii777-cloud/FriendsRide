import 'dart:async';
import 'package:flutter/material.dart';
import 'package:friendsride_app/models/ride_model.dart';
import 'package:friendsride_app/services/firestore_service.dart';
import 'package:friendsride_app/widgets/map/map_driver_waiting.dart';
import 'package:intl/intl.dart';

class MapDriverInterface extends StatelessWidget {
  final FirestoreService firestoreService;
  final Ride? currentActiveRide;
  final Duration? driverPickupEta;
  final double? driverPickupDistanceKm;
  final DateTime? driverPickupArrivalTime;
  final Duration? driverDestinationEta;
  final double? driverDestinationDistanceKm;
  final DateTime? driverDestinationArrivalTime;
  final String? driverTrafficSummary;
  final String? driverCategoryName;
  final int pendingRidesCount;
  final void Function(Ride) onNewRideAssigned;
  final void Function(String) onNavigateToRide;
  final void Function(String) onListenForChat;
  final VoidCallback? onUpdateEstimates;
  final VoidCallback onResetEtaMetrics;
  final void Function(Ride?) onActiveRideChanged;

  const MapDriverInterface({
    super.key,
    required this.firestoreService,
    this.currentActiveRide,
    this.driverPickupEta,
    this.driverPickupDistanceKm,
    this.driverPickupArrivalTime,
    this.driverDestinationEta,
    this.driverDestinationDistanceKm,
    this.driverDestinationArrivalTime,
    this.driverTrafficSummary,
    this.driverCategoryName,
    required this.pendingRidesCount,
    required this.onNewRideAssigned,
    required this.onNavigateToRide,
    required this.onListenForChat,
    this.onUpdateEstimates,
    required this.onResetEtaMetrics,
    required this.onActiveRideChanged,
  });

  static String _formatDriverEta(Duration? duration) {
    if (duration == null) return '—';
    if (duration.inMinutes >= 1) {
      return '${duration.inMinutes} min';
    }
    if (duration.inSeconds >= 30) {
      return '<1 min';
    }
    return '<30 sec';
  }

  static String _formatDriverDistance(double? distanceKm) {
    if (distanceKm == null) return '—';
    if (distanceKm >= 1) {
      return '${distanceKm.toStringAsFixed(1)} km';
    }
    final meters = (distanceKm * 1000).round();
    return '$meters m';
  }

  static String _formatRideStatus(String? status) {
    switch (status) {
      case 'driver_found':
        return 'În drum către pasager';
      case 'accepted':
        return 'Confirmată';
      case 'driver_en_route':
        return 'În drum către preluare';
      case 'arrived':
        return 'Șoferul a sosit';
      case 'in_progress':
        return 'Cursă în desfășurare';
      case 'completed':
        return 'Finalizată';
      case 'cancelled':
        return 'Anulată';
      default:
        return 'Status necunoscut';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Ride?>(
      stream: firestoreService.getActiveDriverRideStream(),
      builder: (context, activeRideSnapshot) {
        if (activeRideSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final Ride? newActiveRide = activeRideSnapshot.data;

        // ✅ NOU: Navigare automată când apare o cursă nouă acceptată
        if (newActiveRide != null && currentActiveRide?.id != newActiveRide.id) {
          debugPrint("🎵 Cursă nouă atribuită (${newActiveRide.id}). Se redă sunetul de notificare.");
          onNewRideAssigned(newActiveRide);

          // ✅ NOU: Navigare automată la ActiveRideScreen când apare o cursă nouă
          if (['accepted', 'arrived', 'in_progress'].contains(newActiveRide.status)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted && currentActiveRide?.id != newActiveRide.id) {
                debugPrint('🚗 [MAP] Auto-navigating to ActiveRideScreen for ride ${newActiveRide.id}');
                onNavigateToRide(newActiveRide.id);
              }
            });
          }
        }
        if (newActiveRide?.id != currentActiveRide?.id) {
          onActiveRideChanged(newActiveRide);
        }

        if (newActiveRide == null) {
          if (driverPickupEta != null ||
              driverDestinationEta != null ||
              driverTrafficSummary != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                onResetEtaMetrics();
              }
            });
          }
          return MapDriverWaiting(
            driverCategoryName: driverCategoryName,
            pendingRidesCount: pendingRidesCount,
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          onListenForChat(newActiveRide.id);
          onUpdateEstimates?.call();
        });

        final statusLabel = _formatRideStatus(newActiveRide.status);
        final trafficSummary = driverTrafficSummary;

        return Positioned(
          bottom: 20, left: 20, right: 20,
          child: GestureDetector(
            onTap: () => onNavigateToRide(newActiveRide.id),
            child: Card(
              color: Colors.orange.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(60),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.local_taxi, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Cursă activă',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Pasager: ${newActiveRide.passengerId}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.visible,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                statusLabel,
                                style: TextStyle(
                                  color: Colors.white.withAlpha(200),
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.visible,
                              ),
                            ],
                          ),
                        ),
                        if (trafficSummary != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(40),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              trafficSummary,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Preluare',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                newActiveRide.startAddress,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Destinație',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                newActiveRide.destinationAddress,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Până la preluare',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDriverEta(driverPickupEta),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _formatDriverDistance(driverPickupDistanceKm),
                              style: TextStyle(
                                color: Colors.white.withAlpha(200),
                                fontSize: 12,
                              ),
                            ),
                            if (driverPickupArrivalTime != null)
                              Text(
                                'Ridicare ~${DateFormat.Hm().format(driverPickupArrivalTime!)}',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(200),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            const SizedBox(height: 12),
                            const Text(
                              'Până la destinație',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDriverEta(driverDestinationEta),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _formatDriverDistance(driverDestinationDistanceKm),
                              style: TextStyle(
                                color: Colors.white.withAlpha(200),
                                fontSize: 12,
                              ),
                            ),
                            if (driverDestinationArrivalTime != null)
                              Text(
                                'Sosire ~${DateFormat.Hm().format(driverDestinationArrivalTime!)}',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(200),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Harta este înghețată pentru performanță',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Atinge pentru detalii ➜',
                        style: TextStyle(
                          color: Colors.white.withAlpha(220),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
