import 'package:cloud_firestore/cloud_firestore.dart';

class SavedAddress {
  final String id;
  final String label; // ex: "Acasă", "Serviciu"
  final String address; // Adresa completă, ca text
  final GeoPoint coordinates; // Coordonatele geografice

  SavedAddress({
    required this.id,
    required this.label,
    required this.address,
    required this.coordinates,
  });

  // Convertim un obiect în formatul necesar pentru Firestore
  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'address': address,
      'coordinates': coordinates,
    };
  }

  // Creăm un obiect din datele primite de la Firestore
  factory SavedAddress.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return SavedAddress(
      id: doc.id,
      label: data['label'] ?? '',
      address: data['address'] ?? '',
      coordinates: data['coordinates'] ?? const GeoPoint(0, 0),
    );
  }
}
