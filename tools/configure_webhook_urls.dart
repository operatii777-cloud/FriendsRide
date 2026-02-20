import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:friendsride_app/delivery/services/restaurant_service.dart';

/// Script standalone pentru configurarea webhookUrl în Firestore
/// 
/// Rulează cu: dart run tools/configure_webhook_urls.dart
/// 
/// SAU integrează în aplicație și apelează configureAllRestaurantsWebhook()
void main() async {
  print('🚀 Configurare Webhook URL pentru restaurante\n');
  
  // Inițializează Firebase
  // Notă: Trebuie să ai firebase_options.dart configurat
  try {
    await Firebase.initializeApp();
    print('✅ Firebase inițializat\n');
  } catch (e) {
    print('❌ Eroare la inițializarea Firebase: $e');
    print('💡 Asigură-te că ai configurat firebase_options.dart');
    exit(1);
  }
  
  // Configurează pentru toate restaurantele
  await configureAllRestaurantsWebhook();
  
  print('\n✅ Configurare completă!');
  exit(0);
}

/// Configurează webhookUrl pentru toate restaurantele din Firestore
Future<void> configureAllRestaurantsWebhook({
  String webhookUrl = 'http://localhost:3001',
}) async {
  try {
    final firestore = FirebaseFirestore.instance;
    final restaurantService = RestaurantService();
    
    print('🔍 Căutare restaurante în Firestore...\n');
    
    // Obține toate restaurantele
    final restaurantsSnapshot = await firestore.collection('restaurants').get();
    
    if (restaurantsSnapshot.docs.isEmpty) {
      print('⚠️ Nu există restaurante în Firestore!');
      print('💡 Creează mai întâi un restaurant prin onboarding.\n');
      return;
    }
    
    print('📋 Găsite ${restaurantsSnapshot.docs.length} restaurante\n');
    print('🔧 Configurare webhookUrl: $webhookUrl\n');
    print('─' * 50);
    print('');
    
    int configured = 0;
    int skipped = 0;
    int errors = 0;
    
    for (final doc in restaurantsSnapshot.docs) {
      final restaurantId = doc.id;
      final data = doc.data();
      final restaurantName = data['name'] ?? 'N/A';
      final currentWebhookUrl = data['webhookUrl'] as String?;
      
      // Dacă deja are webhookUrl configurat, skip (sau actualizează dacă vrei)
      if (currentWebhookUrl != null && currentWebhookUrl.isNotEmpty && currentWebhookUrl == webhookUrl) {
        print('⏭️  Restaurant: $restaurantName');
        print('   ID: $restaurantId');
        print('   Webhook URL: $currentWebhookUrl (deja configurat)');
        print('   Status: Skip\n');
        skipped++;
        continue;
      }
      
      // Configurează webhookUrl
      try {
        await restaurantService.updateRestaurant(
          restaurantId: restaurantId,
          webhookUrl: webhookUrl,
        );
        
        print('✅ Restaurant: $restaurantName');
        print('   ID: $restaurantId');
        if (currentWebhookUrl != null) {
          print('   Webhook URL vechi: $currentWebhookUrl');
        }
        print('   Webhook URL nou: $webhookUrl');
        print('   Status: Configurat cu succes\n');
        configured++;
      } catch (e) {
        print('❌ Restaurant: $restaurantName');
        print('   ID: $restaurantId');
        print('   Eroare: $e\n');
        errors++;
      }
    }
    
    print('─' * 50);
    print('📊 REZUMAT:');
    print('   ✅ Configurate: $configured');
    print('   ⏭️  Skip: $skipped');
    print('   ❌ Erori: $errors');
    print('   📋 Total: ${restaurantsSnapshot.docs.length}');
    print('─' * 50);
    
  } catch (e) {
    print('❌ Eroare la configurarea webhookUrl: $e');
    rethrow;
  }
}

