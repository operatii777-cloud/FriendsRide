/// 🔍 VERIFICARE STATICĂ A FIXURILOR IMPLEMENTATE
/// 
/// Acest script verifică static că fixurile sunt implementate corect
/// prin analiza codului sursă.
library;

import 'dart:io';

void main() async {
  print('🔍 VERIFICARE STATICĂ - FIXURI IMPLEMENTATE');
  print('=' * 60);
  
  final results = <String, bool>{};
  
  // Verificări
  results['Fix 1: Validare cursă duplicată'] = await verificaValidareCursaDuplicata();
  results['Fix 2: Fix passengerId'] = await verificaFixPassengerId();
  results['Fix 3: Validare coordonate'] = await verificaValidareCoordonate();
  results['Fix 4: Validare distanță'] = await verificaValidareDistanta();
  results['Fix 5: Geocoding opriri'] = await verificaGeocodingOpriri();
  results['Fix 6: Error handling'] = await verificaErrorHandling();
  results['Fix 7: Timeout'] = await verificaTimeout();
  results['Fix 8: Coordonate în RideRequest'] = await verificaCoordonateRideRequest();
  
  // Rezultate
  print('\n\n📊 REZULTATE VERIFICARE:');
  print('-' * 60);
  
  int passedCount = 0;
  int failedCount = 0;
  
  results.forEach((fix, result) {
    final status = result ? '✅' : '❌';
    print('$status $fix');
    if (result) {
      passedCount++;
    } else {
      failedCount++;
    }
  });
  
  print('\n📈 STATISTICI:');
  print('   ✅ Verificări trecute: $passedCount/${results.length}');
  print('   ❌ Verificări eșuate: $failedCount/${results.length}');
  
  if (failedCount == 0) {
    print('\n🎉 TOATE VERIFICĂRILE AU TRECUT!');
  } else {
    print('\n⚠️ EXISTĂ VERIFICĂRI EȘUATE - Verifică codul!');
  }
}

Future<bool> verificaValidareCursaDuplicata() async {
  print('\n🔍 Verifică Fix 1: Validare cursă duplicată...');
  
  try {
    final file = File('lib/services/firestore_service.dart');
    final content = await file.readAsString();
    
    // Verifică că există verificarea pentru curse active
    final hasActiveRidesCheck = content.contains('activeRides') && 
                                content.contains('whereIn') &&
                                content.contains('pending') &&
                                content.contains('accepted');
    
    // Verifică că există excepția
    final hasException = content.contains('deja o cursă activă') ||
                        content.contains('already has an active ride');
    
    final result = hasActiveRidesCheck && hasException;
    
    if (result) {
      print('   ✅ Validare cursă duplicată implementată');
    } else {
      print('   ❌ Validare cursă duplicată LIPSEȘTE sau incompletă');
    }
    
    return result;
  } catch (e) {
    print('   ⚠️ Eroare la verificare: $e');
    return false;
  }
}

Future<bool> verificaFixPassengerId() async {
  print('\n🔍 Verifică Fix 2: Fix passengerId...');
  
  try {
    final file = File('lib/voice/ride/ride_flow_manager.dart');
    final content = await file.readAsString();
    
    // Verifică că folosește FirebaseAuth pentru user ID
    final hasFirebaseAuth = content.contains('FirebaseAuth.instance.currentUser?.uid');
    
    // Verifică că validează user ID
    final hasValidation = content.contains('userId == null') || 
                         content.contains('userId.isEmpty');
    
    final result = hasFirebaseAuth && hasValidation;
    
    if (result) {
      print('   ✅ Fix passengerId implementat');
    } else {
      print('   ❌ Fix passengerId LIPSEȘTE sau incomplet');
    }
    
    return result;
  } catch (e) {
    print('   ⚠️ Eroare la verificare: $e');
    return false;
  }
}

Future<bool> verificaValidareCoordonate() async {
  print('\n🔍 Verifică Fix 3: Validare coordonate...');
  
  try {
    final file = File('lib/services/firestore_service.dart');
    final content = await file.readAsString();
    
    // Verifică validarea coordonatelor
    final hasNullCheck = content.contains('pickupLat == null') ||
                        content.contains('destLat == null');
    
    final hasRangeCheck = (content.contains('pickupLat < -90') || 
                          content.contains('pickupLat > 90')) &&
                         (content.contains('destLat < -90') || 
                          content.contains('destLat > 90'));
    
    final result = hasNullCheck && hasRangeCheck;
    
    if (result) {
      print('   ✅ Validare coordonate implementată');
    } else {
      print('   ❌ Validare coordonate LIPSEȘTE sau incompletă');
    }
    
    return result;
  } catch (e) {
    print('   ⚠️ Eroare la verificare: $e');
    return false;
  }
}

Future<bool> verificaValidareDistanta() async {
  print('\n🔍 Verifică Fix 4: Validare distanță...');
  
  try {
    final file = File('lib/services/firestore_service.dart');
    final content = await file.readAsString();
    
    // Verifică calcularea distanței
    final hasDistanceCalc = content.contains('_calculateHaversineDistance');
    
    // Verifică validarea distanței minime
    final hasMinCheck = content.contains('distance < 0.1') ||
                       content.contains('100 metri');
    
    // Verifică validarea distanței maxime
    final hasMaxCheck = content.contains('distance > 200') ||
                       content.contains('200 km');
    
    final result = hasDistanceCalc && hasMinCheck && hasMaxCheck;
    
    if (result) {
      print('   ✅ Validare distanță implementată');
    } else {
      print('   ❌ Validare distanță LIPSEȘTE sau incompletă');
    }
    
    return result;
  } catch (e) {
    print('   ⚠️ Eroare la verificare: $e');
    return false;
  }
}

Future<bool> verificaGeocodingOpriri() async {
  print('\n🔍 Verifică Fix 5: Geocoding opriri...');
  
  try {
    final file = File('lib/screens/map_screen.dart');
    final content = await file.readAsString();
    
    // Verifică că folosește geocoding real (nu default)
    final hasGeocoding = content.contains('_getCoordinatesForDestination') ||
                        content.contains('await Future.wait');
    
    // Verifică că nu folosește doar coordonate default
    final hasDefaultOnly = content.contains("'latitude': 44.4268") &&
                          !content.contains('coordinates?.coordinates.lat');
    
    final result = hasGeocoding && !hasDefaultOnly;
    
    if (result) {
      print('   ✅ Geocoding opriri implementat');
    } else {
      print('   ❌ Geocoding opriri LIPSEȘTE sau folosește doar default');
    }
    
    return result;
  } catch (e) {
    print('   ⚠️ Eroare la verificare: $e');
    return false;
  }
}

Future<bool> verificaErrorHandling() async {
  print('\n🔍 Verifică Fix 6: Error handling...');
  
  try {
    final file = File('lib/voice/ride/ride_flow_manager.dart');
    final content = await file.readAsString();
    
    // Verifică error handling în _fillAddressAndNavigateToConfirmation
    final hasTryCatch = content.contains('try {') &&
                       content.contains('catch (e)');
    
    // Verifică validarea rideId
    final hasRideIdCheck = content.contains('rideId == null') ||
                          content.contains('rideId.isEmpty');
    
    final result = hasTryCatch && hasRideIdCheck;
    
    if (result) {
      print('   ✅ Error handling implementat');
    } else {
      print('   ❌ Error handling LIPSEȘTE sau incomplet');
    }
    
    return result;
  } catch (e) {
    print('   ⚠️ Eroare la verificare: $e');
    return false;
  }
}

Future<bool> verificaTimeout() async {
  print('\n🔍 Verifică Fix 7: Timeout...');
  
  try {
    final file = File('lib/voice/ride/ride_flow_manager.dart');
    final content = await file.readAsString();
    
    // Verifică timeout pentru _calculateRealPrice
    final hasPriceTimeout = content.contains('_calculateRealPrice().timeout') ||
                           content.contains('Duration(seconds: 30)');
    
    // Verifică timeout pentru onCreateRideRequest
    final hasRideTimeout = content.contains('onCreateRideRequest(rideRequest).timeout') ||
                          content.contains('TimeoutException');
    
    final result = hasPriceTimeout || hasRideTimeout;
    
    if (result) {
      print('   ✅ Timeout implementat');
    } else {
      print('   ❌ Timeout LIPSEȘTE');
    }
    
    return result;
  } catch (e) {
    print('   ⚠️ Eroare la verificare: $e');
    return false;
  }
}

Future<bool> verificaCoordonateRideRequest() async {
  print('\n🔍 Verifică Fix 8: Coordonate în RideRequest...');
  
  try {
    final file = File('lib/models/voice_models.dart');
    final content = await file.readAsString();
    
    // Verifică că RideRequest are câmpuri pentru coordonate
    final hasPickupLat = content.contains('pickupLatitude') &&
                        content.contains('double?');
    
    final hasDestLat = content.contains('destinationLatitude') &&
                      content.contains('double?');
    
    final result = hasPickupLat && hasDestLat;
    
    if (result) {
      print('   ✅ Coordonate în RideRequest implementate');
    } else {
      print('   ❌ Coordonate în RideRequest LIPSESC');
    }
    
    return result;
  } catch (e) {
    print('   ⚠️ Eroare la verificare: $e');
    return false;
  }
}

