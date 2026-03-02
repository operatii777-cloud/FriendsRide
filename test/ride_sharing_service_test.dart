import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:friendsride_app/services/ride_sharing_service.dart';
import 'package:friendsride_app/models/ride_sharing_model.dart';

void main() {
  group('RideSharingService Matching Logic', () {
    test('Routes are compatible if pickup and destination are close', () {
      final share1 = RideShare(
        id: '1',
        rideId: 'r1',
        passengerId: 'u1',
        pickupAddress: 'A',
        destinationAddress: 'B',
        pickupLatitude: 44.4268,
        pickupLongitude: 26.1025,
        destinationLatitude: 44.4350,
        destinationLongitude: 26.1010,
        requestedAt: Timestamp.now(),
        status: 'pending',
        originalCost: 50.0,
      );
      final share2 = RideShare(
        id: '2',
        rideId: 'r2',
        passengerId: 'u2',
        pickupAddress: 'A2',
        destinationAddress: 'B2',
        pickupLatitude: 44.4270,
        pickupLongitude: 26.1027,
        destinationLatitude: 44.4352,
        destinationLongitude: 26.1012,
        requestedAt: Timestamp.now(),
        status: 'pending',
        originalCost: 55.0,
      );
      expect(RideSharingService.areRoutesCompatible(share1, share2), isTrue);
    });

    test('Routes are NOT compatible if pickup and destination are far', () {
      final share1 = RideShare(
        id: '1',
        rideId: 'r1',
        passengerId: 'u1',
        pickupAddress: 'A',
        destinationAddress: 'B',
        pickupLatitude: 44.4268,
        pickupLongitude: 26.1025,
        destinationLatitude: 44.4350,
        destinationLongitude: 26.1010,
        requestedAt: Timestamp.now(),
        status: 'pending',
        originalCost: 50.0,
      );
      final share2 = RideShare(
        id: '2',
        rideId: 'r2',
        passengerId: 'u2',
        pickupAddress: 'A2',
        destinationAddress: 'B2',
        pickupLatitude: 45.0000,
        pickupLongitude: 27.0000,
        destinationLatitude: 45.1000,
        destinationLongitude: 27.1000,
        requestedAt: Timestamp.now(),
        status: 'pending',
        originalCost: 55.0,
      );
      expect(RideSharingService.areRoutesCompatible(share1, share2), isFalse);
    });
  });
}
