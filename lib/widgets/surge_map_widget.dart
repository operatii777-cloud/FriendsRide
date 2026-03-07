import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:friendsride_app/services/surge_pricing_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Widget dedicat pentru vizualizarea zonelor de surge pricing pe hartă.
/// Afișează o suprafață tip overlay cu gradient de culori în funcție de
/// intensitatea cererii (verde = normal, galben = ușor, portocaliu = moderat,
/// roșu = surge ridicat).
class SurgeMapWidget extends StatefulWidget {
  /// Latitudinea centrului vizibil al hărții
  final double centerLatitude;

  /// Longitudinea centrului vizibil al hărții
  final double centerLongitude;

  /// Raza vizibilă în kilometri (folosit pentru a filtra zonele)
  final double radiusKm;

  /// Controlează vizibilitatea widget-ului
  final bool isVisible;

  /// Callback apelat când utilizatorul apasă o zonă surge
  final void Function(SurgeZoneInfo zone)? onZoneTapped;

  const SurgeMapWidget({
    super.key,
    required this.centerLatitude,
    required this.centerLongitude,
    this.radiusKm = 10.0,
    this.isVisible = true,
    this.onZoneTapped,
  });

  @override
  State<SurgeMapWidget> createState() => _SurgeMapWidgetState();
}

class _SurgeMapWidgetState extends State<SurgeMapWidget>
    with SingleTickerProviderStateMixin {
  final SurgePricingService _surgePricingService = SurgePricingService();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  List<SurgeZoneInfo> _surgeZones = [];
  bool _isLoading = false;
  StreamSubscription<QuerySnapshot>? _zonesSubscription;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _startListeningToSurgeZones();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _zonesSubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startListeningToSurgeZones() {
    _zonesSubscription = FirebaseFirestore.instance
        .collection('surge_zones')
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      final zones = snapshot.docs
          .map((doc) => SurgeZoneInfo.fromFirestore(doc))
          .where((zone) =>
              _distanceKm(
                  zone.latitude, zone.longitude,
                  widget.centerLatitude, widget.centerLongitude) <=
              widget.radiusKm)
          .toList();
      setState(() {
        _surgeZones = zones;
        _isLoading = false;
      });
    }, onError: (_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  /// Haversine distance in km between two coordinates
  double _distanceKm(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _deg2rad(double deg) => deg * math.pi / 180;

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.local_fire_department, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'Hartă Zone Surge',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              _buildLegend(),
            ],
          ),
        ),

        // Zones list or loading/empty state
        Container(
          constraints: const BoxConstraints(maxHeight: 260),
          color: Theme.of(context).colorScheme.surface,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _surgeZones.isEmpty
                  ? _buildEmptyState()
                  : _buildZonesList(),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _legendDot(Colors.green, 'Normal'),
        const SizedBox(width: 6),
        _legendDot(Colors.yellow.shade700, 'Ușor'),
        const SizedBox(width: 6),
        _legendDot(Colors.orange, 'Moderat'),
        const SizedBox(width: 6),
        _legendDot(Colors.red, 'Ridicat'),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 2),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 40),
            SizedBox(height: 8),
            Text(
              'Nu există zone de surge în această zonă.\nPrețurile sunt normale.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZonesList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _surgeZones.length,
      itemBuilder: (context, index) {
        final zone = _surgeZones[index];
        return _buildZoneTile(zone);
      },
    );
  }

  Widget _buildZoneTile(SurgeZoneInfo zone) {
    final color = _surgeColor(zone.multiplier);
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: zone.multiplier > 2.0 ? _pulseAnimation.value : 1.0,
          child: child,
        );
      },
      child: ListTile(
        onTap: () => widget.onZoneTapped?.call(zone),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withAlpha(51),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              '${zone.multiplier.toStringAsFixed(1)}x',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        title: Text(
          _surgeLabel(zone.multiplier),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${zone.activeRequests} cereri • ${zone.availableDrivers} șoferi disponibili',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Icon(Icons.chevron_right, color: color),
      ),
    );
  }

  Color _surgeColor(double multiplier) {
    if (multiplier >= 2.5) return Colors.red;
    if (multiplier >= 2.0) return Colors.orange;
    if (multiplier >= 1.5) return Colors.yellow.shade700;
    if (multiplier > 1.0) return Colors.lightGreen;
    return Colors.green;
  }

  String _surgeLabel(double multiplier) {
    if (multiplier >= 2.5) return 'Surge Ridicat';
    if (multiplier >= 2.0) return 'Surge Mare';
    if (multiplier >= 1.5) return 'Surge Moderat';
    if (multiplier > 1.0) return 'Surge Ușor';
    return 'Prețuri Normale';
  }
}

/// Model pentru informațiile unei zone surge
class SurgeZoneInfo {
  final String geohash;
  final double latitude;
  final double longitude;
  final double multiplier;
  final int activeRequests;
  final int availableDrivers;
  final DateTime? lastUpdated;

  const SurgeZoneInfo({
    required this.geohash,
    required this.latitude,
    required this.longitude,
    required this.multiplier,
    required this.activeRequests,
    required this.availableDrivers,
    this.lastUpdated,
  });

  factory SurgeZoneInfo.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final activeRequests = (data['activeRequests'] as num?)?.toInt() ?? 0;
    final availableDrivers = (data['availableDrivers'] as num?)?.toInt() ?? 0;
    final multiplier = _computeMultiplier(activeRequests, availableDrivers);

    return SurgeZoneInfo(
      geohash: doc.id,
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      multiplier: multiplier,
      activeRequests: activeRequests,
      availableDrivers: availableDrivers,
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
    );
  }

  /// Calculates the surge multiplier from demand/supply metrics.
  ///
  /// Pricing tiers (demand/supply ratio → multiplier):
  /// - ratio ≤ 1.0  → 1.0x  (no surge)
  /// - ratio 1.0–1.2 → up to 1.5x (low surge, linear scale ×2.5/unit)
  /// - ratio 1.2–1.5 → up to 2.0x (moderate surge, linear scale ×1.67/unit)
  /// - ratio 1.5–2.0 → up to 2.5x (high surge, linear scale ×1.0/unit)
  /// - ratio > 2.0   → up to 3.0x  (very high surge, capped at 3.0)
  /// - no drivers    → 2.0x  if requests > 0, else 1.0x
  static const double _tierVeryHighRatio = 2.0;
  static const double _tierHighRatio = 1.5;
  static const double _tierModerateRatio = 1.2;
  static const double _tierLowRatio = 1.0;

  static const double _baseVeryHigh = 2.5;
  static const double _baseHigh = 2.0;
  static const double _baseModerate = 1.5;

  static const double _slopeVeryHigh = 0.5;
  static const double _slopeHigh = 1.0;
  static const double _slopeModerate = 1.67;
  static const double _slopeLow = 2.5;

  static double _computeMultiplier(int activeRequests, int availableDrivers) {
    if (availableDrivers <= 0) {
      return activeRequests > 0 ? 2.0 : 1.0;
    }
    final ratio = activeRequests / availableDrivers;
    double multiplier;
    if (ratio > _tierVeryHighRatio) {
      multiplier = _baseVeryHigh + (ratio - _tierVeryHighRatio) * _slopeVeryHigh;
    } else if (ratio > _tierHighRatio) {
      multiplier = _baseHigh + (ratio - _tierHighRatio) * _slopeHigh;
    } else if (ratio > _tierModerateRatio) {
      multiplier = _baseModerate + (ratio - _tierModerateRatio) * _slopeModerate;
    } else if (ratio > _tierLowRatio) {
      multiplier = 1.0 + (ratio - _tierLowRatio) * _slopeLow;
    } else {
      multiplier = 1.0;
    }
    return multiplier.clamp(1.0, 3.0);
  }
}
