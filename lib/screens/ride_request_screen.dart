import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/mapbox_utils.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Visibility;
import 'package:friendsride_app/models/ride_model.dart';
import 'package:friendsride_app/models/saved_address_model.dart';
import 'package:friendsride_app/screens/legal_screen.dart';
import 'package:friendsride_app/screens/map_picker_screen.dart';
import 'package:friendsride_app/screens/searching_for_driver_screen.dart';
import 'package:friendsride_app/services/firestore_service.dart';
import 'package:friendsride_app/services/geocoding_service.dart';
import 'package:friendsride_app/services/pricing_service.dart';
import 'package:friendsride_app/services/routing_service.dart';
import 'package:friendsride_app/services/ride_sharing_service.dart';
import 'package:friendsride_app/widgets/ride_sharing_option_widget.dart';
import 'package:friendsride_app/widgets/category_card.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:friendsride_app/utils/logger.dart';

class RideRequestScreen extends StatefulWidget {
  final geolocator.Position startPosition;
  final bool isScheduling;

  const RideRequestScreen({
    super.key,
    required this.startPosition,
    this.isScheduling = false,
  });

  @override
  State<RideRequestScreen> createState() => _RideRequestScreenState();
}

class _RideRequestScreenState extends State<RideRequestScreen> {
  // Controllers and Focus Nodes
  final _formKey = GlobalKey<FormState>();
  final _startAddressController = TextEditingController();
  final _destinationAddressController = TextEditingController();
  final FocusNode _startFocusNode = FocusNode();
  final FocusNode _destinationFocusNode = FocusNode();

  // Services
  final FirestoreService _firestoreService = FirestoreService();
  final PricingService _pricingService = PricingService();
  final GeocodingService _geocodingService = GeocodingService();
  final RoutingService _routingService = RoutingService();
  final RideSharingService _rideSharingService = RideSharingService();
  // final EtaService _etaService = EtaService(); // Eliminat

  // Map related
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  Map<String, dynamic>? _routeGeoJSON;

  // State Management
  bool _isLoading = false;
  bool _isShowingSuggestions = false;
  bool _isAutoStarting = false; // ✅ NOU: Indicator pentru auto-start
  Point? _startPoint;
  Point? _endPoint;

  // Ride Details
  Map<RideCategory, Map<String, double>> _faresByCategory = {};
  Map<RideCategory, DriverEtaResult?> _etaByCategory = {};
  double _distanceInKm = 0;
  double _estimatedDurationInMinutes = 0;
  RideCategory _selectedCategory = RideCategory.standard;
  
  // ✅ NOU: Ride Sharing
  final bool _isRideSharingEnabled = true; // ✅ ACTIVAT
  bool _isRideSharingSelected = false;

  // User Data
  List<AddressSuggestion> _suggestions = [];
  Timer? _debounce;
  SavedAddress? _homeAddress;
  SavedAddress? _workAddress;
  
  // Scheduling
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;

  // NOU: StreamSubscription și Timer pentru a gestiona ETA-ul stabil
  StreamSubscription? _driverLocationSubscription;
  Timer? _etaClearTimer;
  
  // ✅ NOU: Timer pentru auto-start căutare șoferi după selecția categoriei
  Timer? _autoStartTimer;
  
  // ✅ NOU: Helper pentru afișarea statusului cursei
  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'searching':
        return 'Căutare șoferi';
      case 'pending':
        return 'În așteptare';
      case 'driver_found':
        return 'Șofer găsit';
      case 'accepted':
        return 'Acceptată';
      case 'arrived':
        return 'Șoferul a ajuns';
      case 'in_progress':
        return 'În curs';
      default:
        return status;
    }
  }

  @override
  void initState() {
    super.initState();
    _startPoint = Point(
        coordinates:
            Position(widget.startPosition.longitude, widget.startPosition.latitude));
    _getAddressFromPosition(widget.startPosition, _startAddressController);
    _startAddressController.addListener(() => _onAddressChanged(_startAddressController));
    _destinationAddressController.addListener(() => _onAddressChanged(_destinationAddressController));
    _startFocusNode.addListener(_onFocusChange);
    _destinationFocusNode.addListener(_onFocusChange);
    _loadSavedAddresses();
  }

  @override
  void dispose() {
    _startAddressController.dispose();
    _destinationAddressController.dispose();
    _startFocusNode.dispose();
    _destinationFocusNode.dispose();
    _debounce?.cancel();
    _driverLocationSubscription?.cancel();
    _etaClearTimer?.cancel();
    _autoStartTimer?.cancel();
    super.dispose();
  }
  
  // --- CORE LOGIC ---

  Future<void> _calculateRouteAndEta() async {
    FocusScope.of(context).unfocus();
    if (_startPoint == null || _endPoint == null) return;

    setState(() => _isLoading = true);
    Logger.debug("--- Starting route and ETA calculation ---");

    try {
      final List<Point> waypoints = [_startPoint!, _endPoint!];
      _routeGeoJSON = await _routingService.getRoute(waypoints).timeout(const Duration(seconds: 15));
      if (_routeGeoJSON == null) throw Exception("Routing service failed.");

      _distanceInKm = _routingService.extractDistance(_routeGeoJSON) / 1000;

      // CORECTAT: Folosim o viteză medie constantă
      const double averageSpeed = 40.0; // Viteza medie in km/h
      if (averageSpeed <= 0) throw Exception("Invalid average speed.");
      _estimatedDurationInMinutes = (_distanceInKm / averageSpeed) * 60;

      _faresByCategory = {
        for (var category in RideCategory.values)
          category: _pricingService.calculateFare(
            distanceInKm: _distanceInKm,
            durationInMinutes: _estimatedDurationInMinutes,
            category: category,
          ),
      };

      await _calculateEtaForAllCategories();
      
      _drawRouteAndMarkers();

      _listenForDriverUpdates();

      Logger.debug("--- Route and ETA calculation successful ---");
    } on TimeoutException {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Operation timed out. Please check your connection.'), backgroundColor: Colors.red));
        }
    } catch (e) {
      Logger.error("Error in _calculateRouteAndEta: ${e.toString()}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error calculating route: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: Colors.red));
      }
    } finally {
        if(mounted) {
            setState(() => _isLoading = false);
        }
    }
  }

  void _listenForDriverUpdates() {
    _driverLocationSubscription?.cancel();
    Logger.debug("Pornit ascultătorul pentru locațiile șoferilor ---", tag: 'LIVE ETA');
    _driverLocationSubscription = _firestoreService.getNearbyAvailableDrivers().listen((snapshot) {
      Logger.debug("Detectat update la șoferi. Se recalculează ETA... ---", tag: 'LIVE ETA');
      if (mounted && _faresByCategory.isNotEmpty) {
         _calculateEtaForAllCategories();
      }
    });
  }

  void _stopListeningForDriverUpdates() {
    Logger.debug("Oprit ascultătorul pentru locațiile șoferilor ---", tag: 'LIVE ETA');
    _driverLocationSubscription?.cancel();
    _driverLocationSubscription = null;
    _etaClearTimer?.cancel();
  }

  Future<void> _calculateEtaForAllCategories() async {
    if (_startPoint == null) return;
    
    _etaClearTimer?.cancel();

    final etaResults = <RideCategory, DriverEtaResult?>{};
    bool atLeastOneDriverFound = false;

    for (final category in RideCategory.values) {
      try {
        final etaResult = await _firestoreService.getNearestDriverEta(_startPoint!, category);
        etaResults[category] = etaResult;
        if (etaResult != null) {
          atLeastOneDriverFound = true;
        }
      } catch (e) {
        etaResults[category] = null;
      }
    }
    
    if (mounted) {
      if (atLeastOneDriverFound) {
        setState(() => _etaByCategory = etaResults);
      } else {
        Logger.debug("Niciun șofer găsit. Se va șterge ETA în 5 secunde dacă situația persistă.", tag: 'LIVE ETA');
        _etaClearTimer = Timer(const Duration(seconds: 5), () {
          if (mounted) {
            Logger.debug("Timer expirat. Se confirmă ștergerea ETA.", tag: 'LIVE ETA');
            setState(() => _etaByCategory.clear());
          }
        });
      }
    }
  }

  Future<void> _confirmAndRequestRide() async {
    // Anulează auto-start timer dacă utilizatorul apasă manual butonul
    _autoStartTimer?.cancel();
    if (mounted) {
      setState(() {
        _isAutoStarting = true; // Afișează indicator și pentru apăsare manuală
      });
    }
    _stopListeningForDriverUpdates();

    final fareDetails = _faresByCategory[_selectedCategory];
    if (fareDetails == null || _startPoint == null || _endPoint == null) return;

    if (widget.isScheduling && (_scheduledDate == null || _scheduledTime == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select the date and time for scheduling.'), backgroundColor: Colors.red),
      );
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User not authenticated.'), backgroundColor: Colors.red),
      );
      return;
    }

    DateTime? finalScheduledTime;
    if (widget.isScheduling) {
      finalScheduledTime = DateTime(
        _scheduledDate!.year, _scheduledDate!.month, _scheduledDate!.day,
        _scheduledTime!.hour, _scheduledTime!.minute,
      );
      
      // ✅ Validare: Rezervarea trebuie să fie cu cel puțin 2 ore în avans
      final now = DateTime.now();
      final timeDifference = finalScheduledTime.difference(now);
      
      if (timeDifference.inHours < 2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rezervarea trebuie să fie făcută cu cel puțin 2 ore în avans față de ora rezervării cursei.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
        if (mounted) {
          setState(() {
            _isAutoStarting = false;
          });
        }
        return;
      }
    }

    final newRide = Ride(
      id: '',
      passengerId: userId,
      startAddress: _startAddressController.text,
      destinationAddress: _destinationAddressController.text,
      distance: _distanceInKm,
      startLatitude: _startPoint!.coordinates.lat.toDouble(),
      startLongitude: _startPoint!.coordinates.lng.toDouble(),
      destinationLatitude: _endPoint!.coordinates.lat.toDouble(),
      destinationLongitude: _endPoint!.coordinates.lng.toDouble(),
      durationInMinutes: _estimatedDurationInMinutes,
      baseFare: fareDetails['baseFare']!,
      perKmRate: fareDetails['perKmRate']!,
      perMinRate: fareDetails['perMinRate']!,
      totalCost: fareDetails['totalCost']!,
      appCommission: fareDetails['appCommission']!,
      driverEarnings: fareDetails['driverEarnings']!,
      timestamp: DateTime.now(),
      status: 'pending',
      category: _selectedCategory,
      stops: [],
      isScheduled: widget.isScheduling,
      scheduledPickupTime: finalScheduledTime,
    );

    String? rideId;
    try {
      rideId = await _firestoreService.requestRide(newRide);
    } on ActiveRideException catch (e) {
      // ✅ FIX: Afișează dialog de confirmare când există o cursă activă
      if (!mounted) {
        setState(() {
          _isLoading = false;
          _isAutoStarting = false;
        });
        return;
      }
      
      // ✅ FIX: Setează _isLoading = false înainte de a afișa dialogul pentru a nu bloca UI-ul
      setState(() {
        _isLoading = false;
        _isAutoStarting = false;
      });
      
      // ✅ FIX: Așteaptă ca UI-ul să fie complet renderat și ca loading indicator-ul să dispară
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) {
        return;
      }
      
      // ✅ FIX: Folosește showGeneralDialog cu root navigator pentru a afișa dialogul deasupra tuturor elementelor
      final rootNavigator = Navigator.of(context, rootNavigator: true);
      final shouldCancel = await showGeneralDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black54,
        barrierLabel: 'Cursă activă',
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) {
          return AlertDialog(
            title: const Text('Cursă activă detectată'),
            content: SingleChildScrollView(
              child: Text(
                '${e.message}\n\n'
                'Status cursă: ${_getStatusDisplayName(e.activeRideStatus)}\n'
                'ID cursă: ${e.activeRideId.length > 8 ? e.activeRideId.substring(0, 8) : e.activeRideId}...',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => rootNavigator.pop(false),
                child: const Text('Anulează'),
              ),
              ElevatedButton(
                onPressed: () => rootNavigator.pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                child: const Text('Anulează cursa precedentă'),
              ),
            ],
          );
        },
      );
      
      if (shouldCancel == true && mounted) {
        // Anulează cursa precedentă și creează una nouă
        try {
          await _firestoreService.cancelRide(e.activeRideId);
          // Reîncearcă crearea cursei
          rideId = await _firestoreService.requestRide(newRide);
        } catch (cancelError) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _isAutoStarting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Eroare la anularea cursei precedente: $cancelError'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      } else {
        // Utilizatorul a anulat - nu facem nimic
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isAutoStarting = false;
          });
        }
        return;
      }
    } catch (e) {
      // Alte erori
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isAutoStarting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Eroare la crearea cursei: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // După catch, rideId este garantat să fie setat dacă nu s-a făcut return
    final finalRideId = rideId;
    
    // ✅ NOU: Creează ride sharing request dacă este selectat
    if (_isRideSharingSelected && _startPoint != null && _endPoint != null) {
      try {
        await _rideSharingService.createRideShareRequest(
          rideId: finalRideId,
          pickupAddress: newRide.startAddress,
          destinationAddress: newRide.destinationAddress,
          pickupLatitude: newRide.startLatitude!,
          pickupLongitude: newRide.startLongitude!,
          destinationLatitude: newRide.destinationLatitude!,
          destinationLongitude: newRide.destinationLongitude!,
          originalCost: fareDetails['totalCost'] ?? 0.0,
        );
        Logger.info('Ride sharing request created for ride $rideId');
      } catch (e) {
        Logger.error('Error creating ride sharing request: $e', error: e);
        // Continuă cu cererea normală chiar dacă ride sharing eșuează
      }
    }

    if (!mounted) return;

    if (widget.isScheduling) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride scheduled successfully!'), backgroundColor: Colors.green),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => SearchingForDriverScreen(rideId: finalRideId)),
      );
    }
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(_faresByCategory.isEmpty ? (widget.isScheduling ? 'Schedule a ride' : 'Where to?') : 'Choose a ride'),
        leading: _faresByCategory.isNotEmpty ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _resetToAddressInput,
        ) : null,
      ),
      body: Stack(
        children: [
          MapWidget(
            onMapCreated: _onMapCreated,
            cameraOptions: CameraOptions(
                              center: _startPoint != null ? _startPoint! : MapboxUtils.createPoint(widget.startPosition.latitude, widget.startPosition.longitude),
              zoom: 12.0
            ),
            styleUri: Theme.of(context).brightness == Brightness.dark
                ? MapboxStyles.DARK
                : MapboxStyles.MAPBOX_STREETS,
          ),
          
          _buildSlidingPanel(),

          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildSlidingPanel() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        elevation: 8,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _faresByCategory.isEmpty
                  ? _buildAddressInputForm()
                  : _buildCategorySelection(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressInputForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isScheduling) _buildSchedulingFields(context),
          _buildAddressInput(
            controller: _startAddressController,
            focusNode: _startFocusNode,
            labelText: 'Start location',
          ),
          const SizedBox(height: 12),
          _buildAddressInput(
            controller: _destinationAddressController,
            focusNode: _destinationFocusNode,
            labelText: 'Destination',
          ),
          const SizedBox(height: 12),
          if (_isShowingSuggestions)
            _buildSuggestionsList()
          else
            _buildQuickAddressButtons(),
        ],
      ),
    );
  }

  Widget _buildCategorySelection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildRideDetail(Icons.access_time, '${_estimatedDurationInMinutes.round()} min', 'Duration'),
            Container(height: 40, width: 1, color: Colors.grey.shade300),
            _buildRideDetail(Icons.route, '${_distanceInKm.toStringAsFixed(1)} km', 'Distance'),
          ],
        ),
        const Divider(height: 24),
        ...RideCategory.values.map((category) => _buildPremiumCategoryCard(category)),
        
        // ✅ NOU: Ride Sharing Option
        if (_isRideSharingEnabled && _faresByCategory.isNotEmpty) ...[
          const SizedBox(height: 16),
          RideSharingOptionWidget(
            isEnabled: _isRideSharingEnabled,
            isSelected: _isRideSharingSelected,
            originalCost: _faresByCategory[_selectedCategory]?['totalCost'] ?? 0.0,
            sharedCost: _isRideSharingSelected
                ? (_faresByCategory[_selectedCategory]?['totalCost'] ?? 0.0) * 0.7
                : null,
            onChanged: (value) {
              setState(() {
                _isRideSharingSelected = value;
              });
            },
          ),
        ],
        
        const SizedBox(height: 16),
        // ✅ NOU: Mesaj pentru auto-start
        if (_isAutoStarting)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  'Căutare șoferi...',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _confirmAndRequestRide,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
            ),
            child: Text(
              widget.isScheduling 
                  ? 'Schedule Ride' 
                  : (_isAutoStarting ? 'Căutare în curs...' : 'Confirm & Request Ride'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        if (widget.isScheduling) _buildDisclaimer(context),
      ],
    );
  }

  Widget _buildRideDetail(IconData icon, String value, String label) {
    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.visible,
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.visible,
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCategoryCard(RideCategory category) {
    final fare = _faresByCategory[category];
    if (fare == null) return const SizedBox.shrink();
    
    final etaResult = _etaByCategory[category];
    String? estimatedTime;
    
    if (etaResult != null) {
      // Format: "~5 min • 2.3 km" (ETA și distanță)
      estimatedTime = '~${etaResult.durationInMinutes} min • ${_distanceInKm.toStringAsFixed(1)} km';
    } else if (_distanceInKm > 0) {
      // Dacă nu avem ETA dar avem distanță, afișăm doar distanța
      estimatedTime = '${_distanceInKm.toStringAsFixed(1)} km';
    }
    
    // Determină dacă este recomandat (Standard este recomandat implicit)
    final isRecommended = category == RideCategory.standard;
    
    return PremiumCategoryCard(
      category: category,
      icon: _getCategoryIcon(category),
      title: category.name[0].toUpperCase() + category.name.substring(1),
      subtitle: _getCategorySubtitle(category),
      fareDetails: fare,
      isSelected: category == _selectedCategory,
      onTap: () => _onCategorySelected(category),
      estimatedTime: estimatedTime,
      isRecommended: isRecommended,
    );
  }
  
  // ✅ NOU: Handler pentru selecția categoriei cu auto-start
  void _onCategorySelected(RideCategory category) {
    // Anulează timer-ul anterior dacă există
    _autoStartTimer?.cancel();
    
    setState(() {
      _selectedCategory = category;
      _isAutoStarting = false; // Reset indicator
    });
    
    // ✅ Auto-start căutare șoferi după 2.5 secunde (comportament Uber/Bolt)
    _autoStartTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted && _faresByCategory.isNotEmpty && _startPoint != null && _endPoint != null) {
        Logger.debug('Căutare șoferi declanșată automat pentru categoria: ${category.name}', tag: 'AUTO-START');
        setState(() {
          _isAutoStarting = true; // Afișează indicator
        });
        _confirmAndRequestRide();
      }
    });
  }

  Widget _buildSuggestionsList() {
    if (!_isShowingSuggestions || _suggestions.isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 200,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return ListTile(
            leading: const Icon(Icons.location_on),
            title: Text(suggestion.description, maxLines: 2, overflow: TextOverflow.ellipsis),
            onTap: () => _onSuggestionSelected(suggestion),
          );
        },
      ),
    );
  }

  // --- HELPER METHODS & WIDGETS ---

  void _resetToAddressInput() {
    _stopListeningForDriverUpdates();

    setState(() {
      _faresByCategory.clear();
      _etaByCategory.clear();
      _routeGeoJSON = null;
      _destinationAddressController.clear();
      _endPoint = null;
      _mapboxMap?.style.removeStyleLayer("route-layer");
      _mapboxMap?.style.removeStyleSource("route-source");
      _pointAnnotationManager?.deleteAll();
      _addStartMarker();
    });
  }
  
  void _onFocusChange() {
    setState(() {
      _isShowingSuggestions = _startFocusNode.hasFocus || _destinationFocusNode.hasFocus;
    });
  }

  void _onAddressChanged(TextEditingController controller) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (controller.text.length < 3) {
      if (mounted) {
        setState(() => _suggestions = []);
      }
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 700), () async {
      final results = await _geocodingService.fetchSuggestions(controller.text, widget.startPosition);
      if (mounted) {
        setState(() => _suggestions = results);
      }
    });
  }

  // FUNCȚIA MODIFICATĂ - returnează datele când se selectează destinația
  Future<void> _onSuggestionSelected(AddressSuggestion suggestion) async {
    final focusScope = FocusScope.of(context);
    List<Location> locations = await locationFromAddress(suggestion.description);
    
    if (!mounted || locations.isEmpty) return;

            final selectedPoint = MapboxUtils.createPoint(locations.first.latitude, locations.first.longitude);

    if (_startFocusNode.hasFocus) {
      // Logica pentru punctul de start rămâne neschimbată
      setState(() {
        _startAddressController.text = suggestion.description;
        _startPoint = selectedPoint;
        _suggestions = [];
        _isShowingSuggestions = false;
      });
      
      focusScope.unfocus();
    } else if (_destinationFocusNode.hasFocus) {
      // Pentru destinație, returnează datele către map_screen.dart
      final result = {
        'point': selectedPoint,
        'address': suggestion.description,
      };

      // Închide ecranul și returnează rezultatul
      Navigator.of(context).pop(result);
      return; // Ieși din funcție pentru a nu continua cu logica de mai jos
    }

    // Logica existentă pentru când ambele puncte sunt setate
    if (_startPoint != null && _endPoint != null) {
      _calculateRouteAndEta();
    }
  }

  Future<void> _getAddressFromPosition(geolocator.Position position, TextEditingController controller) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (mounted && placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        controller.text = "${place.street ?? ''}, ${place.locality ?? ''}".replaceAll(RegExp(r'^, |, $'), '');
      }
    } catch (e) {
      if (mounted) {
        controller.text = "Could not get current address";
      }
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    _pointAnnotationManager = await _mapboxMap?.annotations.createPointAnnotationManager(id: "markers-manager");
    _addStartMarker();
  }

  void _addStartMarker() async {
    if (_startPoint == null) return;
    final ByteData startIconBytes = await rootBundle.load("assets/images/passenger_icon.png");
    _pointAnnotationManager?.create(PointAnnotationOptions(
              geometry: _startPoint!,
      image: startIconBytes.buffer.asUint8List(),
      iconSize: 0.15,
      iconAnchor: IconAnchor.BOTTOM,
    ));
  }

  Future<void> _drawRouteAndMarkers() async {
    if (_mapboxMap == null) return;

    try {
      await _mapboxMap?.style.removeStyleLayer("route-layer");
      await _mapboxMap?.style.removeStyleSource("route-source");
    } catch (e) { /* Ignore if not found */ }
    _pointAnnotationManager?.deleteAll();

    if (_routeGeoJSON != null) {
      final routeGeometry = _routeGeoJSON!['routes'][0]['geometry'];
      await _mapboxMap?.style.addSource(GeoJsonSource(id: 'route-source', data: json.encode(routeGeometry)));
      await _mapboxMap?.style.addLayer(LineLayer(
          id: 'route-layer',
          sourceId: 'route-source',
          lineColor: Colors.blue.toARGB32(),
          lineWidth: 6.0,
          lineOpacity: 0.8));
    }

    final ByteData startIconBytes = await rootBundle.load("assets/images/passenger_icon.png");
    final ByteData endIconBytes = await rootBundle.load("assets/images/pin_icon.png");
    final markers = <PointAnnotationOptions>[];
    if (_startPoint != null) {
              markers.add(PointAnnotationOptions(geometry: _startPoint!, image: startIconBytes.buffer.asUint8List(), iconSize: 0.15, iconAnchor: IconAnchor.BOTTOM));
    }
    if (_endPoint != null) {
              markers.add(PointAnnotationOptions(geometry: _endPoint!, image: endIconBytes.buffer.asUint8List(), iconSize: 0.3, iconAnchor: IconAnchor.BOTTOM));
    }
    if (markers.isNotEmpty) {
      _pointAnnotationManager?.createMulti(markers);
    }

    if (_startPoint != null && _endPoint != null) {
      final centerLat = (_startPoint!.coordinates.lat + _endPoint!.coordinates.lat) / 2;
      final centerLng = (_startPoint!.coordinates.lng + _endPoint!.coordinates.lng) / 2;
              final centerPoint = MapboxUtils.createPoint(centerLat, centerLng);

      final distance = geolocator.Geolocator.distanceBetween(
        _startPoint!.coordinates.lat.toDouble(),
        _startPoint!.coordinates.lng.toDouble(),
        _endPoint!.coordinates.lat.toDouble(),
        _endPoint!.coordinates.lng.toDouble(),
      );

      double zoom = 14;
      if (distance > 1000) {
        zoom = 14 - (log(distance / 1000) / log(2));
      }
      zoom = max(zoom, 4.0);

      _mapboxMap?.flyTo(
        CameraOptions(
          center: centerPoint,
          zoom: zoom,
          padding: MbxEdgeInsets(top: 100, left: 50, bottom: 350, right: 50),
        ),
        MapAnimationOptions(duration: 1500),
      );
    }
  }
  
  // FUNCȚIA MODIFICATĂ - returnează datele pentru adresele salvate
  void _setDestinationFromSavedAddress(SavedAddress address) {
            final selectedPoint = MapboxUtils.createPoint(address.coordinates.latitude, address.coordinates.longitude);
    
    // Creează rezultatul pentru a-l returna
    final result = {
      'point': selectedPoint,
      'address': address.address,
    };

    // Închide ecranul și returnează rezultatul
    Navigator.of(context).pop(result);
  }

  Widget _buildAddressInput({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String labelText,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Theme.of(context).canvasColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        suffixIcon: IconButton(
          icon: const Icon(Icons.map_outlined, color: Colors.blue),
          tooltip: 'Choose on map',
          onPressed: () async {
            final result = await Navigator.of(context).push<Map<String, dynamic>>(
              MaterialPageRoute(builder: (ctx) => MapPickerScreen(initialLocation: widget.startPosition)),
            );
            if (result != null && result.containsKey('location')) {
              final newPoint = result['location'] as Point;
              final newAddress = result['address'] as String;
              
              if (focusNode == _startFocusNode) {
                // Pentru start location, setează local
                setState(() {
                  _startAddressController.text = newAddress;
                  _startPoint = newPoint;
                });
              } else {
                // Pentru destination, returnează datele
                final destinationResult = {
                  'point': newPoint,
                  'address': newAddress,
                };
                if (mounted) {
  Navigator.of(context).pop(destinationResult);
}
              }
            }
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'This field is required.';
        }
        return null;
      },
    );
  }
  
  Widget _buildQuickAddressButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (_homeAddress != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ActionChip(
                avatar: const Icon(Icons.home, size: 18),
                label: const Text('Home'),
                onPressed: () => _setDestinationFromSavedAddress(_homeAddress!),
              ),
            ),
          if (_workAddress != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ActionChip(
                avatar: const Icon(Icons.work, size: 18),
                label: const Text('Work'),
                onPressed: () => _setDestinationFromSavedAddress(_workAddress!),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSchedulingFields(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context, 
                    initialDate: _scheduledDate ?? DateTime.now(), 
                    firstDate: DateTime.now(), 
                    lastDate: DateTime.now().add(const Duration(days: 30))
                  );
                  if (picked != null) {
                    setState(() => _scheduledDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date', 
                    border: OutlineInputBorder(), 
                    prefixIcon: Icon(Icons.calendar_today)
                  ),
                  child: Text(_scheduledDate == null ? 'Select date' : DateFormat('dd MMMM yyyy', 'ro_RO').format(_scheduledDate!)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context, 
                    initialTime: _scheduledTime ?? TimeOfDay.now()
                  );
                  if (picked != null) {
                    setState(() => _scheduledTime = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Time', 
                    border: OutlineInputBorder(), 
                    prefixIcon: Icon(Icons.access_time)
                  ),
                  child: Text(_scheduledTime == null ? 'Select time' : _scheduledTime!.format(context)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDisclaimer(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (ctx) => const LegalScreen())
        ),
        child: Text(
          'No fee for cancellations made more than 1.5 hours in advance. See Terms & Conditions.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary, 
            decoration: TextDecoration.underline, 
            fontSize: 12
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(RideCategory category) {
    switch (category) {
      case RideCategory.standard: 
        return Icons.drive_eta;
      case RideCategory.family:
        return Icons.family_restroom_rounded;
      case RideCategory.energy: 
        return Icons.electric_car;
      case RideCategory.best: 
        return Icons.star;
    }
  }

  String _getCategorySubtitle(RideCategory category) {
    switch (category) {
      case RideCategory.standard: 
        return "The most affordable option.";
      case RideCategory.family:
        return "More space for family and luggage.";
      case RideCategory.energy: 
        return "Travel eco with an electric car.";
      case RideCategory.best: 
        return "Experience premium comfort.";
    }
  }
  
  // --- DATA LOADING ---
  void _loadSavedAddresses() {
    _firestoreService.getSavedAddresses().listen((addresses) {
      if (mounted) {
        setState(() {
          try {
            _homeAddress = addresses.firstWhere((addr) =>
                addr.label.toLowerCase() == 'acasă' ||
                addr.label.toLowerCase() == 'acasa');
          } catch (e) {
            _homeAddress = null;
          }
          try {
            _workAddress = addresses.firstWhere((addr) =>
                addr.label.toLowerCase() == 'serviciu' ||
                addr.label.toLowerCase() == 'birou');
          } catch (e) {
            _workAddress = null;
          }
        });
      }
    });
  }
}