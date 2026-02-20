/// 🧪 HELPER PENTRU MODUL DE TESTARE
/// 
/// Acest helper permite testarea aplicației fără autentificare reală,
/// simulând utilizatori și curse pentru testare rapidă.
library;

import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class TestModeHelper {
  static const bool _isTestMode = bool.fromEnvironment('TEST_MODE', defaultValue: false);
  
  /// Verifică dacă aplicația rulează în modul de testare
  static bool get isTestMode => _isTestMode || kDebugMode;
  
  /// Conturi de test predefinite
  static const Map<String, Map<String, String>> testAccounts = {
    'passenger': {
      'email': 'pasager.test@friendsride.ro',
      'password': 'Test123456',
      'name': 'Pasager Test',
      'role': 'passenger',
    },
    'driver': {
      'email': 'sofer.test@friendsride.ro',
      'password': 'Test123456',
      'name': 'Șofer Test',
      'role': 'driver',
    },
  };
  
  /// Coordonate pentru ruta de test
  static const Map<String, String> testRouteAddresses = {
    'pickup': 'Prelungirea Ghencea 45 bloc D4, București',
    'destination': 'Aeroport Otopeni - Sosiri, București',
  };
  
  static const Map<String, Map<String, double>> testRouteCoordinates = {
    'pickup': {
      'lat': 44.4268,
      'lng': 26.1025,
    },
    'destination': {
      'lat': 44.5711,
      'lng': 26.0858,
    },
  };
  
  /// Autentificare rapidă cu cont de test
  static Future<UserCredential?> quickLogin(String accountType) async {
    if (!isTestMode) {
      debugPrint('⚠️ Test mode is disabled. Set TEST_MODE=true to enable.');
      return null;
    }
    
    final account = testAccounts[accountType];
    if (account == null) {
      debugPrint('❌ Invalid account type: $accountType');
      return null;
    }
    
    try {
      final auth = FirebaseAuth.instance;
      
      // Încearcă să se logheze
      try {
        final credential = await auth.signInWithEmailAndPassword(
          email: account['email']!,
          password: account['password']!,
        );
        debugPrint('✅ Quick login successful: ${account['email']}');
        return credential;
      } catch (e) {
        // Dacă contul nu există, îl creează
        debugPrint('📝 Account does not exist, creating...');
        final credential = await auth.createUserWithEmailAndPassword(
          email: account['email']!,
          password: account['password']!,
        );
        
        // Creează profilul utilizatorului
        await _createTestUserProfile(credential.user!.uid, account);
        
        debugPrint('✅ Test account created and logged in: ${account['email']}');
        return credential;
      }
    } catch (e) {
      debugPrint('❌ Quick login error: $e');
      return null;
    }
  }
  
  /// Creează profilul utilizatorului de test
  static Future<void> _createTestUserProfile(String uid, Map<String, String> account) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'id': uid,
        'email': account['email'],
        'displayName': account['name'],
        'role': account['role'],
        'createdAt': FieldValue.serverTimestamp(),
        'isTestAccount': true,
      });
      debugPrint('✅ Test user profile created');
    } catch (e) {
      debugPrint('❌ Error creating test user profile: $e');
    }
  }
  
  /// Creează o cursă de test
  static Future<String?> createTestRide({
    required String passengerId,
    String? driverId,
  }) async {
    if (!isTestMode) {
      debugPrint('⚠️ Test mode is disabled');
      return null;
    }
    
    try {
      final rideData = {
        'passengerId': passengerId,
        'driverId': driverId,
        'startAddress': testRouteAddresses['pickup'],
        'destinationAddress': testRouteAddresses['destination'],
        'startLatitude': testRouteCoordinates['pickup']!['lat'],
        'startLongitude': testRouteCoordinates['pickup']!['lng'],
        'destinationLatitude': testRouteCoordinates['destination']!['lat'],
        'destinationLongitude': testRouteCoordinates['destination']!['lng'],
        'status': driverId != null ? 'accepted' : 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'isTestRide': true,
      };
      
      final docRef = await FirebaseFirestore.instance
          .collection('rides')
          .add(rideData);
      
      debugPrint('✅ Test ride created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating test ride: $e');
      return null;
    }
  }
  
  /// Simulează mișcarea șoferului către destinație
  static Future<void> simulateDriverMovement({
    required String driverId,
    required double targetLat,
    required double targetLng,
    int steps = 10,
  }) async {
    if (!isTestMode) {
      debugPrint('⚠️ Test mode is disabled');
      return;
    }
    
    try {
      final startLat = testRouteCoordinates['pickup']!['lat']!;
      final startLng = testRouteCoordinates['pickup']!['lng']!;
      
      final latStep = (targetLat - startLat) / steps;
      final lngStep = (targetLng - startLng) / steps;
      
      for (int i = 0; i <= steps; i++) {
        final currentLat = startLat + (latStep * i);
        final currentLng = startLng + (lngStep * i);
        
        await FirebaseFirestore.instance
            .collection('driver_locations')
            .doc(driverId)
            .set({
          'position': GeoPoint(currentLat, currentLng),
          'bearing': _calculateBearing(
            startLat + (latStep * (i - 1)),
            startLng + (lngStep * (i - 1)),
            currentLat,
            currentLng,
          ),
          'timestamp': FieldValue.serverTimestamp(),
        });
        
        debugPrint('📍 Driver position updated: $currentLat, $currentLng');
        await Future.delayed(Duration(milliseconds: 500));
      }
      
      debugPrint('✅ Driver movement simulation completed');
    } catch (e) {
      debugPrint('❌ Error simulating driver movement: $e');
    }
  }
  
  /// Calculează bearing-ul între două puncte
  static double _calculateBearing(double lat1, double lng1, double lat2, double lng2) {
    final dLng = (lng2 - lng1) * (math.pi / 180);
    final lat1Rad = lat1 * (math.pi / 180);
    final lat2Rad = lat2 * (math.pi / 180);
    
    final y = math.sin(dLng) * math.cos(lat2Rad);
    final x = math.cos(lat1Rad) * math.sin(lat2Rad) - 
              math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(dLng);
    
    final bearing = (math.atan2(y, x) * (180 / math.pi) + 360) % 360;
    return bearing;
  }
}

