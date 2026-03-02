import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:friendsride_app/models/saved_address_model.dart';

/// Working Hours Model
/// 
/// Reprezintă programul de lucru al unui restaurant pentru o zi
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

/// Restaurant Status Enum
enum RestaurantStatus {
  open,
  closed,
  busy,
}

/// Restaurant Model
/// 
/// Reprezintă un restaurant partener
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
  final String? webhookUrl; // URL-ul Restaurant App v3 pentru webhooks
  final String? restaurantAppV3TenantId; // ID-ul tenant-ului în Restaurant App v3
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
    this.webhookUrl,
    this.restaurantAppV3TenantId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Restaurant.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Restaurant(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      address: _savedAddressFromMap(data['address'] as Map<String, dynamic>),
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
      webhookUrl: data['webhookUrl'] as String?,
      restaurantAppV3TenantId: data['restaurantAppV3TenantId'] as String?,
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
      'webhookUrl': webhookUrl,
      'restaurantAppV3TenantId': restaurantAppV3TenantId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
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

  Restaurant copyWith({
    String? id,
    String? name,
    String? description,
    SavedAddress? address,
    String? imageUrl,
    double? rating,
    int? reviewCount,
    int? estimatedDeliveryTime,
    double? deliveryFee,
    double? minimumOrder,
    List<String>? cuisineTypes,
    RestaurantStatus? status,
    Map<String, WorkingHours>? workingHours,
    List<String>? deliveryZones,
    String? webhookUrl,
    String? restaurantAppV3TenantId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Restaurant(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      minimumOrder: minimumOrder ?? this.minimumOrder,
      cuisineTypes: cuisineTypes ?? this.cuisineTypes,
      status: status ?? this.status,
      workingHours: workingHours ?? this.workingHours,
      deliveryZones: deliveryZones ?? this.deliveryZones,
      webhookUrl: webhookUrl ?? this.webhookUrl,
      restaurantAppV3TenantId: restaurantAppV3TenantId ?? this.restaurantAppV3TenantId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

