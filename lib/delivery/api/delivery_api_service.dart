import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:friendsride_app/models/saved_address_model.dart';
import '../models/delivery_order_model.dart';
import '../models/product_model.dart';
import '../models/delivery_status.dart';
import '../models/order_item_model.dart';
import '../services/restaurant_api_key_service.dart';

/// API Service pentru integrare cu restaurante externe
/// 
/// Acest serviciu expune API endpoints pentru restaurante care doresc
/// să se integreze cu FriendsRide Delivery prin API Standard
class DeliveryApiService {
  static final DeliveryApiService _instance = DeliveryApiService._internal();
  factory DeliveryApiService() => _instance;
  DeliveryApiService._internal();

  final RestaurantApiKeyService _apiKeyService = RestaurantApiKeyService();

  // Base URL pentru API (va fi configurat în Cloud Functions)
  static const String _baseUrl = 'https://us-central1-friendsride.cloudfunctions.net';

  /// Validează un API key și returnează restaurantId
  Future<String?> validateApiKey(String apiKey) async {
    try {
      return await _apiKeyService.getRestaurantIdFromApiKey(apiKey);
    } catch (e) {
      return null;
    }
  }

  /// Obține restaurantId din API key
  Future<String?> getRestaurantIdFromApiKey(String apiKey) async {
    return await _apiKeyService.getRestaurantIdFromApiKey(apiKey);
  }

  /// Creează o comandă prin API (pentru restaurante externe)
  Future<DeliveryOrder?> createOrderViaApi({
    required String apiKey,
    required String restaurantId,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> deliveryAddress,
    required String paymentMethod,
    String? customerPhone,
    String? customerName,
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/delivery/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'restaurantId': restaurantId,
          'items': items,
          'deliveryAddress': deliveryAddress,
          'paymentMethod': paymentMethod,
          'customerPhone': customerPhone,
          'customerName': customerName,
          'notes': notes,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return _convertToDeliveryOrder(data);
      } else {
        throw Exception('Failed to create order: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Actualizează statusul unei comenzi (pentru restaurante externe)
  Future<void> updateOrderStatusViaApi({
    required String apiKey,
    required String orderId,
    required String status,
    int? estimatedTime,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/delivery/orders/$orderId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'status': status,
          'estimatedTime': estimatedTime,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update order status: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Obține meniul unui restaurant prin API
  Future<List<Product>> getMenuViaApi({
    required String apiKey,
    required String restaurantId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/delivery/restaurants/$restaurantId/menu'),
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('products') && data['products'] is List) {
          return (data['products'] as List).map((item) {
            final itemMap = item as Map<String, dynamic>;
            // Convert API response to Product model
            return Product(
              id: itemMap['id'] ?? '',
              restaurantId: itemMap['restaurantId'] ?? restaurantId,
              name: itemMap['name'] ?? '',
              description: itemMap['description'] ?? '',
              price: (itemMap['price'] ?? 0).toDouble(),
              imageUrl: itemMap['imageUrl'],
              category: itemMap['category'] ?? '',
              isAvailable: itemMap['isAvailable'] ?? true,
              allergens: List<String>.from(itemMap['allergens'] ?? []),
              nutritionalInfo: itemMap['nutritionalInfo'] as Map<String, dynamic>?,
              availableModifications: (itemMap['availableModifications'] as List<dynamic>?)
                  ?.map((mod) => ProductModification.fromMap(mod as Map<String, dynamic>))
                  .toList(),
              createdAt: itemMap['createdAt'] != null
                  ? DateTime.parse(itemMap['createdAt'])
                  : DateTime.now(),
              updatedAt: itemMap['updatedAt'] != null
                  ? DateTime.parse(itemMap['updatedAt'])
                  : DateTime.now(),
            );
          }).toList();
        }
        return [];
      } else {
        throw Exception('Failed to get menu: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Sincronizează meniul unui restaurant (pentru restaurante externe)
  Future<void> syncMenuViaApi({
    required String apiKey,
    required String restaurantId,
    required List<Map<String, dynamic>> products,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/delivery/restaurants/$restaurantId/menu/sync'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'products': products,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to sync menu: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Convertește răspunsul API la DeliveryOrder
  DeliveryOrder _convertToDeliveryOrder(Map<String, dynamic> data) {
    // Get restaurant address (required)
    final restaurantAddress = _convertToSavedAddress(
      data['restaurantAddress'] as Map<String, dynamic>?,
      defaultLabel: 'Restaurant',
    );

    // Get delivery address (required)
    final deliveryAddress = _convertToSavedAddress(
      data['deliveryAddress'] as Map<String, dynamic>?,
      defaultLabel: 'Delivery',
    );

    return DeliveryOrder(
      id: data['id'] ?? data['orderId'] ?? '',
      customerId: data['customerId'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      status: _convertStringToStatus(data['status'] ?? 'pending'),
      items: (data['items'] as List<dynamic>?)
              ?.map((item) => _convertToOrderItem(item as Map<String, dynamic>))
              .toList() ??
          [],
      deliveryAddress: deliveryAddress,
      restaurantAddress: restaurantAddress,
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      deliveryFee: (data['deliveryFee'] ?? 0).toDouble(),
      serviceFee: (data['serviceFee'] ?? 0).toDouble(),
      total: (data['total'] ?? 0).toDouble(),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.parse(data['createdAt']))
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] is Timestamp
              ? (data['updatedAt'] as Timestamp).toDate()
              : DateTime.parse(data['updatedAt']))
          : DateTime.now(),
      estimatedDeliveryTime: data['estimatedDeliveryTime'] != null
          ? (data['estimatedDeliveryTime'] is Timestamp
              ? (data['estimatedDeliveryTime'] as Timestamp).toDate()
              : DateTime.now().add(Duration(minutes: data['estimatedDeliveryTime'] as int? ?? 30)))
          : null,
      actualDeliveryTime: data['actualDeliveryTime'] != null
          ? (data['actualDeliveryTime'] is Timestamp
              ? (data['actualDeliveryTime'] as Timestamp).toDate()
              : DateTime.parse(data['actualDeliveryTime']))
          : null,
      paymentMethod: data['paymentMethod'] ?? 'card',
      promoCode: data['promoCode'],
      discount: data['discount']?.toDouble(),
      courierId: data['courierId'],
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convertește un item din API la OrderItem
  OrderItem _convertToOrderItem(Map<String, dynamic> item) {
    return OrderItem(
      id: item['id'] ?? '',
      productId: item['productId'] ?? item['id'] ?? '',
      productName: item['name'] ?? item['productName'] ?? '',
      quantity: item['quantity'] ?? 1,
      unitPrice: (item['price'] ?? item['unitPrice'] ?? 0).toDouble(),
      totalPrice: (item['totalPrice'] ?? (item['price'] ?? 0) * (item['quantity'] ?? 1)).toDouble(),
      modifications: List<String>.from(item['modifications'] ?? []),
      specialNotes: item['notes'] ?? item['specialNotes'],
    );
  }

  /// Convertește string la DeliveryOrderStatus
  DeliveryOrderStatus _convertStringToStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return DeliveryOrderStatus.pending;
      case 'accepted':
        return DeliveryOrderStatus.accepted;
      case 'preparing':
        return DeliveryOrderStatus.preparing;
      case 'ready':
        return DeliveryOrderStatus.ready;
      case 'picked_up':
        return DeliveryOrderStatus.pickedUp;
      case 'on_the_way':
        return DeliveryOrderStatus.onTheWay;
      case 'delivered':
        return DeliveryOrderStatus.delivered;
      case 'cancelled':
        return DeliveryOrderStatus.cancelled;
      default:
        return DeliveryOrderStatus.pending;
    }
  }

  /// Convertește map la SavedAddress
  SavedAddress _convertToSavedAddress(Map<String, dynamic>? map, {String defaultLabel = 'Address'}) {
    if (map == null) {
      return SavedAddress(
        id: '',
        label: defaultLabel,
        address: '',
        coordinates: const GeoPoint(0, 0),
      );
    }

    GeoPoint coordinates;
    if (map['coordinates'] is GeoPoint) {
      coordinates = map['coordinates'] as GeoPoint;
    } else if (map['latitude'] != null && map['longitude'] != null) {
      coordinates = GeoPoint(
        (map['latitude'] as num).toDouble(),
        (map['longitude'] as num).toDouble(),
      );
    } else {
      coordinates = const GeoPoint(0, 0);
    }

    return SavedAddress(
      id: map['id'] ?? '',
      label: map['label'] ?? defaultLabel,
      address: map['address'] ?? '',
      coordinates: coordinates,
    );
  }
}

