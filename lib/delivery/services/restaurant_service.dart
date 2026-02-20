import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:friendsride_app/models/saved_address_model.dart';
import 'package:friendsride_app/delivery/models/restaurant_model.dart';
import 'package:friendsride_app/delivery/models/product_model.dart';
import 'package:friendsride_app/utils/logger.dart';
import 'package:friendsride_app/services/intelligent_cache_service.dart';

/// Restaurant Service
/// 
/// Gestionează operațiunile legate de restaurante
class RestaurantService {
  static final RestaurantService _instance = RestaurantService._internal();
  factory RestaurantService() => _instance;
  RestaurantService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final IntelligentCacheService _cache = IntelligentCacheService();
  
  // Cache TTL pentru meniu: 15 minute (meniul se schimbă rar)
  static const Duration _menuCacheTTL = Duration(minutes: 15);

  /// Obține lista de restaurante
  Future<List<Restaurant>> getRestaurants({
    int limit = 50,
    String? cuisineType,
    double? minRating,
    RestaurantStatus? status,
  }) async {
    try {
      Query query = _db.collection('restaurants').limit(limit);

      if (cuisineType != null) {
        query = query.where('cuisineTypes', arrayContains: cuisineType);
      }

      if (minRating != null) {
        query = query.where('rating', isGreaterThanOrEqualTo: minRating);
      }

      if (status != null) {
        query = query.where('status', isEqualTo: _statusToString(status));
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => Restaurant.fromFirestore(doc))
          .toList();
    } catch (e) {
      Logger.error('Error getting restaurants: $e', tag: 'RESTAURANT');
      return [];
    }
  }

  /// Obține un restaurant după ID
  Future<Restaurant?> getRestaurant(String restaurantId) async {
    try {
      final doc = await _db.collection('restaurants').doc(restaurantId).get();
      if (!doc.exists) {
        return null;
      }
      return Restaurant.fromFirestore(doc);
    } catch (e) {
      Logger.error('Error getting restaurant: $e', tag: 'RESTAURANT');
      return null;
    }
  }

  /// Obține meniul unui restaurant (cu cache pentru reducerea traficului de date)
  Future<List<Product>> getMenu(String restaurantId, {bool forceRefresh = false}) async {
    final cacheKey = 'menu_$restaurantId';
    
    try {
      // Verifică cache-ul dacă nu forțăm refresh-ul
      if (!forceRefresh) {
        final cachedMenu = await _cache.get<List<dynamic>>(
          cacheKey,
          maxAge: _menuCacheTTL,
        );
        
        // ✅ IMPORTANT: Nu folosim cache-ul dacă este gol - permite sincronizarea automată
        if (cachedMenu != null && cachedMenu.isNotEmpty) {
          // Convertim din cache în Product objects
          try {
            final products = cachedMenu.map((item) {
              if (item is Map<String, dynamic>) {
                // Reconstruim Product din Map
                return Product(
                  id: item['id'] ?? '',
                  restaurantId: item['restaurantId'] ?? restaurantId,
                  name: item['name'] ?? '',
                  description: item['description'] ?? '',
                  price: (item['price'] ?? 0.0).toDouble(),
                  imageUrl: item['imageUrl'],
                  category: item['category'] ?? '',
                  isAvailable: item['isAvailable'] ?? true,
                  allergens: List<String>.from(item['allergens'] ?? []),
                  nutritionalInfo: item['nutritionalInfo'] as Map<String, dynamic>?,
                  availableModifications: (item['availableModifications'] as List<dynamic>?)
                      ?.map((mod) => ProductModification.fromMap(mod as Map<String, dynamic>))
                      .toList(),
                  createdAt: item['createdAt'] != null 
                      ? (item['createdAt'] as Timestamp).toDate()
                      : DateTime.now(),
                  updatedAt: item['updatedAt'] != null
                      ? (item['updatedAt'] as Timestamp).toDate()
                      : DateTime.now(),
                );
              }
              return null;
            }).whereType<Product>().toList();
            
            if (products.isNotEmpty) {
              Logger.info('Menu loaded from cache for restaurant: $restaurantId (${products.length} products)', tag: 'RESTAURANT');
              return products;
            }
          } catch (e) {
            Logger.warning('Error parsing cached menu, fetching fresh: $e', tag: 'RESTAURANT');
            // Continuă cu fetch-ul fresh dacă cache-ul este corupt
          }
        } else if (cachedMenu != null && cachedMenu.isEmpty) {
          // Cache-ul conține o listă goală - invalidăm pentru a permite sincronizarea
          Logger.info('Empty menu cache detected, invalidating to allow sync for restaurant: $restaurantId', tag: 'RESTAURANT');
          await _cache.invalidate(cacheKey);
        }
      }
      
      // Fetch fresh data din Firestore
      final snapshot = await _db
          .collection('products')
          .where('restaurantId', isEqualTo: restaurantId)
          .where('isAvailable', isEqualTo: true)
          .orderBy('category')
          .get();

      final products = snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .toList();
      
      // Salvează în cache pentru următoarea utilizare
      if (products.isNotEmpty) {
        final cacheData = products.map((product) => {
          'id': product.id,
          'restaurantId': product.restaurantId,
          'name': product.name,
          'description': product.description,
          'price': product.price,
          'imageUrl': product.imageUrl,
          'category': product.category,
          'isAvailable': product.isAvailable,
          'allergens': product.allergens,
          'nutritionalInfo': product.nutritionalInfo,
          'availableModifications': product.availableModifications?.map((mod) => mod.toMap()).toList(),
          'createdAt': Timestamp.fromDate(product.createdAt),
          'updatedAt': Timestamp.fromDate(product.updatedAt),
        }).toList();
        
        await _cache.set(
          cacheKey,
          cacheData,
          ttl: _menuCacheTTL,
          priority: 2, // Prioritate medie pentru meniu
        );
        
        Logger.info('Menu cached for restaurant: $restaurantId (${products.length} products)', tag: 'RESTAURANT');
      }

      return products;
    } catch (e) {
      Logger.error('Error getting menu: $e', tag: 'RESTAURANT');
      return [];
    }
  }
  
  /// Invalidă cache-ul pentru meniul unui restaurant
  Future<void> _invalidateMenuCache(String restaurantId) async {
    final cacheKey = 'menu_$restaurantId';
    await _cache.invalidate(cacheKey);
    Logger.info('Menu cache invalidated for restaurant: $restaurantId', tag: 'RESTAURANT');
  }

  /// Căutare restaurante după nume sau descriere
  Future<List<Restaurant>> searchRestaurants(String query) async {
    try {
      // Firestore doesn't support full-text search, so we'll do a simple filter
      // For production, consider using Algolia or Elasticsearch
      final snapshot = await _db.collection('restaurants').get();
      
      final results = snapshot.docs
          .map((doc) => Restaurant.fromFirestore(doc))
          .where((restaurant) {
        final searchLower = query.toLowerCase();
        return restaurant.name.toLowerCase().contains(searchLower) ||
            restaurant.description.toLowerCase().contains(searchLower) ||
            restaurant.cuisineTypes.any((type) => type.toLowerCase().contains(searchLower));
      }).toList();

      return results;
    } catch (e) {
      Logger.error('Error searching restaurants: $e', tag: 'RESTAURANT');
      return [];
    }
  }

  /// Filtrare restaurante după criterii multiple
  Future<List<Restaurant>> filterRestaurants({
    List<String>? cuisineTypes,
    double? minRating,
    int? maxDeliveryTime,
    double? maxDeliveryFee,
    RestaurantStatus? status,
    geolocator.Position? userLocation,
    double? maxDistance, // in km
  }) async {
    try {
      Query query = _db.collection('restaurants');

      if (cuisineTypes != null && cuisineTypes.isNotEmpty) {
        query = query.where('cuisineTypes', arrayContainsAny: cuisineTypes);
      }

      if (minRating != null) {
        query = query.where('rating', isGreaterThanOrEqualTo: minRating);
      }

      if (maxDeliveryTime != null) {
        query = query.where('estimatedDeliveryTime', isLessThanOrEqualTo: maxDeliveryTime);
      }

      if (maxDeliveryFee != null) {
        query = query.where('deliveryFee', isLessThanOrEqualTo: maxDeliveryFee);
      }

      if (status != null) {
        query = query.where('status', isEqualTo: _statusToString(status));
      }

      final snapshot = await query.get();
      var results = snapshot.docs
          .map((doc) => Restaurant.fromFirestore(doc))
          .toList();

      // Filter by distance if user location is provided
      if (userLocation != null && maxDistance != null) {
        results = results.where((restaurant) {
          final distance = geolocator.Geolocator.distanceBetween(
            userLocation.latitude,
            userLocation.longitude,
            restaurant.address.coordinates.latitude,
            restaurant.address.coordinates.longitude,
          ) / 1000; // Convert to km
          return distance <= maxDistance;
        }).toList();
      }

      return results;
    } catch (e) {
      Logger.error('Error filtering restaurants: $e', tag: 'RESTAURANT');
      return [];
    }
  }

  /// Stream pentru restaurante (updates în timp real)
  Stream<List<Restaurant>> getRestaurantsStream({
    int limit = 50,
    RestaurantStatus? status,
  }) {
    Query query = _db.collection('restaurants').limit(limit);

    if (status != null) {
      query = query.where('status', isEqualTo: _statusToString(status));
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Restaurant.fromFirestore(doc))
        .toList());
  }

  /// Obține restaurantId-ul pentru un ownerId (utilizator)
  Future<String?> getRestaurantIdByOwnerId(String ownerId) async {
    try {
      final apiKeyDoc = await _db
          .collection('restaurant_api_keys')
          .where('ownerId', isEqualTo: ownerId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (apiKeyDoc.docs.isNotEmpty) {
        return apiKeyDoc.docs.first.data()['restaurantId'] as String?;
      }
      return null;
    } catch (e) {
      Logger.error('Error getting restaurant ID by owner: $e', tag: 'RESTAURANT');
      return null;
    }
  }

  /// Actualizează informațiile unui restaurant
  Future<void> updateRestaurant({
    required String restaurantId,
    String? name,
    String? description,
    SavedAddress? address,
    String? imageUrl,
    double? deliveryFee,
    double? minimumOrder,
    int? estimatedDeliveryTime,
    List<String>? cuisineTypes,
    Map<String, WorkingHours>? workingHours,
    RestaurantStatus? status,
    String? webhookUrl,
    String? restaurantAppV3TenantId,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };

      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (address != null) updates['address'] = address.toMap();
      if (imageUrl != null) updates['imageUrl'] = imageUrl;
      if (deliveryFee != null) updates['deliveryFee'] = deliveryFee;
      if (minimumOrder != null) updates['minimumOrder'] = minimumOrder;
      if (estimatedDeliveryTime != null) updates['estimatedDeliveryTime'] = estimatedDeliveryTime;
      if (cuisineTypes != null) updates['cuisineTypes'] = cuisineTypes;
      if (workingHours != null) {
        updates['workingHours'] = workingHours.map((key, value) => MapEntry(key, value.toMap()));
      }
      if (status != null) updates['status'] = _statusToString(status);
      if (webhookUrl != null) updates['webhookUrl'] = webhookUrl;
      if (restaurantAppV3TenantId != null) updates['restaurantAppV3TenantId'] = restaurantAppV3TenantId;

      await _db.collection('restaurants').doc(restaurantId).update(updates);
    } catch (e) {
      Logger.error('Error updating restaurant: $e', tag: 'RESTAURANT');
      rethrow;
    }
  }

  /// Creează un produs nou
  Future<String> createProduct({
    required String restaurantId,
    required String name,
    required String description,
    required double price,
    required String category,
    String? imageUrl,
    bool isAvailable = true,
    List<String>? allergens,
    Map<String, dynamic>? nutritionalInfo,
    List<ProductModification>? availableModifications,
  }) async {
    try {
      final productId = _db.collection('products').doc().id;
      final now = Timestamp.now();

      await _db.collection('products').doc(productId).set({
        'restaurantId': restaurantId,
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'imageUrl': imageUrl,
        'isAvailable': isAvailable,
        'allergens': allergens ?? [],
        'nutritionalInfo': nutritionalInfo,
        'availableModifications': availableModifications?.map((mod) => mod.toMap()).toList(),
        'createdAt': now,
        'updatedAt': now,
      });

      // Invalidă cache-ul meniului
      await _invalidateMenuCache(restaurantId);

      return productId;
    } catch (e) {
      Logger.error('Error creating product: $e', tag: 'RESTAURANT');
      rethrow;
    }
  }

  /// Actualizează un produs
  Future<void> updateProduct({
    required String productId,
    String? name,
    String? description,
    double? price,
    String? category,
    String? imageUrl,
    bool? isAvailable,
    List<String>? allergens,
    Map<String, dynamic>? nutritionalInfo,
    List<ProductModification>? availableModifications,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };

      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (price != null) updates['price'] = price;
      if (category != null) updates['category'] = category;
      if (imageUrl != null) updates['imageUrl'] = imageUrl;
      if (isAvailable != null) updates['isAvailable'] = isAvailable;
      if (allergens != null) updates['allergens'] = allergens;
      if (nutritionalInfo != null) updates['nutritionalInfo'] = nutritionalInfo;
      if (availableModifications != null) {
        updates['availableModifications'] = availableModifications.map((mod) => mod.toMap()).toList();
      }

      await _db.collection('products').doc(productId).update(updates);
      
      // Invalidă cache-ul meniului - trebuie să obținem restaurantId-ul
      final productDoc = await _db.collection('products').doc(productId).get();
      if (productDoc.exists) {
        final restaurantId = productDoc.data()?['restaurantId'] as String?;
        if (restaurantId != null) {
          await _invalidateMenuCache(restaurantId);
        }
      }
    } catch (e) {
      Logger.error('Error updating product: $e', tag: 'RESTAURANT');
      rethrow;
    }
  }

  /// Șterge un produs
  Future<void> deleteProduct(String productId) async {
    try {
      // Obține restaurantId-ul înainte de ștergere pentru invalidare cache
      final productDoc = await _db.collection('products').doc(productId).get();
      final restaurantId = productDoc.data()?['restaurantId'] as String?;
      
      await _db.collection('products').doc(productId).delete();
      
      // Invalidă cache-ul meniului
      if (restaurantId != null) {
        await _invalidateMenuCache(restaurantId);
      }
    } catch (e) {
      Logger.error('Error deleting product: $e', tag: 'RESTAURANT');
      rethrow;
    }
  }

  static String _statusToString(RestaurantStatus status) {
    switch (status) {
      case RestaurantStatus.open:
        return 'open';
      case RestaurantStatus.closed:
        return 'closed';
      case RestaurantStatus.busy:
        return 'busy';
    }
  }
}

