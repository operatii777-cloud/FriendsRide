import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rating_model.dart';

/// Service pentru gestionarea rating-urilor delivery
class DeliveryRatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creează un rating pentru restaurant
  Future<void> rateRestaurant({
    required String orderId,
    required String userId,
    required String restaurantId,
    required int rating,
    String? comment,
    List<String>? tags,
  }) async {
    final ratingDoc = DeliveryRating(
      id: _firestore.collection('delivery_ratings').doc().id,
      orderId: orderId,
      userId: userId,
      restaurantId: restaurantId,
      rating: rating,
      comment: comment,
      tags: tags,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('delivery_ratings')
        .doc(ratingDoc.id)
        .set(ratingDoc.toFirestore());

    // Update restaurant average rating
    await _updateRestaurantRating(restaurantId);
  }

  /// Creează un rating pentru curier
  Future<void> rateCourier({
    required String orderId,
    required String userId,
    required String courierId,
    required int rating,
    String? comment,
    List<String>? tags,
  }) async {
    final ratingDoc = DeliveryRating(
      id: _firestore.collection('delivery_ratings').doc().id,
      orderId: orderId,
      userId: userId,
      courierId: courierId,
      rating: rating,
      comment: comment,
      tags: tags,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('delivery_ratings')
        .doc(ratingDoc.id)
        .set(ratingDoc.toFirestore());

    // Update courier average rating
    await _updateCourierRating(courierId);
  }

  /// Actualizează rating-ul mediu al restaurantului
  Future<void> _updateRestaurantRating(String restaurantId) async {
    final ratings = await _firestore
        .collection('delivery_ratings')
        .where('restaurantId', isEqualTo: restaurantId)
        .get();

    if (ratings.docs.isEmpty) {
      return;
    }

    double totalRating = 0;
    int count = 0;

    for (final doc in ratings.docs) {
      final data = doc.data();
      totalRating += (data['rating'] as int? ?? 0);
      count++;
    }

    final averageRating = totalRating / count;

    await _firestore.collection('restaurants').doc(restaurantId).update({
      'rating': averageRating,
      'totalRatings': count,
    });
  }

  /// Actualizează rating-ul mediu al curierului
  Future<void> _updateCourierRating(String courierId) async {
    final ratings = await _firestore
        .collection('delivery_ratings')
        .where('courierId', isEqualTo: courierId)
        .get();

    if (ratings.docs.isEmpty) {
      return;
    }

    double totalRating = 0;
    int count = 0;

    for (final doc in ratings.docs) {
      final data = doc.data();
      totalRating += (data['rating'] as int? ?? 0);
      count++;
    }

    final averageRating = totalRating / count;

    await _firestore.collection('couriers').doc(courierId).update({
      'rating': averageRating,
      'totalRatings': count,
    });
  }

  /// Obține rating-urile pentru un restaurant
  Stream<List<DeliveryRating>> getRestaurantRatings(String restaurantId) {
    return _firestore
        .collection('delivery_ratings')
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DeliveryRating.fromFirestore(doc))
            .toList());
  }

  /// Obține rating-urile pentru un curier
  Stream<List<DeliveryRating>> getCourierRatings(String courierId) {
    return _firestore
        .collection('delivery_ratings')
        .where('courierId', isEqualTo: courierId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DeliveryRating.fromFirestore(doc))
            .toList());
  }

  /// Verifică dacă utilizatorul a dat deja rating pentru o comandă
  Future<bool> hasRatedOrder(String orderId, String userId) async {
    final rating = await _firestore
        .collection('delivery_ratings')
        .where('orderId', isEqualTo: orderId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    return rating.docs.isNotEmpty;
  }

  /// Obține rating-ul mediu pentru un restaurant
  Future<double> getRestaurantAverageRating(String restaurantId) async {
    final restaurantDoc = await _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .get();

    final data = restaurantDoc.data();
    return (data?['rating'] as double? ?? 0.0);
  }

  /// Obține rating-ul mediu pentru un curier
  Future<double> getCourierAverageRating(String courierId) async {
    final courierDoc = await _firestore.collection('couriers').doc(courierId).get();

    final data = courierDoc.data();
    return (data?['rating'] as double? ?? 0.0);
  }
}

