// lib/widgets/address_input_view.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:friendsride_app/models/ride_model.dart';
import 'package:friendsride_app/models/saved_address_model.dart';
import 'package:friendsride_app/models/stop_location.dart';
import 'package:friendsride_app/screens/map_picker_screen.dart';
import 'package:friendsride_app/screens/manage_addresses_screen.dart';
import 'package:friendsride_app/screens/add_address_screen.dart';
import 'package:friendsride_app/services/firestore_service.dart';
import 'package:friendsride_app/services/geocoding_service.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:geocoding/geocoding.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:friendsride_app/widgets/voice_input_button.dart';
import 'package:provider/provider.dart';
import 'package:friendsride_app/voice/integration/friendsride_voice_integration.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:friendsride_app/l10n/app_localizations.dart';
import 'package:friendsride_app/utils/logger.dart';

class AddressInputView extends StatefulWidget {
  final ScrollController scrollController;
  final geolocator.Position startPosition;
  final Function(Point startPoint, Point endPoint, String startAddress, String destAddress) onDestinationSelected;
  
  final List<StopLocation> stops;
  final Function(StopLocation) onStopAdded;
  final Function(int) onStopRemoved;

  const AddressInputView({
    super.key,
    required this.scrollController,
    required this.startPosition,
    required this.onDestinationSelected,
    required this.stops,
    required this.onStopAdded,
    required this.onStopRemoved,
  });

  @override
  State<AddressInputView> createState() => _AddressInputViewState();
}

class _AddressInputViewState extends State<AddressInputView> {
  static const double _leftGutterWidth = 24.0;
  final _startAddressController = TextEditingController();
  final _destinationAddressController = TextEditingController();
  final FocusNode _destinationFocusNode = FocusNode();
  final FocusNode _startFocusNode = FocusNode();

  final List<TextEditingController> _stopControllers = <TextEditingController>[];
  final List<FocusNode> _stopFocusNodes = <FocusNode>[];
  int? _activeStopIndex;

  final GeocodingService _geocodingService = GeocodingService();
  final FirestoreService _firestoreService = FirestoreService();

  List<AddressSuggestion> _suggestions = <AddressSuggestion>[];
  List<LocalSuggestion> _localMatches = <LocalSuggestion>[];
  Timer? _debounce;
  Point? _startPoint;
  Point? _endPoint;
  bool _isLoadingSuggestions = false;
  int _activeQueryId = 0;
  final Map<String, CachedSuggestions> _suggestionCache = <String, CachedSuggestions>{};
  // Opririle sunt gestionate acum prin butonul "+" din cardul destinației; tipul vechi nu mai este folosit
  // ignore: unused_field
  bool _tipAddStopSeen = true; // păstrat pentru compatibilitate cu preferințele salvate
  
  StreamSubscription? _savedAddressesSubscription;
  StreamSubscription? _recentRidesSubscription;

  SavedAddress? _homeAddress;
  SavedAddress? _workAddress;
  List<SavedAddress> _favoriteAddresses = <SavedAddress>[];
  List<Ride> _recentRides = <Ride>[];

  bool get _isSearching => 
    (_destinationFocusNode.hasFocus && _destinationAddressController.text.isNotEmpty) ||
    (_startFocusNode.hasFocus && _startAddressController.text.isNotEmpty) ||
    (_activeStopIndex != null && _stopFocusNodes.isNotEmpty && 
     _activeStopIndex! < _stopFocusNodes.length && 
     _stopFocusNodes[_activeStopIndex!].hasFocus &&
     _stopControllers[_activeStopIndex!].text.isNotEmpty) ||
    _isLoadingSuggestions || _suggestions.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _startPoint = Point(coordinates: Position(widget.startPosition.longitude, widget.startPosition.latitude));
    _getAddressFromPosition(widget.startPosition, _startAddressController);
    _startAddressController.addListener(_onStartAddressChanged);
    _destinationAddressController.addListener(_onAddressChanged);
    _destinationFocusNode.addListener(() { 
      if(mounted) setState(() {});
    });
    _startFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _loadSavedAddresses();
    _loadRecentDestinations();
    _initializeStopControllers();

    () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (!mounted) return;
        setState(() {
          _tipAddStopSeen = prefs.getBool('tip_add_stop_seen') ?? false;
        });
      } catch (_) {}
    }();

    // Voice integration listener after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupVoiceListener();
    });
  }

  @override
  void dispose() {
    _startAddressController.dispose();
    _destinationAddressController.dispose();
    _destinationFocusNode.dispose();
    _startFocusNode.dispose();
    _debounce?.cancel();
    
    _savedAddressesSubscription?.cancel();
    _recentRidesSubscription?.cancel();
    
    for (var controller in _stopControllers) {
      controller.dispose();
    }
    for (var focusNode in _stopFocusNodes) {
      focusNode.dispose();
    }
    
    try {
      final voice = Provider.of<FriendsRideVoiceIntegration>(context, listen: false);
      voice.removeListener(_onVoiceChange);
    } catch (_) {}
    super.dispose();
  }

  void _setupVoiceListener() {
    try {
      FriendsRideVoiceIntegration? voice;
      try {
        voice = Provider.of<FriendsRideVoiceIntegration>(context, listen: false);
      } catch (_) { voice = null; }
      if (voice != null) {
        voice.addListener(_onVoiceChange);
        Logger.info('Voice listener setup complete', tag: 'ADDRESS_INPUT');
      }
    } catch (e) {
      Logger.error('Voice listener setup failed: $e', tag: 'ADDRESS_INPUT', error: e);
    }
  }

  void _onVoiceChange() async {
    try {
      FriendsRideVoiceIntegration? voice;
      try {
        voice = Provider.of<FriendsRideVoiceIntegration>(context, listen: false);
      } catch (_) { voice = null; }
      if (voice == null) return;
      final v = voice;

      // Destination from voice - ✅ FIX: Apelăm direct metoda pentru destinație
      // pentru a evita conflictul cu focus-ul câmpului de start
      if (v.hasNewVoiceDestination && v.voiceDestination != null) {
        final dest = v.voiceDestination!;
        Logger.info('Voice destination detected: $dest', tag: 'ADDRESS_INPUT');
        _destinationAddressController.text = dest;
        // ✅ FIX: Setăm destinația direct, ignorând focus-ul câmpurilor
        await _setVoiceDestination(dest);
        v.updateBookingProgress('Câmpul destinație completat. Calculez ruta...');
      }

      // Pickup from voice
      if (v.hasNewVoicePickup && v.voicePickup != null) {
        final pick = v.voicePickup!;
        Logger.info('Voice pickup detected: $pick', tag: 'ADDRESS_INPUT');
        _startAddressController.text = pick;
        await _selectStartAddress(pick);
        v.updateBookingProgress('Punctul de plecare completat.');
      }

      if (v.hasNewVoiceDestination || v.hasNewVoicePickup) {
        v.markVoiceEventsProcessed();
        if (_canConfirmAddresses()) {
          Future.delayed(const Duration(seconds: 2), () {
            if (!mounted) return;
            v.updateBookingProgress('Adresele sunt complete. Pregătesc opțiunile de cursă...');
            _confirmAddresses();
          });
        }
      }
    } catch (e) {
      Logger.error('Voice change handler error: $e', tag: 'ADDRESS_INPUT', error: e);
    }
  }

  

  Widget _buildConnectorLine({double height = 24}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _leftGutterWidth,
            child: Center(
              child: Container(width: 2, height: height, color: Colors.grey.shade300),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(child: SizedBox()),
        ],
      ),
    );
  }

  Widget _buildLeadingIcon({required bool isStart}) {
    return SizedBox(
      width: _leftGutterWidth,
      child: Icon(
        isStart ? Icons.trip_origin : Icons.place_outlined,
        size: 18,
        color: isStart ? Colors.green : Colors.redAccent,
      ),
    );
  }

  void _onStartAddressChanged() {
    if (_debounce?.isActive ?? false) { _debounce!.cancel(); }
    if (!mounted) return;
    setState(() {});
    if (_startAddressController.text.length < 3) {
      if (mounted) {
        setState(() {
          _localMatches.clear();
        });
      }
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 150), () async {
      final query = _startAddressController.text;
      final normalized = _normalizeRomanianText(query);
      _updateLocalMatches(normalized);
      // Show cached suggestions immediately if available (24h TTL)
      final cached = _suggestionCache[normalized];
      if (cached != null && DateTime.now().difference(cached.timestamp).inHours < 24) {
        if (mounted) {
          setState(() { _suggestions = cached.items; _isLoadingSuggestions = false; });
        }
      }
      if (mounted) setState(() { _isLoadingSuggestions = true; });
      final currentId = ++_activeQueryId;
      final results = await _fetchSuggestionsWithCache(query, normalized).timeout(const Duration(seconds: 5), onTimeout: () => <AddressSuggestion>[]);
      if (!mounted) return;
      if (currentId != _activeQueryId) return; // newer query took over
      setState(() {
        _suggestions = results;
        _isLoadingSuggestions = false;
      });
      if (results.isEmpty && normalized != query) {
        // Fallback: try normalized if original had no results
        final fallbackResults = await _fetchSuggestionsWithCache(normalized, normalized).timeout(const Duration(seconds: 5), onTimeout: () => <AddressSuggestion>[]);
        if (!mounted) return;
        if (currentId != _activeQueryId) return;
        setState(() {
          _suggestions = fallbackResults;
        });
      }
    });
  }

  void _initializeStopControllers() {
    for (int i = 0; i < widget.stops.length; i++) {
      final controller = TextEditingController(text: widget.stops[i].address);
      final focusNode = FocusNode();
      
      controller.addListener(() => _onStopAddressChanged(i));
      focusNode.addListener(() {
        if (focusNode.hasFocus) {
          setState(() => _activeStopIndex = i);
        } else if (_activeStopIndex == i) {
          setState(() => _activeStopIndex = null);
        }
      });
      
      _stopControllers.add(controller);
      _stopFocusNodes.add(focusNode);
    }
  }

  // ignore: unused_element
  void _addStop() {
    final l10n = AppLocalizations.of(context)!;
    if (widget.stops.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.max5Stops),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final controller = TextEditingController();
    final focusNode = FocusNode();
    final index = _stopControllers.length;
    
    controller.addListener(() => _onStopAddressChanged(index));
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        setState(() => _activeStopIndex = index);
      } else if (_activeStopIndex == index) {
        setState(() => _activeStopIndex = null);
      }
    });
    
    setState(() {
      _stopControllers.add(controller);
      _stopFocusNodes.add(focusNode);
    });
    
    Future.delayed(const Duration(milliseconds: 100), () {
      focusNode.requestFocus();
    });
  }

  // ignore: unused_element
  void _removeStop(int index) {
    if (index < _stopControllers.length) {
      _stopControllers[index].dispose();
      _stopFocusNodes[index].dispose();
      
      setState(() {
        _stopControllers.removeAt(index);
        _stopFocusNodes.removeAt(index);
        if (_activeStopIndex == index) {
          _activeStopIndex = null;
        } else if (_activeStopIndex != null && _activeStopIndex! > index) {
          _activeStopIndex = _activeStopIndex! - 1;
        }
      });
      
      widget.onStopRemoved(index);
    }
  }

  Future<void> _getAddressFromText(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (!mounted) return;
      if (locations.isNotEmpty) {
        final location = locations.first;
        setState(() {
          _startPoint = Point(coordinates: Position(location.longitude, location.latitude));
        });
        Logger.debug('Start point updated from voice input: ${location.latitude}, ${location.longitude}');
      }
    } catch (e) {
      Logger.error('Error geocoding voice input: $e', error: e);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.addressNotFound(address)),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _getAddressFromPosition(geolocator.Position position, TextEditingController controller) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (!mounted) return;
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        controller.text = "${place.street ?? ''}, ${place.locality ?? ''}".replaceAll(RegExp(r'^, |, $'), '');
      }
    } catch (e) {
      if (mounted) controller.text = "Nu s-a putut obține adresa curentă";
    }
  }

  void _onAddressChanged() {
    if (_debounce?.isActive ?? false) { _debounce!.cancel(); }
    if (!mounted) return;
    setState(() {});
    if (_destinationAddressController.text.length < 3) {
      if (mounted) {
        setState(() {
          _localMatches.clear();
        });
      }
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 150), () async {
      final query = _destinationAddressController.text;
      final normalized = _normalizeRomanianText(query);
      _updateLocalMatches(normalized);
      // Show cached suggestions immediately if available (24h TTL)
      final cached = _suggestionCache[normalized];
      if (cached != null && DateTime.now().difference(cached.timestamp).inHours < 24) {
        if (mounted) {
          setState(() { _suggestions = cached.items; _isLoadingSuggestions = false; });
        }
      }
      if (mounted) setState(() { _isLoadingSuggestions = true; });
      final currentId = ++_activeQueryId;
      final results = await _fetchSuggestionsWithCache(query, normalized).timeout(const Duration(seconds: 5), onTimeout: () => <AddressSuggestion>[]);
      if (!mounted) return;
      if (currentId != _activeQueryId) return; // newer query took over
      setState(() {
        _suggestions = results;
        _isLoadingSuggestions = false;
      });
      if (results.isEmpty && normalized != query) {
        // Fallback: try normalized if original had no results
        final fallbackResults = await _fetchSuggestionsWithCache(normalized, normalized).timeout(const Duration(seconds: 5), onTimeout: () => <AddressSuggestion>[]);
        if (!mounted) return;
        if (currentId != _activeQueryId) return;
        setState(() {
          _suggestions = fallbackResults;
        });
      }
    });
  }

  // ignore: unused_element
  void _onStopAddressChanged(int index) {
    if (_debounce?.isActive ?? false) { _debounce!.cancel(); }
    if (!mounted || index >= _stopControllers.length) return;
    setState(() {});
    if (_stopControllers[index].text.length < 3) {
      if (mounted) {
        setState(() {
          _localMatches.clear();
        });
      }
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 150), () async {
      final query = _stopControllers[index].text;
      final normalized = _normalizeRomanianText(query);
      _updateLocalMatches(normalized);
      // Show cached suggestions immediately if available (24h TTL)
      final cached = _suggestionCache[normalized];
      if (cached != null && DateTime.now().difference(cached.timestamp).inHours < 24) {
        if (mounted) {
          setState(() { _suggestions = cached.items; _isLoadingSuggestions = false; });
        }
      }
      if (mounted) setState(() { _isLoadingSuggestions = true; });
      final currentId = ++_activeQueryId;
      final results = await _fetchSuggestionsWithCache(query, normalized).timeout(const Duration(seconds: 5), onTimeout: () => <AddressSuggestion>[]);
      if (!mounted) return;
      if (currentId != _activeQueryId) return;
      setState(() {
        _suggestions = results;
        _isLoadingSuggestions = false;
      });
    });
  }

  Future<void> _selectAddress(String address, {Point? point}) async {
    Logger.debug('Selecting address: $address, isStop: $_activeStopIndex');
    
    if (_activeStopIndex != null) {
      await _selectStopAddress(_activeStopIndex!, address, point: point);
    } else if (_startFocusNode.hasFocus) {
      await _selectStartAddress(address, point: point);
    } else {
      _destinationAddressController.text = address;
      _destinationFocusNode.unfocus();
      setState(() { _suggestions.clear(); });

      try {
        if (point != null) {
          _endPoint = point;
          Logger.debug('End point set from parameter');
        } else {
          List<Location> locations = await locationFromAddress(address);
          if (locations.isEmpty) throw Exception("Adresa nu a putut fi găsită pe hartă.");
          _endPoint = Point(coordinates: Position(locations.first.longitude, locations.first.latitude));
          Logger.debug('End point geocoded');
        }
        
      } catch (e) {
        Logger.error('Error setting destination: $e', error: e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }

  Future<void> _selectStartAddress(String address, {Point? point}) async {
    _startAddressController.text = address;
    _startFocusNode.unfocus();
    setState(() { _suggestions.clear(); });
    try {
      if (point != null) {
        _startPoint = point;
        Logger.debug('Start point set from parameter');
      } else {
        List<Location> locations = await locationFromAddress(address);
        if (locations.isEmpty) throw Exception("Adresa nu a putut fi găsită pe hartă.");
        _startPoint = Point(coordinates: Position(locations.first.longitude, locations.first.latitude));
        Logger.debug('Start point geocoded');
      }
    } catch (e) {
      Logger.error('Error setting start: $e', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  /// ✅ NOU: Setează destinația din comandă vocală (ignoră focus-ul câmpurilor)
  Future<void> _setVoiceDestination(String address) async {
    Logger.info('Setting voice destination: $address', tag: 'ADDRESS_INPUT');
    
    // Unfocus both fields to avoid confusion
    _startFocusNode.unfocus();
    _destinationFocusNode.unfocus();
    setState(() { _suggestions.clear(); });

    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isEmpty) {
        throw Exception("Adresa nu a putut fi găsită pe hartă.");
      }
      
      final location = locations.first;
      _endPoint = Point(coordinates: Position(location.longitude, location.latitude));
      
      Logger.info('Voice destination set: ${location.latitude}, ${location.longitude}', tag: 'ADDRESS_INPUT');
      
      // Notify parent widget about the change
      if (mounted) {
        setState(() {});
      }
      
    } catch (e) {
      Logger.error('Error setting voice destination: $e', tag: 'ADDRESS_INPUT', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nu am putut găsi adresa: $address'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _selectStopAddress(int index, String address, {Point? point}) async {
    if (index >= _stopControllers.length) return;
    
    _stopControllers[index].text = address;
    _stopFocusNodes[index].unfocus();
    setState(() { 
      _suggestions.clear();
      _activeStopIndex = null;
    });

    try {
      Point stopPoint;
      if (point != null) {
        stopPoint = point;
      } else {
        List<Location> locations = await locationFromAddress(address);
        if (locations.isEmpty) throw Exception("Adresa nu a putut fi găsită pe hartă.");
        stopPoint = Point(coordinates: Position(locations.first.longitude, locations.first.latitude));
      }
      
      final stopLocation = StopLocation(
        address: address,
        latitude: stopPoint.coordinates.lat.toDouble(),
        longitude: stopPoint.coordinates.lng.toDouble(),
      );
      
      widget.onStopAdded(stopLocation);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
  
  void _loadSavedAddresses() {
    _savedAddressesSubscription?.cancel();
    _savedAddressesSubscription = _firestoreService.getSavedAddresses().listen((addresses) {
      if (mounted) {
        setState(() {
          try { _homeAddress = addresses.firstWhere((addr) => addr.label.toLowerCase() == 'acasă'); } catch (e) { _homeAddress = null; }
          try { _workAddress = addresses.firstWhere((addr) => addr.label.toLowerCase() == 'serviciu'); } catch (e) { _workAddress = null; }
          _favoriteAddresses = addresses.where((addr) => addr.label.toLowerCase() != 'acasă' && addr.label.toLowerCase() != 'serviciu').toList();
        });
      }
    });
  }

  void _loadRecentDestinations() {
    _recentRidesSubscription?.cancel();
    _recentRidesSubscription = _firestoreService.getRidesHistory(limit: 10).listen((rides) {
      if (mounted) {
        final uniqueDestinations = <String, Ride>{};
        for (var ride in rides) {
          if (!uniqueDestinations.containsKey(ride.destinationAddress)) {
            uniqueDestinations[ride.destinationAddress] = ride;
          }
        }
        setState(() {
          _recentRides = uniqueDestinations.values.toList();
        });
      }
    });
  }

  bool _canConfirmAddresses() {
    return _startAddressController.text.isNotEmpty && 
           _destinationAddressController.text.isNotEmpty &&
           _startPoint != null &&
           _endPoint != null;
  }

  void _confirmAddresses() async {
    Logger.debug('Confirming manually entered addresses');
    Logger.debug('Start: ${_startAddressController.text} - Point: $_startPoint');
    Logger.debug('Destination: ${_destinationAddressController.text} - Point: $_endPoint');
    
    if (!_canConfirmAddresses()) {
      if (_endPoint == null && _destinationAddressController.text.isNotEmpty) {
        try {
          List<Location> locations = await locationFromAddress(_destinationAddressController.text);
          if (locations.isNotEmpty) {
            _endPoint = Point(coordinates: Position(locations.first.longitude, locations.first.latitude));
            Logger.debug('Destination geocoded on confirm: $_endPoint');
          }
        } catch (e) {
          Logger.error('Failed to geocode destination on confirm: $e', error: e);
          if (mounted) {
            final l10n = AppLocalizations.of(context)!;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.noCoordinatesForDestination(e.toString())),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      } else {
        Logger.debug('Cannot confirm - missing data');
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.fillBothAddresses),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
    }
    
    if (_startPoint != null && _endPoint != null) {
      HapticFeedback.lightImpact();
      Logger.debug('Calling onDestinationSelected with confirmed addresses');
      widget.onDestinationSelected(
        _startPoint!, 
        _endPoint!, 
        _startAddressController.text, 
        _destinationAddressController.text
      );
      Logger.info('Manual confirmation completed - should trigger ride options');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)),
          ),
        ),
        // 1) WHERE TO (Destinație) – primul câmp
        _buildAddressInput(
          controller: _destinationAddressController,
          focusNode: _destinationFocusNode,
          labelText: 'Destinație',
          icon: Icons.location_on,
        ),
        const SizedBox(height: 12),
        
        // PLUS button between destination and pickup
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _onAddStopPressed,
              icon: const Icon(Icons.add, size: 18),
              label: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context)!;
                  return Text(l10n.addStop);
                },
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 3) Pickup (Preluare)
        _buildAddressInput(
          controller: _startAddressController,
          focusNode: _startFocusNode,
          labelText: 'Preluare de la',
          icon: Icons.my_location,
          isStart: true,
        ),
        const SizedBox(height: 16),
        
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton(
            onPressed: _canConfirmAddresses() ? _confirmAddresses : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _canConfirmAddresses() ? Colors.blue : Colors.grey,
              padding: const EdgeInsets.all(16),
            ),
            child: Text(
              _canConfirmAddresses() 
                ? 'Confirmă adresele selectate'
                : _endPoint == null 
                  ? 'Selectează destinația'
                  : 'Completează adresele',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isSearching 
            ? (_isLoadingSuggestions ? _buildSkeletonList() : _buildSuggestionsList())
            : _buildSavedAndRecentList(),
        )
      ],
    );
  }

  Widget _buildSkeletonList() {
    return Column(
      children: List.generate(6, (i) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.grey.shade300, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 12, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 8),
                  Container(height: 10, width: 180, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4))),
                ],
              ),
            )
          ],
        ),
      )),
    );
  }

  // WIDGET OPTIMIZAT PENTRU OPRIRI
  // ignore: unused_element
  Widget _buildStopInput(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLeadingIcon(isStart: true),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.orange.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // PRIMUL RÂND: Butoane funcționale + buton eliminare
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.blue.withValues(alpha: 0.4)),
                            ),
                            child: const Text('via', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue)),
                          ),
                          // Butonul de voce funcțional
                          VoiceInputButton(
                            onSpeechResult: (transcription) {
                              _stopControllers[index].text = transcription;
                              _selectStopAddress(index, transcription);
                            },
                            onSpeechError: (error) {
                              final l10n = AppLocalizations.of(context)!;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.errorVoiceRecognition(error.toString())),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            },
                            hintText: 'Apasă pentru a vorbi',
                            size: 24,
                            timeoutSeconds: 10,
                          ),
                          const SizedBox(width: 8),
                          // Butonul de hartă funcțional
                          IconButton(
                            icon: Icon(Icons.map_outlined, color: Colors.grey.shade600, size: 20),
                            tooltip: 'Alege de pe hartă',
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            onPressed: () async {
                              FocusScope.of(context).unfocus();
                              final result = await Navigator.of(context).push<Map<String, dynamic>>(
                                MaterialPageRoute(builder: (ctx) => MapPickerScreen(initialLocation: widget.startPosition)),
                              );
                              if (result != null && result.containsKey('location') && mounted) {
                                final newPoint = result['location'] as Point;
                                final newAddress = result['address'] as String;
                                await _selectStopAddress(index, newAddress, point: newPoint);
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          // Butonul pentru eliminarea oprire
                          GestureDetector(
                            onTap: () => _removeStop(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.remove_circle,
                                color: Colors.red.shade600,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // AL DOILEA RÂND: Câmpul de text cu X integrat
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _stopControllers[index],
                              focusNode: _stopFocusNodes[index],
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                labelText: 'Oprirea ${index + 1}',
                                border: const OutlineInputBorder(borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              onChanged: (_) => _onStopAddressChanged(index),
                            ),
                          ),
                          if (_stopControllers[index].text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _stopControllers[index].clear();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                margin: const EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.red.shade600,
                                  size: 16,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        _buildConnectorLine(height: 24),
      ],
    );
  }

  // WIDGET OPTIMIZAT PENTRU ADRESE NORMALE (destinație/preluare) cu gutter și icon lead
  Widget _buildAddressInput({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String labelText,
    required IconData icon,
    bool isStart = false,
  }) {
    final field = Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // PRIMUL RÂND: Etichetă (stânga) + butoane (dreapta)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      labelText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: (!isStart) ? FontWeight.bold : FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VoiceInputButton(
                      onSpeechResult: (transcription) {
                        controller.text = transcription;
                        if (!isStart) {
                          _selectAddress(transcription);
                        } else {
                          _getAddressFromText(transcription);
                        }
                      },
                      onSpeechError: (error) {
                        final l10n = AppLocalizations.of(context)!;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.errorVoiceRecognition(error.toString())),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      },
                      size: 24,
                      timeoutSeconds: 10,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.map_outlined, color: Colors.grey.shade600, size: 20),
                      tooltip: 'Alege de pe hartă',
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: () async {
                        FocusScope.of(context).unfocus();
                        final result = await Navigator.of(context).push<Map<String, dynamic>>(
                          MaterialPageRoute(builder: (ctx) => MapPickerScreen(initialLocation: widget.startPosition)),
                        );
                        if (result != null && result.containsKey('location') && mounted) {
                          final newPoint = result['location'] as Point;
                          final newAddress = result['address'] as String;
                          if (!isStart) {
                            _selectAddress(newAddress, point: newPoint);
                          } else {
                            setState(() {
                              _startAddressController.text = newAddress;
                              _startPoint = newPoint;
                            });
                          }
                        }
                      },
                    ),
                    // Removed inline plus from destination header; plus is placed between fields now
                  ],
                ),
              ],
            ),
          ),
          // AL DOILEA RÂND: Câmpul de text cu border permanent
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: controller.text.isEmpty ? 'Caută adrese...' : null,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onChanged: (_) => isStart ? _onStartAddressChanged() : _onAddressChanged(),
                  ),
                ),
                if (controller.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        controller.clear();
                        if (!isStart) {
                          _endPoint = null;
                        } else {
                          _startPoint = null;
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.red.shade600,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLeadingIcon(isStart: isStart),
            Expanded(child: field),
          ],
        ),
        if (!isStart) _buildConnectorLine(height: 24),
      ],
    );
  }

  Future<void> _onAddStopPressed() async {
    try {
      FocusScope.of(context).unfocus();
      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(builder: (ctx) => MapPickerScreen(initialLocation: widget.startPosition)),
      );
      if (result != null && result.containsKey('location') && mounted) {
        final newPoint = result['location'] as Point;
        final newAddress = result['address'] as String;
        final stopLocation = StopLocation(
          address: newAddress,
          latitude: newPoint.coordinates.lat.toDouble(),
          longitude: newPoint.coordinates.lng.toDouble(),
        );
        widget.onStopAdded(stopLocation);
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.intermediateStopAdded)),
        );
      }
    } catch (_) {}
  }

  Widget _buildSuggestionsList() {
    final query = _destinationFocusNode.hasFocus
        ? _destinationAddressController.text
        : (_startFocusNode.hasFocus ? _startAddressController.text : '');
    if ((query.isEmpty) && _localMatches.isEmpty && _suggestions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          children: [
            const SizedBox(width: 56),
            Expanded(
              child: Text(
                'Tastează pentru a căuta adrese...',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      );
    }

    final List<SuggestionRow> rows = <SuggestionRow>[];
    // Compute keyword-based scoring over local and remote
    final keywords = _buildKeywords(query);
    // Local rows
    for (final m in _localMatches) {
      rows.add(SuggestionRow.local(m));
    }
    // Remote rows
    for (final s in _suggestions) {
      rows.add(SuggestionRow.remote(s));
    }

    // Score and sort
    rows.sort((a, b) {
      final sa = _scoreRow(a, keywords);
      final sb = _scoreRow(b, keywords);
      if (sa != sb) return sb.compareTo(sa); // higher first
      // tie-break by distance for remote
      final da = a.remote?.distanceMeters ?? double.infinity;
      final db = b.remote?.distanceMeters ?? double.infinity;
      return da.compareTo(db);
    });

    return Column(
      children: [
        if (_isLoadingSuggestions)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: rows.length,
          separatorBuilder: (context, index) => Divider(height: 1, indent: 56, endIndent: 16),
          itemBuilder: (context, index) {
            final row = rows[index];
            if (row.isLocal) {
              final m = row.local!;
              final icon = _iconForLocalType(m.type);
              return ListTile(
                leading: Icon(icon, color: Theme.of(context).textTheme.bodySmall?.color),
                title: _buildHighlightedText(m.description, query),
                onTap: () {
                  if (m.point != null) {
                    _selectAddress(m.description, point: m.point);
                  } else {
                    _selectAddress(m.description);
                  }
                },
              );
            } else {
              final s = row.remote!;
              String distanceLabel = '';
              if (s.distanceMeters != null) {
                distanceLabel = _formatDistance(s.distanceMeters!);
              }
              final suppressGeneric = keywords.isNotEmpty && !_containsAllKeywords(_normalizeRomanianText(s.description), keywords);
              if (suppressGeneric) {
                return const SizedBox.shrink();
              }
              // Choose icon by score buckets
              IconData icon = Icons.location_on_outlined;
              Color iconColor = Theme.of(context).iconTheme.color ?? Colors.grey;
              if (s.score >= 60) {
                icon = Icons.star;
                iconColor = Colors.amber;
              } else if (s.score >= 50) {
                icon = Icons.history;
                iconColor = Colors.blue;
              }
              return ListTile(
                leading: Icon(icon, color: iconColor),
                title: _buildHighlightedText(s.description, query),
                subtitle: distanceLabel.isEmpty
                    ? null
                    : Text(
                        'Aproximativ $distanceLabel',
                        style: TextStyle(color: Theme.of(context).colorScheme.primary),
                      ),
                onTap: () {
                  final point = Point(coordinates: Position(s.longitude, s.latitude));
                  _selectAddress(s.description, point: point);
                },
              );
            }
          },
        ),
      ],
    );
  }

  String _formatDistance(double meters) {
    return meters < 1000
        ? '${meters.toStringAsFixed(0)} m'
        : '${(meters / 1000).toStringAsFixed(1)} km';
  }

  // ✅ NOU: Navighează la ecranul de adăugare adresă cu label precompletat
  void _navigateToAddAddress(String label) {
    final existingAddress = label == 'Acasă' ? _homeAddress : _workAddress;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => AddAddressScreen(
          addressToEdit: existingAddress,
          initialLabel: existingAddress == null ? label : null, // ✅ Precompletează label-ul doar dacă nu există adresă
        ),
      ),
    ).then((_) {
      // Reîncarcă adresele salvate după ce utilizatorul revine
      _loadSavedAddresses();
    });
  }

  Widget _buildSavedAndRecentList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // ✅ FIX: Afișează butonul "Acasă" întotdeauna - dacă există adresă, o folosește, altfel permite adăugarea
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context)!;
                  return ActionChip(
                    avatar: const Icon(Icons.home_rounded, size: 20),
                    label: Text(l10n.home),
                    onPressed: _homeAddress != null
                        ? () => _selectAddress(_homeAddress!.address, point: Point(coordinates: Position(_homeAddress!.coordinates.longitude, _homeAddress!.coordinates.latitude)))
                        : () => _navigateToAddAddress(l10n.home),
                  );
                },
              ),
            ),
            // ✅ FIX: Afișează butonul "Serviciu" întotdeauna - dacă există adresă, o folosește, altfel permite adăugarea
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return ActionChip(
                  avatar: const Icon(Icons.work_rounded, size: 20),
                  label: Text(l10n.work),
                  onPressed: _workAddress != null
                      ? () => _selectAddress(_workAddress!.address, point: Point(coordinates: Position(_workAddress!.coordinates.longitude, _workAddress!.coordinates.latitude)))
                      : () => _navigateToAddAddress(l10n.work),
                );
              },
            ),
          ],
        ),
        const Divider(height: 32),
        Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return Text(l10n.recentDestinations, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey.shade600));
          },
        ),
        const SizedBox(height: 8),
        if (_recentRides.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Text("Nicio destinație recentă.", style: TextStyle(color: Colors.grey)))
        else
          ...() {
            final List<Widget> recentWidgets = <Widget>[];
            for (var ride in _recentRides) {
              recentWidgets.add(
                ListTile(
                  leading: const Icon(Icons.history_rounded),
                  title: Text(ride.destinationAddress, maxLines: 2, overflow: TextOverflow.visible, style: const TextStyle(fontSize: 15)),
                  onTap: () => _selectAddress(
                    ride.destinationAddress,
                    point: ride.destinationLatitude != null && ride.destinationLongitude != null
                        ? Point(coordinates: Position(ride.destinationLongitude!, ride.destinationLatitude!))
                        : null,
                  ),
                ),
              );
            }
            return recentWidgets;
          }(),
        const Divider(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Favorite", style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey.shade600)),
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return TextButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (ctx) => const ManageAddressesScreen()
                    ));
                  },
                  child: Text(l10n.edit),
                );
              },
            )
          ],
        ),
        if (_favoriteAddresses.isEmpty)
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text(l10n.noFavoriteAddressAdded, style: const TextStyle(color: Colors.grey)));
            },
          )
        else
         ...() {
            final List<Widget> favoriteWidgets = <Widget>[];
            for (var addr in _favoriteAddresses) {
              favoriteWidgets.add(
                ListTile(
                  leading: Icon(Icons.star_rounded, color: Colors.amber.shade700),
                  title: Text(addr.label),
                  subtitle: Text(addr.address, maxLines: 2, overflow: TextOverflow.visible, style: const TextStyle(fontSize: 13)),
                  onTap: () => _selectAddress(addr.address, point: Point(coordinates: Position(addr.coordinates.longitude, addr.coordinates.latitude))),
                ),
              );
            }
            return favoriteWidgets;
          }(),
      ],
    );
  }

  // ===================== Helper models and functions =====================
  String _normalizeRomanianText(String text) {
    final lower = text.toLowerCase();
    final noDiacritics = lower
        .replaceAll('ă', 'a')
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('ș', 's')
        .replaceAll('ş', 's')
        .replaceAll('ț', 't')
        .replaceAll('ţ', 't');
    String expanded = noDiacritics
        .replaceAll(RegExp(r'^\s*sos\b'), 'soseaua')
        .replaceAll(RegExp(r'\bstr\.?\b'), 'strada')
        .replaceAll(RegExp(r'\bbd\.?\b'), 'bulevardul')
        .replaceAll(RegExp(r'\bbl\.?\b'), 'blocul')
        .replaceAll(RegExp(r'\bnr\b'), 'numarul')
        .replaceAll(RegExp(r'\bet\b'), 'etajul')
        .replaceAll(RegExp(r'\bap\b'), 'apartamentul')
        .replaceAll(RegExp(r'pța|piata'), 'piata');
    expanded = expanded.replaceAll(RegExp(r'\s+'), ' ').trim();
    return expanded;
  }

  List<String> _buildKeywords(String raw) {
    if (raw.isEmpty) return <String>[];
    final base = _normalizeRomanianText(raw);
    return base.split(' ').where((w) => w.isNotEmpty).toList();
  }

  bool _containsAllKeywords(String candidateNorm, List<String> keywords) {
    for (final k in keywords) {
      if (!candidateNorm.contains(k)) return false;
    }
    return true;
  }

  double _scoreRow(SuggestionRow row, List<String> keywords) {
    String text = row.isLocal ? row.local!.description : row.remote!.description;
    final norm = _normalizeRomanianText(text);
    if (keywords.isEmpty) return 0.0;
    int matches = 0;
    for (final k in keywords) {
      if (norm.contains(k)) matches++;
    }
    double score = matches.toDouble();
    // Boost exact phrase
    final phrase = keywords.join(' ');
    if (norm.contains(phrase)) score += 1.5;
    // Penalize generic-only matches (contains only very generic words)
    final generic = {'strada', 'soseaua', 'bulevardul', 'blocul', 'piata'};
    final nonGenericMatches = keywords.where((k) => !generic.contains(k)).where((k) => norm.contains(k)).length;
    if (nonGenericMatches == 0) score -= 1.0;
    return score;
  }

  int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;
    final v0 = List<int>.generate(t.length + 1, (i) => i);
    final v1 = List<int>.filled(t.length + 1, 0);
    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        final cost = s[i] == t[j] ? 0 : 1;
        v1[j + 1] = [
          v1[j] + 1,
          v0[j + 1] + 1,
          v0[j] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
      for (int j = 0; j < v0.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[t.length];
  }

  void _updateLocalMatches(String normalizedQuery) {
    if (normalizedQuery.length < 2) {
      _localMatches = <LocalSuggestion>[];
      return;
    }
    final List<LocalSuggestion> matches = <LocalSuggestion>[];

    // Home / Work
    if (_homeAddress != null) {
      final n = _normalizeRomanianText(_homeAddress!.address);
      final score = _scoreMatch(normalizedQuery, n);
      if (score > 0) {
        matches.add(LocalSuggestion(
          description: _homeAddress!.address,
          type: LocalType.home,
          point: Point(coordinates: Position(_homeAddress!.coordinates.longitude, _homeAddress!.coordinates.latitude)),
          score: score,
        ));
      }
    }
    if (_workAddress != null) {
      final n = _normalizeRomanianText(_workAddress!.address);
      final score = _scoreMatch(normalizedQuery, n);
      if (score > 0) {
        matches.add(LocalSuggestion(
          description: _workAddress!.address,
          type: LocalType.work,
          point: Point(coordinates: Position(_workAddress!.coordinates.longitude, _workAddress!.coordinates.latitude)),
          score: score,
        ));
      }
    }

    // Favorites
    for (final addr in _favoriteAddresses) {
      final n = _normalizeRomanianText(addr.address);
      final score = _scoreMatch(normalizedQuery, n);
      if (score > 0) {
        matches.add(LocalSuggestion(
          description: addr.address,
          type: LocalType.favorite,
          point: Point(coordinates: Position(addr.coordinates.longitude, addr.coordinates.latitude)),
          score: score,
        ));
      }
    }

    // Recent rides
    for (final ride in _recentRides) {
      final n = _normalizeRomanianText(ride.destinationAddress);
      final score = _scoreMatch(normalizedQuery, n);
      if (score > 0) {
        matches.add(LocalSuggestion(
          description: ride.destinationAddress,
          type: LocalType.recent,
          point: (ride.destinationLatitude != null && ride.destinationLongitude != null)
              ? Point(coordinates: Position(ride.destinationLongitude!, ride.destinationLatitude!))
              : null,
          score: score,
        ));
      }
    }

    matches.sort((a, b) => b.score.compareTo(a.score));
    _localMatches = matches.take(6).toList();
  }

  double _scoreMatch(String queryNorm, String candidateNorm) {
    if (candidateNorm.contains(queryNorm)) return 3.0; // partial/exact
    final dist = _levenshtein(candidateNorm, queryNorm);
    final maxLen = candidateNorm.length.clamp(queryNorm.length, 50);
    final ratio = 1.0 - (dist / maxLen);
    return ratio >= 0.7 ? ratio : 0.0;
  }

  Future<List<AddressSuggestion>> _fetchSuggestionsWithCache(String query, String normalized) async {
    // Cache lookup (24h)
    final now = DateTime.now();
    final key = normalized;
    final cached = _suggestionCache[key];
    if (cached != null && now.difference(cached.timestamp).inHours < 24) {
      return cached.items;
    }
    final results = await _geocodingService.fetchSuggestions(query, widget.startPosition);
    // Cache store
    _suggestionCache[key] = CachedSuggestions(items: results, timestamp: now);
    return results;
  }

  IconData _iconForLocalType(LocalType type) {
    switch (type) {
      case LocalType.home:
        return Icons.home_rounded;
      case LocalType.work:
        return Icons.work_rounded;
      case LocalType.favorite:
        return Icons.star_rounded;
      case LocalType.recent:
        return Icons.history_rounded;
    }
  }

  Widget _buildHighlightedText(String text, String query) {
    if (query.isEmpty) return Text(text, maxLines: 1, overflow: TextOverflow.ellipsis);
    final normText = _normalizeRomanianText(text);
    final normQuery = _normalizeRomanianText(query);
    final idx = normText.indexOf(normQuery);
    if (idx < 0) return Text(text, maxLines: 1, overflow: TextOverflow.ellipsis);
    final start = idx;
    final end = idx + normQuery.length;
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          TextSpan(text: text.substring(0, start), style: DefaultTextStyle.of(context).style),
          TextSpan(text: text.substring(start, end), style: DefaultTextStyle.of(context).style.copyWith(fontWeight: FontWeight.w700)),
          TextSpan(text: text.substring(end), style: DefaultTextStyle.of(context).style),
        ],
      ),
    );
  }

}

// Models for local suggestion row (top-level to satisfy analyzer rules)
enum LocalType { home, work, favorite, recent }
class LocalSuggestion {
  final String description;
  final LocalType type;
  final Point? point;
  final double score;
  LocalSuggestion({required this.description, required this.type, this.point, required this.score});
}

class SuggestionRow {
  final LocalSuggestion? local;
  final AddressSuggestion? remote;
  final bool isLocal;
  SuggestionRow.local(this.local)
      : remote = null,
        isLocal = true;
  SuggestionRow.remote(this.remote)
      : local = null,
        isLocal = false;
}

class CachedSuggestions {
  final List<AddressSuggestion> items;
  final DateTime timestamp;
  CachedSuggestions({required this.items, required this.timestamp});
}