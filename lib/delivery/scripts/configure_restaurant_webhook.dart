import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/restaurant_service.dart';

/// Script pentru configurarea webhookUrl pentru restaurante în Firestore
/// 
/// Utilizare:
/// 1. Rulează acest script pentru a configura webhookUrl pentru un restaurant
/// 2. Sau folosește RestaurantService.updateRestaurant() direct
void main() async {
  // Inițializează Firebase (dacă nu e deja inițializat)
  // Firebase.initializeApp();
  
  final restaurantService = RestaurantService();
  final firestore = FirebaseFirestore.instance;
  
  // EXEMPLU: Configurează webhookUrl pentru un restaurant
  // Înlocuiește 'restaurant_id_here' cu ID-ul real al restaurantului
  const restaurantId = 'restaurant_id_here';
  const webhookUrl = 'http://localhost:3001'; // Portul Restaurant App v3
  
  try {
    // Verifică dacă restaurantul există
    final restaurant = await restaurantService.getRestaurant(restaurantId);
    if (restaurant == null) {
      print('❌ Restaurant cu ID $restaurantId nu există!');
      return;
    }
    
    print('✅ Restaurant găsit: ${restaurant.name}');
    print('📍 Webhook URL actual: ${restaurant.webhookUrl ?? "N/A"}');
    
    // Actualizează webhookUrl
    await restaurantService.updateRestaurant(
      restaurantId: restaurantId,
      // webhookUrl nu este în updateRestaurant, trebuie să actualizăm direct în Firestore
    );
    
    // Actualizează direct în Firestore (pentru că updateRestaurant nu are webhookUrl)
    await firestore.collection('restaurants').doc(restaurantId).update({
      'webhookUrl': webhookUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    print('✅ Webhook URL configurat cu succes!');
    print('📍 Nou webhook URL: $webhookUrl');
    
    // Verifică actualizarea
    final updatedRestaurant = await restaurantService.getRestaurant(restaurantId);
    print('✅ Verificare: ${updatedRestaurant?.webhookUrl}');
    
  } catch (e) {
    print('❌ Eroare la configurarea webhookUrl: $e');
  }
}

/// Funcție helper pentru configurarea webhookUrl pentru un restaurant
Future<void> configureRestaurantWebhook({
  required String restaurantId,
  required String webhookUrl,
  String? restaurantAppV3TenantId,
}) async {
  try {
    final firestore = FirebaseFirestore.instance;
    
    // Verifică dacă restaurantul există
    final restaurantDoc = await firestore.collection('restaurants').doc(restaurantId).get();
    if (!restaurantDoc.exists) {
      throw Exception('Restaurant cu ID $restaurantId nu există!');
    }
    
    // Actualizează webhookUrl
    final updates = <String, dynamic>{
      'webhookUrl': webhookUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    
    if (restaurantAppV3TenantId != null) {
      updates['restaurantAppV3TenantId'] = restaurantAppV3TenantId;
    }
    
    await firestore.collection('restaurants').doc(restaurantId).update(updates);
    
    print('✅ Webhook URL configurat pentru restaurant $restaurantId');
    print('📍 Webhook URL: $webhookUrl');
    
  } catch (e) {
    print('❌ Eroare la configurarea webhookUrl: $e');
    rethrow;
  }
}

