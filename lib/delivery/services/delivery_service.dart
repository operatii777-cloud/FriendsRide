import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:friendsride_app/delivery/models/delivery_order_model.dart';
import 'package:friendsride_app/delivery/models/delivery_status.dart';
import 'package:friendsride_app/delivery/models/order_item_model.dart';
import 'package:friendsride_app/models/saved_address_model.dart';
import 'package:friendsride_app/utils/logger.dart';
import 'restaurant_service.dart';

/// Delivery Service
/// 
/// Gestionează toate operațiunile legate de comenzi de delivery
class DeliveryService {
  static final DeliveryService _instance = DeliveryService._internal();
  factory DeliveryService() => _instance;
  DeliveryService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RestaurantService _restaurantService = RestaurantService();

  /// Creează o comandă nouă
  Future<DeliveryOrder> createOrder({
    required String restaurantId,
    required List<OrderItem> items,
    required SavedAddress deliveryAddress,
    required SavedAddress restaurantAddress,
    required String paymentMethod,
    required double subtotal,
    required double deliveryFee,
    required double serviceFee,
    required double total,
    String? promoCode,
    double? discount,
    String? notes,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now();
      final orderId = _db.collection('delivery_orders').doc().id;

      final order = DeliveryOrder(
        id: orderId,
        customerId: userId,
        restaurantId: restaurantId,
        status: DeliveryOrderStatus.pending,
        items: items,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        serviceFee: serviceFee,
        total: total,
        deliveryAddress: deliveryAddress,
        restaurantAddress: restaurantAddress,
        createdAt: now,
        updatedAt: now,
        paymentMethod: paymentMethod,
        promoCode: promoCode,
        discount: discount,
        metadata: notes != null ? {'notes': notes} : null,
      );

      await _db.collection('delivery_orders').doc(orderId).set(order.toFirestore());

      Logger.info('Delivery order created: $orderId', tag: 'DELIVERY');

      // Trimite comanda către Restaurant App v3 dacă restaurantul are webhookUrl configurat
      await _sendOrderToRestaurantAppV3(order, restaurantId);

      return order;
    } catch (e) {
      Logger.error('Error creating delivery order: $e', tag: 'DELIVERY');
      rethrow;
    }
  }

  /// Obține o comandă după ID
  Future<DeliveryOrder?> getOrder(String orderId) async {
    try {
      final doc = await _db.collection('delivery_orders').doc(orderId).get();
      if (!doc.exists) {
        return null;
      }
      return DeliveryOrder.fromFirestore(doc);
    } catch (e) {
      Logger.error('Error getting delivery order: $e', tag: 'DELIVERY');
      return null;
    }
  }

  /// Stream pentru updates în timp real ale unei comenzi
  Stream<DeliveryOrder?> getOrderStream(String orderId) {
    return _db
        .collection('delivery_orders')
        .doc(orderId)
        .snapshots()
        .map((doc) => doc.exists ? DeliveryOrder.fromFirestore(doc) : null);
  }

  /// Actualizează statusul unei comenzi
  Future<void> updateOrderStatus({
    required String orderId,
    required DeliveryOrderStatus status,
    String? courierId,
    DateTime? estimatedDeliveryTime,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status.toFirestoreString(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (courierId != null) {
        updates['courierId'] = courierId;
      }

      if (estimatedDeliveryTime != null) {
        updates['estimatedDeliveryTime'] = Timestamp.fromDate(estimatedDeliveryTime);
      }

      await _db.collection('delivery_orders').doc(orderId).update(updates);

      Logger.info('Order status updated: $orderId -> ${status.toFirestoreString()}', tag: 'DELIVERY');
    } catch (e) {
      Logger.error('Error updating order status: $e', tag: 'DELIVERY');
      rethrow;
    }
  }

  /// Atribuie un curier unei comenzi
  Future<void> assignCourier({
    required String orderId,
    required String courierId,
  }) async {
    try {
      await updateOrderStatus(
        orderId: orderId,
        status: DeliveryOrderStatus.accepted,
        courierId: courierId,
      );
    } catch (e) {
      Logger.error('Error assigning courier: $e', tag: 'DELIVERY');
      rethrow;
    }
  }

  /// Anulează o comandă (doar dacă nu au trecut mai mult de 5 minute de la plasare)
  /// 
  /// Returnează true dacă anularea a reușit, false dacă a expirat timpul
  Future<bool> cancelOrder(String orderId, {String? reason}) async {
    try {
      // Obține comanda pentru a verifica timpul
      final order = await getOrder(orderId);
      if (order == null) {
        throw Exception('Comanda nu a fost găsită');
      }

      // Verifică dacă comanda poate fi anulată
      if (order.status == DeliveryOrderStatus.cancelled) {
        throw Exception('Comanda este deja anulată');
      }

      if (order.status == DeliveryOrderStatus.delivered) {
        throw Exception('Comanda a fost deja livrată');
      }

      // Verifică timer-ul de 5 minute
      final timeSinceCreation = DateTime.now().difference(order.createdAt);
      const maxCancellationTime = Duration(minutes: 5);

      if (timeSinceCreation > maxCancellationTime) {
        throw Exception(
          'Nu mai poți anula comanda. Timpul de anulare (5 minute) a expirat.',
        );
      }

      // Actualizează status-ul în Firestore
      final updates = <String, dynamic>{
        'status': DeliveryOrderStatus.cancelled.toFirestoreString(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final metadata = <String, dynamic>{
        ...?order.metadata,
        'cancellationReason': reason ?? 'Anulată de client',
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledBy': 'customer',
      };

      updates['metadata'] = metadata;

      await _db.collection('delivery_orders').doc(orderId).update(updates);

      Logger.info('Order cancelled: $orderId', tag: 'DELIVERY');

      // Trimite webhook către Restaurant App v3 dacă există restaurantOrderId
      if (order.metadata?['restaurantOrderId'] != null) {
        await _sendCancellationToRestaurantAppV3(
          orderId: orderId,
          restaurantOrderId: order.metadata!['restaurantOrderId'] as String,
          restaurantId: order.restaurantId,
          reason: reason ?? 'Anulată de client',
        );
      }

      return true;
    } catch (e) {
      Logger.error('Error cancelling order: $e', tag: 'DELIVERY');
      rethrow;
    }
  }

  /// Trimite notificare de anulare către Restaurant App v3
  Future<void> _sendCancellationToRestaurantAppV3({
    required String orderId,
    required String restaurantOrderId,
    required String restaurantId,
    required String reason,
  }) async {
    try {
      final restaurant = await _restaurantService.getRestaurant(restaurantId);
      if (restaurant == null || restaurant.webhookUrl == null || restaurant.webhookUrl!.isEmpty) {
        Logger.info('Restaurant $restaurantId nu are webhookUrl configurat - anularea rămâne doar în Firestore', tag: 'DELIVERY');
        return;
      }

      final normalizedBaseUrl = await _normalizeWebhookUrl(restaurant.webhookUrl!);
      final cancelUrl = normalizedBaseUrl.endsWith('/')
          ? '${normalizedBaseUrl}api/orders/$restaurantOrderId/cancel'
          : '$normalizedBaseUrl/api/orders/$restaurantOrderId/cancel';

      Logger.info('🔄 [DELIVERY] Sending cancellation to Restaurant App v3: $cancelUrl', tag: 'DELIVERY');

      final response = await http.post(
        Uri.parse(cancelUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'reason': reason,
          'cancelledBy': 'customer',
          'friendsrideOrderId': orderId,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        Logger.info('✅ [DELIVERY] Cancellation sent to Restaurant App v3 successfully', tag: 'DELIVERY');
      } else {
        Logger.warning('⚠️ [DELIVERY] Failed to send cancellation to Restaurant App v3: ${response.statusCode}', tag: 'DELIVERY');
      }
    } catch (e) {
      Logger.error('❌ [DELIVERY] Error sending cancellation to Restaurant App v3: $e', tag: 'DELIVERY');
      // Nu aruncăm eroare - anularea rămâne în Firestore
    }
  }

  /// Trimite comanda către Restaurant App v3 (dacă este configurat)
  Future<void> _sendOrderToRestaurantAppV3(
    DeliveryOrder order,
    String restaurantId,
  ) async {
    try {
      Logger.info('🔄 [DELIVERY] Starting order transmission to Restaurant App v3 for order: ${order.id}', tag: 'DELIVERY');
      
      // Obține informațiile restaurantului
      final restaurant = await _restaurantService.getRestaurant(restaurantId);
      if (restaurant == null || restaurant.webhookUrl == null || restaurant.webhookUrl!.isEmpty) {
        Logger.info('Restaurant $restaurantId nu are webhookUrl configurat - comanda rămâne doar în Firestore', tag: 'DELIVERY');
        return;
      }

      Logger.info('🔄 [DELIVERY] Restaurant webhookUrl: ${restaurant.webhookUrl}', tag: 'DELIVERY');

      // Normalizează URL-ul pentru a funcționa atât pe emulator cât și pe device fizic
      final normalizedBaseUrl = await _normalizeWebhookUrl(restaurant.webhookUrl!);
      Logger.info('🔄 [DELIVERY] Normalized base URL: $normalizedBaseUrl', tag: 'DELIVERY');

      final webhookUrl = normalizedBaseUrl.endsWith('/')
          ? '${normalizedBaseUrl}api/delivery/orders'
          : '$normalizedBaseUrl/api/delivery/orders';

      Logger.info('🔄 [DELIVERY] Full webhook URL: $webhookUrl', tag: 'DELIVERY');

      // Obține categoriile produselor pentru a determina station (BAR vs KITCHEN)
      final List<Map<String, dynamic>> itemsWithCategory = [];
      for (final item in order.items) {
        try {
          // Obține produsul din Firestore pentru a lua categoria
          final productDoc = await _db.collection('products').doc(item.productId).get();
          String category = 'Other';
          if (productDoc.exists) {
            final productData = productDoc.data();
            category = productData?['category'] ?? 'Other';
          }
          
          itemsWithCategory.add({
            'id': item.productId,
            'name': item.productName,
            'quantity': item.quantity,
            'price': item.unitPrice,
            'totalPrice': item.totalPrice,
            'category': category, // Adăugăm categoria pentru determinarea station
            'modifications': item.modifications,
            'notes': item.specialNotes,
          });
        } catch (e) {
          Logger.warning('⚠️ [DELIVERY] Error getting category for product ${item.productId}: $e', tag: 'DELIVERY');
          // Fallback: adaugă item-ul fără categorie
          itemsWithCategory.add({
            'id': item.productId,
            'name': item.productName,
            'quantity': item.quantity,
            'price': item.unitPrice,
            'totalPrice': item.totalPrice,
            'category': 'Other',
            'modifications': item.modifications,
            'notes': item.specialNotes,
          });
        }
      }

      // Pregătește datele pentru Restaurant App v3
      final requestBody = {
        'friendsrideOrderId': order.id,
        'restaurantId': restaurantId,
        'items': itemsWithCategory,
        'customerId': order.customerId,
        'deliveryAddress': {
          'address': order.deliveryAddress.address,
          'label': order.deliveryAddress.label,
          'latitude': order.deliveryAddress.coordinates.latitude,
          'longitude': order.deliveryAddress.coordinates.longitude,
        },
        'total': order.total,
        'paymentMethod': order.paymentMethod,
        'customerPhone': null, // Va fi adăugat din user profile dacă e necesar
        'customerName': null, // Va fi adăugat din user profile dacă e necesar
        'notes': order.metadata?['notes'] as String?,
      };

      Logger.info('🔄 [DELIVERY] Sending POST request with ${order.items.length} items...', tag: 'DELIVERY');

      // Trimite POST către Restaurant App v3 (timeout mărit la 30 secunde)
      final response = await http.post(
        Uri.parse(webhookUrl),
        headers: {
          'Content-Type': 'application/json',
          // Poți adăuga autentificare aici dacă e necesară
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      Logger.info('🔄 [DELIVERY] Response status: ${response.statusCode}', tag: 'DELIVERY');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final restaurantOrderId = responseData['restaurantOrderId'] as String?;
        
        Logger.info('🔄 [DELIVERY] Response body: ${response.body}', tag: 'DELIVERY');
        
        if (restaurantOrderId != null) {
          // Salvează restaurantOrderId în Firestore pentru tracking
          await _db.collection('delivery_orders').doc(order.id).update({
            'restaurantOrderId': restaurantOrderId,
            'metadata': {
              ...?order.metadata,
              'restaurantOrderId': restaurantOrderId,
              'sentToRestaurantAppAt': FieldValue.serverTimestamp(),
            },
          });
        }

        Logger.info(
          '✅ [DELIVERY] Order ${order.id} sent to Restaurant App v3 successfully. Restaurant Order ID: $restaurantOrderId',
          tag: 'DELIVERY',
        );
      } else {
        Logger.error(
          '❌ [DELIVERY] Failed to send order to Restaurant App v3: ${response.statusCode} - ${response.body}',
          tag: 'DELIVERY',
        );
        // Nu aruncăm eroare - comanda rămâne în Firestore și poate fi trimisă manual mai târziu
      }
    } catch (e, stackTrace) {
      Logger.error(
        '❌ [DELIVERY] Error sending order to Restaurant App v3: $e',
        tag: 'DELIVERY',
      );
      Logger.error(
        '❌ [DELIVERY] Stack trace: $stackTrace',
        tag: 'DELIVERY',
      );
      // Nu aruncăm eroare - comanda rămâne în Firestore
    }
  }

  /// Normalizează URL-ul webhook pentru a funcționa atât pe emulator cât și pe device fizic
  Future<String> _normalizeWebhookUrl(String webhookUrl) async {
    // Dacă URL-ul conține localhost sau 127.0.0.1 sau 10.0.2.2, înlocuiește cu adresa corectă
    if (webhookUrl.contains('localhost') || webhookUrl.contains('127.0.0.1') || webhookUrl.contains('10.0.2.2')) {
      if (Platform.isAndroid) {
        try {
          final deviceInfo = DeviceInfoPlugin();
          final androidInfo = await deviceInfo.androidInfo;
          
          // Dacă este device fizic, folosește host-ul configurat sau IP-ul default
          if (androidInfo.isPhysicalDevice) {
            // Încearcă să citească host-ul configurat din SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            final configuredHost = prefs.getString('restaurant_app_v3_ip');
            
            // Dacă există host configurat, folosește-l
            if (configuredHost != null && configuredHost.isNotEmpty) {
              Logger.info('✅ [DELIVERY] Using configured host: $configuredHost', tag: 'DELIVERY');
              // Dacă webhookUrl este localhost sau 10.0.2.2, înlocuiește doar host-ul
              final uri = Uri.tryParse(webhookUrl);
              if (uri != null) {
                // Dacă configuredHost este un URL complet, folosește-l direct
                if (configuredHost.startsWith('http://') || configuredHost.startsWith('https://')) {
                  return configuredHost;
                }
                // Păstrează protocolul și portul, schimbă doar host-ul
                final newUri = uri.replace(host: configuredHost);
                return newUri.toString();
              }
              // Fallback: înlocuiește simplu
              return webhookUrl
                  .replaceAll('localhost', configuredHost)
                  .replaceAll('127.0.0.1', configuredHost)
                  .replaceAll('10.0.2.2', configuredHost);
            }
            
            // Dacă nu există host configurat, folosește IP-ul default
            // NOTĂ: Pentru utilizare pe date mobile, configurează URL-ul public (ngrok, etc.)
            const defaultPcIp = '192.168.50.238'; // IP-ul PC-ului detectat
            Logger.warning('⚠️ [DELIVERY] No configured host found, using default: $defaultPcIp', tag: 'DELIVERY');
            Logger.warning('💡 [DELIVERY] Configure URL in Delivery Settings for mobile data usage', tag: 'DELIVERY');
            return webhookUrl
                .replaceAll('localhost', defaultPcIp)
                .replaceAll('127.0.0.1', defaultPcIp)
                .replaceAll('10.0.2.2', defaultPcIp);
          } else {
            // Pentru emulator Android, folosește 10.0.2.2
            Logger.info('✅ [DELIVERY] Android emulator detected, using 10.0.2.2', tag: 'DELIVERY');
            return webhookUrl
                .replaceAll('localhost', '10.0.2.2')
                .replaceAll('127.0.0.1', '10.0.2.2');
          }
        } catch (e) {
          Logger.warning('⚠️ [DELIVERY] Error detecting device type: $e, using original URL', tag: 'DELIVERY');
          return webhookUrl;
        }
      } else if (Platform.isIOS) {
        // Pentru iOS simulator, folosește localhost
        Logger.info('✅ [DELIVERY] iOS simulator detected, using localhost', tag: 'DELIVERY');
        return webhookUrl;
      }
    }
    
    // Dacă URL-ul nu conține localhost/127.0.0.1/10.0.2.2, returnează-l așa cum este
    return webhookUrl;
  }

  /// Obține comenzile unui client
  Stream<List<DeliveryOrder>> getCustomerOrders({
    String? customerId,
    int limit = 50,
  }) {
    final uid = customerId ?? _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value([]);
    }

    return _db
        .collection('delivery_orders')
        .where('customerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DeliveryOrder.fromFirestore(doc))
            .toList());
  }

  /// Obține comenzile unui curier
  Stream<List<DeliveryOrder>> getCourierOrders({
    String? courierId,
    int limit = 50,
  }) {
    final uid = courierId ?? _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value([]);
    }

    // First get courier document to find courierId
    return _db
        .collection('couriers')
        .where('userId', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .asyncMap((courierSnapshot) async {
      if (courierSnapshot.docs.isEmpty) {
        return <DeliveryOrder>[];
      }

      final courierDoc = courierSnapshot.docs.first;
      final courierIdFromDoc = courierDoc.id;

      final ordersSnapshot = await _db
          .collection('delivery_orders')
          .where('courierId', isEqualTo: courierIdFromDoc)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return ordersSnapshot.docs
          .map((doc) => DeliveryOrder.fromFirestore(doc))
          .toList();
    });
  }

  /// Obține comenzile unui restaurant
  Stream<List<DeliveryOrder>> getRestaurantOrders({
    required String restaurantId,
    DeliveryOrderStatus? status,
    int limit = 50,
  }) {
    Query query = _db
        .collection('delivery_orders')
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (status != null) {
      query = query.where('status', isEqualTo: status.toFirestoreString());
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => DeliveryOrder.fromFirestore(doc))
        .toList());
  }

  /// Marchează o comandă ca livrată
  Future<void> markAsDelivered(String orderId) async {
    try {
      await updateOrderStatus(
        orderId: orderId,
        status: DeliveryOrderStatus.delivered,
      );

      await _db.collection('delivery_orders').doc(orderId).update({
        'actualDeliveryTime': FieldValue.serverTimestamp(),
      });

      Logger.info('Order marked as delivered: $orderId', tag: 'DELIVERY');
    } catch (e) {
      Logger.error('Error marking order as delivered: $e', tag: 'DELIVERY');
      rethrow;
    }
  }

  /// Obține comenzi disponibile pentru curieri (status = ready)
  Future<List<DeliveryOrder>> getAvailableOrders() async {
    try {
      final snapshot = await _db
          .collection('delivery_orders')
          .where('status', isEqualTo: DeliveryOrderStatus.ready.toFirestoreString())
          .orderBy('createdAt', descending: false)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => DeliveryOrder.fromFirestore(doc))
          .toList();
    } catch (e) {
      Logger.error('Error getting available orders: $e', tag: 'DELIVERY');
      return [];
    }
  }

  /// Stream pentru comenzi disponibile
  Stream<List<DeliveryOrder>> getAvailableOrdersStream() {
    return _db
        .collection('delivery_orders')
        .where('status', isEqualTo: DeliveryOrderStatus.ready.toFirestoreString())
        .orderBy('createdAt', descending: false)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DeliveryOrder.fromFirestore(doc))
            // ✅ Filtrare: exclude comenzile anulate (status cancelled sau metadata.isCancelledInRestaurant = true)
            .where((order) => 
              order.status != DeliveryOrderStatus.cancelled &&
              (order.metadata?['isCancelledInRestaurant'] != true)
            )
            .toList());
  }

  /// Obține comanda activă pentru un curier
  Future<DeliveryOrder?> getActiveOrderForCourier({String? courierId}) async {
    try {
      final uid = courierId ?? _auth.currentUser?.uid;
      if (uid == null) {
        return null;
      }

      // Get courier document
      final courierSnapshot = await _db
          .collection('couriers')
          .where('userId', isEqualTo: uid)
          .limit(1)
          .get();

      if (courierSnapshot.docs.isEmpty) {
        return null;
      }

      final courierIdFromDoc = courierSnapshot.docs.first.id;

      // Get active order
      final orderSnapshot = await _db
          .collection('delivery_orders')
          .where('courierId', isEqualTo: courierIdFromDoc)
          .where('status', whereIn: [
            DeliveryOrderStatus.accepted.toFirestoreString(),
            DeliveryOrderStatus.pickedUp.toFirestoreString(),
            DeliveryOrderStatus.onTheWay.toFirestoreString(),
          ])
          .limit(1)
          .get();

      if (orderSnapshot.docs.isEmpty) {
        return null;
      }

      return DeliveryOrder.fromFirestore(orderSnapshot.docs.first);
    } catch (e) {
      Logger.error('Error getting active order: $e', tag: 'DELIVERY');
      return null;
    }
  }

  /// Stream pentru comanda activă a unui curier
  Stream<DeliveryOrder?> getActiveOrderStreamForCourier({String? courierId}) {
    final uid = courierId ?? _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value(null);
    }

    return _db
        .collection('couriers')
        .where('userId', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .asyncMap((courierSnapshot) async {
      if (courierSnapshot.docs.isEmpty) {
        return null;
      }

      final courierIdFromDoc = courierSnapshot.docs.first.id;

      return _db
          .collection('delivery_orders')
          .where('courierId', isEqualTo: courierIdFromDoc)
          .where('status', whereIn: [
            DeliveryOrderStatus.accepted.toFirestoreString(),
            DeliveryOrderStatus.pickedUp.toFirestoreString(),
            DeliveryOrderStatus.onTheWay.toFirestoreString(),
          ])
          .limit(1)
          .snapshots()
          .map((orderSnapshot) {
        if (orderSnapshot.docs.isEmpty) {
          return null;
        }
        return DeliveryOrder.fromFirestore(orderSnapshot.docs.first);
      });
    }).asyncExpand((stream) => stream);
  }

  /// Acceptă o comandă de către un curier
  Future<void> acceptOrder({
    required String orderId,
    String? courierId,
  }) async {
    try {
      final uid = courierId ?? _auth.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      // Get courier document
      final courierSnapshot = await _db
          .collection('couriers')
          .where('userId', isEqualTo: uid)
          .limit(1)
          .get();

      if (courierSnapshot.docs.isEmpty) {
        throw Exception('Courier not found');
      }

      final courierIdFromDoc = courierSnapshot.docs.first.id;

      // Update order
      await updateOrderStatus(
        orderId: orderId,
        status: DeliveryOrderStatus.accepted,
        courierId: courierIdFromDoc,
      );

      Logger.info('Order accepted by courier: $orderId', tag: 'DELIVERY');
    } catch (e) {
      Logger.error('Error accepting order: $e', tag: 'DELIVERY');
      rethrow;
    }
  }

  /// Marchează comanda ca preluată de curier
  Future<void> markAsPickedUp(String orderId) async {
    try {
      await updateOrderStatus(
        orderId: orderId,
        status: DeliveryOrderStatus.pickedUp,
      );
      Logger.info('Order marked as picked up: $orderId', tag: 'DELIVERY');
    } catch (e) {
      Logger.error('Error marking order as picked up: $e', tag: 'DELIVERY');
      rethrow;
    }
  }

  /// Marchează comanda ca în drum către client
  Future<void> markAsOnTheWay(String orderId) async {
    try {
      await updateOrderStatus(
        orderId: orderId,
        status: DeliveryOrderStatus.onTheWay,
      );
      Logger.info('Order marked as on the way: $orderId', tag: 'DELIVERY');
    } catch (e) {
      Logger.error('Error marking order as on the way: $e', tag: 'DELIVERY');
      rethrow;
    }
  }
}

