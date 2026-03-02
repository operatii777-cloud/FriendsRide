import 'package:cloud_firestore/cloud_firestore.dart';

/// Model pentru rating-uri delivery
class DeliveryRating {
  final String id;
  final String orderId;
  final String userId; // customerId
  final String? restaurantId;
  final String? courierId;
  final int rating; // 1-5
  final String? comment;
  final List<String>? tags; // ["fast", "friendly", "good_food"]
  final DateTime createdAt;

  DeliveryRating({
    required this.id,
    required this.orderId,
    required this.userId,
    this.restaurantId,
    this.courierId,
    this.rating = 5,
    this.comment,
    this.tags,
    required this.createdAt,
  });

  factory DeliveryRating.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DeliveryRating(
      id: doc.id,
      orderId: data['orderId'] as String,
      userId: data['userId'] as String,
      restaurantId: data['restaurantId'] as String?,
      courierId: data['courierId'] as String?,
      rating: data['rating'] as int? ?? 5,
      comment: data['comment'] as String?,
      tags: data['tags'] != null ? List<String>.from(data['tags'] as List) : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'orderId': orderId,
      'userId': userId,
      'restaurantId': restaurantId,
      'courierId': courierId,
      'rating': rating,
      'comment': comment,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  DeliveryRating copyWith({
    String? id,
    String? orderId,
    String? userId,
    String? restaurantId,
    String? courierId,
    int? rating,
    String? comment,
    List<String>? tags,
    DateTime? createdAt,
  }) {
    return DeliveryRating(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      restaurantId: restaurantId ?? this.restaurantId,
      courierId: courierId ?? this.courierId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Tag-uri disponibile pentru rating-uri
enum RatingTag {
  fast,
  friendly,
  goodFood,
  onTime,
  clean,
  professional,
  slow,
  unfriendly,
  badFood,
  late,
  dirty,
  unprofessional,
}

extension RatingTagExtension on RatingTag {
  String getDisplayName(String locale) {
    switch (this) {
      case RatingTag.fast:
        return locale == 'ro' ? 'Rapid' : 'Fast';
      case RatingTag.friendly:
        return locale == 'ro' ? 'Prietenos' : 'Friendly';
      case RatingTag.goodFood:
        return locale == 'ro' ? 'Mâncare bună' : 'Good food';
      case RatingTag.onTime:
        return locale == 'ro' ? 'La timp' : 'On time';
      case RatingTag.clean:
        return locale == 'ro' ? 'Curat' : 'Clean';
      case RatingTag.professional:
        return locale == 'ro' ? 'Profesionist' : 'Professional';
      case RatingTag.slow:
        return locale == 'ro' ? 'Lent' : 'Slow';
      case RatingTag.unfriendly:
        return locale == 'ro' ? 'Neprietenos' : 'Unfriendly';
      case RatingTag.badFood:
        return locale == 'ro' ? 'Mâncare proastă' : 'Bad food';
      case RatingTag.late:
        return locale == 'ro' ? 'Întârziere' : 'Late';
      case RatingTag.dirty:
        return locale == 'ro' ? 'Murdar' : 'Dirty';
      case RatingTag.unprofessional:
        return locale == 'ro' ? 'Neprofesionist' : 'Unprofessional';
    }
  }
}

