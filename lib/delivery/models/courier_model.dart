import 'package:cloud_firestore/cloud_firestore.dart';

/// Courier Status Enum
enum CourierStatus {
  offline,
  online,
  delivering,
}

/// Vehicle Type Enum
enum VehicleType {
  bike,
  scooter,
  car,
}

/// Courier Model
/// 
/// Reprezintă un curier partener
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

  Courier copyWith({
    String? id,
    String? userId,
    CourierStatus? status,
    String? currentOrderId,
    VehicleType? vehicleType,
    double? rating,
    int? completedDeliveries,
    GeoPoint? currentLocation,
    DateTime? lastLocationUpdate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Courier(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      vehicleType: vehicleType ?? this.vehicleType,
      rating: rating ?? this.rating,
      completedDeliveries: completedDeliveries ?? this.completedDeliveries,
      currentLocation: currentLocation ?? this.currentLocation,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

