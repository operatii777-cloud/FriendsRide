import 'package:flutter_test/flutter_test.dart';
import 'package:friendsride_app/models/ride_model.dart';
import 'package:friendsride_app/models/cancellation_policy_model.dart';
import 'package:friendsride_app/services/pricing_service.dart';

void main() {
  group('Enhanced Price Estimate Tests', () {
    test('PricingService calculates fare correctly', () {
      final pricingService = PricingService();
      
      final fare = pricingService.calculateFare(
        distanceInKm: 10.0,
        durationInMinutes: 20.0,
        category: RideCategory.standard,
      );
      
      expect(fare['totalCost'], greaterThan(0));
      expect(fare['baseFare'], equals(3.0));
      expect(fare['driverEarnings'], greaterThan(0));
    });
    
    test('PricingService calculates fare with stops', () {
      final pricingService = PricingService();
      
      final fare = pricingService.calculateFareWithStops(
        distanceInKm: 10.0,
        durationInMinutes: 20.0,
        category: RideCategory.standard,
        numberOfStops: 2,
      );
      
      expect(fare['totalCost'], greaterThan(0));
      expect(fare['stopsFee'], equals(4.0)); // 2 stops × 2 RON
      expect(fare['stopsCount'], equals(2.0));
    });
  });
  
  group('Cancellation Policy Tests', () {
    test('Free cancellation in first 2 minutes', () {
      final now = DateTime.now();
      final acceptedAt = now.subtract(const Duration(minutes: 1));
      
      final policy = CancellationPolicy.calculatePolicy(
        rideStatus: 'accepted',
        isDriver: false,
        isScheduled: false,
        acceptedAt: acceptedAt,
        rideCost: 50.0,
      );
      
      expect(policy.isFree, isTrue);
      expect(policy.fee, isNull);
    });
    
    test('Fee applies after 2 minutes', () {
      final now = DateTime.now();
      final acceptedAt = now.subtract(const Duration(minutes: 5));
      
      final policy = CancellationPolicy.calculatePolicy(
        rideStatus: 'accepted',
        isDriver: false,
        isScheduled: false,
        acceptedAt: acceptedAt,
        rideCost: 50.0,
      );
      
      expect(policy.isFree, isFalse);
      expect(policy.fee, greaterThan(0));
    });
    
    test('Higher fee for arrived status', () {
      final now = DateTime.now();
      final acceptedAt = now.subtract(const Duration(minutes: 10));
      
      final policyArrived = CancellationPolicy.calculatePolicy(
        rideStatus: 'arrived',
        isDriver: false,
        isScheduled: false,
        acceptedAt: acceptedAt,
        rideCost: 50.0,
      );
      
      final policyAccepted = CancellationPolicy.calculatePolicy(
        rideStatus: 'accepted',
        isDriver: false,
        isScheduled: false,
        acceptedAt: acceptedAt,
        rideCost: 50.0,
      );
      
      expect(policyArrived.fee, greaterThan(policyAccepted.fee ?? 0));
    });
    
    test('Driver compensation calculation', () {
      final compensation = CancellationPolicy.calculateDriverCompensation(
        rideStatus: 'accepted',
        rideCost: 50.0,
        passengerCancelled: true,
      );
      
      expect(compensation, greaterThan(0));
    });
  });
  
  group('Ride Model Tests', () {
    test('Ride model has all required fields', () {
      final ride = Ride(
        id: 'test-id',
        passengerId: 'passenger-id',
        startAddress: 'Start',
        destinationAddress: 'Destination',
        distance: 10.0,
        baseFare: 3.0,
        perKmRate: 2.5,
        perMinRate: 0.4,
        totalCost: 30.0,
        appCommission: 4.5,
        driverEarnings: 25.5,
        timestamp: DateTime.now(),
        status: 'pending',
        category: RideCategory.standard,
        stops: [],
        tip: 0,
        wasCancelled: false,
        declinedBy: [],
      );
      
      expect(ride.id, equals('test-id'));
      expect(ride.passengerId, equals('passenger-id'));
      expect(ride.totalCost, equals(30.0));
    });
  });
}

