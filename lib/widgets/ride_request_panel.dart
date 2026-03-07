// lib/widgets/ride_request_panel.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:friendsride_app/models/ride_model.dart';
import 'package:friendsride_app/models/stop_location.dart';
import 'package:friendsride_app/screens/searching_for_driver_screen.dart';
import 'package:friendsride_app/services/firestore_service.dart';
import 'package:friendsride_app/services/pricing_service.dart';
import 'package:friendsride_app/services/routing_service.dart';
import 'package:friendsride_app/widgets/address_input_view.dart';
import 'package:friendsride_app/widgets/ride_confirmation_view.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:friendsride_app/utils/logger.dart';

enum PanelState { addressInput, rideConfirmation }

class RideRequestPanel extends StatefulWidget {
  final geolocator.Position startPosition;
  final Function(Map<String, dynamic>?) onRouteCalculated; 

  const RideRequestPanel({
    super.key,
    required this.startPosition,
    required this.onRouteCalculated,
  });

  @override
  State<RideRequestPanel> createState() => RideRequestPanelState();
}

class RideRequestPanelState extends State<RideRequestPanel> {
  PanelState _panelState = PanelState.addressInput;
  bool _isLoading = false;

  final FirestoreService _firestoreService = FirestoreService();
  final PricingService _pricingService = PricingService();
  final RoutingService _routingService = RoutingService();
  // final EtaService _etaService = EtaService(); // Eliminat

  Point? _startPoint;
  Point? _endPoint;
  String _startAddress = '';
  String _destinationAddress = '';
  
  // ADĂUGAT: Variabile pentru opriri multiple
  final List<StopLocation> _stops = <StopLocation>[];
  
  Map<RideCategory, Map<String, double>> _faresByCategory = {};
  Map<RideCategory, DriverEtaResult?> _etaByCategory = {};
  double _distanceInKm = 0;
  double _estimatedDurationInMinutes = 0;
  RideCategory _selectedCategory = RideCategory.standard;

  StreamSubscription? _driverLocationSubscription;

  @override
  void initState() {
    super.initState();
    _startPoint = Point(coordinates: Position(widget.startPosition.longitude, widget.startPosition.latitude));
  }

  @override
  void dispose() {
    _driverLocationSubscription?.cancel();
    super.dispose();
  }

  // ADĂUGAT: Metodă publică pentru resetarea panelului
  void resetPanel() {
    if (!mounted) return;
    
    Logger.debug('RideRequestPanel: Resetting panel state');
    
    setState(() {
      _panelState = PanelState.addressInput;
      _isLoading = false;
      _endPoint = null;
      _startAddress = '';
      _destinationAddress = '';
      _stops.clear(); // Resetăm opririle
      _faresByCategory.clear();
      _etaByCategory.clear();
      _distanceInKm = 0;
      _estimatedDurationInMinutes = 0;
      _selectedCategory = RideCategory.standard;
    });
    
    _driverLocationSubscription?.cancel();
    
    // Curățăm ruta din MapScreen
    widget.onRouteCalculated(null);
    
    Logger.info('RideRequestPanel: Reset completed');
  }

  // ✅ NOU: Metodă pentru setarea destinației din exterior (POI selection)
  void setDestination({
    required String address,
    required double latitude,
    required double longitude,
  }) {
    Logger.info('RideRequestPanel: Setting destination from POI: $address');
    Logger.info('RideRequestPanel: Destination coordinates: $latitude, $longitude');
    
    if (!mounted) {
      Logger.error('RideRequestPanel: Cannot set destination - widget not mounted');
      return;
    }
    
    try {
      setState(() {
        _destinationAddress = address;
        _endPoint = Point(coordinates: Position(longitude, latitude));
        Logger.info('RideRequestPanel: Destination state updated successfully');
      });
      
      // Recalculează ruta dacă ai și pickup
      if (_startPoint != null) {
        Logger.info('RideRequestPanel: Recalculating route with new destination...');
        _onDestinationSelected(_startPoint!, _endPoint!, _startAddress, _destinationAddress);
      } else {
        Logger.info('RideRequestPanel: No pickup point yet - waiting for pickup');
      }
      
      Logger.info('RideRequestPanel: Destination set successfully');
      
    } catch (e) {
      Logger.error('RideRequestPanel: Error setting destination: $e', error: e);
      Logger.error('Stack trace: ${StackTrace.current}');
    }
  }
  
  // ✅ NOU: Metodă pentru setarea pickup-ului din exterior (POI selection)
  void setPickup({
    required String address,
    required double latitude,
    required double longitude,
  }) {
    Logger.info('RideRequestPanel: Setting pickup from POI: $address');
    Logger.info('RideRequestPanel: Pickup coordinates: $latitude, $longitude');
    
    if (!mounted) {
      Logger.error('RideRequestPanel: Cannot set pickup - widget not mounted');
      return;
    }
    
    try {
      setState(() {
        _startAddress = address;
        _startPoint = Point(coordinates: Position(longitude, latitude));
        Logger.info('RideRequestPanel: Pickup state updated successfully');
      });
      
      // Recalculează ruta dacă ai și destinația
      if (_endPoint != null) {
        Logger.info('RideRequestPanel: Recalculating route with new pickup...');
        _onDestinationSelected(_startPoint!, _endPoint!, _startAddress, _destinationAddress);
      } else {
        Logger.info('RideRequestPanel: No destination yet - waiting for destination');
      }
      
      Logger.info('RideRequestPanel: Pickup set successfully');
      
    } catch (e) {
      Logger.error('RideRequestPanel: Error setting pickup: $e', error: e);
      Logger.error('Stack trace: ${StackTrace.current}');
    }
  }

  // ✅ ÎMBUNĂTĂȚIT: Metoda addStop cu validare completă
  void addStop(StopLocation stop) {
    // ✅ VALIDARE NUMĂR MAXIM OPRIRI
    if (_stops.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Poți adăuga maximum 5 opriri'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // ✅ VALIDARE DISTANȚĂ ÎNTRE OPRIRI
    if (_stops.isNotEmpty) {
      final lastStop = _stops.last;
      final distance = _calculateDistanceBetweenStops(lastStop, stop);
      if (distance < 0.1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opririle trebuie să fie la cel puțin 100m distanță'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }
    
    setState(() {
      _stops.add(stop);
    });
    
    Logger.info('Added stop: ${stop.address}. Total stops: ${_stops.length}');
    
    // Recalculăm ruta doar dacă avem și destinația setată
    if (_endPoint != null) {
      _recalculateRouteWithStops();
    }
  }
  
  // ✅ NOU: Calculează distanța între două opriri
  double _calculateDistanceBetweenStops(StopLocation stop1, StopLocation stop2) {
    const double earthRadius = 6371; // km
    final lat1 = stop1.latitude * (math.pi / 180);
    final lat2 = stop2.latitude * (math.pi / 180);
    final deltaLat = (stop2.latitude - stop1.latitude) * (math.pi / 180);
    final deltaLng = (stop2.longitude - stop1.longitude) * (math.pi / 180);
    
    final a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(deltaLng / 2) * math.sin(deltaLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  // ADĂUGAT: Metoda removeStop să recalculeze ruta
  void removeStop(int index) {
    if (index >= 0 && index < _stops.length) {
      final removedStop = _stops[index];
      setState(() {
        _stops.removeAt(index);
      });
      
      Logger.debug('Removed stop: ${removedStop.address}. Remaining stops: ${_stops.length}');
      
      // Recalculăm ruta doar dacă avem destinația
      if (_endPoint != null) {
        if (_stops.isEmpty) {
          // Dacă nu mai avem opriri, calculăm ruta simplă
          _onDestinationSelected(_startPoint!, _endPoint!, _startAddress, _destinationAddress);
        } else {
          // Altfel recalculăm cu opririle rămase
          _recalculateRouteWithStops();
        }
      }
    }
  }

  // ADĂUGAT: Metodă pentru recalcularea rutei cu opriri
  Future<void> _recalculateRouteWithStops() async {
    if (_startPoint == null || _endPoint == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Construim lista de waypoints: start -> opriri -> destinație
      List<Point> waypoints = [_startPoint!];
      
      // Adăugăm opririle în ordinea corectă
      for (var stop in _stops) {
        waypoints.add(Point(coordinates: Position(stop.longitude, stop.latitude)));
        Logger.debug('Added stop waypoint: ${stop.address} at ${stop.latitude}, ${stop.longitude}');
      }
      
      // Adăugăm destinația
      waypoints.add(_endPoint!);
      
      Logger.debug('Recalculating route with ${waypoints.length} waypoints (${_stops.length} stops)');
      
      final routeData = await _routingService.getRoute(waypoints);
      if (!mounted) return;
      if (routeData == null) throw Exception("Nu s-a putut calcula ruta cu opriri.");

      // IMPORTANT: Trimitem ruta actualizată către MapScreen
      widget.onRouteCalculated(routeData);

      _distanceInKm = _routingService.extractDistance(routeData) / 1000;
      
      // CORECTAT: Folosim o viteză medie constantă
      const double averageSpeed = 40.0; // Viteza medie in km/h
      _estimatedDurationInMinutes = (_distanceInKm / averageSpeed) * 60;

      // Recalculăm tarifele incluzând taxa pentru opriri
      _faresByCategory = {
        for (var category in RideCategory.values)
          category: _pricingService.calculateFareWithStops(
            distanceInKm: _distanceInKm,
            durationInMinutes: _estimatedDurationInMinutes,
            category: category,
            numberOfStops: _stops.length,
          ),
      };

      await _calculateEtaForAllCategories();
      
      Logger.info('Route recalculated successfully with ${_stops.length} stops');
      
    } catch (e) {
      Logger.error('Error recalculating route with stops: $e', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la recalcularea rutei: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onDestinationSelected(Point startPoint, Point endPoint, String startAddress, String destAddress) async {
    setState(() {
      _isLoading = true;
      _startPoint = startPoint;
      _endPoint = endPoint;
      _startAddress = startAddress;
      _destinationAddress = destAddress;
    });

    // ✅ FEEDBACK PENTRU UTILIZATOR
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se calculează ruta...'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    try {
      // Construim waypoints incluzând opririle dacă există
      List<Point> waypoints = [startPoint];
      
      // Adăugăm opririle existente
      for (var stop in _stops) {
        waypoints.add(Point(coordinates: Position(stop.longitude, stop.latitude)));
        Logger.debug('Including existing stop: ${stop.address}');
      }
      
      waypoints.add(endPoint);
      
      Logger.debug('Calculating route with ${waypoints.length} waypoints including ${_stops.length} stops');
      
      final routeData = await _routingService.getRoute(waypoints);
      if (!mounted) return;
      if (routeData == null) throw Exception("Nu s-a putut calcula ruta.");

      widget.onRouteCalculated(routeData);

      _distanceInKm = _routingService.extractDistance(routeData) / 1000;
      
      // CORECTAT: Folosim o viteză medie constantă
      const double averageSpeed = 40.0; // Viteza medie in km/h
      _estimatedDurationInMinutes = (_distanceInKm / averageSpeed) * 60;

      // MODIFICAT: Calculăm tarifele incluzând opririle
      _faresByCategory = {
        for (var category in RideCategory.values)
          category: _stops.isEmpty 
            ? _pricingService.calculateFare(
                distanceInKm: _distanceInKm,
                durationInMinutes: _estimatedDurationInMinutes,
                category: category,
              )
            : _pricingService.calculateFareWithStops(
                distanceInKm: _distanceInKm,
                durationInMinutes: _estimatedDurationInMinutes,
                category: category,
                numberOfStops: _stops.length,
              ),
      };

      await _calculateEtaForAllCategories();
      if (!mounted) return;

      setState(() {
        _panelState = PanelState.rideConfirmation;
        _isLoading = false;
      });
      _listenForDriverUpdates();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() { _isLoading = false; });
      }
    }
  }
  
  Future<void> _calculateEtaForAllCategories() async {
    if (_startPoint == null) return;
    final results = <RideCategory, DriverEtaResult?>{};
    for (final category in RideCategory.values) {
        results[category] = await _firestoreService.getNearestDriverEta(_startPoint!, category);
    }
    if(mounted) {
        setState(() { _etaByCategory = results; });
    }
  }

  void _listenForDriverUpdates() {
    _driverLocationSubscription?.cancel();
    _driverLocationSubscription = _firestoreService.getNearbyAvailableDrivers().listen((snapshot) {
      if (mounted && _panelState == PanelState.rideConfirmation) {
         _calculateEtaForAllCategories();
      }
    });
  }

  Future<void> _confirmAndRequestRide() async {
    final fareDetails = _faresByCategory[_selectedCategory];
    if (fareDetails == null || _startPoint == null || _endPoint == null) return;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    // ✅ VALIDARE DISTANȚĂ MINIMĂ/MAXIMĂ
    if (_distanceInKm < 0.1) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Distanța este prea mică. Distanța minimă este 100 metri.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (_distanceInKm > 200) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Distanța este prea mare. Distanța maximă este 200 km.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    Logger.info('Creating ride for user: $userId with ${_stops.length} stops', tag: 'RIDE');
    setState(() { _isLoading = true; });
    
    final ride = Ride(
      id: '', // Va fi generat de Firestore
      passengerId: userId,  // ✅ MODIFICAT: userId → passengerId
      startAddress: _startAddress,
      destinationAddress: _destinationAddress,
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
      // ADĂUGAT: Includem opririle în ride
      stops: _stops.map((stop) => stop.toMap()).toList(),
    );

    // ADĂUGAT: Debug pentru a verifica opririle
    Logger.info('Ride stops: ${ride.stops}', tag: 'RIDE');

    Logger.info('Calling requestRide...', tag: 'RIDE');
    final rideId = await _firestoreService.requestRide(ride);
    Logger.info('Ride created with ID: $rideId', tag: 'RIDE');
    if (!mounted) return;

    setState(() { _isLoading = false; });
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => SearchingForDriverScreen(rideId: rideId)),
    );
  }
  
  void _resetToAddressInput() {
    _driverLocationSubscription?.cancel();
    widget.onRouteCalculated(null);
    setState(() {
      _panelState = PanelState.addressInput;
      _faresByCategory.clear();
      _etaByCategory.clear();
      // Nu resetăm opririle când ne întoarcem la address input
      // Utilizatorul poate să-și păstreze opririle și să schimbe doar destinația
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [ 
              BoxShadow(
                color: Colors.black.withAlpha(38), 
                blurRadius: 10, 
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _panelState == PanelState.addressInput
                    ? AddressInputView(
                        key: const ValueKey('addressInput'),
                        scrollController: scrollController,
                        startPosition: widget.startPosition,
                        onDestinationSelected: _onDestinationSelected,
                        // ADĂUGAT: Trimitem datele despre opriri către AddressInputView
                        stops: _stops,
                        onStopAdded: addStop,
                        onStopRemoved: removeStop,
                      )
                    : RideConfirmationView(
                        key: const ValueKey('rideConfirm'),
                        scrollController: scrollController,
                        fares: _faresByCategory,
                        etas: _etaByCategory,
                        distance: _distanceInKm,
                        duration: _estimatedDurationInMinutes,
                        selectedCategory: _selectedCategory,
                        onCategorySelected: (category) { 
                          if(mounted) { 
                            setState(() { 
                              _selectedCategory = category; 
                            });
                          }
                        },
                        onConfirm: _confirmAndRequestRide,
                        onBack: _resetToAddressInput,
                        // ADĂUGAT: Trimitem și informații despre opriri
                        stops: _stops,
                      ),
              ),
              if (_isLoading)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(128),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        );
      },
    );
  }
}