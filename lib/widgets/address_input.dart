// lib/widgets/address_input_view.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:friendsride_app/models/ride_model.dart';
import 'package:friendsride_app/models/saved_address_model.dart';
import 'package:friendsride_app/models/stop_location.dart';
import 'package:friendsride_app/screens/map_picker_screen.dart';
import 'package:friendsride_app/screens/manage_addresses_screen.dart';
import 'package:friendsride_app/services/firestore_service.dart';
// ignore: unused_import
import 'package:friendsride_app/services/geocoding_service.dart' as geocoding;
import 'package:friendsride_app/services/optimized_geocoding_service.dart' as optimized;
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:geocoding/geocoding.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

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
  final _startAddressController = TextEditingController();
  final _destinationAddressController = TextEditingController();
  final FocusNode _destinationFocusNode = FocusNode();

  final List<TextEditingController> _stopControllers = <TextEditingController>[];
  final List<FocusNode> _stopFocusNodes = <FocusNode>[];
  int? _activeStopIndex;

  // final geocoding.GeocodingService _geocodingService = geocoding.GeocodingService(); // Folosim OptimizedGeocodingService
  final optimized.OptimizedGeocodingService _optimizedGeocodingService = optimized.OptimizedGeocodingService();
  final FirestoreService _firestoreService = FirestoreService();

  List<optimized.AddressSuggestion> _suggestions = <optimized.AddressSuggestion>[];
  Timer? _debounce;
  Point? _startPoint;
  Point? _endPoint;
  
  StreamSubscription? _savedAddressesSubscription;
  StreamSubscription? _recentRidesSubscription;

  SavedAddress? _homeAddress;
  SavedAddress? _workAddress;
  List<SavedAddress> _favoriteAddresses = <SavedAddress>[];
  List<Ride> _recentRides = <Ride>[];

  // Cache pentru rezultatele frecvente
  static final Map<String, List<optimized.AddressSuggestion>> _suggestionsCache = <String, List<optimized.AddressSuggestion>>{};
  static const int _maxCacheSize = 100;
  
  // Loading state pentru feedback vizual
  bool _isLoadingSuggestions = false;

  bool get _isSearching => 
    (_destinationFocusNode.hasFocus && _destinationAddressController.text.isNotEmpty) ||
    (_activeStopIndex != null && _stopFocusNodes.isNotEmpty && 
     _activeStopIndex! < _stopFocusNodes.length && 
     _stopFocusNodes[_activeStopIndex!].hasFocus &&
     _stopControllers[_activeStopIndex!].text.isNotEmpty);

  @override
  void initState() {
    super.initState();
    _startPoint = Point(coordinates: Position(widget.startPosition.longitude, widget.startPosition.latitude));
    _getAddressFromPosition(widget.startPosition, _startAddressController);
    _destinationAddressController.addListener(_onAddressChanged);
    _destinationFocusNode.addListener(() { 
      if(mounted) setState(() {});
    });
    _loadSavedAddresses();
    _loadRecentDestinations();
    _initializeStopControllers();
  }

  @override
  void dispose() {
    _startAddressController.dispose();
    _destinationAddressController.dispose();
    _destinationFocusNode.dispose();
    _debounce?.cancel();
    
    _savedAddressesSubscription?.cancel();
    _recentRidesSubscription?.cancel();
    
    for (var controller in _stopControllers) {
      controller.dispose();
    }
    for (var focusNode in _stopFocusNodes) {
      focusNode.dispose();
    }
    
    super.dispose();
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

  void _addStop() {
    if (widget.stops.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Poți adăuga maximum 5 opriri'),
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
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (!mounted) return;
    
    setState(() {
      _isLoadingSuggestions = false;
    });
    
    final query = _destinationAddressController.text.trim().toLowerCase();
    
    if (query.length < 3) {
      if (mounted) setState(() => _suggestions.clear());
      return;
    }

    // Verifică cache-ul mai întâi
    if (_suggestionsCache.containsKey(query)) {
      final cachedResults = _suggestionsCache[query]!;
      if (mounted) {
        setState(() {
          _suggestions = cachedResults.take(5).toList();
          _isLoadingSuggestions = false;
        });
      }
      return;
    }

    setState(() {
      _isLoadingSuggestions = true;
    });

    _debounce = Timer(const Duration(milliseconds: 200), () async {
      try {
        // Folosește serviciul optimizat pentru performanță mai bună
        final results = await _optimizedGeocodingService.searchAddresses(
          query: query,
          userPosition: widget.startPosition,
          useCache: true,
          maxResults: 5,
        );
        if (mounted) {
          final limitedResults = results.take(5).toList();
          
          // Cache rezultatele
          _cacheResults(query, limitedResults);
          
          setState(() {
            _suggestions = limitedResults;
            _isLoadingSuggestions = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _suggestions.clear();
            _isLoadingSuggestions = false;
          });
        }
      }
    });
  }

  void _onStopAddressChanged(int index) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (!mounted || index >= _stopControllers.length) return;
    
    setState(() {
      _isLoadingSuggestions = false;
    });
    
    final query = _stopControllers[index].text.trim().toLowerCase();
    
    if (query.length < 3) {
      if (mounted) setState(() => _suggestions.clear());
      return;
    }

    // Verifică cache-ul
    if (_suggestionsCache.containsKey(query)) {
      final cachedResults = _suggestionsCache[query]!;
      if (mounted) {
        setState(() {
          _suggestions = cachedResults.take(5).toList();
          _isLoadingSuggestions = false;
        });
      }
      return;
    }

    setState(() {
      _isLoadingSuggestions = true;
    });

    _debounce = Timer(const Duration(milliseconds: 200), () async {
      try {
        // Folosește serviciul optimizat pentru performanță mai bună
        final results = await _optimizedGeocodingService.searchAddresses(
          query: query,
          userPosition: widget.startPosition,
          useCache: true,
          maxResults: 5,
        );
        if (mounted) {
          final limitedResults = results.take(5).toList();
          
          // Cache rezultatele
          _cacheResults(query, limitedResults);
          
          setState(() {
            _suggestions = limitedResults;
            _isLoadingSuggestions = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _suggestions.clear();
            _isLoadingSuggestions = false;
          });
        }
      }
    });
  }

  // Metodă pentru cache management
  void _cacheResults(String query, List<optimized.AddressSuggestion> results) {
    _suggestionsCache[query] = results;
    
    // Cleanup cache dacă devine prea mare
    if (_suggestionsCache.length > _maxCacheSize) {
      final excess = _suggestionsCache.length - _maxCacheSize;
      final keysToRemove = _suggestionsCache.keys.take(excess).toList();
      for (final key in keysToRemove) {
        _suggestionsCache.remove(key);
      }
    }
  }

  Future<void> _selectAddress(String address, {Point? point}) async {
    debugPrint('Selecting address: $address, isStop: $_activeStopIndex');
    
    if (_activeStopIndex != null) {
      await _selectStopAddress(_activeStopIndex!, address, point: point);
    } else {
      _destinationAddressController.text = address;
      _destinationFocusNode.unfocus();
      setState(() { 
        _suggestions.clear();
        _isLoadingSuggestions = false;
      });

      try {
        if (point != null) {
          _endPoint = point;
          debugPrint('End point set from parameter');
        } else {
          setState(() => _isLoadingSuggestions = true);
          List<Location> locations = await locationFromAddress(address);
          if (locations.isEmpty) throw Exception("Adresa nu a putut fi găsită pe hartă.");
          _endPoint = Point(coordinates: Position(locations.first.longitude, locations.first.latitude));
          debugPrint('End point geocoded');
          setState(() => _isLoadingSuggestions = false);
        }
        
      } catch (e) {
        debugPrint('Error setting destination: $e');
        if (mounted) {
          setState(() => _isLoadingSuggestions = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
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
      _isLoadingSuggestions = false;
    });

    try {
      Point stopPoint;
      if (point != null) {
        stopPoint = point;
      } else {
        setState(() => _isLoadingSuggestions = true);
        List<Location> locations = await locationFromAddress(address);
        if (locations.isEmpty) throw Exception("Adresa nu a putut fi găsită pe hartă.");
        stopPoint = Point(coordinates: Position(locations.first.longitude, locations.first.latitude));
        setState(() => _isLoadingSuggestions = false);
      }
      
      final stopLocation = StopLocation(
        address: address,
        latitude: stopPoint.coordinates.lat.toDouble(),
        longitude: stopPoint.coordinates.lng.toDouble(),
      );
      
      widget.onStopAdded(stopLocation);
      
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSuggestions = false);
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
    debugPrint('Confirming manually entered addresses');
    debugPrint('Start: ${_startAddressController.text} - Point: $_startPoint');
    debugPrint('Destination: ${_destinationAddressController.text} - Point: $_endPoint');
    
    if (!_canConfirmAddresses()) {
      if (_endPoint == null && _destinationAddressController.text.isNotEmpty) {
        try {
          setState(() => _isLoadingSuggestions = true);
          List<Location> locations = await locationFromAddress(_destinationAddressController.text);
          if (locations.isNotEmpty) {
            _endPoint = Point(coordinates: Position(locations.first.longitude, locations.first.latitude));
            debugPrint('Destination geocoded on confirm: $_endPoint');
          }
          setState(() => _isLoadingSuggestions = false);
        } catch (e) {
          debugPrint('Failed to geocode destination on confirm: $e');
          if (mounted) {
            setState(() => _isLoadingSuggestions = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Nu s-au găsit coordonate pentru destinație: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      } else {
        debugPrint('Cannot confirm - missing data');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Completează ambele adrese pentru a continua'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
    }
    
    if (_startPoint != null && _endPoint != null) {
      debugPrint('Calling onDestinationSelected with confirmed addresses');
      widget.onDestinationSelected(
        _startPoint!, 
        _endPoint!, 
        _startAddressController.text, 
        _destinationAddressController.text
      );
      debugPrint('Manual confirmation completed - should trigger ride options');
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
        _buildAddressInput(
          controller: _startAddressController,
          labelText: 'Preluare de la',
          icon: Icons.my_location,
          isStart: true,
        ),
        const SizedBox(height: 12),
        
        ...() {
          final List<Widget> stopWidgets = <Widget>[];
          for (int index = 0; index < _stopControllers.length; index++) {
            stopWidgets.add(
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildStopInput(index),
              ),
            );
          }
          return stopWidgets;
        }(),
        
        if (_stopControllers.length < 5)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OutlinedButton.icon(
              onPressed: _addStop,
              icon: const Icon(Icons.add_location_alt, size: 18),
              label: Text('Adaugă oprire (${widget.stops.length}/5)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: Colors.orange.shade300),
              ),
            ),
          ),
        
        _buildAddressInput(
          controller: _destinationAddressController,
          focusNode: _destinationFocusNode,
          labelText: 'Destinație',
          icon: Icons.location_on,
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
            child: _isLoadingSuggestions 
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
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
            ? _buildSuggestionsList() 
            : _buildSavedAndRecentList(),
        )
      ],
    );
  }

  Widget _buildStopInput(int index) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _stopControllers[index],
              focusNode: _stopFocusNodes[index],
              style: const TextStyle(fontSize: 14, overflow: TextOverflow.ellipsis),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.location_on, color: Colors.orange.shade600),
                labelText: 'Oprirea ${index + 1}',
                border: const OutlineInputBorder(borderSide: BorderSide.none),
                suffixIcon: IconButton(
                  icon: Icon(Icons.map_outlined, color: Colors.grey.shade600),
                  tooltip: 'Alege de pe hartă',
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
              ),
            ),
          ),
          IconButton(
            onPressed: () => _removeStop(index),
            icon: Icon(Icons.remove_circle, color: Colors.red.shade400),
            tooltip: 'Elimină oprirea',
          ),
        ],
      ),
    );
  }

  Widget _buildAddressInput({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String labelText,
    required IconData icon,
    bool isStart = false,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      style: const TextStyle(fontSize: 14, overflow: TextOverflow.ellipsis),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
        labelText: labelText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoadingSuggestions && (focusNode?.hasFocus ?? false))
              const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            IconButton(
              icon: Icon(Icons.map_outlined, color: Colors.grey.shade600),
              tooltip: 'Alege de pe hartă',
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
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    if (_isLoadingSuggestions && _suggestions.isEmpty) {
      return SizedBox(
        height: 100,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text('Căutăm adrese...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        return ListTile(
          leading: const Icon(Icons.place_outlined),
          title: Text(suggestion.description, maxLines: 2, overflow: TextOverflow.ellipsis),
          onTap: () => _selectAddress(suggestion.description),
        );
      },
    );
  }

  Widget _buildSavedAndRecentList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (_homeAddress != null)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ActionChip(
                  avatar: const Icon(Icons.home_rounded, size: 20),
                  label: const Text('Acasă'),
                  onPressed: () => _selectAddress(_homeAddress!.address, point: Point(coordinates: Position(_homeAddress!.coordinates.longitude, _homeAddress!.coordinates.latitude))),
                ),
              ),
            if (_workAddress != null)
              ActionChip(
                avatar: const Icon(Icons.work_rounded, size: 20),
                label: const Text('Serviciu'),
                onPressed: () => _selectAddress(_workAddress!.address, point: Point(coordinates: Position(_workAddress!.coordinates.longitude, _workAddress!.coordinates.latitude))),
              ),
          ],
        ),
        const Divider(height: 32),
        Text("Destinații Recente", style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey.shade600)),
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
                  title: Text(ride.destinationAddress, maxLines: 1, overflow: TextOverflow.ellipsis),
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
            TextButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (ctx) => const ManageAddressesScreen()
                ));
              },
              child: const Text("Editează"),
            )
          ],
        ),
        if (_favoriteAddresses.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Text("Nicio adresă favorită adăugată.", style: TextStyle(color: Colors.grey)))
        else
         ...() {
            final List<Widget> favoriteWidgets = <Widget>[];
            for (var addr in _favoriteAddresses) {
              favoriteWidgets.add(
                ListTile(
                  leading: Icon(Icons.star_rounded, color: Colors.amber.shade700),
                  title: Text(addr.label),
                  subtitle: Text(addr.address, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () => _selectAddress(addr.address, point: Point(coordinates: Position(addr.coordinates.longitude, addr.coordinates.latitude))),
                ),
              );
            }
            return favoriteWidgets;
          }(),
      ],
    );
  }
}