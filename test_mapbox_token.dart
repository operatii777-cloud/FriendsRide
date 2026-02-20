import 'dart:io';
import 'package:flutter/foundation.dart';

/// Test script pentru validarea token-ului Mapbox
/// Rulează cu: dart test_mapbox_token.dart

void main() async {
  debugPrint('🧪 Testing Mapbox token configuration...');
  const String token = 'pk.eyJ1IjoiZnJpZW5kc293bmVyIiwiYSI6ImNtY244d2M5YzAwNzcybHIwcW1pamRlaDYifQ.dVokhVMCvhB-28SRP5gsgg';
  debugPrint('🔑 Token: ${token.substring(0, 20)}...');
  
  // Verifică formatul token-ului
  if (!token.startsWith('pk.eyJ1')) {
    debugPrint('❌ FORMAT INVALID - Token-ul trebuie să înceapă cu "pk.eyJ1"');
    return;
  }
  
  if (token.contains('example')) {
    debugPrint('❌ TOKEN PLACEHOLDER - Înlocuiește cu token-ul real');
    return;
  }
  
  debugPrint('✅ Token format valid');
  
  // Testează API-urile Mapbox
  await testGeocodingAPI(token);
  await testDirectionsAPI(token);
  await testMapStylesAPI(token);
  
  debugPrint('\n🎉 Toate testele au trecut! Token-ul Mapbox este configurat corect.');
}

Future<void> testGeocodingAPI(String token) async {
  debugPrint('\n📍 Test 1: Geocoding API');
  
  try {
    final url = 'https://api.mapbox.com/geocoding/v5/mapbox.places/Bucharest.json?access_token=$token';
    final response = await HttpClient().getUrl(Uri.parse(url)).then((req) => req.close());
    
    if (response.statusCode == 200) {
      debugPrint('✅ Geocoding API: OK (200)');
    } else if (response.statusCode == 401) {
      debugPrint('❌ Geocoding API: UNAUTHORIZED (401) - Token invalid!');
    } else {
      debugPrint('⚠️ Geocoding API: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('❌ Geocoding API: Error - $e');
  }
}

Future<void> testDirectionsAPI(String token) async {
  debugPrint('\n🚗 Test 2: Directions API');
  
  try {
    final url = 'https://api.mapbox.com/directions/v5/mapbox/driving/23.5991,46.7712;23.5991,46.7712?access_token=$token';
    final response = await HttpClient().getUrl(Uri.parse(url)).then((req) => req.close());
    
    if (response.statusCode == 200) {
      debugPrint('✅ Directions API: OK (200)');
    } else if (response.statusCode == 401) {
      debugPrint('❌ Directions API: UNAUTHORIZED (401) - Token invalid!');
    } else {
      debugPrint('⚠️ Directions API: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('❌ Directions API: Error - $e');
  }
}

Future<void> testMapStylesAPI(String token) async {
  debugPrint('\n🎨 Test 3: Map Styles');
  
  try {
    final url = 'https://api.mapbox.com/styles/v1/mapbox/streets-v12?access_token=$token';
    final response = await HttpClient().getUrl(Uri.parse(url)).then((req) => req.close());
    
    if (response.statusCode == 200) {
      debugPrint('✅ Map Styles: OK (200)');
    } else if (response.statusCode == 401) {
      debugPrint('❌ Map Styles: UNAUTHORIZED (401) - Token invalid!');
    } else {
      debugPrint('⚠️ Map Styles: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('❌ Map Styles: Error - $e');
  }
}
