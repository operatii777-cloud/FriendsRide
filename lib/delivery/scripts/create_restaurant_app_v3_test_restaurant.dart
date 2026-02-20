import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:friendsride_app/firebase_options.dart';
import 'package:friendsride_app/delivery/services/restaurant_onboarding_service.dart';
import 'package:friendsride_app/delivery/services/restaurant_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Script pentru crearea unui restaurant de test conectat la Restaurant App v3
/// cu sincronizarea meniurilor existente
/// 
/// Rulare: dart run lib/delivery/scripts/create_restaurant_app_v3_test_restaurant.dart
Future<void> main() async {
  try {
    // Initializează Firebase
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    print('✅ Firebase inițializat');

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ Trebuie să fii autentificat în Firebase!');
      print('💡 Autentifică-te în FriendsRide App mai întâi.');
      return;
    }

    print('✅ Utilizator autentificat: ${user.email}');
    print('📋 UID: ${user.uid}\n');

    final onboardingService = RestaurantOnboardingService();
    final restaurantService = RestaurantService();

    // Restaurant App v3 Test Restaurant
    print('📝 Creare restaurant: Restaurant App v3 Test...');
    final restaurantId = await onboardingService.createManualOnboardingRequest(
      restaurantName: 'Restaurant App v3 Test',
      description: 'Restaurant de test conectat la Restaurant App v3 cu meniurile existente',
      address: 'Strada Test 123, București',
      latitude: 44.4268,
      longitude: 26.1025,
      phoneNumber: '+40712345678',
      email: 'test@restaurantappv3.ro',
      ownerId: user.uid,
      commissionRate: 12.0,
      cuisineTypes: ['Romanian', 'Traditional'],
      deliveryFee: 7.0,
      minimumOrder: 30.0,
      estimatedDeliveryTime: 35,
      workingHours: {
        'monday': {'openTime': '10:00', 'closeTime': '22:00', 'isOpen': true},
        'tuesday': {'openTime': '10:00', 'closeTime': '22:00', 'isOpen': true},
        'wednesday': {'openTime': '10:00', 'closeTime': '22:00', 'isOpen': true},
        'thursday': {'openTime': '10:00', 'closeTime': '22:00', 'isOpen': true},
        'friday': {'openTime': '10:00', 'closeTime': '23:00', 'isOpen': true},
        'saturday': {'openTime': '10:00', 'closeTime': '23:00', 'isOpen': true},
        'sunday': {'openTime': '12:00', 'closeTime': '22:00', 'isOpen': true},
      },
    );
    print('✅ Restaurant creat cu ID: $restaurantId\n');

    // Configurează webhookUrl pentru Restaurant App v3
    print('🔧 Configurare webhookUrl pentru Restaurant App v3...');
    await restaurantService.updateRestaurant(
      restaurantId: restaurantId,
      webhookUrl: 'http://localhost:3001',
      restaurantAppV3TenantId: 'test_tenant_1',
    );
    print('✅ WebhookUrl configurat: http://localhost:3001\n');

    // Sincronizează meniurile din Restaurant App v3
    print('📦 Sincronizare meniuri din Restaurant App v3...');
    await _syncMenuFromRestaurantAppV3(restaurantId, user.uid);
    
    print('\n✅ Restaurant App v3 Test creat cu succes!');
    print('\n📋 Rezumat:');
    print('  - Restaurant ID: $restaurantId');
    print('  - Webhook URL: http://localhost:3001');
    print('  - Tenant ID: test_tenant_1');
    print('\n💡 Acum poți:');
    print('  1. Deschide FriendsRide și vei vedea restaurantul în Delivery');
    print('  2. Vei vedea meniurile sincronizate din Restaurant App v3');
    print('  3. Poți plasa comenzi de test pentru delivery');
    print('  4. Comenzile vor ajunge automat în Restaurant App v3 (port 3001)');
  } catch (e, stackTrace) {
    print('❌ Eroare: $e');
    print('Stack trace: $stackTrace');
  }
}

/// Sincronizează meniurile din Restaurant App v3 către FriendsRide
Future<void> _syncMenuFromRestaurantAppV3(String restaurantId, String ownerId) async {
  try {
    // Obține meniul din Restaurant App v3
    final menuUrl = Uri.parse('http://localhost:3001/api/menu/all?lang=ro');
    print('  📡 Request către: $menuUrl');
    
    final response = await http.get(menuUrl).timeout(const Duration(seconds: 10));
    
    if (response.statusCode != 200) {
      print('  ⚠️ Nu s-au putut obține meniurile din Restaurant App v3');
      print('  📋 Status: ${response.statusCode}');
      print('  📋 Răspuns: ${response.body}');
      print('  💡 Asigură-te că Restaurant App v3 rulează pe portul 3001');
      print('  💡 Rulează: cd C:\\restaurant_app\\restaurant_app_v3_translation_system\\server && node server.js');
      return;
    }

    final menuData = jsonDecode(response.body);
    // Restaurant App v3 returnează un array direct sau un obiect cu 'menu'
    final products = menuData is List 
        ? menuData 
        : (menuData['menu'] as List<dynamic>? ?? []);
    
    if (products.isEmpty) {
      print('  ⚠️ Nu există produse în Restaurant App v3');
      print('  💡 Adaugă produse în Restaurant App v3 mai întâi');
      print('  💡 Accesează: http://localhost:3001/admin.html și adaugă produse');
      return;
    }

    print('  ✅ Găsite ${products.length} produse în Restaurant App v3');
    print('  📦 Sincronizare produse în Firestore...');

    final firestore = FirebaseFirestore.instance;
    int syncedCount = 0;
    int errorCount = 0;

    for (final productData in products) {
      try {
        // Restaurant App v3 folosește 'id' sau 'product_id'
        final productId = (productData['id'] ?? productData['product_id'] ?? '').toString();
        final firestoreProductId = productId.isNotEmpty 
            ? productId 
            : firestore.collection('products').doc().id;
        
        // Mapare câmpuri din Restaurant App v3 la Firestore
        final product = {
          'restaurantId': restaurantId,
          'name': productData['name'] ?? productData['name_ro'] ?? 'Produs fără nume',
          'description': productData['description'] ?? productData['description_ro'] ?? '',
          'price': ((productData['price'] ?? productData['sell_price'] ?? 0.0) as num).toDouble(),
          'category': productData['category'] ?? productData['category_ro'] ?? 'Other',
          'imageUrl': productData['image_url'] ?? productData['imageUrl'],
          'isAvailable': (productData['is_sellable'] ?? productData['isAvailable'] ?? 1) == 1,
          'allergens': _parseAllergens(productData['allergens']),
          'availableModifications': _parseModifications(productData['modifications'] ?? []),
          'nutritionalInfo': productData['nutritional_info'] ?? productData['nutritionalInfo'],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await firestore.collection('products').doc(firestoreProductId).set(product);
        syncedCount++;
        print('    ✅ ${product['name']} - ${product['price']} RON');
      } catch (e) {
        errorCount++;
        print('    ❌ Eroare la sincronizarea produsului: $e');
      }
    }

    print('\n  📊 Rezumat sincronizare:');
    print('    ✅ Sincronizate: $syncedCount');
    if (errorCount > 0) {
      print('    ❌ Erori: $errorCount');
    }
  } on http.ClientException catch (e) {
    print('  ❌ Eroare de conexiune la Restaurant App v3: $e');
    print('  💡 Asigură-te că Restaurant App v3 rulează pe portul 3001');
    print('  💡 Rulează: cd C:\\restaurant_app\\restaurant_app_v3_translation_system\\server && node server.js');
  } catch (e) {
    print('  ❌ Eroare la sincronizarea meniului: $e');
  }
}

/// Parse allergens din format Restaurant App v3
List<String> _parseAllergens(dynamic allergens) {
  if (allergens == null) return [];
  if (allergens is String) {
    // Dacă e string, încearcă să-l parseze ca JSON sau să-l împartă prin virgulă
    try {
      final parsed = jsonDecode(allergens);
      if (parsed is List) return parsed.cast<String>();
    } catch (_) {
      // Dacă nu e JSON valid, împarte prin virgulă
      return allergens.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
  }
  if (allergens is List) return allergens.cast<String>();
  return [];
}

/// Parse modifications din format Restaurant App v3
List<Map<String, dynamic>> _parseModifications(dynamic modifications) {
  if (modifications == null || modifications is! List) return [];
  return modifications.map((mod) {
    if (mod is Map) {
      return {
        'id': mod['id'] ?? '',
        'name': mod['name'] ?? mod['name_ro'] ?? '',
        'price': ((mod['price'] ?? 0.0) as num).toDouble(),
      };
    }
    return {'id': '', 'name': '', 'price': 0.0};
  }).toList();
}

