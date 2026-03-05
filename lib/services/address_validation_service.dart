import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:friendsride_app/utils/logger.dart';

/// 🏠 AddressValidationService - Serviciu complet pentru validarea și geocodarea adreselor
/// 
/// Oferă:
/// - ✅ Validare în timp real pentru adrese introduse prin text sau voce
/// - 🌍 Geocoding cu multiple surse (Google, OpenStreetMap, local)
/// - 📍 Extragerea coordonatelor geografice
/// - 🔍 Sugestii de adrese cu autocompletare
/// - 🎯 Validare pentru România cu prioritizare locală
/// - ⚡ Cache și optimizări pentru performanță
class AddressValidationService {
  static final AddressValidationService _instance = AddressValidationService._internal();
  factory AddressValidationService() => _instance;
  AddressValidationService._internal();

  // Cache pentru rezultatele de geocoding (evită duplicate requests)
  final Map<String, AddressValidationResult> _validationCache = {};
  final Map<String, List<AddressSuggestion>> _suggestionsCache = {};
  
  // Timer pentru debouncing
  Timer? _debounceTimer;
  
  // Starea validării curente
  AddressValidationState _currentState = AddressValidationState.idle;
  String? _currentValidationMessage;

  // Getters pentru starea curentă
  AddressValidationState get currentState => _currentState;
  String? get currentValidationMessage => _currentValidationMessage;

  /// 🎤 Validează o adresă introdusă prin voce sau text
  /// 
  /// [address] - Adresa de validat
  /// [isVoiceInput] - Dacă e input vocal (pentru optimizări)
  /// [timeoutSeconds] - Timeout pentru validare
  Future<AddressValidationResult> validateAddress({
    required String address,
    bool isVoiceInput = false,
    int timeoutSeconds = 10,
  }) async {
    if (address.trim().isEmpty) {
      return AddressValidationResult.invalid(
        message: 'Adresa nu poate fi goală',
        suggestions: [],
      );
    }

    if (address.length < 3) {
      return AddressValidationResult.invalid(
        message: 'Adresa trebuie să aibă cel puțin 3 caractere',
        suggestions: [],
      );
    }

    // Verifică cache-ul pentru rezultate rapide
    final cacheKey = address.toLowerCase().trim();
    if (_validationCache.containsKey(cacheKey)) {
      Logger.debug('AddressValidationService: Cache hit for: $address');
      return _validationCache[cacheKey]!;
    }

    // Actualizează starea
    _updateState(AddressValidationState.validating, 'Validând adresa...');

    try {
      // 1. Încearcă geocoding-ul local (Google) - cel mai rapid
      AddressValidationResult? localResult = await _tryLocalGeocoding(address, timeoutSeconds);
      if (localResult != null && localResult.isValid) {
        _cacheResult(cacheKey, localResult);
        _updateState(AddressValidationState.valid, 'Adresa validată cu succes');
        return localResult;
      }

      // 2. Încearcă OpenStreetMap (gratuit, bun pentru România)
      AddressValidationResult? osmResult = await _tryOpenStreetMapGeocoding(address, timeoutSeconds);
      if (osmResult != null && osmResult.isValid) {
        _cacheResult(cacheKey, osmResult);
        _updateState(AddressValidationState.valid, 'Adresa validată cu succes');
        return osmResult;
      }

      // 3. Încearcă geocoding-ul cu sugestii
      AddressValidationResult? suggestionResult = await _trySuggestionBasedValidation(address, timeoutSeconds);
      if (suggestionResult != null) {
        _cacheResult(cacheKey, suggestionResult);
        _updateState(
          suggestionResult.isValid ? AddressValidationState.valid : AddressValidationState.needsClarification,
          suggestionResult.message,
        );
        return suggestionResult;
      }

      // 4. Dacă nimic nu a funcționat
      final invalidResult = AddressValidationResult.invalid(
        message: 'Nu s-a putut valida adresa. Încearcă să fii mai specific.',
        suggestions: [],
      );
      
      _cacheResult(cacheKey, invalidResult);
      _updateState(AddressValidationState.invalid, invalidResult.message);
      return invalidResult;

    } catch (e) {
      Logger.error('AddressValidationService: Validation error: $e', error: e);
      
      final errorResult = AddressValidationResult.invalid(
        message: 'Eroare la validarea adresei: $e',
        suggestions: [],
      );
      
      _cacheResult(cacheKey, errorResult);
      _updateState(AddressValidationState.error, errorResult.message);
      return errorResult;
    }
  }

  /// 🌍 Încearcă geocoding-ul local cu Google
  Future<AddressValidationResult?> _tryLocalGeocoding(String address, int timeoutSeconds) async {
    try {
      final locations = await locationFromAddress(address)
          .timeout(Duration(seconds: timeoutSeconds));

      if (locations.isNotEmpty) {
        final location = locations.first;
        final point = Point(coordinates: Position(location.longitude, location.latitude));
        
        return AddressValidationResult.valid(
          address: address,
          coordinates: point,
          confidence: 0.9,
          source: 'Google Geocoding',
          suggestions: [],
        );
      }
    } catch (e) {
      Logger.error('AddressValidationService: Local geocoding failed: $e', error: e);
    }
    return null;
  }

  /// 🗺️ Încearcă geocoding-ul cu OpenStreetMap
  Future<AddressValidationResult?> _tryOpenStreetMapGeocoding(String address, int timeoutSeconds) async {
    try {
      // Adaugă "România" la adresă dacă nu e specificat
      final fullAddress = address.toLowerCase().contains('românia') || 
                          address.toLowerCase().contains('romania')
        ? address 
        : '$address, România';
      
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(fullAddress)}'
        '&format=json'
        '&limit=1'
        '&countrycodes=ro'
        '&addressdetails=1'
      );
      
      final response = await http.get(url).timeout(Duration(seconds: timeoutSeconds));
      
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        
        if (data.isNotEmpty) {
          final result = data.first;
          final lat = double.parse(result['lat'].toString());
          final lon = double.parse(result['lon'].toString());
          final displayName = result['display_name'] as String;
          
          final point = Point(coordinates: Position(lon, lat));
          
          return AddressValidationResult.valid(
            address: displayName,
            coordinates: point,
            confidence: 0.8,
            source: 'OpenStreetMap',
            suggestions: [],
          );
        }
      }
    } catch (e) {
      Logger.error('AddressValidationService: OSM geocoding failed: $e', error: e);
    }
    return null;
  }

  /// 🔍 Încearcă validarea bazată pe sugestii
  Future<AddressValidationResult?> _trySuggestionBasedValidation(String address, int timeoutSeconds) async {
    try {
      final suggestions = await getAddressSuggestions(address, timeoutSeconds: timeoutSeconds);
      
      if (suggestions.isNotEmpty) {
        // Găsește cea mai bună potrivire
        final bestMatch = _findBestMatch(address, suggestions);
        
        if (bestMatch != null) {
          // Încearcă să geocodeze cea mai bună sugestie
          final validationResult = await _tryLocalGeocoding(bestMatch, timeoutSeconds);
          if (validationResult != null && validationResult.isValid) {
            return AddressValidationResult.valid(
              address: validationResult.address!,
              coordinates: validationResult.coordinates!,
              confidence: 0.7,
              source: 'Suggestion-based',
              suggestions: suggestions,
            );
          }
        }
        
        // Returnează rezultat cu sugestii dacă nu s-a putut geocoda
        return AddressValidationResult.needsClarification(
          message: 'Alege o adresă din sugestii:',
          suggestions: suggestions,
        );
      }
    } catch (e) {
      Logger.error('AddressValidationService: Suggestion validation failed: $e', error: e);
    }
    return null;
  }

  /// 🔍 Găsește cea mai bună potrivire între adresa introdusă și sugestii
  String? _findBestMatch(String input, List<AddressSuggestion> suggestions) {
    if (suggestions.isEmpty) return null;
    
    final inputLower = input.toLowerCase();
    
    // 1. Caută potrivire exactă
    for (final suggestion in suggestions) {
      if (suggestion.description.toLowerCase() == inputLower) {
        return suggestion.description;
      }
    }
    
    // 2. Caută potrivire parțială
    for (final suggestion in suggestions) {
      if (suggestion.description.toLowerCase().contains(inputLower) ||
          inputLower.contains(suggestion.description.toLowerCase())) {
        return suggestion.description;
      }
    }
    
    // 3. Returnează prima sugestie dacă nu s-a găsit nimic
    return suggestions.first.description;
  }

  /// 📍 Obține sugestii de adrese pentru autocompletare
  Future<List<AddressSuggestion>> getAddressSuggestions(
    String input, {
    int timeoutSeconds = 5,
  }) async {
    if (input.trim().isEmpty || input.length < 3) {
      return [];
    }

    final cacheKey = 'suggestions_${input.toLowerCase().trim()}';
    if (_suggestionsCache.containsKey(cacheKey)) {
      return _suggestionsCache[cacheKey]!;
    }

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(input)}'
        '&format=json'
        '&limit=5'
        '&countrycodes=ro'
        '&addressdetails=1'
      );
      
      final response = await http.get(url).timeout(Duration(seconds: timeoutSeconds));
      
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        final suggestions = data.map((json) => AddressSuggestion.fromJson(json)).toList();
        
        // Cache rezultatul
        _suggestionsCache[cacheKey] = suggestions;
        
        return suggestions;
      }
    } catch (e) {
      Logger.error('AddressValidationService: Suggestions failed: $e', error: e);
    }
    
    return [];
  }

  /// 🎯 Validează o adresă cu feedback vizual în timp real
  /// 
  /// Perfect pentru integrarea cu VoiceInputButton și câmpurile de input
  Stream<AddressValidationResult> validateAddressStream({
    required String address,
    bool isVoiceInput = false,
    Duration debounceTime = const Duration(milliseconds: 500),
  }) async* {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }

    _debounceTimer = Timer(debounceTime, () async {
      final result = await validateAddress(
        address: address,
        isVoiceInput: isVoiceInput,
      );
      
      // Stream-ul va fi implementat prin callback-uri în UI
      // Aici doar actualizăm starea
      _updateState(
        result.isValid ? AddressValidationState.valid : AddressValidationState.invalid,
        result.message,
      );
    });

    // Returnează starea curentă imediat
    yield AddressValidationResult.validating(
      message: 'Se validează adresa...',
      suggestions: [],
    );
  }

  /// 🧹 Curăță cache-ul pentru a elibera memoria
  void clearCache() {
    _validationCache.clear();
    _suggestionsCache.clear();
    Logger.debug('AddressValidationService: Cache cleared');
  }

  /// 💾 Cache un rezultat de validare
  void _cacheResult(String key, AddressValidationResult result) {
    // Limitează dimensiunea cache-ului
    if (_validationCache.length > 100) {
      final oldestKey = _validationCache.keys.first;
      _validationCache.remove(oldestKey);
    }
    
    _validationCache[key] = result;
  }

  /// 🔄 Actualizează starea validării
  void _updateState(AddressValidationState state, String? message) {
    _currentState = state;
    _currentValidationMessage = message;
    Logger.debug('AddressValidationService: State updated to $state: $message');
  }

  /// 🧹 Cleanup
  void dispose() {
    _debounceTimer?.cancel();
    clearCache();
  }
}

/// 🎯 Rezultatul validării unei adrese
class AddressValidationResult {
  final bool isValid;
  final String? address;
  final Point? coordinates;
  final double confidence;
  final String? source;
  final String message;
  final List<AddressSuggestion> suggestions;
  final AddressValidationState state;

  const AddressValidationResult._({
    required this.isValid,
    this.address,
    this.coordinates,
    this.confidence = 0.0,
    this.source,
    required this.message,
    required this.suggestions,
    required this.state,
  });

  /// ✅ Adresa validă cu coordonate
  factory AddressValidationResult.valid({
    required String address,
    required Point coordinates,
    double confidence = 1.0,
    String? source,
    List<AddressSuggestion> suggestions = const [],
  }) {
    return AddressValidationResult._(
      isValid: true,
      address: address,
      coordinates: coordinates,
      confidence: confidence,
      source: source,
      message: 'Adresa validată cu succes',
      suggestions: suggestions,
      state: AddressValidationState.valid,
    );
  }

  /// ❌ Adresa invalidă
  factory AddressValidationResult.invalid({
    required String message,
    List<AddressSuggestion> suggestions = const [],
  }) {
    return AddressValidationResult._(
      isValid: false,
      message: message,
      suggestions: suggestions,
      state: AddressValidationState.invalid,
    );
  }

  /// 🔍 Adresa necesită clarificare (sugestii disponibile)
  factory AddressValidationResult.needsClarification({
    required String message,
    required List<AddressSuggestion> suggestions,
  }) {
    return AddressValidationResult._(
      isValid: false,
      message: message,
      suggestions: suggestions,
      state: AddressValidationState.needsClarification,
    );
  }

  /// ⏳ Adresa se validează
  factory AddressValidationResult.validating({
    required String message,
    List<AddressSuggestion> suggestions = const [],
  }) {
    return AddressValidationResult._(
      isValid: false,
      message: message,
      suggestions: suggestions,
      state: AddressValidationState.validating,
    );
  }

  /// 🚨 Eroare la validare
  factory AddressValidationResult.error({
    required String message,
    List<AddressSuggestion> suggestions = const [],
  }) {
    return AddressValidationResult._(
      isValid: false,
      message: message,
      suggestions: suggestions,
      state: AddressValidationState.error,
    );
  }
}

/// 🔄 Stările posibile ale validării
enum AddressValidationState {
  idle,           // Inactiv
  validating,     // Se validează
  valid,          // Valid
  invalid,        // Invalid
  needsClarification, // Necesită clarificare
  error,          // Eroare
}

/// 🔍 Sugestie de adresă pentru autocompletare
class AddressSuggestion {
  final String description;
  final String placeId;
  final double? latitude;
  final double? longitude;
  final String? type;
  final double? importance;

  const AddressSuggestion({
    required this.description,
    required this.placeId,
    this.latitude,
    this.longitude,
    this.type,
    this.importance,
  });

  factory AddressSuggestion.fromJson(Map<String, dynamic> json) {
    return AddressSuggestion(
      description: json['display_name'] ?? 'Adresă necunoscută',
      placeId: json['place_id']?.toString() ?? '',
      latitude: json['lat'] != null ? double.tryParse(json['lat'].toString()) : null,
      longitude: json['lon'] != null ? double.tryParse(json['lon'].toString()) : null,
      type: json['type'],
      importance: json['importance'] != null ? double.tryParse(json['importance'].toString()) : null,
    );
  }

  /// 🎯 Convertește sugestia într-un Point pentru hartă
  Point? toPoint() {
    if (latitude != null && longitude != null) {
      return Point(coordinates: Position(longitude!, latitude!));
    }
    return null;
  }
}
