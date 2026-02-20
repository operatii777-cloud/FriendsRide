import 'package:cloud_firestore/cloud_firestore.dart';

/// Service pentru analytics și rapoarte delivery
class DeliveryAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obține statistici pentru un restaurant
  Future<Map<String, dynamic>> getRestaurantStats({
    required String restaurantId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final end = endDate ?? DateTime.now();
    final start = startDate ?? end.subtract(const Duration(days: 30));

    final orders = await _firestore
        .collection('delivery_orders')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    double totalRevenue = 0;
    int totalOrders = orders.docs.length;
    int completedOrders = 0;
    int cancelledOrders = 0;
    double averageOrderValue = 0;

    for (final doc in orders.docs) {
      final data = doc.data();
      final status = data['status'] as String;
      final total = (data['total'] as num).toDouble();

      totalRevenue += total;

      if (status == 'delivered') {
        completedOrders++;
      } else if (status == 'cancelled') {
        cancelledOrders++;
      }
    }

    if (totalOrders > 0) {
      averageOrderValue = totalRevenue / totalOrders;
    }

    return {
      'totalRevenue': totalRevenue,
      'totalOrders': totalOrders,
      'completedOrders': completedOrders,
      'cancelledOrders': cancelledOrders,
      'averageOrderValue': averageOrderValue,
      'completionRate': totalOrders > 0 ? completedOrders / totalOrders : 0.0,
      'period': {
        'start': start,
        'end': end,
      },
    };
  }

  /// Obține statistici pentru un curier
  Future<Map<String, dynamic>> getCourierStats({
    required String courierId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final end = endDate ?? DateTime.now();
    final start = startDate ?? end.subtract(const Duration(days: 30));

    final orders = await _firestore
        .collection('delivery_orders')
        .where('courierId', isEqualTo: courierId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    int totalDeliveries = 0;
    double totalEarnings = 0;
    double averageDeliveryTime = 0;
    int totalDeliveryTime = 0;

    for (final doc in orders.docs) {
      final data = doc.data();
      final status = data['status'] as String;

      if (status == 'delivered') {
        totalDeliveries++;
        // Calculate earnings for courier (fixed fee per delivery + distance-based)
        // Base fee: 5 RON per delivery
        // Distance fee: 0.5 RON per km after first 3 km
        final deliveryFee = (data['deliveryFee'] ?? 5.0).toDouble();
        // For now, use deliveryFee as earnings (can be refined with distance calculation)
        totalEarnings += deliveryFee;

        // Calculate delivery time
        final createdAt = (data['createdAt'] as Timestamp).toDate();
        final deliveredAt = data['deliveredAt'] != null
            ? (data['deliveredAt'] as Timestamp).toDate()
            : null;

        if (deliveredAt != null) {
          totalDeliveryTime += deliveredAt.difference(createdAt).inMinutes;
        }
      }
    }

    if (totalDeliveries > 0) {
      averageDeliveryTime = totalDeliveryTime / totalDeliveries;
    }

    return {
      'totalDeliveries': totalDeliveries,
      'totalEarnings': totalEarnings,
      'averageDeliveryTime': averageDeliveryTime,
      'period': {
        'start': start,
        'end': end,
      },
    };
  }

  /// Obține top produse pentru un restaurant
  Future<List<Map<String, dynamic>>> getTopProducts({
    required String restaurantId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
  }) async {
    final end = endDate ?? DateTime.now();
    final start = startDate ?? end.subtract(const Duration(days: 30));

    final orders = await _firestore
        .collection('delivery_orders')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    final productCounts = <String, int>{};
    final productNames = <String, String>{};

    for (final doc in orders.docs) {
      final data = doc.data();
      final items = data['items'] as List<dynamic>? ?? [];

      for (final item in items) {
        final productId = item['productId'] as String? ?? '';
        final productName = item['productName'] as String? ?? '';
        final quantity = item['quantity'] as int? ?? 1;

        productCounts[productId] = (productCounts[productId] ?? 0) + quantity;
        productNames[productId] = productName;
      }
    }

    final sortedProducts = productCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedProducts.take(limit).map((entry) {
      return {
        'productId': entry.key,
        'productName': productNames[entry.key] ?? 'Unknown',
        'quantity': entry.value,
      };
    }).toList();
  }

  /// Obține statistici globale (admin)
  Future<Map<String, dynamic>> getGlobalStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final end = endDate ?? DateTime.now();
    final start = startDate ?? end.subtract(const Duration(days: 30));

    final orders = await _firestore
        .collection('delivery_orders')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    double totalRevenue = 0;
    int totalOrders = orders.docs.length;
    int activeRestaurants = 0;
    int activeCouriers = 0;

    final restaurantIds = <String>{};
    final courierIds = <String>{};

    for (final doc in orders.docs) {
      final data = doc.data();
      final total = (data['total'] as num).toDouble();
      final restaurantId = data['restaurantId'] as String?;
      final courierId = data['courierId'] as String?;

      totalRevenue += total;

      if (restaurantId != null) {
        restaurantIds.add(restaurantId);
      }

      if (courierId != null) {
        courierIds.add(courierId);
      }
    }

    activeRestaurants = restaurantIds.length;
    activeCouriers = courierIds.length;

    return {
      'totalRevenue': totalRevenue,
      'totalOrders': totalOrders,
      'activeRestaurants': activeRestaurants,
      'activeCouriers': activeCouriers,
      'averageOrderValue': totalOrders > 0 ? totalRevenue / totalOrders : 0.0,
      'period': {
        'start': start,
        'end': end,
      },
    };
  }
}

