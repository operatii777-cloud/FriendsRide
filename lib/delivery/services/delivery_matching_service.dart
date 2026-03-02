import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:friendsride_app/delivery/models/courier_model.dart';
import 'package:friendsride_app/delivery/models/delivery_order_model.dart';
import 'package:friendsride_app/delivery/services/courier_service.dart';
import 'package:friendsride_app/utils/logger.dart';

/// Delivery Matching Service
/// 
/// Gestionează matching-ul între comenzi și curieri
class DeliveryMatchingService {
  static final DeliveryMatchingService _instance = DeliveryMatchingService._internal();
  factory DeliveryMatchingService() => _instance;
  DeliveryMatchingService._internal();

  final CourierService _courierService = CourierService();

  /// Găsește curieri disponibili pentru o comandă
  Future<List<CourierMatchResult>> findAvailableCouriers({
    required DeliveryOrder order,
    double maxDistanceKm = 10.0,
    int maxResults = 5,
  }) async {
    try {
      // Get restaurant location
      final restaurantLocation = GeoPoint(
        order.restaurantAddress.coordinates.latitude,
        order.restaurantAddress.coordinates.longitude,
      );

      // Get available couriers near restaurant
      final couriers = await _courierService.getAvailableCouriers(
        location: restaurantLocation,
        radiusKm: maxDistanceKm,
        limit: 20,
      );

      if (couriers.isEmpty) {
        Logger.warning('No available couriers found', tag: 'MATCHING');
        return [];
      }

      // Calculate ETA and distance for each courier
      final results = <CourierMatchResult>[];
      for (final courier in couriers.take(maxResults)) {
        if (courier.currentLocation == null) {
          continue;
        }

        try {
          // Calculate distance from courier to restaurant
          final distanceToRestaurant = geolocator.Geolocator.distanceBetween(
            courier.currentLocation!.latitude,
            courier.currentLocation!.longitude,
            restaurantLocation.latitude,
            restaurantLocation.longitude,
          ) / 1000; // Convert to km

          // Calculate distance from restaurant to delivery address
          final distanceToDelivery = geolocator.Geolocator.distanceBetween(
            restaurantLocation.latitude,
            restaurantLocation.longitude,
            order.deliveryAddress.coordinates.latitude,
            order.deliveryAddress.coordinates.longitude,
          ) / 1000; // Convert to km

          // Estimate ETA (simplified - assumes average speed based on vehicle type)
          final avgSpeedKmh = _getAverageSpeed(courier.vehicleType);
          final etaToRestaurant = (distanceToRestaurant / avgSpeedKmh * 60).round(); // minutes
          final etaToDelivery = (distanceToDelivery / avgSpeedKmh * 60).round(); // minutes
          final totalEta = etaToRestaurant + etaToDelivery;

          // Calculate match score (lower is better)
          final score = _calculateMatchScore(
            courier: courier,
            distanceToRestaurant: distanceToRestaurant,
            totalEta: totalEta,
          );

          results.add(CourierMatchResult(
            courier: courier,
            distanceToRestaurant: distanceToRestaurant,
            distanceToDelivery: distanceToDelivery,
            estimatedEta: totalEta,
            matchScore: score,
          ));
        } catch (e) {
          Logger.error('Error calculating match for courier ${courier.id}: $e', tag: 'MATCHING');
          continue;
        }
      }

      // Sort by match score (best first)
      results.sort((a, b) => a.matchScore.compareTo(b.matchScore));

      Logger.info('Found ${results.length} courier matches for order ${order.id}', tag: 'MATCHING');
      return results;
    } catch (e) {
      Logger.error('Error finding available couriers: $e', tag: 'MATCHING');
      return [];
    }
  }

  /// Potrivește un curier cu o comandă (selectează cel mai bun match)
  Future<Courier?> matchCourierToOrder(DeliveryOrder order) async {
    try {
      final matches = await findAvailableCouriers(order: order, maxResults: 1);
      if (matches.isEmpty) {
        return null;
      }
      return matches.first.courier;
    } catch (e) {
      Logger.error('Error matching courier to order: $e', tag: 'MATCHING');
      return null;
    }
  }

  /// Calculează ETA pentru livrare
  Future<int> calculateETA({
    required GeoPoint fromLocation,
    required GeoPoint toLocation,
    required VehicleType vehicleType,
  }) async {
    try {
      final distance = geolocator.Geolocator.distanceBetween(
        fromLocation.latitude,
        fromLocation.longitude,
        toLocation.latitude,
        toLocation.longitude,
      ) / 1000; // Convert to km

      final avgSpeed = _getAverageSpeed(vehicleType);
      final eta = (distance / avgSpeed * 60).round(); // minutes

      // Add buffer for traffic, etc.
      return eta + 5; // Add 5 minutes buffer
    } catch (e) {
      Logger.error('Error calculating ETA: $e', tag: 'MATCHING');
      return 30; // Default 30 minutes
    }
  }

  /// Obține viteza medie în funcție de tipul de vehicul
  double _getAverageSpeed(VehicleType vehicleType) {
    switch (vehicleType) {
      case VehicleType.bike:
        return 15.0; // km/h
      case VehicleType.scooter:
        return 25.0; // km/h
      case VehicleType.car:
        return 40.0; // km/h (considering traffic)
    }
  }

  /// Calculează score-ul de matching (lower is better)
  double _calculateMatchScore({
    required Courier courier,
    required double distanceToRestaurant,
    required int totalEta,
  }) {
    // Base score from distance
    double score = distanceToRestaurant * 10;

    // Add ETA penalty
    score += totalEta * 2;

    // Rating bonus (higher rating = lower score)
    score -= courier.rating * 5;

    // Experience bonus (more deliveries = lower score)
    score -= (courier.completedDeliveries / 100) * 2;

    return score;
  }
}

/// Result of courier matching
class CourierMatchResult {
  final Courier courier;
  final double distanceToRestaurant; // km
  final double distanceToDelivery; // km
  final int estimatedEta; // minutes
  final double matchScore; // lower is better

  CourierMatchResult({
    required this.courier,
    required this.distanceToRestaurant,
    required this.distanceToDelivery,
    required this.estimatedEta,
    required this.matchScore,
  });
}

