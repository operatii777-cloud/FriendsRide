/// Order Item Model
/// 
/// Reprezintă un produs din comandă cu modificări și note speciale
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

  /// Create OrderItem from Firestore map
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

  /// Convert OrderItem to Firestore map
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

  /// Create a copy with updated fields
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

