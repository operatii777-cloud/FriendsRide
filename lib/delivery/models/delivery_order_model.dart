import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:friendsride_app/models/saved_address_model.dart';
import 'package:friendsride_app/delivery/models/order_item_model.dart';
import 'package:friendsride_app/delivery/models/delivery_status.dart';

/// Delivery Order Model
/// 
/// Reprezintă o comandă completă de delivery cu toate detaliile
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

  /// Factory constructor from Firestore DocumentSnapshot
  factory DeliveryOrder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DeliveryOrder(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      courierId: data['courierId'],
      status: DeliveryOrderStatusExtension.fromString(data['status'] ?? 'pending'),
      items: (data['items'] as List<dynamic>?)
          ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList() ?? [],
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      deliveryFee: (data['deliveryFee'] ?? 0).toDouble(),
      serviceFee: (data['serviceFee'] ?? 0).toDouble(),
      total: (data['total'] ?? 0).toDouble(),
      deliveryAddress: _savedAddressFromMap(data['deliveryAddress'] as Map<String, dynamic>),
      restaurantAddress: _savedAddressFromMap(data['restaurantAddress'] as Map<String, dynamic>),
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

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'restaurantId': restaurantId,
      'courierId': courierId,
      'status': status.toFirestoreString(),
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

  /// Helper method to create SavedAddress from map
  static SavedAddress _savedAddressFromMap(Map<String, dynamic> map) {
    return SavedAddress(
      id: map['id'] ?? '',
      label: map['label'] ?? '',
      address: map['address'] ?? '',
      coordinates: map['coordinates'] as GeoPoint? ?? const GeoPoint(0, 0),
    );
  }

  /// Create a copy with updated fields
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

