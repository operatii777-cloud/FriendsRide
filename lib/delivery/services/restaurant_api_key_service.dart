import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

/// Service pentru gestionarea API keys pentru restaurante
class RestaurantApiKeyService {
  static final RestaurantApiKeyService _instance =
      RestaurantApiKeyService._internal();
  factory RestaurantApiKeyService() => _instance;
  RestaurantApiKeyService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Generează un API key nou pentru un restaurant
  Future<String> generateApiKey({
    required String restaurantId,
    required String ownerId,
  }) async {
    try {
      // Generează un API key unic
      final apiKey = _generateUniqueApiKey();
      final hashedKey = _hashApiKey(apiKey);

      // Salvează API key-ul (hashed) în Firestore
      await _db.collection('restaurant_api_keys').doc(restaurantId).set({
        'restaurantId': restaurantId,
        'ownerId': ownerId,
        'hashedKey': hashedKey,
        'createdAt': Timestamp.now(),
        'lastUsedAt': null,
        'isActive': true,
        'rateLimit': {
          'requestsPerMinute': 100,
          'requestsPerHour': 1000,
          'requestsPerDay': 10000,
        },
      });

      // Returnează API key-ul plain (doar o dată, apoi nu mai e accesibil)
      return apiKey;
    } catch (e) {
      throw Exception('Failed to generate API key: $e');
    }
  }

  /// Validează un API key
  Future<bool> validateApiKey({
    required String apiKey,
    required String restaurantId,
  }) async {
    try {
      final hashedKey = _hashApiKey(apiKey);
      final keyDoc = await _db
          .collection('restaurant_api_keys')
          .doc(restaurantId)
          .get();

      if (!keyDoc.exists) {
        return false;
      }

      final keyData = keyDoc.data()!;
      final storedHash = keyData['hashedKey'] as String;
      final isActive = keyData['isActive'] as bool? ?? false;

      if (!isActive) {
        return false;
      }

      // Verifică hash-ul
      if (storedHash != hashedKey) {
        return false;
      }

      // Actualizează lastUsedAt
      await _db.collection('restaurant_api_keys').doc(restaurantId).update({
        'lastUsedAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Obține informații despre API key pentru un restaurant
  Future<Map<String, dynamic>?> getApiKeyInfo(String restaurantId) async {
    try {
      final keyDoc = await _db
          .collection('restaurant_api_keys')
          .doc(restaurantId)
          .get();

      if (!keyDoc.exists) {
        return null;
      }

      final data = keyDoc.data()!;
      return {
        'restaurantId': data['restaurantId'],
        'createdAt': data['createdAt'],
        'lastUsedAt': data['lastUsedAt'],
        'isActive': data['isActive'] ?? false,
        'rateLimit': data['rateLimit'],
      };
    } catch (e) {
      return null;
    }
  }

  /// Revocă (dezactivează) un API key
  Future<void> revokeApiKey(String restaurantId) async {
    try {
      await _db.collection('restaurant_api_keys').doc(restaurantId).update({
        'isActive': false,
        'revokedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to revoke API key: $e');
    }
  }

  /// Reactivează un API key
  Future<void> reactivateApiKey(String restaurantId) async {
    try {
      await _db.collection('restaurant_api_keys').doc(restaurantId).update({
        'isActive': true,
        'reactivatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to reactivate API key: $e');
    }
  }

  /// Regenerare API key (revocă vechiul și generează unul nou)
  Future<String> regenerateApiKey({
    required String restaurantId,
    required String ownerId,
  }) async {
    try {
      // Revocă vechiul
      await revokeApiKey(restaurantId);

      // Generează unul nou
      return await generateApiKey(
        restaurantId: restaurantId,
        ownerId: ownerId,
      );
    } catch (e) {
      throw Exception('Failed to regenerate API key: $e');
    }
  }

  /// Generează un API key unic
  String _generateUniqueApiKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    final base64Key = base64Encode(bytes);
    return 'fr_${base64Key.replaceAll(RegExp(r'[+/=]'), '').substring(0, 40)}';
  }

  /// Obține restaurantId din API key (caută în toate restaurantele)
  Future<String?> getRestaurantIdFromApiKey(String apiKey) async {
    try {
      final hashedKey = _hashApiKey(apiKey);
      
      // Caută în toate documentele din restaurant_api_keys
      final keysSnapshot = await _db.collection('restaurant_api_keys').get();
      
      for (final doc in keysSnapshot.docs) {
        final data = doc.data();
        final storedHash = data['hashedKey'] as String?;
        final isActive = data['isActive'] as bool? ?? false;
        
        if (isActive && storedHash == hashedKey) {
          return data['restaurantId'] as String?;
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Obține lista de restaurante pentru un API key (pentru compatibilitate)
  Future<List<Map<String, dynamic>>> getRestaurantsByApiKey(String apiKey) async {
    final restaurantId = await getRestaurantIdFromApiKey(apiKey);
    if (restaurantId == null) {
      return [];
    }
    
    // Obține informațiile despre restaurant
    final restaurantDoc = await _db.collection('restaurants').doc(restaurantId).get();
    if (!restaurantDoc.exists) {
      return [];
    }
    
    final data = restaurantDoc.data()!;
    return [{
      'id': restaurantId,
      ...data,
    }];
  }

  /// Hash-uiește un API key pentru stocare securizată
  String _hashApiKey(String apiKey) {
    final bytes = utf8.encode(apiKey);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

