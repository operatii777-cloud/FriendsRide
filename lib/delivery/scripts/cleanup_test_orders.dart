/// Script pentru curățarea comenzilor de test din Firestore
/// 
/// Acest script:
/// 1. Găsește toate comenzile de test (pending/ready fără curier)
/// 2. Le marchează ca "cancelled" sau le șterge
/// 3. Opțional: șterge comenzile vechi (> 24 ore)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:friendsride_app/delivery/models/delivery_order_model.dart';
import 'package:friendsride_app/delivery/models/delivery_status.dart';

class CleanupTestOrders {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Găsește și marchează toate comenzile de test ca "cancelled"
  Future<void> cancelAllTestOrders({
    bool onlyPending = true,
    bool onlyReady = false,
    bool olderThan24Hours = false,
    String? restaurantId,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      print('🔍 Căutare comenzi de test...');

      // Construiește query-ul
      Query query = _db.collection('delivery_orders');

      // Filtrează după status
      if (onlyPending) {
        query = query.where('status', isEqualTo: 'pending');
      } else if (onlyReady) {
        query = query.where('status', isEqualTo: 'ready');
      }

      // Filtrează după restaurant (dacă e specificat)
      if (restaurantId != null) {
        query = query.where('restaurantId', isEqualTo: restaurantId);
      }

      // Filtrează comenzile fără curier (probabil de test)
      query = query.where('courierId', isNull: true);

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        print('✅ Nu s-au găsit comenzi de test.');
        return;
      }

      print('📋 Găsite ${snapshot.docs.length} comenzi de test:');

      int cancelledCount = 0;
      int skippedCount = 0;

      for (final doc in snapshot.docs) {
        final order = DeliveryOrder.fromFirestore(doc);
        final orderAge = DateTime.now().difference(order.createdAt);

        // Verifică dacă comanda e mai veche de 24 ore (dacă e cazul)
        if (olderThan24Hours && orderAge.inHours < 24) {
          print('⏭️  Comanda ${order.id.substring(0, 8)}... - mai nouă de 24h, skip');
          skippedCount++;
          continue;
        }

        print('   - Comanda ${order.id.substring(0, 8)}... - Status: ${order.status} - Vârstă: ${orderAge.inHours}h');

        // Marchează comanda ca "cancelled"
        await doc.reference.update({
          'status': DeliveryOrderStatus.cancelled.toFirestoreString(),
          'updatedAt': FieldValue.serverTimestamp(),
          'metadata': {
            ...?order.metadata,
            'cancellationReason': 'Test order cleanup',
            'cancelledAt': FieldValue.serverTimestamp(),
            'cancelledBy': 'system',
          },
        });

        cancelledCount++;
        print('   ✅ Comanda ${order.id.substring(0, 8)}... marcată ca "cancelled"');
      }

      print('\n📊 Rezumat:');
      print('   ✅ Comenzi anulate: $cancelledCount');
      print('   ⏭️  Comenzi skip-uite: $skippedCount');
      print('   📋 Total procesate: ${snapshot.docs.length}');
    } catch (e) {
      print('❌ Eroare la curățarea comenzilor de test: $e');
      rethrow;
    }
  }

  /// Șterge complet TOATE comenzile de delivery (ATENȚIE: operație ireversibilă!)
  Future<void> deleteAllDeliveryOrders({
    bool onlyCancelled = false,
    bool olderThan24Hours = false,
    String? restaurantId,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      print('⚠️  ATENȚIE: Vei șterge PERMANENT comenzile de delivery!');
      print('🔍 Căutare comenzi de șters...');

      // Construiește query-ul
      Query query = _db.collection('delivery_orders');

      // Filtrează după status (dacă e specificat)
      if (onlyCancelled) {
        query = query.where('status', isEqualTo: 'cancelled');
      }

      // Filtrează după restaurant (dacă e specificat)
      if (restaurantId != null) {
        query = query.where('restaurantId', isEqualTo: restaurantId);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        print('✅ Nu s-au găsit comenzi de șters.');
        return;
      }

      print('📋 Găsite ${snapshot.docs.length} comenzi de șters:');

      int deletedCount = 0;
      int skippedCount = 0;

      for (final doc in snapshot.docs) {
        final order = DeliveryOrder.fromFirestore(doc);
        final orderAge = DateTime.now().difference(order.createdAt);

        // Verifică dacă comanda e mai veche de 24 ore (dacă e cazul)
        if (olderThan24Hours && orderAge.inHours < 24) {
          print('⏭️  Comanda ${order.id.substring(0, 8)}... - mai nouă de 24h, skip');
          skippedCount++;
          continue;
        }

        print('   - Comanda ${order.id.substring(0, 8)}... - Status: ${order.status} - Vârstă: ${orderAge.inHours}h');

        // Șterge comanda
        await doc.reference.delete();

        deletedCount++;
        print('   ✅ Comanda ${order.id.substring(0, 8)}... ștearsă');
      }

      print('\n📊 Rezumat:');
      print('   ✅ Comenzi șterse: $deletedCount');
      print('   ⏭️  Comenzi skip-uite: $skippedCount');
      print('   📋 Total procesate: ${snapshot.docs.length}');
    } catch (e) {
      print('❌ Eroare la ștergerea comenzilor de test: $e');
      rethrow;
    }
  }

  /// Listează toate comenzile de test (fără să le modifice)
  Future<void> listTestOrders({
    String? restaurantId,
    bool includeCancelled = true,
  }) async {
    try {
      print('🔍 Căutare comenzi de test...');

      Query query = _db.collection('delivery_orders');

      // Filtrează după restaurant (dacă e specificat)
      if (restaurantId != null) {
        query = query.where('restaurantId', isEqualTo: restaurantId);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        print('✅ Nu s-au găsit comenzi.');
        return;
      }

      print('📋 Găsite ${snapshot.docs.length} comenzi:\n');

      for (final doc in snapshot.docs) {
        final order = DeliveryOrder.fromFirestore(doc);
        final orderAge = DateTime.now().difference(order.createdAt);

        // Skip cancelled dacă nu sunt incluse
        if (!includeCancelled && order.status == DeliveryOrderStatus.cancelled) {
          continue;
        }

        print('   Comanda: ${order.id.substring(0, 8)}...');
        print('   Status: ${order.status}');
        print('   Restaurant: ${order.restaurantId}');
        print('   Vârstă: ${orderAge.inHours}h ${orderAge.inMinutes % 60}m');
        print('   Curier: ${order.courierId ?? "N/A"}');
        print('   Total: ${order.total} RON');
        print('   ---');
      }
    } catch (e) {
      print('❌ Eroare la listarea comenzilor: $e');
      rethrow;
    }
  }
}

