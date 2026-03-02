import 'package:cloud_firestore/cloud_firestore.dart';

/// Product Modification Model
/// 
/// Reprezintă o opțiune de modificare disponibilă pentru un produs
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

/// Product Model
/// 
/// Reprezintă un produs din meniul unui restaurant
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

  Product copyWith({
    String? id,
    String? restaurantId,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? category,
    bool? isAvailable,
    List<String>? allergens,
    Map<String, dynamic>? nutritionalInfo,
    List<ProductModification>? availableModifications,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
      allergens: allergens ?? this.allergens,
      nutritionalInfo: nutritionalInfo ?? this.nutritionalInfo,
      availableModifications: availableModifications ?? this.availableModifications,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

