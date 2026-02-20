// ignore_for_file: avoid_print
// 🧪 MAPBOX CONFIGURATION TEST SCRIPT
// Run with: dart test_mapbox_config.dart

import 'lib/utils/mapbox_config.dart';

void main() {
  print('🧪 TESTING MAPBOX CONFIGURATION...\n');
  
  // Test 1: Configuration Status
  print('📋 TEST 1: Configuration Status');
  MapboxConfig.showConfigurationStatus();
  
  // Test 2: Token Validation
  print('\n📋 TEST 2: Token Validation');
  try {
    final token = MapboxConfig.getAccessToken();
    print('✅ Token retrieved successfully');
    print('✅ Token format: ${token.substring(0, 10)}...');
    print('✅ Token length: ${token.length} characters');
    
    // Basic validation
    if (token.startsWith('pk.')) {
      print('✅ Token format is valid (starts with pk.)');
    } else {
      print('❌ Token format is invalid (should start with pk.)');
    }
    
  } catch (e) {
    print('❌ Token validation failed:');
    print(e.toString());
  }
  
  // Test 3: Configuration Values
  print('\n📋 TEST 3: Configuration Values');
  print('🔧 Default zoom: ${MapboxConfig.defaultZoom}');
  print('🔧 Min zoom: ${MapboxConfig.minZoom}');
  print('🔧 Max zoom: ${MapboxConfig.maxZoom}');
  print('🔧 Default profile: ${MapboxConfig.defaultProfile}');
  print('🔧 Available profiles: ${MapboxConfig.availableProfiles}');
  print('🔧 3D Buildings: ${MapboxConfig.enable3DBuildings}');
  print('🔧 Traffic: ${MapboxConfig.enableTraffic}');
  
  // Test 4: API URLs
  print('\n📋 TEST 4: API URLs');
  try {
    print('🌐 Directions API: ${MapboxConfig.directionsApiUrl}');
    print('🌐 Geocoding API: ${MapboxConfig.geocodingApiUrl}');
    print('🌐 Places API: ${MapboxConfig.placesApiUrl}');
    print('✅ All API URLs generated successfully');
  } catch (e) {
    print('❌ API URL generation failed: $e');
  }
  
  // Test 5: Style URLs
  print('\n📋 TEST 5: Style URLs');
  print('🎨 Light style: ${MapboxConfig.getStyleUrl(isDark: false)}');
  print('🎨 Dark style: ${MapboxConfig.getStyleUrl(isDark: true)}');
  
  print('\n🎯 TESTING COMPLETE!');
  print('📋 If all tests pass, your Mapbox configuration is ready!');
  print('🚀 Next: Run "flutter run" to test in the app');
}
