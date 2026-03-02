/// Delivery Order Status Enum
/// 
/// Reprezintă toate stările posibile ale unei comenzi de delivery
enum DeliveryOrderStatus {
  pending,        // Comandă creată, așteaptă acceptare
  accepted,       // Restaurant a acceptat comanda
  preparing,      // Restaurant pregătește comanda
  ready,          // Comanda este gata pentru preluare
  pickedUp,       // Curier a preluat comanda
  onTheWay,       // Curier este în drum către client
  delivered,      // Comanda a fost livrată
  cancelled,      // Comanda a fost anulată
}

/// Extension for DeliveryOrderStatus to add utility methods
extension DeliveryOrderStatusExtension on DeliveryOrderStatus {
  /// Convert enum to string for Firestore
  String toFirestoreString() {
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

  /// Get display name in Romanian or English
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

  /// Convert string from Firestore to enum
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
}
