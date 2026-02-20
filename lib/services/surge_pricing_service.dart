import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:friendsride_app/utils/logger.dart';

/// Serviciu pentru surge pricing (prețuri dinamice bazate pe cerere/ofertă) - Uber-like
class SurgePricingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Calculează multiplicatorul de surge pentru o zonă
  /// Returnează un multiplicator între 1.0 (fără surge) și 3.0 (surge maxim)
  Future<double> calculateSurgeMultiplier({
    required double latitude,
    required double longitude,
    required String category,
  }) async {
    try {
      // Calculează geohash pentru zonă
      final geohash = _calculateGeohash(latitude, longitude, precision: 5);
      
      // Obține sau creează documentul pentru această zonă
      final zoneDoc = await _db
          .collection('surge_zones')
          .doc(geohash)
          .get();

      if (!zoneDoc.exists) {
        // Zonă nouă - fără surge
        return 1.0;
      }

      final zoneData = zoneDoc.data() as Map<String, dynamic>;
      final activeRequests = (zoneData['activeRequests'] as num?)?.toInt() ?? 0;
      final availableDrivers = (zoneData['availableDrivers'] as num?)?.toInt() ?? 0;
      final categoryData = zoneData['categories'] as Map<String, dynamic>? ?? {};
      final categoryInfo = categoryData[category] as Map<String, dynamic>? ?? {};

      // Calculează raportul cerere/ofertă
      final demandSupplyRatio = availableDrivers > 0
          ? activeRequests / availableDrivers
          : activeRequests.toDouble();

      // Calculează multiplicatorul bazat pe raport
      double multiplier = 1.0;
      
      if (demandSupplyRatio > 2.0) {
        // Surge foarte mare (raport > 2.0)
        multiplier = 2.5 + ((demandSupplyRatio - 2.0) * 0.5).clamp(0.0, 0.5);
      } else if (demandSupplyRatio > 1.5) {
        // Surge mare (raport 1.5-2.0)
        multiplier = 2.0 + ((demandSupplyRatio - 1.5) * 1.0);
      } else if (demandSupplyRatio > 1.2) {
        // Surge moderat (raport 1.2-1.5)
        multiplier = 1.5 + ((demandSupplyRatio - 1.2) * 1.67);
      } else if (demandSupplyRatio > 1.0) {
        // Surge mic (raport 1.0-1.2)
        multiplier = 1.0 + ((demandSupplyRatio - 1.0) * 2.5);
      }

      // Aplică multiplicatorul specific categoriei dacă există
      final categoryMultiplier = (categoryInfo['multiplier'] as num?)?.toDouble() ?? 1.0;
      multiplier *= categoryMultiplier;

      // Limitează multiplicatorul între 1.0 și 3.0
      return multiplier.clamp(1.0, 3.0);
    } catch (e) {
      Logger.error('Error calculating surge multiplier', error: e, tag: 'SurgePricing');
      return 1.0; // Fallback la fără surge
    }
  }

  /// Actualizează numărul de cereri active și șoferi disponibili pentru o zonă
  Future<void> updateZoneMetrics({
    required double latitude,
    required double longitude,
    required String category,
    required int activeRequests,
    required int availableDrivers,
  }) async {
    try {
      final geohash = _calculateGeohash(latitude, longitude, precision: 5);
      final now = DateTime.now();

      await _db.collection('surge_zones').doc(geohash).set({
        'geohash': geohash,
        'latitude': latitude,
        'longitude': longitude,
        'activeRequests': activeRequests,
        'availableDrivers': availableDrivers,
        'lastUpdated': Timestamp.fromDate(now),
        'categories': {
          category: {
            'activeRequests': activeRequests,
            'availableDrivers': availableDrivers,
            'multiplier': _calculateCategoryMultiplier(activeRequests, availableDrivers),
            'lastUpdated': Timestamp.fromDate(now),
          },
        },
      }, SetOptions(merge: true));
    } catch (e) {
      Logger.error('Error updating zone metrics', error: e, tag: 'SurgePricing');
    }
  }

  /// Calculează multiplicatorul pentru o categorie specifică
  double _calculateCategoryMultiplier(int activeRequests, int availableDrivers) {
    if (availableDrivers == 0) return 2.0; // Surge dacă nu există șoferi
    
    final ratio = activeRequests / availableDrivers;
    if (ratio > 2.0) return 2.5;
    if (ratio > 1.5) return 2.0;
    if (ratio > 1.2) return 1.5;
    if (ratio > 1.0) return 1.2;
    return 1.0;
  }

  /// Calculează geohash simplificat pentru o zonă
  String _calculateGeohash(double latitude, double longitude, {int precision = 5}) {
    // Implementare simplificată de geohash
    // În producție, folosește o bibliotecă de geohash
    final latStr = latitude.toStringAsFixed(3);
    final lonStr = longitude.toStringAsFixed(3);
    return '$latStr' '_$lonStr';
  }

  /// Obține explicația pentru surge pricing
  String getSurgeExplanation(double multiplier) {
    if (multiplier >= 2.5) {
      return 'Cerere foarte mare în această zonă. Prețurile sunt mai mari pentru a atrage mai mulți șoferi.';
    } else if (multiplier >= 2.0) {
      return 'Cerere mare în această zonă. Prețurile sunt mai mari pentru a atrage mai mulți șoferi.';
    } else if (multiplier >= 1.5) {
      return 'Cerere moderată în această zonă. Prețurile sunt ușor mai mari.';
    } else if (multiplier > 1.0) {
      return 'Cerere ușor crescută în această zonă.';
    } else {
      return 'Prețuri normale în această zonă.';
    }
  }

  /// Obține culoarea pentru afișarea surge-ului
  String getSurgeColor(double multiplier) {
    if (multiplier >= 2.5) return 'red';
    if (multiplier >= 2.0) return 'orange';
    if (multiplier >= 1.5) return 'yellow';
    if (multiplier > 1.0) return 'lightYellow';
    return 'normal';
  }
}

