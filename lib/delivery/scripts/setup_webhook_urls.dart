import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/restaurant_service.dart';

/// Script pentru configurarea webhookUrl pentru toate restaurantele din Firestore
/// 
/// Rulează acest script pentru a configura webhookUrl pentru toate restaurantele
/// 
/// Utilizare:
/// 1. Asigură-te că Firebase este inițializat în aplicație
/// 2. Apelează configureAllRestaurantsWebhook() sau configureRestaurantWebhookById()
void main() async {
  // Inițializează Firebase (dacă nu e deja inițializat)
  // await Firebase.initializeApp();
  
  print('🚀 Încep configurarea webhookUrl pentru restaurante...\n');
  
  // Configurează pentru toate restaurantele
  await configureAllRestaurantsWebhook();
  
  // SAU configurează pentru un restaurant specific:
  // await configureRestaurantWebhookById('restaurant_id_here');
  
  print('\n✅ Configurare completă!');
}

/// Configurează webhookUrl pentru toate restaurantele din Firestore
Future<void> configureAllRestaurantsWebhook({
  String webhookUrl = 'http://localhost:3001',
}) async {
  try {
    final firestore = FirebaseFirestore.instance;
    final restaurantService = RestaurantService();
    
    // Obține toate restaurantele
    final restaurantsSnapshot = await firestore.collection('restaurants').get();
    
    if (restaurantsSnapshot.docs.isEmpty) {
      print('⚠️ Nu există restaurante în Firestore!');
      print('💡 Creează mai întâi un restaurant prin onboarding.');
      return;
    }
    
    print('📋 Găsite ${restaurantsSnapshot.docs.length} restaurante\n');
    
    int configured = 0;
    int skipped = 0;
    
    for (final doc in restaurantsSnapshot.docs) {
      final restaurantId = doc.id;
      final data = doc.data();
      final restaurantName = data['name'] ?? 'N/A';
      final currentWebhookUrl = data['webhookUrl'] as String?;
      
      // Dacă deja are webhookUrl configurat, opțional să-l skip sau să-l actualizezi
      if (currentWebhookUrl != null && currentWebhookUrl.isNotEmpty) {
        print('⏭️  Restaurant: $restaurantName (ID: $restaurantId)');
        print('   Webhook URL existent: $currentWebhookUrl');
        print('   ⚠️  Skip (deja configurat)\n');
        skipped++;
        continue;
      }
      
      // Configurează webhookUrl
      try {
        await restaurantService.updateRestaurant(
          restaurantId: restaurantId,
          webhookUrl: webhookUrl,
        );
        
        print('✅ Restaurant: $restaurantName (ID: $restaurantId)');
        print('   Webhook URL configurat: $webhookUrl\n');
        configured++;
      } catch (e) {
        print('❌ Eroare la restaurant $restaurantName (ID: $restaurantId): $e\n');
      }
    }
    
    print('📊 Rezumat:');
    print('   ✅ Configurate: $configured');
    print('   ⏭️  Skip: $skipped');
    print('   📋 Total: ${restaurantsSnapshot.docs.length}');
    
  } catch (e) {
    print('❌ Eroare la configurarea webhookUrl: $e');
    rethrow;
  }
}

/// Configurează webhookUrl pentru un restaurant specific
Future<void> configureRestaurantWebhookById({
  required String restaurantId,
  String webhookUrl = 'http://localhost:3001',
  String? restaurantAppV3TenantId,
}) async {
  try {
    final restaurantService = RestaurantService();
    
    // Verifică dacă restaurantul există
    final restaurant = await restaurantService.getRestaurant(restaurantId);
    if (restaurant == null) {
      print('❌ Restaurant cu ID $restaurantId nu există!');
      return;
    }
    
    print('📋 Restaurant găsit: ${restaurant.name}');
    print('📍 Webhook URL actual: ${restaurant.webhookUrl ?? "N/A"}');
    
    // Actualizează webhookUrl
    await restaurantService.updateRestaurant(
      restaurantId: restaurantId,
      webhookUrl: webhookUrl,
      restaurantAppV3TenantId: restaurantAppV3TenantId,
    );
    
    print('✅ Webhook URL configurat cu succes!');
    print('📍 Nou webhook URL: $webhookUrl');
    
    // Verifică actualizarea
    final updatedRestaurant = await restaurantService.getRestaurant(restaurantId);
    print('✅ Verificare: ${updatedRestaurant?.webhookUrl}');
    
  } catch (e) {
    print('❌ Eroare la configurarea webhookUrl: $e');
    rethrow;
  }
}

/// Configurează webhookUrl pentru toate restaurantele (forțează actualizarea)
Future<void> forceUpdateAllRestaurantsWebhook({
  String webhookUrl = 'http://localhost:3001',
}) async {
  try {
    final firestore = FirebaseFirestore.instance;
    final restaurantService = RestaurantService();
    
    // Obține toate restaurantele
    final restaurantsSnapshot = await firestore.collection('restaurants').get();
    
    if (restaurantsSnapshot.docs.isEmpty) {
      print('⚠️ Nu există restaurante în Firestore!');
      return;
    }
    
    print('📋 Găsite ${restaurantsSnapshot.docs.length} restaurante\n');
    print('⚠️  FORȚARE actualizare pentru toate restaurantele...\n');
    
    int updated = 0;
    
    for (final doc in restaurantsSnapshot.docs) {
      final restaurantId = doc.id;
      final data = doc.data();
      final restaurantName = data['name'] ?? 'N/A';
      
      try {
        await restaurantService.updateRestaurant(
          restaurantId: restaurantId,
          webhookUrl: webhookUrl,
        );
        
        print('✅ Restaurant: $restaurantName (ID: $restaurantId)');
        print('   Webhook URL actualizat: $webhookUrl\n');
        updated++;
      } catch (e) {
        print('❌ Eroare la restaurant $restaurantName (ID: $restaurantId): $e\n');
      }
    }
    
    print('📊 Rezumat:');
    print('   ✅ Actualizate: $updated');
    print('   📋 Total: ${restaurantsSnapshot.docs.length}');
    
  } catch (e) {
    print('❌ Eroare la configurarea webhookUrl: $e');
    rethrow;
  }
}

