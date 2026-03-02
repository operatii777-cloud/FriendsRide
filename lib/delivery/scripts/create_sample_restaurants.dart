import 'package:firebase_core/firebase_core.dart';
import 'package:friendsride_app/firebase_options.dart';
import 'package:friendsride_app/delivery/services/restaurant_onboarding_service.dart';

/// Script pentru crearea de restaurante de test în Firestore
/// 
/// Rulare: dart run lib/delivery/scripts/create_sample_restaurants.dart
Future<void> main() async {
  try {
    // Initializează Firebase
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    print('✅ Firebase inițializat');

    final onboardingService = RestaurantOnboardingService();

    // Restaurant 1: Pizza Place
    print('\n📝 Creare restaurant: Pizza Place...');
    final pizzaId = await onboardingService.createManualOnboardingRequest(
      restaurantName: 'Pizza Place',
      description: 'Pizza autentică italiană, preparată cu ingrediente proaspete',
      address: 'Strada Victoriei 10, București',
      latitude: 44.4268,
      longitude: 26.1025,
      phoneNumber: '+40712345678',
      email: 'contact@pizzaplace.ro',
      ownerId: 'test_owner_1', // ID-ul utilizatorului care deține restaurantul
      commissionRate: 12.0,
      cuisineTypes: ['Pizza', 'Italian'],
      deliveryFee: 8.0,
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
    print('✅ Pizza Place creat cu ID: $pizzaId');

    // Restaurant 2: Burger House
    print('\n📝 Creare restaurant: Burger House...');
    final burgerId = await onboardingService.createManualOnboardingRequest(
      restaurantName: 'Burger House',
      description: 'Burgeri artizanali cu carne de calitate premium',
      address: 'Bulevardul Unirii 25, București',
      latitude: 44.4300,
      longitude: 26.1000,
      phoneNumber: '+40712345679',
      email: 'contact@burgerhouse.ro',
      ownerId: 'test_owner_2',
      commissionRate: 10.0,
      cuisineTypes: ['Burgers', 'Fast Food'],
      deliveryFee: 6.0,
      minimumOrder: 25.0,
      estimatedDeliveryTime: 30,
      workingHours: {
        'monday': {'openTime': '11:00', 'closeTime': '23:00', 'isOpen': true},
        'tuesday': {'openTime': '11:00', 'closeTime': '23:00', 'isOpen': true},
        'wednesday': {'openTime': '11:00', 'closeTime': '23:00', 'isOpen': true},
        'thursday': {'openTime': '11:00', 'closeTime': '23:00', 'isOpen': true},
        'friday': {'openTime': '11:00', 'closeTime': '00:00', 'isOpen': true},
        'saturday': {'openTime': '11:00', 'closeTime': '00:00', 'isOpen': true},
        'sunday': {'openTime': '12:00', 'closeTime': '22:00', 'isOpen': true},
      },
    );
    print('✅ Burger House creat cu ID: $burgerId');

    // Restaurant 3: Sushi Master
    print('\n📝 Creare restaurant: Sushi Master...');
    final sushiId = await onboardingService.createManualOnboardingRequest(
      restaurantName: 'Sushi Master',
      description: 'Sushi și sashimi proaspete, preparate de șefi japonezi',
      address: 'Calea Dorobanților 50, București',
      latitude: 44.4500,
      longitude: 26.0900,
      phoneNumber: '+40712345680',
      email: 'contact@sushimaster.ro',
      ownerId: 'test_owner_3',
      commissionRate: 14.0,
      cuisineTypes: ['Sushi', 'Japanese'],
      deliveryFee: 10.0,
      minimumOrder: 50.0,
      estimatedDeliveryTime: 40,
      workingHours: {
        'monday': {'openTime': '12:00', 'closeTime': '22:00', 'isOpen': true},
        'tuesday': {'openTime': '12:00', 'closeTime': '22:00', 'isOpen': true},
        'wednesday': {'openTime': '12:00', 'closeTime': '22:00', 'isOpen': true},
        'thursday': {'openTime': '12:00', 'closeTime': '22:00', 'isOpen': true},
        'friday': {'openTime': '12:00', 'closeTime': '23:00', 'isOpen': true},
        'saturday': {'openTime': '12:00', 'closeTime': '23:00', 'isOpen': true},
        'sunday': {'openTime': '12:00', 'closeTime': '21:00', 'isOpen': true},
      },
    );
    print('✅ Sushi Master creat cu ID: $sushiId');

    // Restaurant 4: La Mama (Romanian)
    print('\n📝 Creare restaurant: La Mama...');
    final mamaId = await onboardingService.createManualOnboardingRequest(
      restaurantName: 'La Mama',
      description: 'Mâncare tradițională românească, preparată cu dragoste',
      address: 'Strada Lipscani 15, București',
      latitude: 44.4300,
      longitude: 26.1000,
      phoneNumber: '+40712345681',
      email: 'contact@lamama.ro',
      ownerId: 'test_owner_4',
      commissionRate: 11.0,
      cuisineTypes: ['Romanian', 'Traditional'],
      deliveryFee: 7.0,
      minimumOrder: 35.0,
      estimatedDeliveryTime: 45,
      workingHours: {
        'monday': {'openTime': '10:00', 'closeTime': '22:00', 'isOpen': true},
        'tuesday': {'openTime': '10:00', 'closeTime': '22:00', 'isOpen': true},
        'wednesday': {'openTime': '10:00', 'closeTime': '22:00', 'isOpen': true},
        'thursday': {'openTime': '10:00', 'closeTime': '22:00', 'isOpen': true},
        'friday': {'openTime': '10:00', 'closeTime': '23:00', 'isOpen': true},
        'saturday': {'openTime': '10:00', 'closeTime': '23:00', 'isOpen': true},
        'sunday': {'openTime': '11:00', 'closeTime': '21:00', 'isOpen': true},
      },
    );
    print('✅ La Mama creat cu ID: $mamaId');

    print('\n✅ Toate restaurantele de test au fost create cu succes!');
    print('\n📋 Rezumat:');
    print('  - Pizza Place: $pizzaId');
    print('  - Burger House: $burgerId');
    print('  - Sushi Master: $sushiId');
    print('  - La Mama: $mamaId');
    print('\n💡 Acum poți deschide FriendsRide și vei vedea aceste restaurante în Delivery!');
  } catch (e, stackTrace) {
    print('❌ Eroare la crearea restaurante: $e');
    print('Stack trace: $stackTrace');
  } finally {
    // Nu închidem Firebase pentru că ar putea afecta alte procese
    // await Firebase.app().delete();
  }
}

