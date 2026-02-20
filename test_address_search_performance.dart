#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;

/// 🚀 Test de performanță pentru căutarea de adrese în București
/// Măsoară timpul de răspuns și testează diferite strategii de optimizare

class AddressSearchPerformanceTest {
  static const String _userAgent = 'FriendsRide/1.0';
  static const Map<String, String> _testAddresses = {
    'Piata Unirii': 'Piata Unirii, București',
    'Gara de Nord': 'Gara de Nord, București',
    'Aeroport Otopeni': 'Aeroportul Henri Coandă, Otopeni',
    'Mall Baneasa': 'Mall Băneasa, București',
    'Universitatea': 'Piața Universității, București',
    'Piata Victoriei': 'Piața Victoriei, București',
    'Parcul Herastrau': 'Parcul Herăstrău, București',
    'Therme Bucuresti': 'Therme București, Voluntari',
    'AFI Cotroceni': 'AFI Cotroceni, București',
    'Promenada Mall': 'Promenada Mall, București',
    'Mega Mall': 'Mega Mall, București',
    'Sun Plaza': 'Sun Plaza, București',
    'Spitalul Floreasca': 'Spitalul Floreasca, București',
    'Opera Romana': 'Opera Română, București',
    'Biblioteca Nationala': 'Biblioteca Națională, București',
  };

  static const Map<String, String> _optimizedEndpoints = {
    'Nominatim Standard': 'https://nominatim.openstreetmap.org/search',
    'Nominatim Cached': 'https://nominatim.openstreetmap.org/search',
    'Google Geocoding': 'https://maps.googleapis.com/maps/api/geocode/json',
    'Mapbox Geocoding': 'https://api.mapbox.com/geocoding/v5/mapbox.places',
  };

  /// 🎯 Test principal de performanță
  static Future<void> runPerformanceTest() async {
    print('🚀 === TEST DE PERFORMANȚĂ CĂUTARE ADRESE ===');
    print('📊 Testez ${_testAddresses.length} adrese din București\n');

    final Map<String, List<SearchResult>> results = {};

    // Testează fiecare endpoint
    for (final entry in _optimizedEndpoints.entries) {
      final endpointName = entry.key;
      final endpointUrl = entry.value;
      
      print('🔍 Testez endpoint: $endpointName');
      print('📍 URL: $endpointUrl\n');

      results[endpointName] = await _testEndpoint(endpointName, endpointUrl);
      
      print('✅ Test completat pentru $endpointName\n');
      await Future.delayed(Duration(seconds: 1)); // Pauză între teste
    }

    // Analizează rezultatele
    _analyzeResults(results);
    
    // Generează recomandări de optimizare
    _generateOptimizationRecommendations(results);
  }

  /// 🧪 Testează un endpoint specific
  static Future<List<SearchResult>> _testEndpoint(String endpointName, String baseUrl) async {
    final List<SearchResult> results = [];

    for (final entry in _testAddresses.entries) {
      final query = entry.key;
      final expectedAddress = entry.value;
      
      print('  🔎 Testez: "$query"');
      
      final result = await _testSingleSearch(endpointName, baseUrl, query, expectedAddress);
      results.add(result);
      
      // Afișează rezultatul
      if (result.success) {
        print('    ✅ Succes: ${result.responseTime}ms - ${result.resultsCount} rezultate');
      } else {
        print('    ❌ Eșec: ${result.error}');
      }
      
      // Pauză mică pentru a nu suprasolicita serviciile
      await Future.delayed(Duration(milliseconds: 200));
    }

    return results;
  }

  /// 🔍 Testează o singură căutare
  static Future<SearchResult> _testSingleSearch(
    String endpointName,
    String baseUrl,
    String query,
    String expectedAddress,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      List<Map<String, dynamic>> searchResults = [];
      String? error;

      switch (endpointName) {
        case 'Nominatim Standard':
          searchResults = await _testNominatimStandard(query);
          break;
        case 'Nominatim Cached':
          searchResults = await _testNominatimOptimized(query);
          break;
        case 'Google Geocoding':
          searchResults = await _testGoogleGeocoding(query);
          break;
        case 'Mapbox Geocoding':
          searchResults = await _testMapboxGeocoding(query);
          break;
        default:
          error = 'Endpoint necunoscut: $endpointName';
      }

      stopwatch.stop();
      
      return SearchResult(
        endpoint: endpointName,
        query: query,
        success: error == null,
        responseTime: stopwatch.elapsedMilliseconds,
        resultsCount: searchResults.length,
        error: error,
        results: searchResults,
      );
      
    } catch (e) {
      stopwatch.stop();
      return SearchResult(
        endpoint: endpointName,
        query: query,
        success: false,
        responseTime: stopwatch.elapsedMilliseconds,
        resultsCount: 0,
        error: e.toString(),
        results: [],
      );
    }
  }

  /// 🌍 Test Nominatim standard
  static Future<List<Map<String, dynamic>>> _testNominatimStandard(String query) async {
    final params = {
      'q': '$query, București, România',
      'format': 'json',
      'addressdetails': '1',
      'limit': '10',
      'countrycodes': 'ro',
    };

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', params);
    final response = await http.get(uri, headers: {'User-Agent': _userAgent});
    
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final List<dynamic> data = json.decode(response.body);
    return data.cast<Map<String, dynamic>>();
  }

  /// ⚡ Test Nominatim optimizat (cu cache și viewbox)
  static Future<List<Map<String, dynamic>>> _testNominatimOptimized(String query) async {
    final params = {
      'q': '$query, București, România',
      'format': 'json',
      'addressdetails': '1',
      'limit': '10',
      'countrycodes': 'ro',
      'bounded': '1',
      'viewbox': '25.9,44.7,26.4,44.2', // București viewbox
      'dedupe': '1', // Elimină duplicatele
    };

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', params);
    final response = await http.get(uri, headers: {
      'User-Agent': _userAgent,
      'Accept': 'application/json',
      'Accept-Encoding': 'gzip, deflate',
    });
    
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final List<dynamic> data = json.decode(response.body);
    return data.cast<Map<String, dynamic>>();
  }

  /// 🗺️ Test Google Geocoding (simulat - fără API key)
  static Future<List<Map<String, dynamic>>> _testGoogleGeocoding(String query) async {
    // Simulare - în realitate ar fi nevoie de API key
    await Future.delayed(Duration(milliseconds: 100)); // Simulare delay
    throw Exception('Google Geocoding necesită API key - nu este configurat');
  }

  /// 🗺️ Test Mapbox Geocoding (simulat - fără access token)
  static Future<List<Map<String, dynamic>>> _testMapboxGeocoding(String query) async {
    // Simulare - în realitate ar fi nevoie de access token
    await Future.delayed(Duration(milliseconds: 150)); // Simulare delay
    throw Exception('Mapbox Geocoding necesită access token - nu este configurat');
  }

  /// 📊 Analizează rezultatele testelor
  static void _analyzeResults(Map<String, List<SearchResult>> results) {
    print('📊 === ANALIZA REZULTATELOR ===\n');

    for (final entry in results.entries) {
      final endpointName = entry.key;
      final endpointResults = entry.value;

      final successfulResults = endpointResults.where((r) => r.success).toList();
      final avgResponseTime = successfulResults.isNotEmpty
          ? successfulResults.map((r) => r.responseTime).reduce((a, b) => a + b) / successfulResults.length
          : 0.0;
      final successRate = (successfulResults.length / endpointResults.length) * 100;
      final avgResultsCount = successfulResults.isNotEmpty
          ? successfulResults.map((r) => r.resultsCount).reduce((a, b) => a + b) / successfulResults.length
          : 0.0;

      print('🎯 $endpointName:');
      print('   📈 Rata de succes: ${successRate.toStringAsFixed(1)}%');
      print('   ⏱️  Timp mediu de răspuns: ${avgResponseTime.toStringAsFixed(0)}ms');
      print('   🔢 Număr mediu de rezultate: ${avgResultsCount.toStringAsFixed(1)}');
      print('   ✅ Teste reușite: ${successfulResults.length}/${endpointResults.length}\n');
    }

    // Găsește cel mai rapid endpoint
    final fastestEndpoint = results.entries
        .map((e) => MapEntry(
            e.key,
            e.value.where((r) => r.success).map((r) => r.responseTime).fold(0, (a, b) => a + b) /
                e.value.where((r) => r.success).length))
        .where((e) => !e.value.isNaN)
        .reduce((a, b) => a.value < b.value ? a : b);

    print('🏆 CEL MAI RAPID ENDPOINT: ${fastestEndpoint.key} (${fastestEndpoint.value.toStringAsFixed(0)}ms medie)\n');
  }

  /// 💡 Generează recomandări de optimizare
  static void _generateOptimizationRecommendations(Map<String, List<SearchResult>> results) {
    print('💡 === RECOMANDĂRI DE OPTIMIZARE ===\n');

    // Analizează performanța Nominatim
    final nominatimResults = results['Nominatim Standard'] ?? [];
    final nominatimOptimizedResults = results['Nominatim Cached'] ?? [];

    if (nominatimResults.isNotEmpty && nominatimOptimizedResults.isNotEmpty) {
      final standardAvg = nominatimResults
          .where((r) => r.success)
          .map((r) => r.responseTime)
          .fold(0, (a, b) => a + b) /
          nominatimResults.where((r) => r.success).length;

      final optimizedAvg = nominatimOptimizedResults
          .where((r) => r.success)
          .map((r) => r.responseTime)
          .fold(0, (a, b) => a + b) /
          nominatimOptimizedResults.where((r) => r.success).length;

      final improvement = ((standardAvg - optimizedAvg) / standardAvg) * 100;

      print('🚀 OPTIMIZARE NOMINATIM:');
      print('   📊 Îmbunătățire: ${improvement.toStringAsFixed(1)}%');
      print('   ⏱️  Timp standard: ${standardAvg.toStringAsFixed(0)}ms');
      print('   ⚡ Timp optimizat: ${optimizedAvg.toStringAsFixed(0)}ms\n');
    }

    print('🎯 RECOMANDĂRI IMPLEMENTARE:');
    print('   1. 🔄 Implementează cache local pentru rezultatele frecvente');
    print('   2. ⚡ Folosește viewbox pentru căutări în București');
    print('   3. 📱 Adaugă debouncing (200ms) pentru input-uri rapide');
    print('   4. 🗂️  Prioritizează rezultatele din București');
    print('   5. 📊 Implementează fallback către multiple surse');
    print('   6. 🎯 Cache pentru adresele salvate de utilizator');
    print('   7. 🔍 Sugestii inteligente bazate pe istoric\n');
  }
}

/// 📋 Rezultat al unui test de căutare
class SearchResult {
  final String endpoint;
  final String query;
  final bool success;
  final int responseTime;
  final int resultsCount;
  final String? error;
  final List<Map<String, dynamic>> results;

  SearchResult({
    required this.endpoint,
    required this.query,
    required this.success,
    required this.responseTime,
    required this.resultsCount,
    this.error,
    required this.results,
  });
}

/// 🚀 Punct de intrare
void main() async {
  try {
    await AddressSearchPerformanceTest.runPerformanceTest();
    print('✅ Test de performanță completat cu succes!');
  } catch (e) {
    print('❌ Eroare în testul de performanță: $e');
    exit(1);
  }
}
