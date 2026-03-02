import 'package:flutter/material.dart';
import 'package:friendsride_app/models/ride_model.dart';
// import 'package:friendsride_app/services/eta_service.dart'; // Eliminat
import 'package:friendsride_app/services/pricing_service.dart';
import 'package:friendsride_app/theme/app_constants.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class EtaPreviewCard extends StatefulWidget {
  final Point startPoint;
  final Point destinationPoint;
  final String destinationAddress;
  final Function(Ride) onConfirmRide;

  const EtaPreviewCard({
    super.key,
    required this.startPoint,
    required this.destinationPoint,
    required this.destinationAddress,
    required this.onConfirmRide,
  });

  @override
  State<EtaPreviewCard> createState() => _EtaPreviewCardState();
}

class _EtaPreviewCardState extends State<EtaPreviewCard> {
  // final EtaService _etaService = EtaService(); // Eliminat
  final PricingService _pricingService = PricingService();

  double? _distance;
  int? _estimatedMinutes;
  Map<String, double>? _fareDetails;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _calculateEstimates();
  }

  Future<void> _calculateEstimates() async {
    // Calculăm distanța
    final distanceInMeters = Geolocator.distanceBetween(
      widget.startPoint.coordinates.lat.toDouble(),
      widget.startPoint.coordinates.lng.toDouble(),
      widget.destinationPoint.coordinates.lat.toDouble(),
      widget.destinationPoint.coordinates.lng.toDouble(),
    );
    final distanceInKm = distanceInMeters / 1000;

    // CORECTAT: Folosim o viteză medie constantă în loc de EtaService
    const double averageSpeed = 40.0; // Viteza medie in km/h

    // Calculăm timpul
    final estimatedTime = (distanceInKm / averageSpeed * 60).round();
    
    // Calculăm prețul folosind PricingService
    final calculatedFares = _pricingService.calculateFare(
      distanceInKm: distanceInKm, 
      durationInMinutes: estimatedTime.toDouble(), 
      category: RideCategory.standard
    );

    if (mounted) {
      setState(() {
        _distance = distanceInKm;
        _estimatedMinutes = estimatedTime;
        _fareDetails = calculatedFares;
        _isLoading = false;
      });
    }
  }

  void _handleConfirm() {
    if (_distance == null || _fareDetails == null || _estimatedMinutes == null) return;

    final newRide = Ride(
      id: '', // Va fi generat de Firestore
      passengerId: '', // Va fi adăugat de FirestoreService
      driverId: null,
      startLatitude: widget.startPoint.coordinates.lat.toDouble(),
      startLongitude: widget.startPoint.coordinates.lng.toDouble(),
      destinationLatitude: widget.destinationPoint.coordinates.lat.toDouble(),
      destinationLongitude: widget.destinationPoint.coordinates.lng.toDouble(),
      startAddress: "Locația mea", 
      destinationAddress: widget.destinationAddress,
      distance: _distance!,
      totalCost: _fareDetails!['totalCost']!,
      status: 'pending',
      timestamp: DateTime.now(), 
      baseFare: _fareDetails!['baseFare']!,
      perKmRate: _fareDetails!['perKmRate']!,
      perMinRate: _fareDetails!['perMinRate']!,
      appCommission: _fareDetails!['appCommission']!,
      driverEarnings: _fareDetails!['driverEarnings']!,
      durationInMinutes: _estimatedMinutes!.toDouble(),
      tip: 0,
      category: RideCategory.standard, 
      isScheduled: false,
    );

    widget.onConfirmRide(newRide);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(AppConstants.spacingM),
      elevation: AppConstants.elevationM,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusL)),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: _isLoading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Se calculează estimarea...'),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildEstimateColumn(
                        context,
                        icon: Icons.access_time_filled,
                        value: '~$_estimatedMinutes min',
                        label: 'Timp estimat',
                      ),
                      _buildEstimateColumn(
                        context,
                        icon: Icons.map,
                        value: '${_distance?.toStringAsFixed(1)} km',
                        label: 'Distanță',
                      ),
                      _buildEstimateColumn(
                        context,
                        icon: Icons.payments,
                        value: '~${_fareDetails?["totalCost"]?.toStringAsFixed(2)} RON',
                        label: 'Cost estimat',
                      ),
                    ],
                  ),
                  const Divider(height: 24.0),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleConfirm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Solicită Cursa'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEstimateColumn(BuildContext context, {required IconData icon, required String value, required String label}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }
}