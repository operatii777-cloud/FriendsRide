import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:friendsride_app/delivery/models/courier_model.dart';
import 'package:friendsride_app/utils/logger.dart';

/// Courier Service
/// 
/// Gestionează operațiunile legate de curieri
class CourierService {
  static final CourierService _instance = CourierService._internal();
  factory CourierService() => _instance;
  CourierService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Curierul devine disponibil (go online)
  Future<void> goOnline({
    required VehicleType vehicleType,
    geolocator.Position? currentLocation,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Find or create courier document
      final courierQuery = await _db
          .collection('couriers')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      final updates = <String, dynamic>{
        'status': CourierStatus.online.toString(),
        'vehicleType': _vehicleTypeToString(vehicleType),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (currentLocation != null) {
        updates['currentLocation'] = GeoPoint(
          currentLocation.latitude,
          currentLocation.longitude,
        );
        updates['lastLocationUpdate'] = FieldValue.serverTimestamp();
      }

      if (courierQuery.docs.isEmpty) {
        // Create new courier document
        updates['userId'] = userId;
        updates['rating'] = 0.0;
        updates['completedDeliveries'] = 0;
        updates['createdAt'] = FieldValue.serverTimestamp();
        await _db.collection('couriers').add(updates);
      } else {
        // Update existing courier
        await courierQuery.docs.first.reference.update(updates);
      }

      Logger.info('Courier went online: $userId', tag: 'COURIER');
    } catch (e) {
      Logger.error('Error going online: $e', tag: 'COURIER');
      rethrow;
    }
  }

  /// Curierul devine indisponibil (go offline)
  Future<void> goOffline() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final courierQuery = await _db
          .collection('couriers')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (courierQuery.docs.isNotEmpty) {
        await courierQuery.docs.first.reference.update({
          'status': CourierStatus.offline.toString(),
          'currentOrderId': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      Logger.info('Courier went offline: $userId', tag: 'COURIER');
    } catch (e) {
      Logger.error('Error going offline: $e', tag: 'COURIER');
      rethrow;
    }
  }

  /// Setează statusul online/offline al curierului
  Future<void> setOnlineStatus(bool isOnline) async {
    if (isOnline) {
      // Get current location if available
      try {
        final location = await geolocator.Geolocator.getCurrentPosition(
          locationSettings: const geolocator.LocationSettings(
            accuracy: geolocator.LocationAccuracy.high,
          ),
        );
        await goOnline(
          vehicleType: VehicleType.bike, // Default, can be changed
          currentLocation: location,
        );
      } catch (e) {
        // If location not available, go online without location
        await goOnline(
          vehicleType: VehicleType.bike,
        );
      }
    } else {
      await goOffline();
    }
  }

  /// Actualizează locația curierului
  Future<void> updateLocation(geolocator.Position location) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return;
      }

      final courierQuery = await _db
          .collection('couriers')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (courierQuery.docs.isNotEmpty) {
        await courierQuery.docs.first.reference.update({
          'currentLocation': GeoPoint(location.latitude, location.longitude),
          'lastLocationUpdate': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      Logger.error('Error updating courier location: $e', tag: 'COURIER');
    }
  }

  /// Obține curierul pentru un user
  Future<Courier?> getCourier({String? userId}) async {
    try {
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) {
        return null;
      }

      final courierQuery = await _db
          .collection('couriers')
          .where('userId', isEqualTo: uid)
          .limit(1)
          .get();

      if (courierQuery.docs.isEmpty) {
        return null;
      }

      return Courier.fromFirestore(courierQuery.docs.first);
    } catch (e) {
      Logger.error('Error getting courier: $e', tag: 'COURIER');
      return null;
    }
  }

  /// Obține curieri disponibili într-o zonă
  Future<List<Courier>> getAvailableCouriers({
    required GeoPoint location,
    double radiusKm = 10.0,
    VehicleType? vehicleType,
    int limit = 20,
  }) async {
    try {
      Query query = _db
          .collection('couriers')
          .where('status', isEqualTo: CourierStatus.online.toString())
          .limit(limit);

      if (vehicleType != null) {
        query = query.where('vehicleType', isEqualTo: _vehicleTypeToString(vehicleType));
      }

      final snapshot = await query.get();
      final couriers = snapshot.docs
          .map((doc) => Courier.fromFirestore(doc))
          .where((courier) {
        if (courier.currentLocation == null) {
          return false;
        }

        // Calculate distance (simplified - for production use geohash)
        final distance = _calculateDistance(
          location.latitude,
          location.longitude,
          courier.currentLocation!.latitude,
          courier.currentLocation!.longitude,
        );

        return distance <= radiusKm;
      }).toList();

      // Sort by distance
      couriers.sort((a, b) {
        if (a.currentLocation == null || b.currentLocation == null) {
          return 0;
        }
        final distA = _calculateDistance(
          location.latitude,
          location.longitude,
          a.currentLocation!.latitude,
          a.currentLocation!.longitude,
        );
        final distB = _calculateDistance(
          location.latitude,
          location.longitude,
          b.currentLocation!.latitude,
          b.currentLocation!.longitude,
        );
        return distA.compareTo(distB);
      });

      return couriers;
    } catch (e) {
      Logger.error('Error getting available couriers: $e', tag: 'COURIER');
      return [];
    }
  }

  /// Calculează distanța între două puncte (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) => degrees * (math.pi / 180);

  static String _vehicleTypeToString(VehicleType type) {
    switch (type) {
      case VehicleType.bike:
        return 'bike';
      case VehicleType.scooter:
        return 'scooter';
      case VehicleType.car:
        return 'car';
    }
  }
}

