import 'package:friendsride_app/models/ride_model.dart';
import 'package:friendsride_app/models/promotion_model.dart';
import 'package:friendsride_app/services/surge_pricing_service.dart';

class PricingService {
  final SurgePricingService _surgePricingService = SurgePricingService();
  
  static const double _baseFare = 3.0; 
  static const double _perKmRate = 2.5;
  static const double _perMinRate = 0.4;
  static const double _appCommissionRate = 0.15; // Comision actualizat la 15%
  
  // ADĂUGAT: Constante pentru opriri multiple
  static const double _stopFee = 2.0; // 2 RON per oprire
  static const double _stopDriverShare = 0.8; // 80% din taxa de opriri merge la șofer
  static const double _stopAppShare = 0.2; // 20% rămâne la aplicație

  // Feature: Wait time fee — driver earns fee after free waiting period
  static const int freeWaitMinutes = 5; // 5 minute gratuite de așteptare
  static const double waitFeePerMinute = 1.0; // 1 RON pe minut după perioada gratuită

  double _getMultiplier(RideCategory category) {
    switch (category) {
      // --- CAZ NOU ADĂUGAT ---
      case RideCategory.family:
        return 1.15; // +15% (mai scump decât Standard, mai ieftin decât Best)
      case RideCategory.energy:
        return 1.20; // +20%
      case RideCategory.best:
        return 1.40; // +40%
      case RideCategory.standard:
        return 1.0; 
    }
  }

  Map<String, double> calculateFare({
    required double distanceInKm, 
    required double durationInMinutes,
    required RideCategory category,
    double? surgeMultiplier,
    Promotion? promotion,
  }) {
    final categoryMultiplier = _getMultiplier(category);
    final finalSurgeMultiplier = surgeMultiplier ?? 1.0;
    final totalMultiplier = categoryMultiplier * finalSurgeMultiplier;

    final currentBaseFare = _baseFare * totalMultiplier;
    final currentPerKmRate = _perKmRate * totalMultiplier;
    final currentPerMinRate = _perMinRate * totalMultiplier;
    
    final distanceCost = distanceInKm * currentPerKmRate;
    final timeCost = durationInMinutes * currentPerMinRate;
    final double totalCost = currentBaseFare + distanceCost + timeCost;
    
    // Apply promotion discount if available
    double discount = 0.0;
    double finalTotalCost = totalCost;
    if (promotion != null && promotion.isValid) {
      discount = promotion.calculateDiscount(totalCost);
      finalTotalCost = totalCost - discount;
      if (finalTotalCost < 0) finalTotalCost = 0;
    }

    final double appCommission = finalTotalCost * _appCommissionRate;
    final double driverEarnings = finalTotalCost - appCommission;

    return {
      'baseFare': currentBaseFare,
      'perKmRate': currentPerKmRate,
      'perMinRate': currentPerMinRate,
      'totalCost': finalTotalCost,
      'originalCost': totalCost,
      'discount': discount,
      'appCommission': appCommission,
      'driverEarnings': driverEarnings,
      'surgeMultiplier': finalSurgeMultiplier,
      'categoryMultiplier': categoryMultiplier,
    };
  }

  /// Calculează prețul cu surge pricing pentru o locație specifică
  Future<Map<String, double>> calculateFareWithSurge({
    required double distanceInKm, 
    required double durationInMinutes,
    required RideCategory category,
    required double latitude,
    required double longitude,
  }) async {
    final surgeMultiplier = await _surgePricingService.calculateSurgeMultiplier(
      latitude: latitude,
      longitude: longitude,
      category: category.toString().split('.').last,
    );

    return calculateFare(
      distanceInKm: distanceInKm,
      durationInMinutes: durationInMinutes,
      category: category,
      surgeMultiplier: surgeMultiplier,
    );
  }

  // ADĂUGAT: Metodă pentru calcularea tarifului cu opriri multiple
  Map<String, double> calculateFareWithStops({
    required double distanceInKm,
    required double durationInMinutes,
    required RideCategory category,
    required int numberOfStops,
    Promotion? promotion,
  }) {
    // Calculăm tariful de bază fără opriri
    final baseFareData = calculateFare(
      distanceInKm: distanceInKm,
      durationInMinutes: durationInMinutes,
      category: category,
      promotion: promotion,
    );
    
    // Calculăm taxa pentru opriri
    final stopsFee = numberOfStops * _stopFee;
    final stopsDriverEarnings = stopsFee * _stopDriverShare;
    final stopsAppCommission = stopsFee * _stopAppShare;
    
    // Actualizăm costurile totale
    final originalTotalCost = (baseFareData['originalCost'] ?? baseFareData['totalCost'])!;
    final newTotalCost = originalTotalCost + stopsFee;
    final discount = baseFareData['discount'] ?? 0.0;
    final finalTotalCost = newTotalCost - discount;
    
    final newDriverEarnings = (finalTotalCost * (1 - _appCommissionRate)) + stopsDriverEarnings;
    final newAppCommission = (finalTotalCost * _appCommissionRate) + stopsAppCommission;
    
    return {
      'baseFare': baseFareData['baseFare']!,
      'perKmRate': baseFareData['perKmRate']!,
      'perMinRate': baseFareData['perMinRate']!,
      'stopsFee': stopsFee, // ADĂUGAT: Taxa pentru opriri
      'stopsCount': numberOfStops.toDouble(), // ADĂUGAT: Numărul de opriri
      'totalCost': finalTotalCost,
      'originalCost': newTotalCost,
      'discount': discount,
      'appCommission': newAppCommission,
      'driverEarnings': newDriverEarnings,
    };
  }

  // ADĂUGAT: Metodă helper pentru obținerea taxei per oprire
  static double getStopFee() => _stopFee;

  // ADĂUGAT: Metodă helper pentru calcularea costului total al opririlor
  static double calculateStopsCost(int numberOfStops) => numberOfStops * _stopFee;

  /// Feature: Wait time fee — calculates fee for driver waiting beyond free period.
  /// Returns the fee in RON (0.0 if within the free period).
  static double calculateWaitTimeFee(DateTime waitStartedAt) {
    final waitedMinutes = DateTime.now().difference(waitStartedAt).inMinutes;
    final billableMinutes = waitedMinutes - freeWaitMinutes;
    if (billableMinutes <= 0) return 0.0;
    return billableMinutes * waitFeePerMinute;
  }
  
  /// 🎯 Metodă simplă pentru calcularea prețului (pentru Voice AI)
  Future<double> calculatePrice({
    required String pickup,
    required String destination,
    required RideCategory category,
  }) async {
    // Simulez calcularea distanței și duratei (în implementarea reală se integrează cu RoutingService)
    final distanceInKm = 5.0; // Placeholder: 5km
    final durationInMinutes = 15.0; // Placeholder: 15 minute
    
    final fareData = calculateFare(
      distanceInKm: distanceInKm,
      durationInMinutes: durationInMinutes,
      category: category,
    );
    
    return fareData['totalCost'] ?? 25.0;
  }

  // ADĂUGAT: Metodă helper pentru formatarea detaliilor de preț cu opriri
  String formatPriceBreakdownWithStops({
    required Map<String, double> fareData,
    required RideCategory category,
  }) {
    final baseFare = fareData['baseFare'] ?? 0.0;
    final distanceCost = (fareData['totalCost'] ?? 0.0) - baseFare - (fareData['stopsFee'] ?? 0.0);
    final stopsFee = fareData['stopsFee'] ?? 0.0;
    final stopsCount = (fareData['stopsCount'] ?? 0.0).toInt();
    
    String breakdown = 'Tarif ${category.name.toUpperCase()}:\n';
    breakdown += '• Tarif de bază: ${baseFare.toStringAsFixed(2)} RON\n';
    breakdown += '• Cost distanță/timp: ${distanceCost.toStringAsFixed(2)} RON\n';
    
    if (stopsCount > 0) {
      breakdown += '• Opriri ($stopsCount × ${_stopFee.toStringAsFixed(2)}): ${stopsFee.toStringAsFixed(2)} RON\n';
    }
    
    breakdown += '• TOTAL: ${fareData['totalCost']?.toStringAsFixed(2)} RON';
    
    return breakdown;
  }
}