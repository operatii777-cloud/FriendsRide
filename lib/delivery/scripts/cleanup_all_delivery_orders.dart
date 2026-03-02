/// Script pentru ștergerea completă a tuturor comenzilor de delivery
/// 
/// Acest script șterge comenzile din:
/// 1. Firestore (delivery_orders collection)
/// 2. Restaurant App v3 SQLite (orders table, type='delivery')
/// 
/// ATENȚIE: Operație IREVERSIBILĂ!

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:friendsride_app/delivery/models/delivery_order_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CleanupAllDeliveryOrders {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Șterge toate comenzile de delivery din Firestore
  Future<void> deleteAllFromFirestore({
    String? restaurantId,
    bool onlyTestOrders = false,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      print('🔍 Căutare comenzi în Firestore...');

      Query query = _db.collection('delivery_orders');

      // Filtrează după restaurant (dacă e specificat)
      if (restaurantId != null) {
        query = query.where('restaurantId', isEqualTo: restaurantId);
      }

      // Pentru test orders, filtrează după restaurantId care conține "test"
      if (onlyTestOrders) {
        query = query.where('restaurantId', isEqualTo: restaurantId ?? 'restaurant_app_v3_test_id');
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        print('✅ Nu s-au găsit comenzi în Firestore.');
        return;
      }

      print('📋 Găsite ${snapshot.docs.length} comenzi în Firestore:');

      int deletedCount = 0;
      for (final doc in snapshot.docs) {
        final order = DeliveryOrder.fromFirestore(doc);
        print('   - Comanda ${order.id.substring(0, 8)}... - Status: ${order.status} - Total: ${order.total} RON');

        // Șterge comanda
        await doc.reference.delete();
        deletedCount++;
        print('   ✅ Comanda ${order.id.substring(0, 8)}... ștearsă din Firestore');
      }

      print('\n📊 Rezumat Firestore:');
      print('   ✅ Comenzi șterse: $deletedCount');
    } catch (e) {
      print('❌ Eroare la ștergerea din Firestore: $e');
      rethrow;
    }
  }

  /// Șterge toate comenzile de delivery din Restaurant App v3
  /// 
  /// ATENȚIE: Această metodă necesită un endpoint în Restaurant App v3
  /// sau acces direct la baza de date SQLite
  Future<void> deleteAllFromRestaurantAppV3({
    required String webhookUrl,
    String? restaurantId,
  }) async {
    try {
      print('🔍 Ștergere comenzi din Restaurant App v3...');
      print('   Webhook URL: $webhookUrl');

      // Normalizează URL-ul
      String normalizedUrl = webhookUrl;
      if (normalizedUrl.endsWith('/')) {
        normalizedUrl = normalizedUrl.substring(0, normalizedUrl.length - 1);
      }

      // Endpoint pentru ștergerea comenzilor de delivery
      // NOTĂ: Acest endpoint trebuie să existe în Restaurant App v3
      final deleteUrl = '$normalizedUrl/api/delivery/orders/cleanup';

      print('📡 Trimitere cerere către: $deleteUrl');

      final response = await http.post(
        Uri.parse(deleteUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'restaurantId': restaurantId,
          'deleteAll': true,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('✅ Comenzi șterse din Restaurant App v3: ${responseData['deletedCount'] ?? 'N/A'}');
      } else {
        print('⚠️ Eroare la ștergerea din Restaurant App v3: ${response.statusCode}');
        print('   Răspuns: ${response.body}');
        print('   NOTĂ: Endpoint-ul /api/delivery/orders/cleanup poate să nu existe în Restaurant App v3');
        print('   Folosește scriptul Node.js direct pentru ștergerea din SQLite');
      }
    } catch (e) {
      print('❌ Eroare la ștergerea din Restaurant App v3: $e');
      print('   NOTĂ: Folosește scriptul Node.js direct pentru ștergerea din SQLite');
    }
  }

  /// Șterge toate comenzile de delivery din toate locațiile
  Future<void> deleteAllFromAllLocations({
    String? restaurantId,
    String? webhookUrl,
    bool onlyTestOrders = false,
  }) async {
    try {
      print('🧹 CURĂȚARE COMPLETĂ - Ștergere comenzi de delivery\n');
      print('=' * 60);

      // 1. Șterge din Firestore
      print('\n1️⃣ Ștergere din Firestore...');
      await deleteAllFromFirestore(
        restaurantId: restaurantId,
        onlyTestOrders: onlyTestOrders,
      );

      // 2. Șterge din Restaurant App v3 (dacă webhookUrl este furnizat)
      if (webhookUrl != null && webhookUrl.isNotEmpty) {
        print('\n2️⃣ Ștergere din Restaurant App v3...');
        await deleteAllFromRestaurantAppV3(
          webhookUrl: webhookUrl,
          restaurantId: restaurantId,
        );
      } else {
        print('\n2️⃣ Skip ștergere din Restaurant App v3 (webhookUrl nu este furnizat)');
        print('   Folosește scriptul Node.js direct pentru ștergerea din SQLite');
      }

      print('\n${'=' * 60}');
      print('✅ CURĂȚARE COMPLETĂ FINALIZATĂ!');
    } catch (e) {
      print('❌ Eroare la curățarea completă: $e');
      rethrow;
    }
  }
}

