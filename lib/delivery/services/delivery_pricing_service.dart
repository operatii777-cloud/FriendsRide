import 'package:friendsride_app/delivery/models/order_item_model.dart';
import 'package:friendsride_app/delivery/models/restaurant_model.dart';
import 'package:friendsride_app/delivery/models/promo_code_model.dart';
import 'package:friendsride_app/models/saved_address_model.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'promo_code_service.dart';

/// Delivery Pricing Service
/// 
/// Calculează prețurile pentru comenzi de delivery
class DeliveryPricingService {
  static final DeliveryPricingService _instance = DeliveryPricingService._internal();
  factory DeliveryPricingService() => _instance;
  DeliveryPricingService._internal();

  final PromoCodeService _promoCodeService = PromoCodeService();

  /// Calculează prețul total al unei comenzi
  Future<PricingResult> calculateOrderPrice({
    required List<OrderItem> items,
    required Restaurant restaurant,
    required SavedAddress deliveryAddress,
    String? promoCode,
  }) async {
    // Calculate subtotal
    double subtotal = 0.0;
    for (final item in items) {
      subtotal += item.totalPrice;
    }

    // Calculate delivery fee
    final deliveryFee = _calculateDeliveryFee(
      restaurant: restaurant,
      deliveryAddress: deliveryAddress,
    );

    // Calculate service fee (10% of subtotal, max 3 RON)
    final serviceFee = (subtotal * 0.10).clamp(0.0, 3.0);

    // Calculate discount if promo code is provided
    double discount = 0.0;
    double promoDeliveryDiscount = 0.0;
    if (promoCode != null) {
      final promoDiscount = await _calculateDiscount(
        promoCode: promoCode,
        subtotal: subtotal,
        restaurantId: restaurant.id,
      );
      discount = promoDiscount['discount'] ?? 0.0;
      promoDeliveryDiscount = promoDiscount['deliveryDiscount'] ?? 0.0;
    }

    // Calculate total (apply delivery discount if promo code is free delivery)
    final finalDeliveryFee = (deliveryFee - promoDeliveryDiscount).clamp(0.0, double.infinity);
    final total = subtotal + finalDeliveryFee + serviceFee - discount;

    return PricingResult(
      subtotal: subtotal,
      deliveryFee: finalDeliveryFee,
      serviceFee: serviceFee,
      discount: discount,
      total: total,
    );
  }

  /// Calculează taxa de livrare
  double _calculateDeliveryFee({
    required Restaurant restaurant,
    required SavedAddress deliveryAddress,
  }) {
    // Base delivery fee from restaurant
    double fee = restaurant.deliveryFee;

    // Calculate distance from restaurant to delivery address
    final distance = geolocator.Geolocator.distanceBetween(
      restaurant.address.coordinates.latitude,
      restaurant.address.coordinates.longitude,
      deliveryAddress.coordinates.latitude,
      deliveryAddress.coordinates.longitude,
    ) / 1000; // Convert to km

    // Add distance-based fee (0.5 RON per km after first 3 km)
    if (distance > 3.0) {
      fee += (distance - 3.0) * 0.5;
    }

    return fee;
  }

  /// Calculează discount-ul pentru un promo code
  Future<Map<String, double>> _calculateDiscount({
    required String promoCode,
    required double subtotal,
    required String restaurantId,
  }) async {
    try {
      final promo = await _promoCodeService.validatePromoCode(
        code: promoCode,
        orderValue: subtotal,
        restaurantId: restaurantId,
      );
      
      if (promo == null) {
        return {'discount': 0.0, 'deliveryDiscount': 0.0};
      }

      // Calculate discount based on promo code type
      double discount = 0.0;
      double deliveryDiscount = 0.0;
      
      switch (promo.type) {
        case PromoCodeType.percentage:
          discount = subtotal * (promo.value / 100);
          if (promo.maxDiscount != null && discount > promo.maxDiscount!) {
            discount = promo.maxDiscount!;
          }
          break;
        case PromoCodeType.fixed:
          discount = promo.value;
          break;
        case PromoCodeType.freeDelivery:
          deliveryDiscount = double.infinity; // Will be clamped to delivery fee
          break;
      }

      return {
        'discount': discount,
        'deliveryDiscount': deliveryDiscount,
      };
    } catch (e) {
      return {'discount': 0.0, 'deliveryDiscount': 0.0};
    }
  }

  /// Verifică dacă o comandă îndeplinește minimum order
  bool meetsMinimumOrder({
    required List<OrderItem> items,
    required Restaurant restaurant,
  }) {
    double subtotal = 0.0;
    for (final item in items) {
      subtotal += item.totalPrice;
    }
    return subtotal >= restaurant.minimumOrder;
  }
}

/// Result of pricing calculation
class PricingResult {
  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final double discount;
  final double total;

  PricingResult({
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.discount,
    required this.total,
  });
}

