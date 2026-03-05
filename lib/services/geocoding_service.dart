
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:friendsride_app/utils/logger.dart';

// Sugestie adresă cu coordonate și distanță (pentru afișare rapidă și selectare fără geocodificare suplimentară)
class AddressSuggestion {
  final String description;
  final double latitude;
  final double longitude;
  final int score;
  double? distanceMeters;
  final String? mapboxId; // optional, retained for compatibility

  AddressSuggestion({
    required this.description,
    required this.latitude,
    required this.longitude,
    this.score = 0,
    this.distanceMeters,
    this.mapboxId,
  });
}

class GeocodingService {
  // ✅ CACHE PENTRU GEOCODING
  final Map<String, _CachedGeocodeResult> _geocodeCache = {};
  static const Duration _cacheExpiry = Duration(hours: 24);
  
  // Sugestii OSM Nominatim (autocomplete-like) cu normalizare română și scorare
  Future<List<AddressSuggestion>> fetchSuggestions(String query, geolocator.Position currentUserPosition) async {
    if (query.trim().length < 2) {
      return [];
    }

    // ✅ VERIFICĂ CACHE
    final cacheKey = query.toLowerCase().trim();
    final cached = _geocodeCache[cacheKey];
    if (cached != null && !cached.isExpired) {
      Logger.debug('GeocodingService: Cache hit for: $query');
      return cached.suggestions;
    }

    // ✅ RETRY LOGIC cu exponential backoff
    return await _fetchSuggestionsWithRetry(query, currentUserPosition, cacheKey);
  }
  
  // ✅ NOU: Fetch cu retry logic
  Future<List<AddressSuggestion>> _fetchSuggestionsWithRetry(
    String query,
    geolocator.Position currentUserPosition,
    String cacheKey, {
    int maxRetries = 3,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final parsed = await _performGeocodingRequest(query, currentUserPosition);
        
        // ✅ SALVEAZĂ ÎN CACHE
        if (parsed.isNotEmpty) {
          _geocodeCache[cacheKey] = _CachedGeocodeResult(
            suggestions: parsed,
            timestamp: DateTime.now(),
          );
        }
        
        return parsed;
      } on TimeoutException catch (e) {
        Logger.error('OSM geocoding timeout (attempt $attempt/$maxRetries): $e', error: e);
        if (attempt == maxRetries) {
          return [];
        }
        // ✅ EXPONENTIAL BACKOFF
        await Future.delayed(Duration(seconds: attempt * 2));
      } catch (e) {
        Logger.error('OSM geocoding error (attempt $attempt/$maxRetries): $e', error: e);
        if (attempt == maxRetries) {
          return [];
        }
        // ✅ EXPONENTIAL BACKOFF
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    
    return [];
  }
  
  // ✅ Helper method pentru fetch (extras din try block)
  Future<List<AddressSuggestion>> _performGeocodingRequest(
    String query,
    geolocator.Position currentUserPosition,
  ) async {
    // Normalizează interogarea similar cu Google STT
    final String normalizedQuery = _normalizeRomanianAddress(query);

    // Context geografic: dacă ești aproape de București, adaugă bias și viewbox
    final double distanceToBucharest = geolocator.Geolocator.distanceBetween(
      currentUserPosition.latitude,
      currentUserPosition.longitude,
      44.4268,
      26.1025,
    );

    final bool nearBucharest = distanceToBucharest < 50000; // 50km
    final String contextualQuery = nearBucharest
        ? '$normalizedQuery, București, România'
        : '$normalizedQuery, România';

    final Map<String, String> params = <String, String>{
      'q': contextualQuery,
      'format': 'json',
      'addressdetails': '1',
      'limit': '10',
      'countrycodes': 'ro',
    };

    // Viewbox pentru București (lon,lat order: left, top, right, bottom)
    if (nearBucharest) {
      params['bounded'] = '1';
      params['viewbox'] = '25.9,44.7,26.4,44.2';
    }

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', params);
    
    // ✅ TIMEOUT PENTRU GEOCODING (10 secunde)
    final response = await http.get(uri, headers: const {'User-Agent': 'FriendsRide/1.0'})
      .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Geocoding timeout pentru: $query');
        },
      );
    
    if (response.statusCode != 200) {
      return [];
    }

    final List<dynamic> data = json.decode(response.body) as List<dynamic>;
    return _parseOSMResults(
      data,
      normalizedQuery,
      currentUserPosition,
    );
  }

  // ✅ NOU: Metoda pentru obținerea adresei din coordonate (cu retry)
  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        final request = 'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json&addressdetails=1';
        
        final response = await http.get(
          Uri.parse(request),
          headers: const {'User-Agent': 'FriendsRide/1.0'},
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Reverse geocoding timeout');
          },
        );
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return data['display_name'] as String?;
        }
        
        if (attempt == 3) {
          return null;
        }
        await Future.delayed(Duration(seconds: attempt * 2));
      } on TimeoutException catch (e) {
        Logger.error('Reverse geocoding timeout (attempt $attempt/3): $e', error: e);
        if (attempt == 3) {
          return null;
        }
        await Future.delayed(Duration(seconds: attempt * 2));
      } catch (e) {
        Logger.error('Reverse geocoding error (attempt $attempt/3): $e', error: e);
        if (attempt == 3) {
          return null;
        }
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    
    return null;
  }

  // --- Helpers ---
  String _normalizeRomanianAddress(String input) {
    String normalized = input.toLowerCase().trim();
    normalized = normalized
        .replaceAll('ă', 'a')
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('ș', 's')
        .replaceAll('ş', 's')
        .replaceAll('ț', 't')
        .replaceAll('ţ', 't');

    final Map<String, String> abbreviations = <String, String>{
      r'\bsos\b': 'soseaua',
      r'\bstr\b': 'strada',
      r'\bstrada\b': 'strada',
      r'\bbd\b': 'bulevardul',
      r'\bbul\b': 'bulevardul',
      r'\bpiata\b': 'piata',
      r'\bpl\b': 'piata',
      r'\bcalea\b': 'calea',
      r'\bnr\b': 'numarul',
      r'\bbl\b': 'blocul',
      r'\bsc\b': 'scara',
      r'\bet\b': 'etajul',
      r'\bap\b': 'apartamentul',
    };

    abbreviations.forEach((String pattern, String replacement) {
      normalized = normalized.replaceAll(RegExp(pattern), replacement);
    });

    return normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  List<AddressSuggestion> _parseOSMResults(
    List<dynamic> data,
    String originalQuery,
    geolocator.Position currentUserPosition,
  ) {
    final List<AddressSuggestion> suggestions = <AddressSuggestion>[];
    final List<String> queryWords = originalQuery.split(' ').where((w) => w.isNotEmpty).toList();

    for (final dynamic item in data) {
      final Map<String, dynamic> m = item as Map<String, dynamic>;
      final String displayName = (m['display_name'] as String?) ?? '';
      final double lat = double.tryParse((m['lat'] ?? '').toString()) ?? 0.0;
      final double lon = double.tryParse((m['lon'] ?? '').toString()) ?? 0.0;
      if (lat == 0.0 && lon == 0.0) continue;

      // Scor pe bază de potrivire a cuvintelor cheie
      int score = 0;
      final String lowerDisplay = displayName.toLowerCase();
      for (final String word in queryWords) {
        if (lowerDisplay.contains(word)) {
          score += word.length > 3 ? 10 : 5;
        }
      }
      if (lowerDisplay.contains('bucurești') || lowerDisplay.contains('bucharest')) {
        score += 20;
      }

      final double distance = geolocator.Geolocator.distanceBetween(
        currentUserPosition.latitude,
        currentUserPosition.longitude,
        lat,
        lon,
      );

      suggestions.add(AddressSuggestion(
        description: _formatAddressDisplay(displayName),
        latitude: lat,
        longitude: lon,
        score: score,
        distanceMeters: distance,
      ));
    }

    suggestions.sort((a, b) {
      final int cs = b.score.compareTo(a.score);
      if (cs != 0) return cs;
      return (a.distanceMeters ?? double.infinity).compareTo(b.distanceMeters ?? double.infinity);
    });

    return suggestions.take(8).toList();
  }

  String _formatAddressDisplay(String displayName) {
    final List<String> parts = displayName.split(', ');
    if (parts.length >= 2) {
      return '${parts[0]}, ${parts[1]}';
    }
    return displayName;
  }
}

// ✅ CLASĂ PENTRU CACHE (top-level)
class _CachedGeocodeResult {
  final List<AddressSuggestion> suggestions;
  final DateTime timestamp;
  
  _CachedGeocodeResult({
    required this.suggestions,
    required this.timestamp,
  });
  
  bool get isExpired {
    return DateTime.now().difference(timestamp) > GeocodingService._cacheExpiry;
  }
}
