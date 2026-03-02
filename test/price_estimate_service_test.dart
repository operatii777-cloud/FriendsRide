import 'package:flutter_test/flutter_test.dart';
import '../lib/services/price_estimate_service.dart';

void main() {
  group('PriceEstimateService', () {
    test('Calcul preț fără surge', () {
      final service = PriceEstimateService();
      final price = service.estimatePrice(distanceKm: 10, durationMin: 20);
      expect(price, 10.0 + 10 * 2.5 + 20 * 0.5);
    });

    test('Calcul preț cu surge', () {
      final service = PriceEstimateService();
      final price = service.estimatePrice(distanceKm: 5, durationMin: 10, surgeMultiplier: 2.0);
      expect(price, (10.0 + 5 * 2.5 + 10 * 0.5) * 2.0);
    });
  });
}