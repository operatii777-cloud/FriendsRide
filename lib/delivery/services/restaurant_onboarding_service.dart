import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:friendsride_app/models/saved_address_model.dart';
import '../models/restaurant_model.dart';
import 'restaurant_api_key_service.dart';

/// Service pentru gestionarea onboarding-ului restaurante
class RestaurantOnboardingService {
  static final RestaurantOnboardingService _instance =
      RestaurantOnboardingService._internal();
  factory RestaurantOnboardingService() => _instance;
  RestaurantOnboardingService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final RestaurantApiKeyService _apiKeyService = RestaurantApiKeyService();

  /// Creează o cerere de onboarding manual (de către admin FriendsRide)
  Future<String> createManualOnboardingRequest({
    required String restaurantName,
    required String description,
    required String address,
    required double latitude,
    required double longitude,
    required String phoneNumber,
    required String email,
    required String ownerId,
    required double commissionRate, // 9-14%
    List<String>? cuisineTypes,
    String? imageUrl,
    Map<String, dynamic>? workingHours,
    double? deliveryFee,
    double? minimumOrder,
    double? estimatedDeliveryTime,
  }) async {
    try {
      final restaurantId = _db.collection('restaurants').doc().id;

      // Creează SavedAddress pentru restaurant
      final savedAddress = SavedAddress(
        id: restaurantId,
        label: restaurantName,
        address: address,
        coordinates: GeoPoint(latitude, longitude),
      );

      // Creează restaurantul direct (manual onboarding = aprobat automat)
      final restaurant = Restaurant(
        id: restaurantId,
        name: restaurantName,
        description: description,
        address: savedAddress,
        cuisineTypes: cuisineTypes ?? [],
        imageUrl: imageUrl,
        workingHours: (workingHours ?? {}).map(
          (key, value) => MapEntry(
            key,
            WorkingHours.fromMap(value as Map<String, dynamic>),
          ),
        ),
        deliveryFee: deliveryFee ?? 5.0,
        minimumOrder: minimumOrder ?? 0.0,
        estimatedDeliveryTime: (estimatedDeliveryTime ?? 30.0).toInt(),
        status: RestaurantStatus.open,
        rating: 0.0,
        reviewCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Salvează restaurantul
      await _db.collection('restaurants').doc(restaurantId).set(
            restaurant.toFirestore(),
          );

      // Generează API key pentru restaurant
      await _apiKeyService.generateApiKey(
        restaurantId: restaurantId,
        ownerId: ownerId,
      );

      return restaurantId;
    } catch (e) {
      throw Exception('Failed to create manual onboarding: $e');
    }
  }

  /// Creează o cerere de onboarding automat (când restaurantul cumpără licența Restaurant App v3)
  Future<String> createAutomaticOnboardingRequest({
    required String restaurantName,
    required String description,
    required String address,
    required double latitude,
    required double longitude,
    required String phoneNumber,
    required String email,
    required String ownerId,
    required String restaurantAppV3TenantId, // ID-ul tenant-ului din Restaurant App v3
    List<String>? cuisineTypes,
    String? imageUrl,
    Map<String, dynamic>? workingHours,
    double? deliveryFee,
    double? minimumOrder,
    double? estimatedDeliveryTime,
  }) async {
    try {
      final requestId = _db.collection('restaurant_onboarding').doc().id;

      // Creează cererea de onboarding
      await _db.collection('restaurant_onboarding').doc(requestId).set({
        'restaurantName': restaurantName,
        'description': description,
        'address': address,
        'location': GeoPoint(latitude, longitude),
        'phoneNumber': phoneNumber,
        'email': email,
        'ownerId': ownerId,
        'restaurantAppV3TenantId': restaurantAppV3TenantId,
        'cuisineTypes': cuisineTypes ?? [],
        'imageUrl': imageUrl,
        'workingHours': workingHours ?? {},
        'deliveryFee': deliveryFee ?? 5.0,
        'minimumOrder': minimumOrder ?? 0.0,
        'estimatedDeliveryTime': estimatedDeliveryTime ?? 30.0,
        'status': 'pending', // pending, approved, rejected
        'onboardingType': 'automatic',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      return requestId;
    } catch (e) {
      throw Exception('Failed to create automatic onboarding request: $e');
    }
  }

  /// Aprobă o cerere de onboarding automat
  Future<String> approveOnboardingRequest({
    required String requestId,
    required double commissionRate, // 9-14%
  }) async {
    try {
      final requestDoc =
          await _db.collection('restaurant_onboarding').doc(requestId).get();

      if (!requestDoc.exists) {
        throw Exception('Onboarding request not found');
      }

      final requestData = requestDoc.data()!;
      final restaurantId = _db.collection('restaurants').doc().id;

      // Creează SavedAddress pentru restaurant
      final location = requestData['location'] as GeoPoint;
      final savedAddress = SavedAddress(
        id: restaurantId,
        label: requestData['restaurantName'] as String,
        address: requestData['address'] as String,
        coordinates: location,
      );

      // Creează restaurantul
      final restaurant = Restaurant(
        id: restaurantId,
        name: requestData['restaurantName'] as String,
        description: requestData['description'] as String,
        address: savedAddress,
        cuisineTypes: (requestData['cuisineTypes'] as List?)?.cast<String>() ?? [],
        imageUrl: requestData['imageUrl'] as String?,
        workingHours: (requestData['workingHours'] as Map<String, dynamic>?)
                ?.map(
                  (key, value) => MapEntry(
                    key,
                    WorkingHours.fromMap(value as Map<String, dynamic>),
                  ),
                ) ??
            {},
        deliveryFee: (requestData['deliveryFee'] as num?)?.toDouble() ?? 5.0,
        minimumOrder: (requestData['minimumOrder'] as num?)?.toDouble() ?? 0.0,
        estimatedDeliveryTime:
            ((requestData['estimatedDeliveryTime'] as num?)?.toDouble() ?? 30.0)
                .toInt(),
        status: RestaurantStatus.open,
        rating: 0.0,
        reviewCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Salvează restaurantul
      await _db.collection('restaurants').doc(restaurantId).set(
            restaurant.toFirestore(),
          );

      // Generează API key
      await _apiKeyService.generateApiKey(
        restaurantId: restaurantId,
        ownerId: requestData['ownerId'] as String,
      );

      // Actualizează statusul cererii
      await _db.collection('restaurant_onboarding').doc(requestId).update({
        'status': 'approved',
        'restaurantId': restaurantId,
        'updatedAt': Timestamp.now(),
      });

      return restaurantId;
    } catch (e) {
      throw Exception('Failed to approve onboarding request: $e');
    }
  }

  /// Respinge o cerere de onboarding
  Future<void> rejectOnboardingRequest({
    required String requestId,
    required String reason,
  }) async {
    try {
      await _db.collection('restaurant_onboarding').doc(requestId).update({
        'status': 'rejected',
        'rejectionReason': reason,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to reject onboarding request: $e');
    }
  }

  /// Obține toate cererile de onboarding
  Stream<QuerySnapshot> getOnboardingRequests({
    String? status, // pending, approved, rejected
  }) {
    Query query = _db.collection('restaurant_onboarding');

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    return query.orderBy('createdAt', descending: true).snapshots();
  }

  /// Obține o cerere de onboarding specifică
  Future<DocumentSnapshot> getOnboardingRequest(String requestId) async {
    return await _db.collection('restaurant_onboarding').doc(requestId).get();
  }
}

