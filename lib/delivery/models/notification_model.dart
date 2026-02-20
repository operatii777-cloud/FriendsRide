import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipuri de notificări pentru delivery
enum NotificationType {
  orderCreated,
  orderAccepted,
  orderReady,
  orderPickedUp,
  orderOnTheWay,
  orderDelivered,
  orderCancelled,
  courierAssigned,
  courierArrived,
  paymentReceived,
  promoCodeApplied,
}

/// Model pentru notificări delivery
class DeliveryNotification {
  final String id;
  final String userId; // customerId, courierId, sau restaurantId
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic>? data; // Additional data (orderId, etc.)
  final bool isRead;
  final DateTime createdAt;

  DeliveryNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    this.isRead = false,
    required this.createdAt,
  });

  factory DeliveryNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DeliveryNotification(
      id: doc.id,
      userId: data['userId'] as String,
      type: _notificationTypeFromString(data['type'] as String),
      title: data['title'] as String,
      body: data['body'] as String,
      data: data['data'] as Map<String, dynamic>?,
      isRead: data['isRead'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': _notificationTypeToString(type),
      'title': title,
      'body': body,
      'data': data,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  DeliveryNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return DeliveryNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static NotificationType _notificationTypeFromString(String value) {
    switch (value) {
      case 'orderCreated':
        return NotificationType.orderCreated;
      case 'orderAccepted':
        return NotificationType.orderAccepted;
      case 'orderReady':
        return NotificationType.orderReady;
      case 'orderPickedUp':
        return NotificationType.orderPickedUp;
      case 'orderOnTheWay':
        return NotificationType.orderOnTheWay;
      case 'orderDelivered':
        return NotificationType.orderDelivered;
      case 'orderCancelled':
        return NotificationType.orderCancelled;
      case 'courierAssigned':
        return NotificationType.courierAssigned;
      case 'courierArrived':
        return NotificationType.courierArrived;
      case 'paymentReceived':
        return NotificationType.paymentReceived;
      case 'promoCodeApplied':
        return NotificationType.promoCodeApplied;
      default:
        return NotificationType.orderCreated;
    }
  }

  static String _notificationTypeToString(NotificationType type) {
    switch (type) {
      case NotificationType.orderCreated:
        return 'orderCreated';
      case NotificationType.orderAccepted:
        return 'orderAccepted';
      case NotificationType.orderReady:
        return 'orderReady';
      case NotificationType.orderPickedUp:
        return 'orderPickedUp';
      case NotificationType.orderOnTheWay:
        return 'orderOnTheWay';
      case NotificationType.orderDelivered:
        return 'orderDelivered';
      case NotificationType.orderCancelled:
        return 'orderCancelled';
      case NotificationType.courierAssigned:
        return 'courierAssigned';
      case NotificationType.courierArrived:
        return 'courierArrived';
      case NotificationType.paymentReceived:
        return 'paymentReceived';
      case NotificationType.promoCodeApplied:
        return 'promoCodeApplied';
    }
  }
}

