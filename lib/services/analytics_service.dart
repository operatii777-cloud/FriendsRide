import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:friendsride_app/models/ride_model.dart';
import 'package:friendsride_app/utils/logger.dart';

/// Serviciu pentru Business Intelligence și Analytics
class AnalyticsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Obține analytics pentru șofer
  Future<Map<String, dynamic>> getDriverAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      // Get rides in period
      final ridesSnapshot = await _db
          .collection('ride_requests')
          .where('driverId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      final rides = ridesSnapshot.docs.map((doc) => Ride.fromFirestore(doc)).toList();

      // Calculate metrics
      final totalRides = rides.length;
      final totalEarnings = rides.fold<double>(0.0, (total, ride) => total + (ride.driverEarnings));
      final totalDistance = rides.fold<double>(0.0, (total, ride) => total + ride.distance);
      final totalDuration = rides.fold<double>(0.0, (total, ride) => total + (ride.durationInMinutes ?? 0));
      final averageRating = _calculateAverageRating(rides);
      final ridesByCategory = _groupRidesByCategory(rides);
      final earningsByDay = _groupEarningsByDay(rides, start, end);

      return {
        'totalRides': totalRides,
        'totalEarnings': totalEarnings,
        'totalDistance': totalDistance,
        'totalDuration': totalDuration,
        'averageRating': averageRating,
        'averageEarningsPerRide': totalRides > 0 ? totalEarnings / totalRides : 0.0,
        'averageDistancePerRide': totalRides > 0 ? totalDistance / totalRides : 0.0,
        'ridesByCategory': ridesByCategory,
        'earningsByDay': earningsByDay,
        'period': {
          'start': start,
          'end': end,
        },
      };
    } catch (e) {
      Logger.error('Error getting driver analytics', error: e, tag: 'Analytics');
      rethrow;
    }
  }

  /// Obține analytics pentru pasager
  Future<Map<String, dynamic>> getPassengerAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      // Get rides in period
      final ridesSnapshot = await _db
          .collection('ride_requests')
          .where('passengerId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      final rides = ridesSnapshot.docs.map((doc) => Ride.fromFirestore(doc)).toList();

      // Calculate metrics
      final totalRides = rides.length;
      final totalSpent = rides.fold<double>(0.0, (total, ride) => total + ride.totalCost);
      final totalDistance = rides.fold<double>(0.0, (total, ride) => total + ride.distance);
      final averageRating = _calculateAverageRating(rides);
      final ridesByCategory = _groupRidesByCategory(rides);

      return {
        'totalRides': totalRides,
        'totalSpent': totalSpent,
        'totalDistance': totalDistance,
        'averageRating': averageRating,
        'averageCostPerRide': totalRides > 0 ? totalSpent / totalRides : 0.0,
        'ridesByCategory': ridesByCategory,
        'period': {
          'start': start,
          'end': end,
        },
      };
    } catch (e) {
      Logger.error('Error getting passenger analytics', error: e, tag: 'Analytics');
      rethrow;
    }
  }

  /// Obține analytics globale (admin)
  Future<Map<String, dynamic>> getGlobalAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      // Get all completed rides in period
      final ridesSnapshot = await _db
          .collection('ride_requests')
          .where('status', isEqualTo: 'completed')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      final rides = ridesSnapshot.docs.map((doc) => Ride.fromFirestore(doc)).toList();

      // Calculate global metrics
      final totalRides = rides.length;
      final totalRevenue = rides.fold<double>(0.0, (total, ride) => total + ride.totalCost);
      final totalCommission = rides.fold<double>(0.0, (total, ride) => total + ride.appCommission);
      final totalDriverEarnings = rides.fold<double>(0.0, (total, ride) => total + ride.driverEarnings);
      final activeDrivers = rides.map((r) => r.driverId).whereType<String>().toSet().length;
      final activePassengers = rides.map((r) => r.passengerId).toSet().length;

      return {
        'totalRides': totalRides,
        'totalRevenue': totalRevenue,
        'totalCommission': totalCommission,
        'totalDriverEarnings': totalDriverEarnings,
        'activeDrivers': activeDrivers,
        'activePassengers': activePassengers,
        'averageRideValue': totalRides > 0 ? totalRevenue / totalRides : 0.0,
        'period': {
          'start': start,
          'end': end,
        },
      };
    } catch (e) {
      Logger.error('Error getting global analytics', error: e, tag: 'Analytics');
      rethrow;
    }
  }

  /// Export analytics data as JSON
  Future<String> exportAnalyticsAsJson(Map<String, dynamic> analytics) async {
    try {
      return const JsonEncoder.withIndent('  ').convert(analytics);
    } catch (e) {
      Logger.error('Error exporting analytics', error: e, tag: 'Analytics');
      rethrow;
    }
  }

  /// Log custom event
  Future<void> logEvent(String eventName, Map<String, dynamic>? parameters) async {
    try {
      await _analytics.logEvent(
        name: eventName,
        parameters: parameters?.map((key, value) => MapEntry(key, value as Object)),
      );
    } catch (e) {
      Logger.error('Error logging event', error: e, tag: 'Analytics');
    }
  }

  // Helper methods
  double _calculateAverageRating(List<Ride> rides) {
    final ratedRides = rides.where((r) => r.driverRating != null).toList();
    if (ratedRides.isEmpty) return 0.0;
    final sum = ratedRides.fold<double>(0.0, (s, r) => s + (r.driverRating ?? 0.0));
    return sum / ratedRides.length;
  }

  Map<String, int> _groupRidesByCategory(List<Ride> rides) {
    final Map<String, int> grouped = {};
    for (final ride in rides) {
      final category = ride.category.name;
      grouped[category] = (grouped[category] ?? 0) + 1;
    }
    return grouped;
  }

  Map<String, double> _groupEarningsByDay(List<Ride> rides, DateTime start, DateTime end) {
    final Map<String, double> earningsByDay = {};
    for (final ride in rides) {
      final dayKey = '${ride.timestamp.year}-${ride.timestamp.month.toString().padLeft(2, '0')}-${ride.timestamp.day.toString().padLeft(2, '0')}';
      earningsByDay[dayKey] = (earningsByDay[dayKey] ?? 0.0) + ride.driverEarnings;
    }
    return earningsByDay;
  }
}

