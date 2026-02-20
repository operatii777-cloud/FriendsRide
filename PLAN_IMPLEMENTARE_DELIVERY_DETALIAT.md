# 🍕 PLAN EXTRAORDINAR DE DETALIAT - IMPLEMENTARE DELIVERY FRIENDSRIDE

**Data:** 2025-01-XX  
**Versiune:** 2.0 - EXTRAORDINAR DE DETALIAT  
**Status:** ÎN IMPLEMENTARE

---

## 📋 CUPRINS

1. [Overview & Arhitectură](#1-overview--arhitectură)
2. [Faza 1: Fundație - Models & Data Structure](#2-faza-1-fundație---models--data-structure)
3. [Faza 2: Fundație - Services](#3-faza-2-fundație---services)
4. [Faza 3: Customer App - Restaurant Discovery](#4-faza-3-customer-app---restaurant-discovery)
5. [Faza 4: Customer App - Product Selection & Cart](#5-faza-4-customer-app---product-selection--cart)
6. [Faza 5: Customer App - Checkout](#6-faza-5-customer-app---checkout)
7. [Faza 6: Customer App - Order Tracking](#7-faza-6-customer-app---order-tracking)
8. [Faza 7: Courier App - Dashboard & Order Management](#8-faza-7-courier-app---dashboard--order-management)
9. [Faza 8: Restaurant App - Order & Menu Management](#9-faza-8-restaurant-app---order--menu-management)
10. [Faza 9: Matching & Optimization](#10-faza-9-matching--optimization)
11. [Faza 10: Advanced Features](#11-faza-10-advanced-features)
12. [Faza 11: Testing & Polish](#12-faza-11-testing--polish)

---

## 1. OVERVIEW & ARHITECTURĂ

### 1.1. **STRUCTURĂ DIRECTOARE**

```
lib/
├── delivery/                    # NOU - Modul Delivery
│   ├── models/
│   │   ├── delivery_order_model.dart
│   │   ├── order_item_model.dart
│   │   ├── restaurant_model.dart
│   │   ├── product_model.dart
│   │   ├── courier_model.dart
│   │   ├── delivery_status.dart
│   │   └── delivery_address_model.dart
│   ├── services/
│   │   ├── delivery_service.dart
│   │   ├── restaurant_service.dart
│   │   ├── courier_service.dart
│   │   ├── delivery_matching_service.dart
│   │   └── delivery_pricing_service.dart
│   ├── screens/
│   │   ├── customer/
│   │   │   ├── restaurant_list_screen.dart
│   │   │   ├── restaurant_detail_screen.dart
│   │   │   ├── product_detail_screen.dart
│   │   │   ├── cart_screen.dart
│   │   │   ├── checkout_screen.dart
│   │   │   └── delivery_tracking_screen.dart
│   │   ├── courier/
│   │   │   ├── courier_dashboard_screen.dart
│   │   │   ├── courier_order_screen.dart
│   │   │   └── courier_earnings_screen.dart
│   │   └── restaurant/
│   │       ├── restaurant_orders_screen.dart
│   │       └── restaurant_menu_management_screen.dart
│   └── widgets/
│       ├── restaurant_card.dart
│       ├── product_card.dart
│       ├── cart_item_card.dart
│       ├── order_status_card.dart
│       └── courier_status_widget.dart
├── ride/                        # EXISTENT - Ride Sharing
└── shared/                      # EXISTENT - Cod partajat
```

### 1.2. **FIRESTORE COLLECTIONS STRUCTURE**

```
delivery_orders/
  {orderId}/
    - id: string
    - customerId: string
    - restaurantId: string
    - courierId: string? (nullable)
    - status: string (pending, accepted, preparing, ready, picked_up, on_the_way, delivered, cancelled)
    - items: array<OrderItem>
    - subtotal: number
    - deliveryFee: number
    - serviceFee: number
    - total: number
    - deliveryAddress: Address
    - restaurantAddress: Address
    - createdAt: timestamp
    - updatedAt: timestamp
    - estimatedDeliveryTime: timestamp?
    - actualDeliveryTime: timestamp?
    - paymentMethod: string
    - promoCode: string?
    - discount: number?
    - metadata: map<string, dynamic>?

restaurants/
  {restaurantId}/
    - id: string
    - name: string
    - description: string
    - address: Address
    - imageUrl: string?
    - rating: number (0-5)
    - reviewCount: number
    - estimatedDeliveryTime: number (minutes)
    - deliveryFee: number
    - minimumOrder: number
    - cuisineTypes: array<string>
    - status: string (open, closed, busy)
    - workingHours: map<string, WorkingHours>
    - deliveryZones: array<string>
    - createdAt: timestamp
    - updatedAt: timestamp

products/
  {productId}/
    - id: string
    - restaurantId: string
    - name: string
    - description: string
    - price: number
    - imageUrl: string?
    - category: string
    - isAvailable: boolean
    - allergens: array<string>
    - nutritionalInfo: map<string, dynamic>?
    - availableModifications: array<ProductModification>?
    - createdAt: timestamp
    - updatedAt: timestamp

couriers/
  {courierId}/
    - id: string
    - userId: string
    - status: string (offline, online, delivering)
    - currentOrderId: string?
    - vehicleType: string (bike, scooter, car)
    - rating: number (0-5)
    - completedDeliveries: number
    - currentLocation: GeoPoint?
    - lastLocationUpdate: timestamp
    - createdAt: timestamp
    - updatedAt: timestamp
```

---

## 2. FAZA 1: FUNDAȚIE - MODELS & DATA STRUCTURE

### 2.1. **DELIVERY ORDER MODEL**

**Fișier:** `lib/delivery/models/delivery_order_model.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:friendsride_app/models/saved_address_model.dart';
import 'order_item_model.dart';
import 'delivery_status.dart';

class DeliveryOrder {
  final String id;
  final String customerId;
  final String restaurantId;
  final String? courierId;
  final DeliveryOrderStatus status;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final double total;
  final SavedAddress deliveryAddress;
  final SavedAddress restaurantAddress;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? estimatedDeliveryTime;
  final DateTime? actualDeliveryTime;
  final String paymentMethod;
  final String? promoCode;
  final double? discount;
  final Map<String, dynamic>? metadata;

  DeliveryOrder({
    required this.id,
    required this.customerId,
    required this.restaurantId,
    this.courierId,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.total,
    required this.deliveryAddress,
    required this.restaurantAddress,
    required this.createdAt,
    required this.updatedAt,
    this.estimatedDeliveryTime,
    this.actualDeliveryTime,
    required this.paymentMethod,
    this.promoCode,
    this.discount,
    this.metadata,
  });

  // Factory constructor from Firestore
  factory DeliveryOrder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DeliveryOrder(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      courierId: data['courierId'],
      status: DeliveryOrderStatus.fromString(data['status'] ?? 'pending'),
      items: (data['items'] as List<dynamic>?)
          ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList() ?? [],
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      deliveryFee: (data['deliveryFee'] ?? 0).toDouble(),
      serviceFee: (data['serviceFee'] ?? 0).toDouble(),
      total: (data['total'] ?? 0).toDouble(),
      deliveryAddress: SavedAddress.fromMap(data['deliveryAddress'] as Map<String, dynamic>),
      restaurantAddress: SavedAddress.fromMap(data['restaurantAddress'] as Map<String, dynamic>),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      estimatedDeliveryTime: data['estimatedDeliveryTime'] != null
          ? (data['estimatedDeliveryTime'] as Timestamp).toDate()
          : null,
      actualDeliveryTime: data['actualDeliveryTime'] != null
          ? (data['actualDeliveryTime'] as Timestamp).toDate()
          : null,
      paymentMethod: data['paymentMethod'] ?? '',
      promoCode: data['promoCode'],
      discount: data['discount']?.toDouble(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  // Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'restaurantId': restaurantId,
      'courierId': courierId,
      'status': status.toString(),
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'serviceFee': serviceFee,
      'total': total,
      'deliveryAddress': deliveryAddress.toMap(),
      'restaurantAddress': restaurantAddress.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'estimatedDeliveryTime': estimatedDeliveryTime != null
          ? Timestamp.fromDate(estimatedDeliveryTime!)
          : null,
      'actualDeliveryTime': actualDeliveryTime != null
          ? Timestamp.fromDate(actualDeliveryTime!)
          : null,
      'paymentMethod': paymentMethod,
      'promoCode': promoCode,
      'discount': discount,
      'metadata': metadata,
    };
  }

  // Copy with method
  DeliveryOrder copyWith({
    String? id,
    String? customerId,
    String? restaurantId,
    String? courierId,
    DeliveryOrderStatus? status,
    List<OrderItem>? items,
    double? subtotal,
    double? deliveryFee,
    double? serviceFee,
    double? total,
    SavedAddress? deliveryAddress,
    SavedAddress? restaurantAddress,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? estimatedDeliveryTime,
    DateTime? actualDeliveryTime,
    String? paymentMethod,
    String? promoCode,
    double? discount,
    Map<String, dynamic>? metadata,
  }) {
    return DeliveryOrder(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      restaurantId: restaurantId ?? this.restaurantId,
      courierId: courierId ?? this.courierId,
      status: status ?? this.status,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      serviceFee: serviceFee ?? this.serviceFee,
      total: total ?? this.total,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      restaurantAddress: restaurantAddress ?? this.restaurantAddress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      actualDeliveryTime: actualDeliveryTime ?? this.actualDeliveryTime,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      promoCode: promoCode ?? this.promoCode,
      discount: discount ?? this.discount,
      metadata: metadata ?? this.metadata,
    );
  }
}
```

### 2.2. **DELIVERY STATUS ENUM**

**Fișier:** `lib/delivery/models/delivery_status.dart`

```dart
enum DeliveryOrderStatus {
  pending,        // Comandă creată, așteaptă acceptare
  accepted,      // Restaurant a acceptat comanda
  preparing,     // Restaurant pregătește comanda
  ready,         // Comanda este gata pentru preluare
  pickedUp,      // Curier a preluat comanda
  onTheWay,      // Curier este în drum către client
  delivered,     // Comanda a fost livrată
  cancelled,     // Comanda a fost anulată

  String toString() {
    switch (this) {
      case DeliveryOrderStatus.pending:
        return 'pending';
      case DeliveryOrderStatus.accepted:
        return 'accepted';
      case DeliveryOrderStatus.preparing:
        return 'preparing';
      case DeliveryOrderStatus.ready:
        return 'ready';
      case DeliveryOrderStatus.pickedUp:
        return 'picked_up';
      case DeliveryOrderStatus.onTheWay:
        return 'on_the_way';
      case DeliveryOrderStatus.delivered:
        return 'delivered';
      case DeliveryOrderStatus.cancelled:
        return 'cancelled';
    }
  }

  static DeliveryOrderStatus fromString(String status) {
    switch (status) {
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

  String getDisplayName(String locale) {
    if (locale == 'ro') {
      switch (this) {
        case DeliveryOrderStatus.pending:
          return 'În așteptare';
        case DeliveryOrderStatus.accepted:
          return 'Acceptată';
        case DeliveryOrderStatus.preparing:
          return 'Se pregătește';
        case DeliveryOrderStatus.ready:
          return 'Gata';
        case DeliveryOrderStatus.pickedUp:
          return 'Preluată';
        case DeliveryOrderStatus.onTheWay:
          return 'În drum';
        case DeliveryOrderStatus.delivered:
          return 'Livrată';
        case DeliveryOrderStatus.cancelled:
          return 'Anulată';
      }
    } else {
      switch (this) {
        case DeliveryOrderStatus.pending:
          return 'Pending';
        case DeliveryOrderStatus.accepted:
          return 'Accepted';
        case DeliveryOrderStatus.preparing:
          return 'Preparing';
        case DeliveryOrderStatus.ready:
          return 'Ready';
        case DeliveryOrderStatus.pickedUp:
          return 'Picked Up';
        case DeliveryOrderStatus.onTheWay:
          return 'On The Way';
        case DeliveryOrderStatus.delivered:
          return 'Delivered';
        case DeliveryOrderStatus.cancelled:
          return 'Cancelled';
      }
    }
  }
}
```

### 2.3. **ORDER ITEM MODEL**

**Fișier:** `lib/delivery/models/order_item_model.dart`

```dart
class OrderItem {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final List<String> modifications; // ["fără ceapă", "extra sos"]
  final String? specialNotes;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.modifications = const [],
    this.specialNotes,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: map['quantity'] ?? 1,
      unitPrice: (map['unitPrice'] ?? 0).toDouble(),
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      modifications: List<String>.from(map['modifications'] ?? []),
      specialNotes: map['specialNotes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'modifications': modifications,
      'specialNotes': specialNotes,
    };
  }

  OrderItem copyWith({
    String? id,
    String? productId,
    String? productName,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    List<String>? modifications,
    String? specialNotes,
  }) {
    return OrderItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      modifications: modifications ?? this.modifications,
      specialNotes: specialNotes ?? this.specialNotes,
    );
  }
}
```

### 2.4. **RESTAURANT MODEL**

**Fișier:** `lib/delivery/models/restaurant_model.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:friendsride_app/models/saved_address_model.dart';

class WorkingHours {
  final String openTime; // "09:00"
  final String closeTime; // "22:00"
  final bool isOpen;

  WorkingHours({
    required this.openTime,
    required this.closeTime,
    required this.isOpen,
  });

  factory WorkingHours.fromMap(Map<String, dynamic> map) {
    return WorkingHours(
      openTime: map['openTime'] ?? '09:00',
      closeTime: map['closeTime'] ?? '22:00',
      isOpen: map['isOpen'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'openTime': openTime,
      'closeTime': closeTime,
      'isOpen': isOpen,
    };
  }
}

enum RestaurantStatus {
  open,
  closed,
  busy,
}

class Restaurant {
  final String id;
  final String name;
  final String description;
  final SavedAddress address;
  final String? imageUrl;
  final double rating;
  final int reviewCount;
  final int estimatedDeliveryTime; // minutes
  final double deliveryFee;
  final double minimumOrder;
  final List<String> cuisineTypes;
  final RestaurantStatus status;
  final Map<String, WorkingHours> workingHours;
  final List<String> deliveryZones;
  final DateTime createdAt;
  final DateTime updatedAt;

  Restaurant({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    this.imageUrl,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.estimatedDeliveryTime,
    required this.deliveryFee,
    required this.minimumOrder,
    this.cuisineTypes = const [],
    this.status = RestaurantStatus.open,
    this.workingHours = const {},
    this.deliveryZones = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Restaurant.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Restaurant(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      address: SavedAddress.fromMap(data['address'] as Map<String, dynamic>),
      imageUrl: data['imageUrl'],
      rating: (data['rating'] ?? 0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      estimatedDeliveryTime: data['estimatedDeliveryTime'] ?? 30,
      deliveryFee: (data['deliveryFee'] ?? 0).toDouble(),
      minimumOrder: (data['minimumOrder'] ?? 0).toDouble(),
      cuisineTypes: List<String>.from(data['cuisineTypes'] ?? []),
      status: _statusFromString(data['status'] ?? 'open'),
      workingHours: (data['workingHours'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(
                key,
                WorkingHours.fromMap(value as Map<String, dynamic>),
              )) ?? {},
      deliveryZones: List<String>.from(data['deliveryZones'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'address': address.toMap(),
      'imageUrl': imageUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'estimatedDeliveryTime': estimatedDeliveryTime,
      'deliveryFee': deliveryFee,
      'minimumOrder': minimumOrder,
      'cuisineTypes': cuisineTypes,
      'status': _statusToString(status),
      'workingHours': workingHours.map((key, value) => MapEntry(key, value.toMap())),
      'deliveryZones': deliveryZones,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static RestaurantStatus _statusFromString(String status) {
    switch (status) {
      case 'open':
        return RestaurantStatus.open;
      case 'closed':
        return RestaurantStatus.closed;
      case 'busy':
        return RestaurantStatus.busy;
      default:
        return RestaurantStatus.open;
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
```

### 2.5. **PRODUCT MODEL**

**Fișier:** `lib/delivery/models/product_model.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModification {
  final String id;
  final String name;
  final double? price; // null = free

  ProductModification({
    required this.id,
    required this.name,
    this.price,
  });

  factory ProductModification.fromMap(Map<String, dynamic> map) {
    return ProductModification(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: map['price']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
    };
  }
}

class Product {
  final String id;
  final String restaurantId;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final String category; // "Aperitive", "Feluri principale", etc.
  final bool isAvailable;
  final List<String> allergens;
  final Map<String, dynamic>? nutritionalInfo;
  final List<ProductModification>? availableModifications;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.category,
    this.isAvailable = true,
    this.allergens = const [],
    this.nutritionalInfo,
    this.availableModifications,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      restaurantId: data['restaurantId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'],
      category: data['category'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
      allergens: List<String>.from(data['allergens'] ?? []),
      nutritionalInfo: data['nutritionalInfo'] as Map<String, dynamic>?,
      availableModifications: (data['availableModifications'] as List<dynamic>?)
          ?.map((mod) => ProductModification.fromMap(mod as Map<String, dynamic>))
          .toList(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'restaurantId': restaurantId,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'isAvailable': isAvailable,
      'allergens': allergens,
      'nutritionalInfo': nutritionalInfo,
      'availableModifications': availableModifications?.map((mod) => mod.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
```

### 2.6. **COURIER MODEL**

**Fișier:** `lib/delivery/models/courier_model.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum CourierStatus {
  offline,
  online,
  delivering,
}

enum VehicleType {
  bike,
  scooter,
  car,
}

class Courier {
  final String id;
  final String userId;
  final CourierStatus status;
  final String? currentOrderId;
  final VehicleType vehicleType;
  final double rating;
  final int completedDeliveries;
  final GeoPoint? currentLocation;
  final DateTime? lastLocationUpdate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Courier({
    required this.id,
    required this.userId,
    this.status = CourierStatus.offline,
    this.currentOrderId,
    required this.vehicleType,
    this.rating = 0.0,
    this.completedDeliveries = 0,
    this.currentLocation,
    this.lastLocationUpdate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Courier.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Courier(
      id: doc.id,
      userId: data['userId'] ?? '',
      status: _statusFromString(data['status'] ?? 'offline'),
      currentOrderId: data['currentOrderId'],
      vehicleType: _vehicleTypeFromString(data['vehicleType'] ?? 'bike'),
      rating: (data['rating'] ?? 0).toDouble(),
      completedDeliveries: data['completedDeliveries'] ?? 0,
      currentLocation: data['currentLocation'] as GeoPoint?,
      lastLocationUpdate: data['lastLocationUpdate'] != null
          ? (data['lastLocationUpdate'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'status': _statusToString(status),
      'currentOrderId': currentOrderId,
      'vehicleType': _vehicleTypeToString(vehicleType),
      'rating': rating,
      'completedDeliveries': completedDeliveries,
      'currentLocation': currentLocation,
      'lastLocationUpdate': lastLocationUpdate != null
          ? Timestamp.fromDate(lastLocationUpdate!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static CourierStatus _statusFromString(String status) {
    switch (status) {
      case 'offline':
        return CourierStatus.offline;
      case 'online':
        return CourierStatus.online;
      case 'delivering':
        return CourierStatus.delivering;
      default:
        return CourierStatus.offline;
    }
  }

  static String _statusToString(CourierStatus status) {
    switch (status) {
      case CourierStatus.offline:
        return 'offline';
      case CourierStatus.online:
        return 'online';
      case CourierStatus.delivering:
        return 'delivering';
    }
  }

  static VehicleType _vehicleTypeFromString(String type) {
    switch (type) {
      case 'bike':
        return VehicleType.bike;
      case 'scooter':
        return VehicleType.scooter;
      case 'car':
        return VehicleType.car;
      default:
        return VehicleType.bike;
    }
  }

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
```

---

## 3. FAZA 2: FUNDAȚIE - SERVICES

### 3.1. **DELIVERY SERVICE**

**Fișier:** `lib/delivery/services/delivery_service.dart`

**Funcționalități:**
- `createOrder()` - Creează o comandă nouă
- `getOrder()` - Obține o comandă după ID
- `getOrderStream()` - Stream pentru updates în timp real
- `updateOrderStatus()` - Actualizează statusul comenzii
- `assignCourier()` - Atribuie un curier comenzii
- `cancelOrder()` - Anulează o comandă
- `getCustomerOrders()` - Obține comenzile unui client
- `getCourierOrders()` - Obține comenzile unui curier
- `getRestaurantOrders()` - Obține comenzile unui restaurant

### 3.2. **RESTAURANT SERVICE**

**Fișier:** `lib/delivery/services/restaurant_service.dart`

**Funcționalități:**
- `getRestaurants()` - Obține lista de restaurante
- `getRestaurant()` - Obține un restaurant după ID
- `getMenu()` - Obține meniul unui restaurant
- `searchRestaurants()` - Căutare restaurante
- `filterRestaurants()` - Filtrare restaurante

### 3.3. **COURIER SERVICE**

**Fișier:** `lib/delivery/services/courier_service.dart`

**Funcționalități:**
- `goOnline()` - Curierul devine disponibil
- `goOffline()` - Curierul devine indisponibil
- `acceptOrder()` - Acceptă o comandă
- `rejectOrder()` - Refuză o comandă
- `updateLocation()` - Actualizează locația curierului
- `completeDelivery()` - Finalizează o livrare

### 3.4. **DELIVERY MATCHING SERVICE**

**Fișier:** `lib/delivery/services/delivery_matching_service.dart`

**Funcționalități:**
- `findAvailableCouriers()` - Găsește curieri disponibili
- `matchCourierToOrder()` - Potrivește un curier cu o comandă
- `calculateETA()` - Calculează ETA pentru livrare

---

**CONTINUARE ÎN URMELELE FAZE...**

*Acest document va fi extins continuu pe măsură ce implementăm fiecare fază.*

