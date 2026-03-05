import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'package:friendsride_app/services/audio_service.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../utils/mapbox_utils.dart';
import '../utils/deprecated_apis_fix.dart';
import 'package:friendsride_app/models/ride_model.dart';
import 'package:friendsride_app/screens/active_ride_screen.dart';
import 'package:friendsride_app/services/firestore_service.dart';
import 'package:friendsride_app/widgets/app_drawer.dart';
import 'package:friendsride_app/widgets/ride_request_panel.dart';
import 'package:friendsride_app/widgets/draggable_ai_button.dart'; // AI button activat
import 'package:friendsride_app/voice/integration/friendsride_voice_integration.dart';
import 'package:friendsride_app/voice/states/voice_interaction_states.dart';
import 'package:friendsride_app/voice/driver/driver_voice_controller.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:friendsride_app/theme/theme_provider.dart';
// NOU: Adăugat pentru POI-uri interactive
import 'package:friendsride_app/services/poi_service.dart';
import 'package:friendsride_app/models/poi_model.dart';
import 'package:friendsride_app/services/routing_service.dart';
import 'package:friendsride_app/screens/searching_for_driver_screen.dart';
import 'package:friendsride_app/services/bucharest_locations_database.dart';
import 'package:friendsride_app/l10n/app_localizations.dart';
import 'package:friendsride_app/widgets/assistant_status_overlay.dart';
import 'package:friendsride_app/providers/assistant_status_provider.dart';
import 'package:friendsride_app/utils/logger.dart';



class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver, TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final AudioService _audioService = AudioService();
  // NOU: Servicii pentru POI-uri interactive
  final PoiService _poiService = PoiService();
  final RoutingService _routingService = RoutingService();
  
  MapboxMap? _mapboxMap;
  
  PolylineAnnotationManager? _routeAnnotationManager;
  PolylineAnnotationManager? _altRouteAnnotationManager; // faint alternatives
  PointAnnotationManager? _userPointAnnotationManager;
  PointAnnotationManager? _routeMarkersAnnotationManager;
  PointAnnotationManager? _driversAnnotationManager;
  // Deprecated: POIs now use SymbolLayer; old manager removed
  CircleAnnotationManager? _pickupCircleManager;
  CircleAnnotationManager? _destinationCircleManager;
  CircleAnnotationManager? _pickupSuggestionsManager;

  // POI performance tuning
  static const int _poiMaxMarkers = 200;   // Cap the number of listed POIs
  PoiCategory? _selectedPoiCategory;       // Current selected POI category (only render after user selects)

  // SymbolLayer + clustering identifiers
  final String _poiSourceId = 'poi-source';
  final String _poiClusterLayerId = 'poi-cluster-layer';
  final String _poiClusterCountLayerId = 'poi-cluster-count-layer';
  final String _poiSymbolLayerId = 'poi-symbol-layer';
  final String _selectedPoiSourceId = 'selected-poi-source';
  final String _selectedPoiLayerId = 'selected-poi-layer';

  // Draggable POI card position
  Offset _poiCardPosition = const Offset(16, 180);

  PointAnnotation? _userPointAnnotation;
  final Map<String, PointAnnotation> _nearbyDriverAnnotations = {};
  // NOU: POI-uri și state management
  final Map<String, PointAnnotation> _poiAnnotations = {};
  PointOfInterest? _selectedPoi;
  bool _showPoiCard = false;
  final List<PointOfInterest> _currentPois = [];
  Timer? _poiUpdateTimer;
  // ✅ NOU: Timer pentru debouncing operațiunile POI 
  Timer? _poiOperationTimer;
  // ✅ NOU: Auto-hide pentru POI selectat dacă nu se navighează
  Timer? _selectedPoiAutoHideTimer;
  
  // ✅ Stabilizare layere POI
  bool _poiLayersInitialized = false;

  // ✅ Debounce pentru animațiile camerei (flyTo)
  Timer? _cameraFlyToTimer;

  // ✅ Throttle pentru drag pe cardul POI
  static const int _poiCardPanThrottleMs = 24;
  DateTime _lastPoiCardPanUpdate = DateTime.fromMillisecondsSinceEpoch(0);

  // ✅ "Search this area" chip disabled per request
  bool _showSearchAreaChip = false; // kept for compatibility, but not used in UI
  double? _lastSearchCenterLat;
  double? _lastSearchCenterLng;

  // ✅ Preview ETA & distance for selected POI (reserved)
  
  // ✅ Loading state pentru căutare POI (chip disabled)
  // ignore: unused_field
  bool _isLoadingPois = false;

  // ✅ Saved places (acasă/birou) — reserved

  // ✅ Scale bar text
  String _scaleBarText = '';

  // ✅ Alternative routes UI state
  bool _isFetchingAlternatives = false;
  // 🚀 First frame optimization: defer MapWidget attach
  bool _showMap = false;
  List<Map<String, dynamic>> _alternativeRoutes = [];
  int _selectedAltRouteIndex = 0;
  double? _currentRouteDistanceMeters;
  double? _currentRouteDurationSeconds;
  String? _pickupQualityLabel;
  Color? _pickupQualityColor;

  // ✅ Pulse animation for pickup marker
  AnimationController? _pickupPulseController;
  Animation<double>? _pickupPulse;

  // ✅ Pulse animation for main route polyline
  AnimationController? _routePulseController;
  Animation<double>? _routePulse;
  PolylineAnnotation? _activeRouteAnnotation;

  // ✅ Recommended pickup spots state
  bool _showPickupSuggestions = false;
  List<Point> _pickupSuggestionPoints = [];

  // ✅ First-run tooltips disabled
  // ignore: unused_field
  bool _tipSearchAreaSeen = true;
  bool _tipAltRoutesSeen = true;
  // ignore: unused_field
  bool _tipRecenterSeen = true;
  // ignore: unused_field
  bool _tipCompassSeen = true;

  Future<void> _prewarmTiles() async {
    try {
      final cam = await _mapboxMap?.getCameraState();
      if (cam == null) return;
      // Setăm prefetch-zoom-delta pe surse raster/vector comune pentru first paint mai rapid
      // Notă: numele surselor variază pe stil; încercăm câteva chei comune în mod best-effort
      const List<String> candidateSources = [
        'composite', // vector base
        'mapbox',
        'basemap',
        'raster-dem',
      ];
      for (final src in candidateSources) {
        try {
          await _mapboxMap!.style.setStyleSourceProperty(src, 'prefetch-zoom-delta', 2);
        } catch (_) {
          // ignore if source not present or property not supported
        }
      }
      // Mică animație de nudge a camerei pentru a declanșa încărcarea timpurie (non-invazivă)
      final center = cam.center;
      final zoom = cam.zoom;
      await _mapboxMap?.flyTo(
        CameraOptions(center: center, zoom: (zoom - 0.01).clamp(0.0, 22.0)),
        MapAnimationOptions(duration: AppDrawer.lowDataMode ? 200 : 300),
      );
      await _mapboxMap?.flyTo(
        CameraOptions(center: center, zoom: zoom),
        MapAnimationOptions(duration: AppDrawer.lowDataMode ? 150 : 250),
      );
    } catch (_) {}
  }
  // ✅ NOU: Logica de vizibilitate pentru AI-ul vocal
  bool get canShowVoiceAI {
    // 🎯 LOGICĂ: Afișează butonul AI pentru pasageri și șoferi indisponibili
    if (_currentRole == UserRole.passenger) return true;
    if (_currentRole == UserRole.driver && !_isDriverAvailable) return true;
    return false;
  }
  
  // ✅ NOU: Voice Overlay State - eliminat, folosit din PassengerVoiceController
  // bool _showVoiceOverlay = false; // ❌ ELIMINAT
  // final TextEditingController _voiceDestinationController = TextEditingController(); // ❌ ELIMINAT
  // final TextEditingController _voicePickupController = TextEditingController(); // ❌ ELIMINAT
  // String _aiResponse = ''; // ❌ ELIMINAT
  // final bool _isListening = false; // ❌ ELIMINAT
  
  // 🛑 NOU: Opriri Intermediare State
  final List<TextEditingController> _intermediateStopsControllers = [];
  final List<String> _intermediateStops = [];
  final int _maxIntermediateStops = 3;
  
  // ✅ NOU: Continuous Listening State - eliminat, folosit din PassengerVoiceController
  // bool _isContinuousListeningActive = false; // ❌ ELIMINAT
  // Timer? _continuousListeningTimer; // ❌ ELIMINAT
  // int _continuousListeningDuration = 0; // ❌ ELIMINAT

  UserRole _currentRole = UserRole.passenger; // ✅ Inițializat corect
  geolocator.Position? _currentPositionObject;
  geolocator.Position? _previousPositionObject;
  bool _isDriverAvailable = false;
  
  // ✅ ÎMBUNĂTĂȚIT: Timer constant pentru șoferii stăționari
  Timer? _locationUpdateTimer; 

  // NOU: Am adăugat un StreamSubscription pentru a gestiona ascultarea locației.
  StreamSubscription<geolocator.Position>? _positionSubscription;
  
  // NOU: Variabile pentru logica de frecvență adaptivă.
  DateTime? _lastUpdateTime;
  final int _standingInterval = 30;
  final int _slowSpeedInterval = 15;
  final int _highSpeedInterval = 5;

  // ✅ Control pentru loguri verbose în build
  static const bool _verboseBuildLogs = false;


  Map<String, dynamic>? _driverProfile;

  bool _shouldResetRoute = false;
  
  // 🚗 FIX: Protecție împotriva apăsărilor multiple pentru butoanele șofer
  bool _isProcessingAccept = false;
  bool _isProcessingDecline = false;
  
  final GlobalKey<RideRequestPanelState> _rideRequestPanelKey = GlobalKey<RideRequestPanelState>();

  StreamSubscription<List<Ride>>? _pendingRidesSubscription;
  StreamSubscription<DocumentSnapshot>? _driverProfileSubscription;
  StreamSubscription? _nearbyDriversSubscription;
  StreamSubscription<QuerySnapshot>? _chatMessagesSubscription;

  Ride? _currentActiveRide;
  double? _driverPickupDistanceKm;
  Duration? _driverPickupEta;
  DateTime? _driverPickupArrivalTime;
  double? _driverDestinationDistanceKm;
  Duration? _driverDestinationEta;
  DateTime? _driverDestinationArrivalTime;
  String? _driverTrafficSummary;
  geolocator.Position? _driverLastEtaPosition;
  DateTime? _driverLastEtaRequestTime;
  bool _driverIsFetchingEta = false;
  static const Duration _driverEtaThrottle = Duration(seconds: 10);
  static const double _driverEtaDistanceThresholdMeters = 80.0;
  RideCategory? _driverCategory;
  List<Ride> _pendingRides = [];
  Ride? _currentRideOffer;
  Timer? _rideOfferTimer;
  int _remainingSeconds = 30;
  
  // ✅ FIX: Câmpul a fost eliminat pentru că nu mai este folosit
  // bool _isNavigatingToActiveRide = false;

  // NOU: Variabile pentru POI functionality - pickup, destination, stops
  final TextEditingController _pickupController = TextEditingController();
  double? _pickupLatitude;
  double? _pickupLongitude;

  
  final TextEditingController _destinationController = TextEditingController();
  double? _destinationLatitude;
  double? _destinationLongitude;
  

  // Afișare automată traseu când avem pickup + destinație (+ opriri)
  Future<void> _checkAndShowRouteAutomatically() async {
    if (_pickupLatitude != null &&
        _pickupLongitude != null &&
        _destinationLatitude != null &&
        _destinationLongitude != null) {
      Logger.debug('Auto-showing route: pickup and destination are set');
      try {
        final List<Point> waypoints = [];

        // Pickup
        waypoints.add(Point(
          coordinates: Position(_pickupLongitude!, _pickupLatitude!),
        ));

        // Opriri intermediare (dacă există)
        for (final stop in _intermediateStops) {
          final coordinates = await _getCoordinatesForDestination(stop);
          if (coordinates != null) {
            waypoints.add(coordinates);
          }
        }

        // Destinație
        waypoints.add(Point(
          coordinates: Position(_destinationLongitude!, _destinationLatitude!),
        ));

        final routeData = await _routingService.getRoute(waypoints);
        if (routeData != null && mounted) {
          await _onRouteCalculated(routeData);
          Logger.info('Route automatically displayed');
        }
      } catch (e) {
        Logger.error('Auto route calculation error: $e', error: e);
      }
    }
  }
  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addObserver(this);
    _initializeScreen();

    // Lazy-init voice services after first frame to avoid blocking first render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final voice = Provider.of<FriendsRideVoiceIntegration>(context, listen: false);
        unawaited(voice.warmUp().catchError((_) {}));
      } catch (_) {}
    });

    // Pulse marker controller
    if (!AppDrawer.lowDataMode) {
      _pickupPulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _pickupPulseController?.repeat(reverse: true);
        }
      });
      _pickupPulse = Tween<double>(begin: 1.0, end: 1.25).animate(CurvedAnimation(parent: _pickupPulseController!, curve: Curves.easeInOut));
    }

    // Load first-run tips flags
    () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (!mounted) return;
        setState(() {
          _tipSearchAreaSeen = prefs.getBool('tip_search_area_seen') ?? false;
          _tipAltRoutesSeen = prefs.getBool('tip_alt_routes_seen') ?? false;
          _tipRecenterSeen = prefs.getBool('tip_recenter_seen') ?? false;
          _tipCompassSeen = prefs.getBool('tip_compass_seen') ?? false;
        });
      } catch (_) {}
    }();
    
    // Defer map creation to first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      setState(() { _showMap = true; });
    });
  }

  // ✅ NOU: Metoda eliminată - folosit din PassengerVoiceController
  // void _showVoiceOverlayDialog() { ... } // ❌ ELIMINAT
  

  

  
  // 🗺️ Obține coordonatele pentru o destinație (cu geocoding real)
  Future<Point?> _getCoordinatesForDestination(String destination) async {
    try {
      // 1. Mai întâi verifică destinațiile predefinite (rapid)
      final predefinedCoordinates = _getPredefinedDestinationCoordinates(destination);
      if (predefinedCoordinates != null) {
        Logger.info('Destinație predefinită găsită: $destination');
        return predefinedCoordinates;
      }
      
      // 2. Dacă nu e predefinită, folosește geocoding API
      Logger.debug('Caut adresa cu geocoding: $destination');
      final coordinates = await _geocodeAddress(destination);
      
      if (coordinates != null) {
        Logger.info('Coordonate găsite cu geocoding: $destination');
        return coordinates;
      }
      
      // 3. ❌ NU FOLOSIM COORDONATE DEFAULT - Returnează null și gestionează eroarea
      Logger.warning('Nu am găsit coordonatele pentru: $destination');
      // Nu returnăm coordonate default - utilizatorul trebuie să specifice o adresă validă
      return null;
      
    } catch (e) {
      Logger.error('Eroare la găsirea coordonatelor: $e', error: e);
      // ❌ NU RETURNĂM COORDONATE DEFAULT
      return null;
    }
  }
  
  // 🗺️ Verifică destinațiile predefinite (rapid) - folosește baza de date extinsă
  Point? _getPredefinedDestinationCoordinates(String destination) {
    // ✅ FIX: Folosește baza de date locală extinsă pentru locații din București și Ilfov
    try {
      final location = BucharestLocationsDatabase.findLocation(destination);
      if (location != null) {
        Logger.info('Destinație predefinită găsită în baza de date: ${location['name']} (${location['category']})');
        return Point(
          coordinates: Position(
            location['longitude'] as double,
            location['latitude'] as double,
          ),
        );
      }
    } catch (e) {
      Logger.warning('Eroare la căutarea în baza de date: $e');
    }
    
    return null; // Nu e predefinită
  }
  
  // 🌍 Geocoding real pentru orice adresă din România (cu timeout și retry)
  Future<Point?> _geocodeAddress(String address) async {
    try {
      // Adaugă "România" la adresă dacă nu e specificat
      final fullAddress = address.toLowerCase().contains('românia') || 
                          address.toLowerCase().contains('romania')
        ? address 
        : '$address, România';
      
      Logger.debug('Geocoding pentru: $fullAddress');
      
      // Folosește OpenStreetMap Nominatim API (gratuit)
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(fullAddress)}'
        '&format=json'
        '&limit=1'
        '&countrycodes=ro'
        '&addressdetails=1'
      );
      
      // ✅ TIMEOUT PENTRU GEOCODING (10 secunde)
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Geocoding timeout');
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        
        if (results.isNotEmpty) {
          final result = results.first;
          final lat = double.parse(result['lat']);
          final lon = double.parse(result['lon']);
          
          // ✅ VALIDARE COORDONATE
          if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
            Logger.warning('Coordonate invalide pentru: $address');
            return null;
          }
          
          Logger.info('Geocoding reușit: $lat, $lon pentru $address');
          return Point(coordinates: Position(lon, lat));
        }
      }
      
      Logger.warning('Nu am găsit rezultate pentru: $address');
      return null;
      
    } on TimeoutException catch (e) {
      Logger.error('Geocoding timeout: $e', error: e);
      return null;
    } catch (e) {
      Logger.error('Eroare geocoding: $e', error: e);
      return null;
    }
  }
  
  // 🗺️ Adaugă marker pentru destinație pe hartă (pin asset)
  Future<void> _addDestinationMarker(Point coordinates, String title) async {
    try {
      // Șterge marker-ele anterioare de destinație
      await _routeMarkersAnnotationManager?.deleteAll();
      
      // Creează un nou marker pentru destinație folosind pin din assets
      final ByteData imageBytes = await rootBundle.load("assets/images/pin_icon.png");
      final Uint8List imageList = imageBytes.buffer.asUint8List();
      final destinationMarkerOptions = PointAnnotationOptions(
        geometry: coordinates,
        image: imageList,
        iconSize: 0.2,
        iconAnchor: IconAnchor.BOTTOM,
      );
      
      // Adaugă marker-ul pe hartă
      await _routeMarkersAnnotationManager?.create(destinationMarkerOptions);
      
      Logger.info('Marker destinație adăugat: $title');
    } catch (e) {
      Logger.error('Eroare la adăugarea marker-ului destinație: $e', error: e);
    }
  }
  
  // Metoda eliminată - nu este utilizată în codul actual
  
  // ✅ NOU: Metoda eliminată - folosit din PassengerVoiceController
  // Future<void> _bookRideWithVoiceDestination() async { ... } // ❌ ELIMINAT
  
  // Metoda eliminată - nu este utilizată în codul actual
  
  // Metodele eliminate - nu sunt utilizate în codul actual
  
  // Metoda eliminată - nu este utilizată în codul actual
  
  // Metoda eliminată - nu este utilizată în codul actual
  
  // Metoda eliminată - nu este utilizată în codul actual
  
  // ✅ NOU: Metoda eliminată - folosit din PassengerVoiceController
  // void _startContinuousListening() { ... } // ❌ ELIMINAT
  
  // ✅ NOU: Metoda eliminată - folosit din PassengerVoiceController
  // void _simulateContinuousVoiceRecognition() { ... } // ❌ ELIMINAT
  
    // ✅ NOU: Metoda eliminată - folosit din PassengerVoiceController
    // void _processVoiceCommand(String command) { ... } // ❌ ELIMINAT
  
  // ✅ NOU: Metodele eliminate - folosite din PassengerVoiceController
  // bool _detectIntermediateStopCommand(String command) { ... } // ❌ ELIMINAT
  // void _processIntermediateStopCommand(String command, String keyword) { ... } // ❌ ELIMINAT
  // String _extractLocationFromCommand(String command, String keyword) { ... } // ❌ ELIMINAT
  

  

  

  
  // 🛑 Construiește widget-urile pentru opririle intermediare
  // void _buildIntermediateStopsWidgets() {
  //   final widgets = <Widget>[];
  //   
  //   for (int i = 0; i < _intermediateStops.length; i++) {
  //     final stop = _intermediateStops[i];
  //     
  //     widgets.add(
  //       Container(
  //         margin: const EdgeInsets.only(bottom: 8),
  //         padding: const EdgeInsets.all(8),
  //         decoration: BoxDecoration(
  //           color: Colors.white,
  //           borderRadius: BorderRadius.circular(8),
  //           border: Border.all(color: Colors.orange.withAlpha(100)),
  //         ),
  //         child: Row(
  //           children: [
  //             Container(
  //               width: 24,
  //               height: 24,
  //               decoration: BoxDecoration(
  //                 color: Colors.orange,
  //                 borderRadius: BorderRadius.circular(12),
  //               ),
  //               child: Center(
  //                 child: Text(
  //                   '${i + 1}',
  //                   style: const TextStyle(
  //                     color: Colors.white,
  //                     fontSize: 12,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //               ),
  //               const SizedBox(width: 12),
  //               Expanded(
  //                 child: Text(
  //                   stop,
  //                   style: const TextStyle(fontSize: 14),
  //                 ),
  //               ),
  //               IconButton(
  //                 onPressed: () => _removeIntermediateStop(i),
  //                 icon: const Icon(Icons.close, color: Colors.red, size: 18),
  //                 padding: EdgeInsets.zero,
  //                 constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     }
  //     
  //     return widgets;
  //   }
  
  // 🛑 Șterge o oprire intermediară
  // void _removeIntermediateStop(int index) {
  //   if (index >= 0 && index < _intermediateStops.length) {
  //     final removedStop = _intermediateStops[index];
  //     
  //     setState(() {
  //       _intermediateStops.removeAt(index);
  //       _intermediateStopsControllers[index].dispose();
  //       _intermediateStopsControllers.removeAt(index);
  //       // ✅ NOU: AI response eliminat - folosit din PassengerVoiceController
  //       // _aiResponse = '🗑️ Oprire ștearsă: $removedStop'; // ❌ ELIMINAT
  //     });
  //     
  //       Logger.debug('Oprire intermediară ștearsă: $removedStop');
  //       
  //       // Actualizează harta (șterge marker-ul)
  //       _updateMapWithAllPoints();
  //     }
  //   }
  
  // ✅ NOU: Metodele eliminate - folosite din PassengerVoiceController
  // bool _detectRideControlCommand(String command) { ... } // ❌ ELIMINAT
  // void _processRideControlCommand(String command, String keyword) { ... } // ❌ ELIMINAT
  // bool _detectStopControlCommand(String command) { ... } // ❌ ELIMINAT
  // void _processStopControlCommand(String command, String keyword) { ... } // ❌ ELIMINAT
  // bool _detectAppControlCommand(String command) { ... } // ❌ ELIMINAT
  // void _processAppControlCommand(String command, String keyword) { ... } // ❌ ELIMINAT
  
  // 🚗 Implementează comenzile pentru controlul cursei
  // Metoda eliminată - nu este utilizată în codul actual
  
  // Metoda eliminată - nu este utilizată în codul actual
  
  // Metoda eliminată - nu este utilizată în codul actual
  
  // Metoda eliminată - nu este utilizată în codul actual
  
  // Metoda eliminată - nu este utilizată în codul actual
  
  // Metoda eliminată - nu este utilizată în codul actual
  
  // Metoda eliminată - nu este utilizată în codul actual
  

  

  

  
  // 💬 Afișează dialogul de ajutor pentru comenzi vocale
  // ✅ NOU: Metoda eliminată - folosit din PassengerVoiceController
  // void _showVoiceHelpDialog() { ... } // ❌ ELIMINAT
  
  // ✅ NOU: Metoda eliminată - folosit din PassengerVoiceController
  // void _stopContinuousListening() { ... } // ❌ ELIMINAT
  


  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    
    Logger.debug('MapScreen dispose - cleaning up all resources');
    
    _audioService.dispose();
    
    // ✅ NOU: Voice controllers eliminate - folosite din PassengerVoiceController
    // _voiceDestinationController.dispose(); // ❌ ELIMINAT
    // _voicePickupController.dispose(); // ❌ ELIMINAT
    
    // 🛑 NOU: Dispose intermediate stops controllers
    for (final controller in _intermediateStopsControllers) {
      controller.dispose();
    }
    _intermediateStopsControllers.clear();
    
    // 🎧 NOU: Stop continuous listening
    // Implementare continuous listening logic prin PassengerVoiceController
    
    // MODIFICAT: Asigurăm oprirea noului stream de locație.
    _stopLocationUpdates();
    
    // NOU: Cleanup pentru POI-uri
    _poiAnnotations.clear();
    _poiUpdateTimer?.cancel();
    _poiOperationTimer?.cancel(); // ✅ NOU: Cancel POI operation timer
    
    // Cancel all timers
    _rideOfferTimer?.cancel();
    _locationUpdateTimer?.cancel();
    _poiUpdateTimer?.cancel();
    _poiOperationTimer?.cancel();

    // Dispose animations
    _pickupPulseController?.dispose();
    _routePulseController?.dispose();
    
    // Cancel all subscriptions
    _pendingRidesSubscription?.cancel();
    _driverProfileSubscription?.cancel();
    _nearbyDriversSubscription?.cancel();
    _chatMessagesSubscription?.cancel();
    
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
            if (state == AppLifecycleState.resumed) {
      Logger.info('App resumed - checking if we need to reset route state');
      
      _resetRouteStateIfNeeded();
      
      if (_isDriverAvailable && _currentRole == UserRole.driver) {
        Logger.debug('App resumed - restarting location updates and ride listener');
        _startDriverLocationUpdates();
        _startListeningForRides(); 
      }
    } else if (state == AppLifecycleState.paused) {
      Logger.debug('⏸ App paused - stopping location updates');
      _stopLocationUpdates();
    }
  }

  void _resetRouteStateIfNeeded() {
    if (!_shouldResetRoute || !mounted) return;
    
    Logger.debug('MapScreen: Resetting route state after ride completion');
    
    _routeAnnotationManager?.deleteAll().catchError((e) {
      Logger.error('Error clearing route annotations: $e', error: e);
    });
    
    _routeMarkersAnnotationManager?.deleteAll().catchError((e) {
      Logger.error('Error clearing route markers: $e', error: e);
    });

    _pickupCircleManager?.deleteAll().catchError((e) {
      Logger.error('Error clearing pickup circle: $e', error: e);
    });

    _destinationCircleManager?.deleteAll().catchError((e) {
      Logger.error('Error clearing destination circle: $e', error: e);
    });
    
    _rideRequestPanelKey.currentState?.resetPanel();
    
    _shouldResetRoute = false;
    
    Logger.info('MapScreen: Route state reset completed');
  }
  
  // ✅ FIX: Metoda veche a fost înlocuită cu _playRideOfferSoundRobust()
  // Future<void> _playRideOfferSound() async { ... }

  // ✅ FIX: Metodă robustă cu multiple fallback-uri
  Future<void> _playRideOfferSoundRobust() async {
    // ✅ VERIFICĂ DOAR mounted - eliminăm verificarea _currentRideOffer
    if (!mounted) return;
    
    Logger.debug('Starting ride offer sound...', tag: 'SOUND');
    
    try {
      // ✅ FIX 1: Testează multiple metode de redare audio
      bool audioPlayed = false;
      
      // Metodă 1: AudioService
      try {
        await _audioService.playRideRequestSound();
        audioPlayed = true;
        Logger.info('AudioService played successfully');
      } catch (e) {
        Logger.error('AudioService failed: $e', error: e);
      }
      
      // Metodă 2: Fallback la system sounds
      if (!audioPlayed) {
        try {
          await SystemSound.play(SystemSoundType.alert);
          audioPlayed = true;
          Logger.info('SystemSound played successfully');
        } catch (e) {
          Logger.error('SystemSound failed: $e', error: e);
        }
      }
      
      // Metodă 3: Fallback la multiple HapticFeedback
      if (!audioPlayed) {
        try {
          HapticFeedback.heavyImpact();
          await Future.delayed(Duration(milliseconds: 300));
          HapticFeedback.heavyImpact();
          await Future.delayed(Duration(milliseconds: 300));
          HapticFeedback.heavyImpact();
          Logger.info('HapticFeedback sequence played');
        } catch (e) {
          Logger.error('HapticFeedback failed: $e', error: e);
        }
      }
      
      // ✅ FIX 2: Redă sunetele suplimentare cu interval mai mare
      if (mounted) {
        for (int i = 1; i <= 3; i++) {
          Future.delayed(Duration(milliseconds: 1000 * i), () async {
            if (mounted) {
              try {
                await _audioService.playRideRequestSound();
              } catch (e) {
                HapticFeedback.heavyImpact();
              }
            }
          });
        }
      }
      
    } catch (e) {
      Logger.error('CRITICAL: All audio methods failed: $e', error: e);
      // Ultimate fallback: Show visual notification
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🚨 ${l10n.newRideAudioUnavailable}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _listenForChatMessages(String rideId) {
    _chatMessagesSubscription?.cancel();
    _chatMessagesSubscription = _firestoreService.getChatMessages(rideId).listen((snapshot) {
      if (!mounted) return;

      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final messageData = change.doc.data();
          final senderId = messageData?['senderId'] as String?;
          final messageText = messageData?['message'] as String? ?? messageData?['text'] as String?;

          // ✅ FIX: Audio pentru mesaje de la șofer către pasager (sau invers)
          if (senderId != null && senderId != currentUserId) {
            // 🔊 FIX: Redă sunetul doar pentru mesajele de chat reale (nu pentru actualizări de locație sau mesaje de sistem)
            if (messageText != null && 
                messageText.isNotEmpty && 
                !messageText.contains('location_update') &&
                !messageText.startsWith('system:')) {
              
              Logger.debug('New message from $senderId to $currentUserId - playing sound notification', tag: 'MAP_CHAT');
              
              // ✅ FIX: Redă sunetul pe background thread
              unawaited(_audioService.playMessageReceivedSound().catchError((e) async {
                Logger.error('Error playing chat sound: $e', tag: 'MAP_CHAT', error: e);
                // ✅ FALLBACK: Încearcă sunetul de sistem dacă audio custom eșuează
                try {
                  await SystemSound.play(SystemSoundType.alert);
                } catch (e2) {
                  Logger.error('Even system sound failed: $e2', tag: 'MAP_CHAT');
                }
              }));
              
              // ✅ FIX: Înlocuiește Vibration cu HapticFeedback
              HapticFeedback.mediumImpact();
            }
          }
        }
      }
    });
  }

  geolocator.Position _applyRoadSnapping(geolocator.Position rawPosition) {
    if (_previousPositionObject == null) {
      return rawPosition;
    }

    final distanceFromPrevious = geolocator.Geolocator.distanceBetween(
      _previousPositionObject!.latitude,
      _previousPositionObject!.longitude,
      rawPosition.latitude,
      rawPosition.longitude,
    );

    if (distanceFromPrevious > 100) {
      Logger.debug('GPS jump detected: ${distanceFromPrevious.toStringAsFixed(1)}m - applying road snapping');
      final interpolationFactor = 100 / distanceFromPrevious;
      final correctedLat = _previousPositionObject!.latitude + 
          (rawPosition.latitude - _previousPositionObject!.latitude) * interpolationFactor;
      final correctedLng = _previousPositionObject!.longitude + 
          (rawPosition.longitude - _previousPositionObject!.longitude) * interpolationFactor;

      return geolocator.Position(
        latitude: correctedLat, longitude: correctedLng,
        timestamp: rawPosition.timestamp, accuracy: rawPosition.accuracy,
        altitude: rawPosition.altitude, altitudeAccuracy: rawPosition.altitudeAccuracy,
        heading: rawPosition.heading, headingAccuracy: rawPosition.headingAccuracy,
        speed: rawPosition.speed, speedAccuracy: rawPosition.speedAccuracy,
      );
    }

    if (distanceFromPrevious < 5 && rawPosition.accuracy > 10) {
      Logger.debug('GPS noise detected - applying smoothing');
      const smoothingFactor = 0.7;
      final smoothedLat = rawPosition.latitude * smoothingFactor + 
          _previousPositionObject!.latitude * (1 - smoothingFactor);
      final smoothedLng = rawPosition.longitude * smoothingFactor + 
          _previousPositionObject!.longitude * (1 - smoothingFactor);

      return geolocator.Position(
        latitude: smoothedLat, longitude: smoothedLng,
        timestamp: rawPosition.timestamp, accuracy: rawPosition.accuracy,
        altitude: rawPosition.altitude, altitudeAccuracy: rawPosition.altitudeAccuracy,
        heading: rawPosition.heading, headingAccuracy: rawPosition.headingAccuracy,
        speed: rawPosition.speed, speedAccuracy: rawPosition.speedAccuracy,
      );
    }
    return rawPosition;
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    Logger.info("Map created. Initializing light map state...");

    try {
      // Disable default UI plugins to reduce AppCompat theme warnings and save GPU
      try {
        final compass = _mapboxMap?.compass;
        final logo = _mapboxMap?.logo;
        final attribution = _mapboxMap?.attribution;
        await compass?.updateSettings(CompassSettings(enabled: false));
        await logo?.updateSettings(LogoSettings(enabled: false));
        await attribution?.updateSettings(AttributionSettings(enabled: false));
      } catch (_) {}

      // Lazy-create annotation managers when first used to reduce startup overhead
      _routeAnnotationManager = null;
      _routeMarkersAnnotationManager = null;
      _userPointAnnotationManager = null;
      _driversAnnotationManager = null;
      _pickupCircleManager = null;
      _destinationCircleManager = null;

      // Initialize route pulse animation (low overhead)
      if (!AppDrawer.lowDataMode) {
        _routePulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
        _routePulse = Tween<double>(begin: 0.6, end: 1.0).animate(
          CurvedAnimation(parent: _routePulseController!, curve: Curves.easeInOut),
        );
        // Start a bit later to avoid jank on first frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _routePulseController?.repeat(reverse: true);
        });
      }
      _pickupSuggestionsManager = null;
      Logger.info("Deferred annotation managers creation (lazy mode).");

      // Defer POI symbol layer init until first category interaction
      
      if (mounted) {
        // Temporarily disable heavy local POI preloading to avoid UI jank.
        _updateUserMarker(centerCamera: true);
        // Warm-up tiles around current center (non-blocking)
        unawaited(_prewarmTiles());
      }
    } catch (e) {
      Logger.error("CRITICAL ERROR creating annotation managers: $e. Map markers will not work.", error: e);
    }
  }

  // Initializes GeoJson source and SymbolLayers for POIs (with clustering)
  // Defer POI layer initialization until first use; method kept for future use
  // ignore: unused_element
  Future<void> _ensurePoiLayersInitialized() async {
    if (_mapboxMap == null) return;
    try {
      final style = _mapboxMap!.style;
      if (_poiLayersInitialized) {
        return; // already initialized
      }

      // Add clustered GeoJSON source for POIs (once)
      final source = GeoJsonSource(
        id: _poiSourceId,
        data: '{"type":"FeatureCollection","features":[]}',
        cluster: true,
        clusterRadius: 60,
        clusterMaxZoom: 15,
      );
      await style.addSource(source);

      // Cluster circles
      await style.addLayer(
        CircleLayer(
          id: _poiClusterLayerId,
          sourceId: _poiSourceId,
          circleColor: Colors.lightBlue.shade400.toARGB32(),
          circleRadius: 18.0,
          filter: ["has", "point_count"],
        ),
      );

      // Cluster count labels
      await style.addLayer(
        SymbolLayer(
          id: _poiClusterCountLayerId,
          sourceId: _poiSourceId,
          textField: '{point_count_abbreviated}',
          textColor: Colors.white.toARGB32(),
          textSize: 12.0,
          textIgnorePlacement: true,
          textAllowOverlap: true,
          filter: ["has", "point_count"],
        ),
      );

      // Individual POI symbols
      await style.addLayer(
        SymbolLayer(
          id: _poiSymbolLayerId,
          sourceId: _poiSourceId,
          iconImage: 'marker-15',
          iconAllowOverlap: true,
          filter: ["!has", "point_count"],
        ),
      );

      // Selected POI highlight source + layer (always present, data empty by default)
      await style.addSource(GeoJsonSource(
        id: _selectedPoiSourceId,
        data: '{"type":"FeatureCollection","features":[]}',
      ));
      await style.addLayer(CircleLayer(
        id: _selectedPoiLayerId,
        sourceId: _selectedPoiSourceId,
        circleColor: Colors.redAccent.toARGB32(),
        circleRadius: 10.0,
        circleStrokeColor: Colors.white.toARGB32(),
        circleStrokeWidth: 2.0,
      ));

      _poiLayersInitialized = true;
    } catch (e) {
      Logger.error('Failed to init POI layers: $e', error: e);
    }
  }

  Future<void> _updateUserMarker({bool centerCamera = false}) async {
          if (!mounted) {
      Logger.debug('⏭ Skipping marker update - widget unmounted or navigating');
      return;
    }
    
    if (_userPointAnnotationManager == null) {
      try {
        _userPointAnnotationManager = await _mapboxMap?.annotations.createPointAnnotationManager(id: 'user-marker-manager');
      } catch (e) {
        Logger.warning('Could not create user annotation manager: $e');
      }
      if (_userPointAnnotationManager == null) {
        Logger.warning('Skipping marker update - annotation manager is null');
        return;
      }
    }
    
    if (_currentPositionObject == null) {
      Logger.warning('Skipping marker update - no current position');
      return;
    }

    try {
      final bool shouldShowPassengerIcon = _currentRole == UserRole.passenger || 
                                          (_currentRole == UserRole.driver && !_isDriverAvailable);
      
      final assetPath = shouldShowPassengerIcon
          ? "assets/images/passenger_icon.png"
          : "assets/images/driver_icon.png";
      
      final ByteData imageBytes = await rootBundle.load(assetPath);
      final Uint8List imageList = imageBytes.buffer.asUint8List();

      double correctedHeading = 0.0;
      if (!shouldShowPassengerIcon && !_currentPositionObject!.heading.isNaN) {
        correctedHeading = _currentPositionObject!.heading;
        if (correctedHeading < 0) {
          correctedHeading += 360;
        }
      }

      String? textField;
      if (!shouldShowPassengerIcon && _driverProfile != null) {
        final driverName = _driverProfile!['displayName'] ?? 'Șofer';
        final licensePlate = _driverProfile!['licensePlate'] ?? '';
        textField = "$driverName\n$licensePlate";
      }

      final options = PointAnnotationOptions(
        geometry: MapboxUtils.createPoint(_currentPositionObject!.latitude, _currentPositionObject!.longitude),
        image: imageList,
        iconSize: shouldShowPassengerIcon ? 0.5 : 0.15,
        iconAnchor: IconAnchor.BOTTOM,
        iconRotate: correctedHeading,
        textField: textField,
        textSize: textField != null ? 12.0 : null,
        textColor: textField != null ? Colors.blue.shade700.toARGB32() : null,
        textHaloColor: textField != null ? Colors.white.toARGB32() : null,
        textHaloWidth: textField != null ? 1.5 : null,
        textAnchor: textField != null ? TextAnchor.BOTTOM : null,
        textOffset: textField != null ? [0.0, -1.0] : null,
        textJustify: textField != null ? TextJustify.CENTER : null,
      );

      if (!mounted || _userPointAnnotationManager == null) {
        Logger.debug('Aborting marker update - state changed during operation');
        return;
      }

      if (_userPointAnnotation != null) {
        await _userPointAnnotationManager?.delete(_userPointAnnotation!);
        _userPointAnnotation = null;
      }
      
      _userPointAnnotation = await _userPointAnnotationManager?.create(options);

      if (centerCamera && _mapboxMap != null && mounted) {
        await _mapboxMap?.flyTo(
          CameraOptions(
            center: MapboxUtils.createPoint(_currentPositionObject!.latitude, _currentPositionObject!.longitude),
            zoom: 15.0,
          ),
          MapAnimationOptions(duration: AppDrawer.lowDataMode ? 600 : 1500)
        );
        
        // ✅ ACTUALIZARE AUTOMATĂ POI-uri la schimbarea locației
        _schedulePoiUpdate();
      }
    } catch (e) {
      Logger.error('Non-fatal error during _updateUserMarker: $e', error: e);
    }
  }

  Future<void> _updateNearbyDrivers(List<QueryDocumentSnapshot<Map<String, dynamic>>> driverDocs) async {
          if (_driversAnnotationManager == null || !mounted) {
      return;
    }

    try {
      final ByteData imageBytes = await rootBundle.load("assets/images/driver_icon.png");
      final Uint8List imageList = imageBytes.buffer.asUint8List();
      
      final currentDriverIds = driverDocs.map((doc) => doc.id).toSet();
      final displayedDriverIds = _nearbyDriverAnnotations.keys.toSet();

      final driversToRemove = displayedDriverIds.difference(currentDriverIds);
      if (driversToRemove.isNotEmpty) {
        final annotationsToRemove = driversToRemove.map((id) => _nearbyDriverAnnotations.remove(id)!).toList();
        for (var annotation in annotationsToRemove) {
          if (mounted) {
            await _driversAnnotationManager?.delete(annotation);
          }
        }
      }

      for (var driverDoc in driverDocs) {
        if (!mounted) break;
        if (driverDoc.id == FirebaseAuth.instance.currentUser?.uid) continue;
        final data = driverDoc.data();
        if (data['position'] != null) {
          final GeoPoint pos = data['position'];
          final double? bearing = data['bearing'] as double?;
          
          double correctedBearing = 0.0;
          if (bearing != null && !bearing.isNaN) {
            correctedBearing = bearing + 180;
            if (correctedBearing >= 360) {
              correctedBearing -= 360;
            }
          }

          if (_nearbyDriverAnnotations.containsKey(driverDoc.id)) {
            final annotation = _nearbyDriverAnnotations[driverDoc.id]!;
            annotation.geometry = MapboxUtils.createPoint(pos.latitude, pos.longitude);
            annotation.iconRotate = correctedBearing;
            if (mounted) {
              await _driversAnnotationManager?.update(annotation);
            }
          } else {
            final options = PointAnnotationOptions(
                          geometry: MapboxUtils.createPoint(pos.latitude, pos.longitude), 
              image: imageList,
              iconSize: 0.15,
              iconAnchor: IconAnchor.BOTTOM,
              iconRotate: correctedBearing,
            );
            if (mounted) {
              final newAnnotation = await _driversAnnotationManager?.create(options);
              if (newAnnotation != null) {
                _nearbyDriverAnnotations[driverDoc.id] = newAnnotation;
              }
            }
          }
        }
      }
    } catch (e) {
      Logger.error('Non-fatal error during _updateNearbyDrivers: $e', error: e);
    }
  }

  void _listenForNearbyDrivers() {
    _nearbyDriversSubscription?.cancel();
    _nearbyDriversSubscription = _firestoreService.getNearbyAvailableDrivers().listen((snapshot) {
      if (mounted) {
        _updateNearbyDrivers(snapshot.docs);
      }
    });
  }

  Future<void> _initializeScreen() async {
    try {
      // Verificare rol cu timeout
      final role = await _firestoreService.getUserRole()
          .timeout(const Duration(seconds: 5), onTimeout: () {
        return UserRole.passenger;
      });
      
      if (!mounted) return;
      setState(() { _currentRole = role; });
      
      // Locația se obține în fundal
      unawaited(_getCurrentLocation(centerCamera: true));
      
      // Ascultarea șoferilor în fundal
      _listenForNearbyDrivers();

      if (_currentRole == UserRole.driver) {
        _driverProfileSubscription = _firestoreService.getUserProfileStream().listen((snapshot) {
          if (mounted && snapshot.exists) {
            setState(() { _driverProfile = snapshot.data(); });
            unawaited(_loadDriverStatus());
            _initializeDriverRideSystem();
          }
        });
      }
    } catch (e) {
      Logger.error('Screen initialization error: $e', error: e);
      if (mounted) {
        setState(() { _currentRole = UserRole.passenger; });
      }
    }
  }

  void _initializeDriverRideSystem() {
    if (_driverProfile != null) {
      final categoryStr = _driverProfile!['driverCategory'] as String?;
      _driverCategory = _getCategoryFromString(categoryStr);
      
      // ✅ FIX: Nu pornim listener-ul aici
      if (_driverCategory != null) {
        Logger.info('Driver system initialized for category: ${_driverCategory!.name}', tag: 'MAP');
        
        // ✅ FIX: Verifică dacă șoferul e deja disponibil din storage
        _checkAndStartDriverSystemIfReady();
      }
    }
  }

  // ✅ SOLUȚIE COMBINATĂ: Metodă nouă pentru verificare completă
  void _checkAndStartDriverSystemIfReady() async {
    try {
      // Verifică statusul din Firestore
      final currentStatus = await _firestoreService.getDriverAvailability();
      
      if (mounted) {
        setState(() { _isDriverAvailable = currentStatus; });
        
        // Acum pornește sistemul dacă totul e gata
        if (_driverCategory != null && _isDriverAvailable) {
          Logger.debug('Starting driver system - category: ${_driverCategory!.name}, available: $_isDriverAvailable', tag: 'MAP');
          _startListeningForRides();
          _startDriverLocationUpdates();
        }
      }
    } catch (e) {
      Logger.error('Error checking driver status: $e', error: e);
    }
  }

  RideCategory? _getCategoryFromString(String? categoryStr) {
    switch (categoryStr) {
      case 'standard': return RideCategory.standard;
      case 'energy': return RideCategory.energy;
      case 'best': return RideCategory.best;
      case null: return null;
      default: return null;
    }
  }

  void _startListeningForRides() {
    if (_driverCategory == null || !_isDriverAvailable) return;
    
    Logger.debug('Starting to listen for ${_driverCategory!.name} rides', tag: 'MAP');
    
    _pendingRidesSubscription?.cancel();
    _pendingRidesSubscription = _firestoreService
        .getPendingRideRequests(_driverCategory!)
        .listen((rides) {
      Logger.debug('Received ${rides.length} pending rides', tag: 'MAP');

      final currentDriverId = FirebaseAuth.instance.currentUser?.uid;
      final availableRides = rides.where((ride) {
        if (ride.status == 'pending') return true;
        if (ride.status == 'driver_found') {
          // păstrăm doar dacă încă nu are asignare clară
          if (ride.driverId == null || ride.driverId!.isEmpty) {
            return true;
          }
          if (currentDriverId != null && ride.driverId == currentDriverId) {
            return false;
          }
          // dacă este deja asignată (inclusiv acestui șofer), nu o mai afișăm ca ofertă
          return false;
        }
        return false;
      }).toList();

      if (!mounted) return;

      setState(() {
        _pendingRides = availableRides;
      });

      if (availableRides.isNotEmpty && _currentRideOffer == null) {
        _showRideOffer(availableRides.first);
      } else if (availableRides.isEmpty && _currentRideOffer != null) {
        _dismissRideOffer();
      }
    });
  }

  void _stopListeningForRides() {
    _pendingRidesSubscription?.cancel();
    _rideOfferTimer?.cancel();
    if (mounted) {
      setState(() {
        _pendingRides.clear();
        _currentRideOffer = null;
      });
    }
  }

  void _showRideOffer(Ride ride) {
    if (mounted) {
      // ✅ FIX: SETEAZĂ STAREA ÎNTÂI
      setState(() {
        _currentRideOffer = ride;
        _remainingSeconds = 30;
      });
      
      // ✅ FIX: APOI REDĂ SUNETUL DUPĂ FRAME UPDATE
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _playRideOfferSoundRobust();
        }
      });
    }
    
    Logger.debug('Showing ride offer: ${ride.destinationAddress}', tag: 'MAP');

    try {
      final driverVoice = Provider.of<DriverVoiceController>(context, listen: false);
      final voiceRequest = DriverVoiceRideRequest.fromRide(ride);
      driverVoice.handleIncomingRideCall(
        voiceRequest,
        onAcceptRide: () => _acceptRide(ride),
        onDeclineRide: () => _declineRide(ride),
        onNavigateToActiveRide: () async => _navigateToActiveRideScreen(ride.id),
      );
    } catch (e) {
      Logger.debug('Unable to start driver voice flow: $e', tag: 'VOICE');
    }
    
    _rideOfferTimer?.cancel();
    _rideOfferTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      if (mounted) {
        setState(() {
          _remainingSeconds--;
        });
      }
      
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _dismissRideOffer();
      }
    });
  }

  void _dismissRideOffer() {
    _rideOfferTimer?.cancel();
    if (mounted) {
      setState(() {
        _currentRideOffer = null;
        _remainingSeconds = 30;
      });
      try {
        unawaited(Provider.of<DriverVoiceController>(context, listen: false).reset());
      } catch (_) {}
    }
  }

  Future<void> _acceptRide(Ride ride) async {
    // ✅ FIX: Protecție îmbunătățită împotriva apăsărilor multiple
    if (_isProcessingAccept) {
      Logger.debug('Already processing accept request, ignoring duplicate tap', tag: 'MAP');
      return;
    }
    
    // ✅ FIX: Setează starea IMEDIAT, înainte de orice altceva
    if (!mounted) return;
    setState(() {
      _isProcessingAccept = true;
    });
    
    // ✅ FIX: Forțează rebuild-ul UI-ului pentru a dezactiva butonul imediat
    await Future.microtask(() {});
    
    try {
      Logger.debug('Accepting ride: ${ride.id}', tag: 'MAP');
      await _firestoreService.acceptRide(ride.id);
      
      // ✅ FIX: Nu mai anulăm oferta imediat - așteptăm confirmarea pasagerului
      // _dismissRideOffer(); // Comentat - lăsăm cardul să rămână până când statusul se schimbă
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cursă acceptată! Așteptăm confirmarea pasagerului...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      Logger.error('Error accepting ride: $e', tag: 'MAP', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la acceptarea cursei: $e'),
            backgroundColor: Colors.red,
          ),
        );
        // ✅ FIX: Re-afișează oferta dacă acceptarea a eșuat
        if (_currentRideOffer?.id == ride.id) {
          // Oferta rămâne activă
        }
      }
    } finally {
      // ✅ FIX: Reset protecția după procesare (cu delay pentru a permite UI-ului să se actualizeze)
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          setState(() {
            _isProcessingAccept = false;
          });
        }
      }
    }
  }

  Future<void> _declineRide(Ride ride) async {
    // 🚗 FIX: Protecție împotriva apăsărilor multiple
    if (_isProcessingDecline) {
      Logger.debug('Already processing decline request, ignoring duplicate tap', tag: 'MAP');
      return;
    }
    
    setState(() {
      _isProcessingDecline = true;
    });
    
    try {
      Logger.debug('Declining ride: ${ride.id}', tag: 'MAP');
      await _firestoreService.declineRide(ride.id);
      _dismissRideOffer();
      
      final remainingRides = _pendingRides.where((r) => r.id != ride.id).toList();
      if (remainingRides.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _showRideOffer(remainingRides.first);
          }
        });
      }
    } catch (e) {
      Logger.error('Error declining ride: $e', tag: 'MAP', error: e);
    } finally {
      // 🚗 FIX: Reset protecția după procesare
      if (mounted) {
        setState(() {
          _isProcessingDecline = false;
        });
      }
    }
  }

  Future<void> _loadDriverStatus() async {
    final status = await _firestoreService.getDriverAvailability();
    if (!mounted) return;
    
    setState(() { _isDriverAvailable = status; });
    
    // ✅ FIX: Pornește sistemul DUPĂ ce statusul e setat
    if (_driverCategory != null && _isDriverAvailable) {
      Logger.info('Driver status loaded - starting ride system', tag: 'MAP');
      _startListeningForRides();
      _startDriverLocationUpdates();
    }
  }

  void _handleRoleChange(bool isDriver) {
    final newRole = isDriver ? UserRole.driver : UserRole.passenger;
    if (_currentRole == newRole) return;
    
    _firestoreService.setUserRole(newRole).then((_) {
        if (mounted) { _initializeScreen(); }
    });
  }

  Future<void> _getCurrentLocation({bool centerCamera = false}) async {
    try {
      // 🚀 PERFORMANȚĂ: Timeout pentru verificarea permisiunilor
      geolocator.LocationPermission permission = await geolocator.Geolocator.checkPermission()
          .timeout(const Duration(seconds: 2), onTimeout: () {
        Logger.warning('Permission check timeout');
        return geolocator.LocationPermission.denied;
      });
      
      if (permission == geolocator.LocationPermission.denied) {
        permission = await geolocator.Geolocator.requestPermission()
            .timeout(const Duration(seconds: 3), onTimeout: () {
          Logger.warning('Permission request timeout');
          return geolocator.LocationPermission.denied;
        });
        
        if (permission != geolocator.LocationPermission.whileInUse && 
            permission != geolocator.LocationPermission.always) {
          return;
        }
      }
      
      // 🚀 PERFORMANȚĂ: Timeout pentru obținerea locației
      geolocator.Position position = await geolocator.Geolocator.getCurrentPosition(
        locationSettings: DeprecatedAPIsFix.createLocationSettings(
          accuracy: geolocator.LocationAccuracy.high,
          timeLimit: Duration(seconds: 5), // Redus de la 10 la 5 secunde
        ),
      ).timeout(const Duration(seconds: 8), onTimeout: () {
        throw TimeoutException('Location request timeout');
      });
      
      if (mounted) {
        setState(() { _currentPositionObject = position; });
        _updateUserMarker(centerCamera: centerCamera);
      }
    } catch (e) {
      Logger.debug("Could not get current location: $e");
      // 🚀 PERFORMANȚĂ: Încercăm să folosim ultima locație cunoscută
      try {
        final lastKnownPosition = await geolocator.Geolocator.getLastKnownPosition()
            .timeout(const Duration(seconds: 1));
        if (lastKnownPosition != null && mounted) {
          setState(() { _currentPositionObject = lastKnownPosition; });
          _updateUserMarker(centerCamera: centerCamera);
        }
      } catch (fallbackError) {
        Logger.debug("Could not get last known location: $fallbackError");
      }
    }
  }

  // ✅ ÎMBUNĂTĂȚIT: Combinăm stream-ul GPS cu timer constant pentru șoferii stăționari
  void _startDriverLocationUpdates() {
    _stopLocationUpdates();
    
    // Setări pentru stream-ul de locație - PĂSTRĂM distanceFilter pentru eficiență
    const locationSettings = geolocator.LocationSettings(
      accuracy: geolocator.LocationAccuracy.high,
      distanceFilter: 10, // Primește update doar dacă locația s-a schimbat cu 10m
    );

    // ✅ CURSOR FIX: Timer cu background execution
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (!mounted || !_isDriverAvailable || _currentRole != UserRole.driver) {
        return;
      }
      
      // 🚀 CURSOR: Rulează pe background thread
      unawaited(_updateDriverLocationInBackground());
    });

    // Pornim ascultarea stream-ului pentru mișcări în timp real
    _positionSubscription = geolocator.Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((geolocator.Position position) {
      
      if (!mounted || !_isDriverAvailable || _currentRole != UserRole.driver) {
        return;
      }
      
      // NOU: Logica de frecvență adaptivă
      final now = DateTime.now();
      int currentInterval;
      final speed = position.speed;

      if (speed < 1.5) { // Sub ~5 km/h, considerăm că stă pe loc
        currentInterval = _standingInterval;
      } else if (speed < 10) { // Sub 36 km/h, viteză de oraș
        currentInterval = _slowSpeedInterval;
      } else { // Viteză mare
        currentInterval = _highSpeedInterval;
      }

      // Verificăm dacă a trecut suficient timp de la ultima trimitere
      if (_lastUpdateTime == null || now.difference(_lastUpdateTime!).inSeconds >= currentInterval) {
        
        Logger.debug('--> Sending location update. Speed: ${speed.toStringAsFixed(2)} m/s. Interval: $currentInterval s.');
        
        final snappedPosition = _applyRoadSnapping(position);
        _firestoreService.updateDriverLocation(snappedPosition, bearing: snappedPosition.heading);
        
        _previousPositionObject = _currentPositionObject;
        if (mounted) {
          setState(() {
            _currentPositionObject = snappedPosition;
          });
        }
        
        _updateDriverRideEstimates(snappedPosition);
        _updateUserMarker(centerCamera: false);
        
        // Resetăm cronometrul
        _lastUpdateTime = now;
      }
    }, onError: (error) {
      Logger.error("Eroare la stream-ul de locație: $error", error: error);
    });

    Logger.info('▶ Started location stream');
  }

  // ✅ ÎMBUNĂTĂȚIT: Oprește și stream-ul și timer-ul
  void _stopLocationUpdates() {
    if (_positionSubscription != null) {
      _positionSubscription!.cancel();
      _positionSubscription = null;
      Logger.debug('⏹ Stopped location stream');
    }
    
    // ✅ ADĂUGAT: Oprește și timer-ul constant
    if (_locationUpdateTimer != null) {
      _locationUpdateTimer!.cancel();
      _locationUpdateTimer = null;
      Logger.debug('⏹ Stopped location timer');
    }
  }

  // ✅ CURSOR: Background location update method
  Future<void> _updateDriverLocationInBackground() async {
    try {
      final position = await geolocator.Geolocator.getCurrentPosition(
        locationSettings: DeprecatedAPIsFix.createLocationSettings(
          accuracy: geolocator.LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );
      
      // ✅ Actualizează Firestore
      await _firestoreService.updateDriverLocation(position);
      
      // ✅ UI update pe main thread
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() { _currentPositionObject = position; });
          _updateDriverRideEstimates(position);
        });
      }
      
      Logger.debug('Background location update successful');
    } catch (e) {
      Logger.error('Background location update failed: $e', error: e);
    }
  }

  void _resetDriverEtaMetrics() {
    if (!mounted) return;
    setState(() {
      _driverPickupDistanceKm = null;
      _driverPickupEta = null;
      _driverPickupArrivalTime = null;
      _driverDestinationDistanceKm = null;
      _driverDestinationEta = null;
      _driverDestinationArrivalTime = null;
      _driverTrafficSummary = null;
    });
  }

  bool _shouldIncludePickupLeg(String? status) {
    const pickupStates = {
      'driver_found',
      'accepted',
      'driver_en_route',
      'arrived',
    };
    if (status == null) return true;
    return pickupStates.contains(status);
  }

  String _formatDriverEta(Duration? duration) {
    if (duration == null) return '—';
    if (duration.inMinutes >= 1) {
      return '${duration.inMinutes} min';
    }
    if (duration.inSeconds >= 30) {
      return '<1 min';
    }
    return '<30 sec';
  }

  String _formatDriverDistance(double? distanceKm) {
    if (distanceKm == null) return '—';
    if (distanceKm >= 1) {
      return '${distanceKm.toStringAsFixed(1)} km';
    }
    final meters = (distanceKm * 1000).round();
    return '$meters m';
  }

  String _formatRideStatus(String? status) {
    switch (status) {
      case 'driver_found':
        return 'În drum către pasager';
      case 'accepted':
        return 'Confirmată';
      case 'driver_en_route':
        return 'În drum către preluare';
      case 'arrived':
        return 'Șoferul a sosit';
      case 'in_progress':
        return 'Cursă în desfășurare';
      case 'completed':
        return 'Finalizată';
      case 'cancelled':
        return 'Anulată';
      default:
        return 'Status necunoscut';
    }
  }

  void _updateDriverRideEstimates(geolocator.Position driverPosition) {
    if (!mounted || _currentActiveRide == null) return;

    final ride = _currentActiveRide!;
    final includePickupLeg = _shouldIncludePickupLeg(ride.status);

    double? pickupDistanceMeters;
    double? destinationDistanceMeters;

    if (includePickupLeg &&
        ride.startLatitude != null &&
        ride.startLongitude != null) {
      pickupDistanceMeters = geolocator.Geolocator.distanceBetween(
        driverPosition.latitude,
        driverPosition.longitude,
        ride.startLatitude!,
        ride.startLongitude!,
      );
    }

    if (ride.destinationLatitude != null && ride.destinationLongitude != null) {
      destinationDistanceMeters = geolocator.Geolocator.distanceBetween(
        driverPosition.latitude,
        driverPosition.longitude,
        ride.destinationLatitude!,
        ride.destinationLongitude!,
      );
    }

    const averageSpeedMps = 10.0;
    Duration? pickupEta;
    Duration? destinationEta;
    DateTime? pickupArrival;
    DateTime? destinationArrival;

    if (!includePickupLeg) {
      pickupDistanceMeters = 0;
      pickupEta = Duration.zero;
      pickupArrival = DateTime.now();
    } else if (pickupDistanceMeters != null) {
      final etaSeconds =
          (pickupDistanceMeters / averageSpeedMps).clamp(0, 60 * 60 * 2).toInt();
      pickupEta = Duration(seconds: etaSeconds);
      pickupArrival = DateTime.now().add(pickupEta);
    }

    if (destinationDistanceMeters != null) {
      final etaSeconds = (destinationDistanceMeters / averageSpeedMps)
          .clamp(0, 60 * 60 * 3)
          .toInt();
      destinationEta = Duration(seconds: etaSeconds);
      destinationArrival = DateTime.now().add(destinationEta);
    }

    setState(() {
      _driverPickupDistanceKm = pickupDistanceMeters != null
          ? pickupDistanceMeters / 1000.0
          : (includePickupLeg ? null : 0);
      _driverPickupEta = pickupEta;
      _driverPickupArrivalTime = pickupArrival;

      _driverDestinationDistanceKm = destinationDistanceMeters != null
          ? destinationDistanceMeters / 1000.0
          : null;
      _driverDestinationEta = destinationEta;
      _driverDestinationArrivalTime = destinationArrival;

      if (pickupDistanceMeters == null &&
          destinationDistanceMeters == null &&
          !includePickupLeg) {
        _driverTrafficSummary = null;
      }
    });

    final now = DateTime.now();
    final hasRecentRequest = _driverLastEtaRequestTime != null &&
        now.difference(_driverLastEtaRequestTime!) < _driverEtaThrottle;

    final bool movedEnough;
    if (_driverLastEtaPosition == null) {
      movedEnough = true;
    } else {
      final movedMeters = geolocator.Geolocator.distanceBetween(
        driverPosition.latitude,
        driverPosition.longitude,
        _driverLastEtaPosition!.latitude,
        _driverLastEtaPosition!.longitude,
      );
      movedEnough = movedMeters >= _driverEtaDistanceThresholdMeters;
    }

    if (hasRecentRequest || !movedEnough || _driverIsFetchingEta) {
      return;
    }

    _driverLastEtaRequestTime = now;
    _driverLastEtaPosition = driverPosition;
    unawaited(_fetchDriverPreciseEta(driverPosition));
  }

  Future<void> _fetchDriverPreciseEta(geolocator.Position driverPosition) async {
    if (_driverIsFetchingEta || _currentActiveRide == null) return;

    final ride = _currentActiveRide!;
    final includePickupLeg = _shouldIncludePickupLeg(ride.status);

    final waypoints = <Point>[
      MapboxUtils.createPoint(driverPosition.latitude, driverPosition.longitude),
    ];

    if (includePickupLeg &&
        ride.startLatitude != null &&
        ride.startLongitude != null) {
      waypoints.add(MapboxUtils.createPoint(ride.startLatitude!, ride.startLongitude!));
    }

    if (ride.destinationLatitude != null && ride.destinationLongitude != null) {
      waypoints.add(MapboxUtils.createPoint(ride.destinationLatitude!, ride.destinationLongitude!));
    }

    if (waypoints.length < 2) return;

    _driverIsFetchingEta = true;
    try {
      final routeResult = await _routingService.getRoute(waypoints);
      if (!mounted || routeResult == null) return;

      final routes = routeResult['routes'];
      if (routes is! List || routes.isEmpty) return;

      final route = routes.first;
      if (route is! Map<String, dynamic>) return;

      final totalDistance = (route['distance'] as num?)?.toDouble();
      final totalDuration = (route['duration'] as num?)?.toDouble();

      double? pickupDistance;
      double? pickupDuration;
      String? trafficSummary;

      final legs = route['legs'];
      if (legs is List && legs.isNotEmpty) {
        final congestionCounts = <String, int>{};
        for (final legEntry in legs) {
          if (legEntry is Map<String, dynamic>) {
            final congestion = (legEntry['annotation'] as Map<String, dynamic>?)
                ?['congestion'];
            if (congestion is List) {
              for (final value in congestion) {
                if (value is String && value.isNotEmpty) {
                  congestionCounts.update(value, (v) => v + 1, ifAbsent: () => 1);
                }
              }
            }
          }
        }

        if (congestionCounts.isNotEmpty) {
          final dominant = congestionCounts.entries
              .reduce((a, b) => a.value >= b.value ? a : b)
              .key;
          trafficSummary = switch (dominant) {
            'low' => 'Trafic lejer',
            'moderate' => 'Trafic moderat',
            'heavy' => 'Trafic aglomerat',
            'severe' => 'Trafic foarte aglomerat',
            _ => null,
          };
        }

        if (includePickupLeg) {
          final firstLeg = legs.first;
          if (firstLeg is Map<String, dynamic>) {
            pickupDistance = (firstLeg['distance'] as num?)?.toDouble();
            pickupDuration = (firstLeg['duration'] as num?)?.toDouble();
          }
        }
      }

      if (!includePickupLeg) {
        pickupDistance ??= 0;
        pickupDuration ??= 0;
      }

      if (!mounted) return;

      setState(() {
        if (pickupDistance != null) {
          _driverPickupDistanceKm = pickupDistance / 1000.0;
        }
        if (pickupDuration != null) {
          _driverPickupEta = Duration(seconds: pickupDuration.round());
          _driverPickupArrivalTime = DateTime.now().add(_driverPickupEta!);
        }

        if (totalDistance != null) {
          _driverDestinationDistanceKm = totalDistance / 1000.0;
        }
        if (totalDuration != null) {
          _driverDestinationEta = Duration(seconds: totalDuration.round());
          _driverDestinationArrivalTime = DateTime.now().add(_driverDestinationEta!);
        }

        if (trafficSummary != null) {
          _driverTrafficSummary = trafficSummary;
        }
      });
    } catch (e) {
      Logger.error('Driver precise ETA calculation failed: $e', error: e);
    } finally {
      _driverIsFetchingEta = false;
    }
  }

  Future<void> _toggleDriverAvailability(bool value) async {
    if (_currentRole != UserRole.driver) return;
    
    if (mounted) {
      setState(() { _isDriverAvailable = value; });
    }
    
    try {
      if (value) {
        if (_driverProfile != null) {
          final category = _getCategoryFromProfile(_driverProfile!);
          await _firestoreService.updateDriverAvailability(
            true,
            displayName: _driverProfile!['displayName'],
            licensePlate: _driverProfile!['licensePlate'],
            category: category,
          );
          _startDriverLocationUpdates();
          _initializeDriverRideSystem();
        } else {
          if (mounted) {
            setState(() { _isDriverAvailable = false; });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profilul șofer se încarcă, încercați din nou...'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      } else {
        await _firestoreService.updateDriverAvailability(false);
        _stopLocationUpdates();
        _stopListeningForRides();
      }
      _updateUserMarker();
    } catch (e) {
      Logger.error('Error updating availability: $e', tag: 'DRIVER', error: e);
      if (mounted) {
        setState(() { _isDriverAvailable = !value; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eroare: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  RideCategory _getCategoryFromProfile(Map<String, dynamic> profile) {
    final categoryStr = profile['driverCategory'] as String?;
    switch (categoryStr) {
      case 'standard': return RideCategory.standard;
      case 'energy': return RideCategory.energy;
      case 'best': return RideCategory.best;
      case null: return RideCategory.standard;
      default: return RideCategory.standard;
    }
  }

  Future<void> _onRouteCalculated(Map<String, dynamic>? routeData) async {
    await _routeAnnotationManager?.deleteAll();
    await _altRouteAnnotationManager?.deleteAll();
    await _routeMarkersAnnotationManager?.deleteAll();
    await _pickupCircleManager?.deleteAll();
    await _destinationCircleManager?.deleteAll();
    
    if (routeData == null || !mounted) {
      setState(() {
        _currentRouteDistanceMeters = null;
        _currentRouteDurationSeconds = null;
      });
      Logger.debug('Route cleared in MapScreen');
      return;
    }
    
          try {
        // Ensure managers exist before drawing
        _routeAnnotationManager ??= await _mapboxMap?.annotations.createPolylineAnnotationManager(id: 'route-manager');
        _routeMarkersAnnotationManager ??= await _mapboxMap?.annotations.createPointAnnotationManager(id: 'route-markers-manager');
        _pickupCircleManager ??= await _mapboxMap?.annotations.createCircleAnnotationManager(id: 'pickup-circle-manager');
        _destinationCircleManager ??= await _mapboxMap?.annotations.createCircleAnnotationManager(id: 'destination-circle-manager');
        final routes = (routeData['routes'] as List?) ?? const [];
        if (routes.isEmpty) return;
        final route = routes[0];
        final geometry = route['geometry'] as Map<String, dynamic>;
        final meters = (route['distance'] as num?)?.toDouble();
        final seconds = (route['duration'] as num?)?.toDouble();
        if (meters != null && seconds != null) {
          if (mounted) {
            setState(() {
              _currentRouteDistanceMeters = meters;
              _currentRouteDurationSeconds = seconds;
            });
          }
        }

        // Pickup spot quality: distanța dintre punctul de preluare și primul punct al rutei
        try {
          if (_pickupLatitude != null && _pickupLongitude != null) {
            final coords = (geometry['coordinates'] as List<dynamic>);
            if (coords.isNotEmpty) {
              final first = coords.first as List<dynamic>;
              final firstLng = (first[0] as num).toDouble();
              final firstLat = (first[1] as num).toDouble();
              final d = _calculateDirectDistance(_pickupLatitude!, _pickupLongitude!, firstLat, firstLng);
              String label;
              Color color;
              if (d <= 10) {
                label = 'Excelent';
                color = Colors.green;
              } else if (d <= 25) {
                label = 'Bun';
                color = Colors.teal;
              } else if (d <= 50) {
                label = 'OK';
                color = Colors.amber.shade700;
              } else {
                label = 'Slab';
                color = Colors.redAccent;
              }
              if (mounted) {
                setState(() {
                  _pickupQualityLabel = label;
                  _pickupQualityColor = color;
                });
              }
            }
          } else {
            if (mounted) {
              setState(() {
                _pickupQualityLabel = null;
                _pickupQualityColor = null;
              });
            }
          }
        } catch (_) {}
        
        // ✅ CORECTAT: Creez obiect LineString pentru Mapbox (fără cast strict)
        final List<dynamic> coordinates = geometry['coordinates'] as List<dynamic>;
        final lineStringGeometry = LineString(
          coordinates: coordinates.map((coord) {
            final List<dynamic> c = coord as List<dynamic>;
            final double lng = (c[0] as num).toDouble();
            final double lat = (c[1] as num).toDouble();
            return Position(lng, lat);
          }).toList(),
        );
        
        // Delete previous active route if any (to avoid stacking)
        if (_activeRouteAnnotation != null) {
          try { await _routeAnnotationManager?.delete(_activeRouteAnnotation!); } catch (_) {}
          _activeRouteAnnotation = null;
        }

        // Base route line (solid blue)
        _activeRouteAnnotation = await _routeAnnotationManager?.create(
          PolylineAnnotationOptions(
            geometry: lineStringGeometry,
            lineColor: Colors.blue.toARGB32(),
            lineWidth: 6.0,
            lineOpacity: 1.0,
          ),
        );

        // Animated pulse overlay (slightly thicker, varying opacity)
        if (_routePulse != null) {
          final double currentOpacity = (_routePulse!.value).clamp(0.4, 1.0);
          await _routeAnnotationManager?.create(
            PolylineAnnotationOptions(
              geometry: lineStringGeometry,
              lineColor: Colors.blueAccent.toARGB32(),
              lineWidth: 7.0,
              lineOpacity: currentOpacity,
            ),
          );
        }

        // Desenează rutele alternative dacă există (faint)
        if (routes.length > 1) {
          // Ensure alt manager exists
          _altRouteAnnotationManager ??= await _mapboxMap?.annotations.createPolylineAnnotationManager(id: 'alt-route-manager');
          for (int i = 1; i < routes.length; i++) {
            final alt = routes[i] as Map<String, dynamic>;
            final g = (alt['geometry'] as Map<String, dynamic>);
            final coords = (g['coordinates'] as List<dynamic>).cast<List<dynamic>>();
            final altLine = LineString(
              coordinates: coords.map((c) => Position((c[0] as num).toDouble(), (c[1] as num).toDouble())).toList(),
            );
            await _altRouteAnnotationManager?.create(
              PolylineAnnotationOptions(
                geometry: altLine,
                lineColor: Colors.grey.shade500.toARGB32(),
                lineWidth: 4.0,
                lineOpacity: 0.4,
              ),
            );
          }
        }
      
      await _addRouteCircles(routeData);
      
      // ✅ Adaugă pin de destinație imediat după desenarea rutei
      try {
        final List<dynamic> endCoord = ((routeData['routes'][0]['geometry']['coordinates']) as List).last as List;
        await _addDestinationMarker(
          MapboxUtils.createPoint((endCoord[1] as num).toDouble(), (endCoord[0] as num).toDouble()),
          'Destinație',
        );
      } catch (_) {}
      
      // ✅ Ajustează camera astfel încât să fie vizibil întreg traseul
      try {
        final List<dynamic> coords = (geometry['coordinates'] as List<dynamic>);
        if (coords.isNotEmpty) {
          final List<double> lats = <double>[];
          final List<double> lngs = <double>[];
          for (final dynamic c in coords) {
            final List<dynamic> p = c as List<dynamic>;
            lngs.add((p[0] as num).toDouble());
            lats.add((p[1] as num).toDouble());
          }
          final southwest = MapboxUtils.createPoint(
            lats.reduce((a, b) => a < b ? a : b),
            lngs.reduce((a, b) => a < b ? a : b),
          );
          final northeast = MapboxUtils.createPoint(
            lats.reduce((a, b) => a > b ? a : b),
            lngs.reduce((a, b) => a > b ? a : b),
          );
          final bounds = CoordinateBounds(
            southwest: southwest,
            northeast: northeast,
            infiniteBounds: false,
          );
          final cameraOptions = await _mapboxMap?.cameraForCoordinateBounds(
            bounds,
            MbxEdgeInsets(
              top: 100.0,
              left: 50.0,
              bottom: 300.0, // spațiu pentru panoul cu opțiuni
              right: 50.0,
            ),
            0.0,
            0.0,
            null,
            null,
          );
          if (cameraOptions != null) {
            await _mapboxMap?.flyTo(cameraOptions, MapAnimationOptions(duration: 1200));
          }
        }
      } catch (e) {
        Logger.error('Failed to fit camera to route: $e', error: e);
      }
      
      Logger.debug('Route and circles displayed in MapScreen');
    } catch (e) {
      Logger.error('Error processing route geometry: $e', error: e);
      Logger.error('Route data structure: $routeData');
    }
  }

  Future<void> _addRouteCircles(Map<String, dynamic> routeData) async {
    if (_pickupCircleManager == null || _destinationCircleManager == null || !mounted) return;
    
    try {
      final route = routeData['routes'][0];
      final geometry = route['geometry'] as Map<String, dynamic>;
      final coordinates = geometry['coordinates'] as List<dynamic>;
      
      if (coordinates.isEmpty) return;
      
      final startCoord = coordinates.first as List<dynamic>;
      final endCoord = coordinates.last as List<dynamic>;
      
      final baseRadius = 12.0;
      final animatedRadius = _pickupPulse?.value != null ? baseRadius * _pickupPulse!.value : baseRadius;
      final pickupOptions = CircleAnnotationOptions(
        geometry: MapboxUtils.createPoint(startCoord[1], startCoord[0]),
        circleRadius: animatedRadius,
        circleColor: Colors.green.toARGB32(),
        circleStrokeWidth: 2,
        circleStrokeColor: Colors.white.toARGB32(),
      );
      
      final destinationOptions = CircleAnnotationOptions(
        geometry: MapboxUtils.createPoint(endCoord[1], endCoord[0]),
        circleRadius: 12,
        circleColor: Colors.red.toARGB32(),
        circleStrokeWidth: 2,
        circleStrokeColor: Colors.white.toARGB32(),
      );
      
      await _pickupCircleManager?.create(pickupOptions);
      await _destinationCircleManager?.create(destinationOptions);
      
      Logger.info('Route circles added successfully');
      
    } catch (e) {
      Logger.error('Error adding route circles: $e', error: e);
    }
  }

  void _navigateToActiveRideScreen(String rideId) {
    Logger.debug('Navigating to ActiveRideScreen - stopping background processes');
    // ✅ FIX: Eliminăm blocajul hartii pentru experiență fluidă
    // _isNavigatingToActiveRide = true;
    _stopLocationUpdates();
    _nearbyDriversSubscription?.cancel();
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ActiveRideScreen(rideId: rideId)),
    ).then((_) {
      Logger.debug('Returned from ActiveRideScreen - resuming background processes');
      // ✅ FIX: Eliminăm blocajul hartii pentru experiență fluidă
    // _isNavigatingToActiveRide = false;
      
      _shouldResetRoute = true;
      
      if (mounted && _isDriverAvailable && _currentRole == UserRole.driver) {
        _startDriverLocationUpdates();
      }
      if (mounted) {
        _listenForNearbyDrivers();
        _resetRouteStateIfNeeded();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_verboseBuildLogs) {
      Logger.debug('DEBUG: MapScreen build() apelat');
      Logger.debug('DEBUG: _currentRole = $_currentRole');
      Logger.debug('DEBUG: _isDriverAvailable = $_isDriverAvailable');
      Logger.debug('DEBUG: ========== BUILD METHOD DEBUG ==========');
      Logger.debug('DEBUG: canShowVoiceAI = $canShowVoiceAI');
      if (canShowVoiceAI) {
        Logger.info('DEBUG:  canShowVoiceAI = true - va afișa AI button și overlay!');
      } else {
        Logger.error('DEBUG:  canShowVoiceAI = false - NU va afișa AI button și overlay!');
      }
      Logger.debug('DEBUG: ========== END BUILD METHOD DEBUG ==========');
    }
    
    final bool shouldShowPassengerUI = _currentRole == UserRole.passenger || 
                                       (_currentRole == UserRole.driver && !_isDriverAvailable);
    
    if (_verboseBuildLogs) {
      Logger.debug('DEBUG: shouldShowPassengerUI = $shouldShowPassengerUI');
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(_currentRole == UserRole.driver ? "Mod Șofer" : "FriendsRide"),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                onPressed: () => themeProvider.toggleTheme(),
                icon: Icon(themeProvider.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                tooltip: 'Schimbă tema',
              );
            },
          ),
          IconButton(
            onPressed: () async {
              await _getCurrentLocation(centerCamera: true);
            },
            icon: const Icon(Icons.my_location),
            tooltip: 'Locația mea',
          ),

          if (_currentRole == UserRole.driver)
            Switch.adaptive(
              value: _isDriverAvailable,
              onChanged: _toggleDriverAvailability,
              activeThumbColor: Colors.green,
              activeTrackColor: Colors.greenAccent,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
        ],
      ),
      drawer: AppDrawer(
        currentRole: _currentRole,
        onRoleChanged: _handleRoleChange,
      ),
      body: Stack(
        children: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              if (!_showMap) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                      SizedBox(height: 12),
                      Text('Se încarcă harta...', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }
              return MapWidget(
                onMapCreated: _onMapCreated,
                onTapListener: (position) => _handleMapTap(MapboxUtils.contextToPoint(position)),
                onMapIdleListener: _onMapIdle,
                cameraOptions: CameraOptions(
                  center: _currentPositionObject != null
                      ? MapboxUtils.createPoint(_currentPositionObject!.latitude, _currentPositionObject!.longitude)
                      : MapboxUtils.createPoint(44.4268, 26.1025),
                  zoom: 14.0,
                ),
                styleUri: AppDrawer.lowDataMode
                    ? MapboxStyles.LIGHT
                    : (themeProvider.isDarkMode 
                    ? MapboxStyles.DARK 
                        : MapboxStyles.MAPBOX_STREETS),
              );
            },
          ),
          
          // ✅ POI Category chips overlay (top, like Google/Waze)
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: SafeArea(
              child: _buildPoiCategoryChips(),
            ),
          ),

          // Scale bar moved to top-left under POI categories
          Positioned(
            top: 60,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Text(
                _scaleBarText,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ),

          if (shouldShowPassengerUI)
            if (_currentPositionObject != null)
              RideRequestPanel(
                key: _rideRequestPanelKey,
                startPosition: _currentPositionObject!,
                onRouteCalculated: _onRouteCalculated,
              )
            else
              const Center(child: CircularProgressIndicator())
          else if (_currentRole == UserRole.driver && _isDriverAvailable)
            if (_currentRideOffer != null)
              _buildRideOfferPopup()
            else
              _buildDriverInterface(),
          
          // NOU: Card informativ pentru POI-uri - Draggable Overlay (bounded, non-blocking)
          if (_showPoiCard && _selectedPoi != null)
            AnimatedPositioned(
              left: _poiCardPosition.dx,
              top: _poiCardPosition.dy,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: Builder(
                builder: (context) {
                  final screenSize = MediaQuery.of(context).size;
                  const double cardWidth = 340.0;
                  const double horizontalPadding = 8.0;
                  const double verticalPadding = 8.0;

                  return AnimatedScale(
                    duration: const Duration(milliseconds: 180),
                    scale: 1.0,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        final DateTime now = DateTime.now();
                        if (now.difference(_lastPoiCardPanUpdate).inMilliseconds < _poiCardPanThrottleMs) {
                          return;
                        }
                        _lastPoiCardPanUpdate = now;
                        setState(() {
                          final double maxX = screenSize.width - cardWidth - horizontalPadding;
                          final double maxY = screenSize.height - 200.0; // keep inside viewport
                          double newX = _poiCardPosition.dx + details.delta.dx;
                          double newY = _poiCardPosition.dy + details.delta.dy;
                          newX = newX.clamp(horizontalPadding, maxX);
                          newY = newY.clamp(verticalPadding, maxY);
                          _poiCardPosition = Offset(newX, newY);
                        });
                      },
                      child: SizedBox(
                        width: cardWidth,
                        child: _buildPoiCard(),
                      ),
                    ),
                  );
                },
              ),
            ),
          
          // ✅ Search this area chip (removed per request)
          /*Positioned(
            top: 16 + MediaQuery.of(context).padding.top,
            right: 16,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _showSearchAreaChip ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: !_showSearchAreaChip,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (_mapboxMap == null || _selectedPoiCategory == null) {
                      setState(() { _showSearchAreaChip = false; });
                      return;
                    }
                    final cam = await _mapboxMap!.getCameraState();
                    _lastSearchCenterLat = cam.center.coordinates.lat.toDouble();
                    _lastSearchCenterLng = cam.center.coordinates.lng.toDouble();
                    setState(() { _showSearchAreaChip = false; _isLoadingPois = true; });
                    await _onPoiCategoryTapped(_selectedPoiCategory!);
                  },
                  icon: _isLoadingPois ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh),
                  label: Text(_isLoadingPois ? 'Se caută…' : 'Caută în această zonă'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 2,
                  ),
                ),
              ),
            ),
          ),*/
          
          // ✅ CONECTARE 1: Intermediate stops list
          if (_intermediateStops.isNotEmpty)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: _buildIntermediateStopsList(), // ✅ AICI se folosește funcția!
            ),
          
          // Camera control buttons moved to AppBar

          // ✅ Alt routes toggle & preview card + ETA/distance preview pentru ruta curentă
          if (_alternativeRoutes.isNotEmpty)
            Positioned(
              bottom: 90 + MediaQuery.of(context).padding.bottom,
              left: 16,
              right: 16,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_currentRouteDistanceMeters != null && _currentRouteDurationSeconds != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              const Icon(Icons.directions, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                '${_routingService.formatDuration(_currentRouteDurationSeconds!)} • ${_routingService.formatDistance(_currentRouteDistanceMeters!)}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              if (_pickupQualityLabel != null && _pickupQualityColor != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _pickupQualityColor!.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _pickupQualityColor!.withValues(alpha: 0.6)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.flag_rounded, size: 14, color: _pickupQualityColor),
                                      const SizedBox(width: 6),
                                      Text(_pickupQualityLabel!, style: TextStyle(fontWeight: FontWeight.w600, color: _pickupQualityColor)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      Row(
                        children: [
                          const Text('Rute alternative', style: TextStyle(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          if (_isFetchingAlternatives) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(_alternativeRoutes.length, (i) {
                            final r = _alternativeRoutes[i];
                            final meters = (r['distance'] as num?)?.toDouble() ?? 0.0;
                            final seconds = (r['duration'] as num?)?.toDouble() ?? 0.0;
                            final dist = _routingService.formatDistance(meters);
                            final eta = _routingService.formatDuration(seconds);
                            final selected = i == _selectedAltRouteIndex;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text('$eta • $dist'),
                                selected: selected,
                                onSelected: (val) async {
                                  setState(() { _selectedAltRouteIndex = i; });
                                  // Re-desenăm ruta: selectata ca principală + celelalte faint
                                  final reordered = <Map<String, dynamic>>[r, ..._alternativeRoutes.where((e) => !identical(e, r)).cast<Map<String, dynamic>>()];
                                  await _onRouteCalculated({'routes': reordered});
                                },
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_alternativeRoutes.isNotEmpty && !_tipAltRoutesSeen)
            Positioned(
              bottom: 160 + MediaQuery.of(context).padding.bottom,
              left: 16,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    setState(() { _tipAltRoutesSeen = true; });
                    try { final prefs = await SharedPreferences.getInstance(); await prefs.setBool('tip_alt_routes_seen', true); } catch (_) {}
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.black.withAlpha(179), borderRadius: BorderRadius.circular(8)),
                    child: const Text('Tip: alege ruta alternativă cea mai rapidă.', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
              ),
            ),

          // ✅ Pickup suggestions chips
          if (_showPickupSuggestions && _pickupSuggestionPoints.isNotEmpty)
            Positioned(
              bottom: 150 + MediaQuery.of(context).padding.bottom,
              left: 16,
              right: 16,
              child: Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Wrap(
                    spacing: 8,
                    children: List.generate(_pickupSuggestionPoints.length, (i) {
                      return ActionChip(
                        avatar: const Icon(Icons.trip_origin, size: 18),
                        label: Text('Pickup ${i + 1}'),
                        onPressed: () {
                          final pt = _pickupSuggestionPoints[i];
                          setState(() {
                            _pickupLatitude = pt.coordinates.lat.toDouble();
                            _pickupLongitude = pt.coordinates.lng.toDouble();
                            _showPickupSuggestions = false;
                          });
                          _updateMapWithNewPickup();
                          _showSafeSnackBar('Punct de preluare selectat', Colors.blue);
                        },
                      );
                    }),
                  ),
                ),
              ),
            ),
          
          // ✅ CONECTARE 2: Ride info panel
          if (_pickupLatitude != null || _destinationLatitude != null)
            Positioned(
              bottom: 200,
              left: 16,
              right: 16,
              child: _buildRideInfoPanel(), // ✅ AICI se folosește funcția!
            ),
          
          // 🎤 AI BUTTON - Afișat doar pentru pasageri și șoferi indisponibili
          if (canShowVoiceAI)
            Consumer2<FriendsRideVoiceIntegration, AssistantStatusProvider>(
              builder: (context, voiceIntegration, statusProvider, child) {
                return DraggableAIButton(
                  onTap: () async {
                    Logger.debug('DEBUG: AI Button apăsat - pornesc voice interaction');
                    try {
                      // ✅ NOU: Actualizează statusul asistentului la "working"
                      statusProvider.setStatus(AssistantWorkStatus.working);
                      
                      await voiceIntegration.startVoiceInteraction();
                      Logger.debug('DEBUG: Voice interaction pornit cu succes');
                    } catch (e) {
                      Logger.error('DEBUG:  Eroare la pornirea voice interaction: $e', error: e);
                      // ✅ NOU: Revenire la idle dacă apare eroare
                      statusProvider.setStatus(AssistantWorkStatus.idle);
                    }
                  },
                  processingState: voiceIntegration.currentContext.processingState,
                );
              },
            ),
          
          // 🎤 VOICE OVERLAY - Afișat când voice interaction este activ
          Consumer2<FriendsRideVoiceIntegration, AssistantStatusProvider>(
            builder: (context, voiceIntegration, statusProvider, child) {
              // ✅ NOU: Actualizează statusul asistentului bazat pe starea voice interaction
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (voiceIntegration.isVoiceActive) {
                  statusProvider.setStatus(AssistantWorkStatus.working);
                } else {
                  statusProvider.setStatus(AssistantWorkStatus.idle);
                }
              });
              
              if (!voiceIntegration.isVoiceActive) return const SizedBox.shrink();
              
              return _buildVoiceOverlay(voiceIntegration);
            },
          ),
          
          // ✅ NOU: Assistant Status Overlay - Indicator mic în colțul din dreapta sus
          const AssistantStatusOverlay(),
        ],
      ),
    );
  }

  Widget _buildRideOfferPopup() {
    final ride = _currentRideOffer;
    if (ride == null) return const SizedBox.shrink();
    return Positioned(
      top: 100,
      left: 16,
      right: 16,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView( // ✅ FIX: Adăugat pentru a preveni overflow
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded( // ✅ FIX: Adăugat Expanded pentru titlu
                      child: Text(
                        'Cursă nouă',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.black12),
                      child: Text('${_remainingSeconds}s', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.place, color: Colors.red, size: 18),
                      const SizedBox(width: 6),
                      Expanded( // ✅ FIX: Adăugat Expanded
                        child: Text(
                          ride.destinationAddress,
                          maxLines: 3,
                          overflow: TextOverflow.visible,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.trip_origin, color: Colors.green, size: 18),
                      const SizedBox(width: 6),
                      Expanded( // ✅ FIX: Adăugat Expanded
                        child: Text(
                          ride.startAddress,
                          maxLines: 2,
                          overflow: TextOverflow.visible,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ]),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessingDecline ? null : () => _declineRide(ride),
                      icon: _isProcessingDecline 
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.close, size: 18),
                      label: Text(_isProcessingDecline ? 'Refuz...' : 'Refuză'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.red.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessingAccept ? null : () => _acceptRide(ride),
                      icon: _isProcessingAccept 
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check, size: 18),
                      label: Text(_isProcessingAccept ? 'Accept...' : 'Acceptă'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.green.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

double _calculateDirectDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final dLat = (lat2 - lat1) * (math.pi / 180);
    final dLon = (lon2 - lon1) * (math.pi / 180);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  Widget _buildDriverInterface() {
    return StreamBuilder<Ride?>(
      stream: _firestoreService.getActiveDriverRideStream(),
      builder: (context, activeRideSnapshot) {
        if (activeRideSnapshot.connectionState == ConnectionState.waiting){
          return const Center(child: CircularProgressIndicator());
        }

        final Ride? newActiveRide = activeRideSnapshot.data;
        
        // ✅ NOU: Navigare automată când apare o cursă nouă acceptată
        if (newActiveRide != null && _currentActiveRide?.id != newActiveRide.id) {
          Logger.debug("Cursă nouă atribuită (${newActiveRide.id}). Se redă sunetul de notificare.");
          // ✅ FIX: Folosește metoda robustă pentru notificarea de cursă
          unawaited(_playRideOfferSoundRobust());
          
          // ✅ NOU: Navigare automată la ActiveRideScreen când apare o cursă nouă
          // Verifică dacă statusul permite navigarea (nu navigăm pentru 'driver_found' care încă așteaptă confirmare)
          if (['accepted', 'arrived', 'in_progress'].contains(newActiveRide.status)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _currentActiveRide?.id != newActiveRide.id) {
                Logger.debug('Auto-navigating to ActiveRideScreen for ride ${newActiveRide.id}', tag: 'MAP');
                _navigateToActiveRideScreen(newActiveRide.id);
              }
            });
          }
        }
        _currentActiveRide = newActiveRide;
        
        if (newActiveRide == null) {
          if (_driverPickupEta != null ||
              _driverDestinationEta != null ||
              _driverTrafficSummary != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _resetDriverEtaMetrics();
              }
            });
          }
          return _buildDriverWaitingIndicator();
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _listenForChatMessages(newActiveRide.id);
          if (_currentPositionObject != null) {
            _updateDriverRideEstimates(_currentPositionObject!);
          }
        });

        final statusLabel = _formatRideStatus(newActiveRide.status);
        final trafficSummary = _driverTrafficSummary;

        return Positioned(
          bottom: 20, left: 20, right: 20,
          child: GestureDetector(
            onTap: () => _navigateToActiveRideScreen(newActiveRide.id),
            child: Card(
              color: Colors.orange.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(60),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.local_taxi, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min, // ✅ FIX: Adăugat mainAxisSize
                            children: [
                              Text(
                                'Cursă activă',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1, // ✅ FIX: Adăugat maxLines
                                overflow: TextOverflow.ellipsis, // ✅ FIX: Adăugat overflow
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Pasager: ${newActiveRide.passengerId}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.visible,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                statusLabel,
                                style: TextStyle(
                                  color: Colors.white.withAlpha(200),
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.visible,
                              ),
                            ],
                          ),
                        ),
                        if (trafficSummary != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(40),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              trafficSummary,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Preluare',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                newActiveRide.startAddress,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Destinație',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                newActiveRide.destinationAddress,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Până la preluare',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDriverEta(_driverPickupEta),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _formatDriverDistance(_driverPickupDistanceKm),
                              style: TextStyle(
                                color: Colors.white.withAlpha(200),
                                fontSize: 12,
                              ),
                            ),
                            if (_driverPickupArrivalTime != null)
                              Text(
                                'Ridicare ~${DateFormat.Hm().format(_driverPickupArrivalTime!)}',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(200),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            const SizedBox(height: 12),
                            const Text(
                              'Până la destinație',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDriverEta(_driverDestinationEta),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _formatDriverDistance(_driverDestinationDistanceKm),
                              style: TextStyle(
                                color: Colors.white.withAlpha(200),
                                fontSize: 12,
                              ),
                            ),
                            if (_driverDestinationArrivalTime != null)
                              Text(
                                'Sosire ~${DateFormat.Hm().format(_driverDestinationArrivalTime!)}',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(200),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Harta este înghețată pentru performanță',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Atinge pentru detalii ➜',
                        style: TextStyle(
                          color: Colors.white.withAlpha(220),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDriverWaitingIndicator() {
    return Positioned(
      bottom: 120,
      left: 16,
      right: 16,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [Colors.green.shade400, Colors.green.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Căutăm curse în zona ta...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Categoria: ${_driverCategory?.name ?? 'standard'} • ${_pendingRides.length} curse disponibile",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withAlpha(204),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =================
  // POI UI WIDGETS
  // =================

  /// Construiește card-ul informativ pentru POI selectat
  Widget _buildPoiCard() {
    final poi = _selectedPoi!;
    
    return Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header cu imagine și buton închidere
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Image.network(
                    poi.imageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        color: Colors.grey.shade300,
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 48,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: _closePoiCard,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(153, 0, 0, 0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Conținut
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titlu
                  Text(
                    poi.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Descriere
                  Text(
                    poi.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Butoane de acțiune - NOU: 3 butoane pentru pickup, destination, stop
                  _buildPOIActions(poi),
                ],
              ),
            ),
          ],
      ),
    );
  }

  /// Construiește butoanele de acțiune pentru POI cu 3 opțiuni
  Widget _buildPOIActions(PointOfInterest poi) {
    return Column(
      children: [
        // Prima linie - Plecare și Destinație
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _setPOIAsPickup(poi),
                icon: const Icon(Icons.my_location, size: 18),
                label: const Text('Plecare'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _setPOIAsDestination(poi),
                icon: const Icon(Icons.flag, size: 18),
                label: const Text('Destinație'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // A doua linie - Oprire intermediară
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _addPOIAsStop(poi),
            icon: const Icon(Icons.add_location, size: 18),
            label: const Text('Adaugă ca oprire'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =================
  // POI CATEGORY CHIPS OVERLAY + ACTIONS
  // =================

  Widget _buildPoiCategoryChips() {
    final List<PoiCategory> categories = [
      PoiCategory.gasStation,
      PoiCategory.restaurant,
      PoiCategory.parking,
      PoiCategory.hotel,
      PoiCategory.hospital,
      PoiCategory.pharmacy,
      PoiCategory.supermarket,
      PoiCategory.bank,
      PoiCategory.atm,
      PoiCategory.school,
      PoiCategory.university,
      PoiCategory.library,
      PoiCategory.police,
      PoiCategory.postOffice,
      PoiCategory.mall,
      PoiCategory.bakery,
      PoiCategory.barPub,
      PoiCategory.park,
      PoiCategory.museum,
      PoiCategory.cinema,
      PoiCategory.theatre,
      PoiCategory.playground,
      PoiCategory.chargingStation,
      PoiCategory.carWash,
      PoiCategory.carRepair,
      PoiCategory.publicTransport,
      PoiCategory.airport,
      PoiCategory.other,
      PoiCategory.tourism,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final category in categories) ...[
              ActionChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(category.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(category.displayName),
                  ],
                ),
                onPressed: () => _onPoiCategoryTapped(category),
                backgroundColor: Colors.white,
                elevation: 2,
                shadowColor: Colors.black12,
                side: BorderSide(color: Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _onPoiCategoryTapped(PoiCategory category) async {
    if (!mounted) return;

    // Toggle same category: clear selection and map
    if (_selectedPoiCategory == category) {
      setState(() {
        _selectedPoiCategory = null;
      });
      await _updatePoiGeoJson(const []); // keep map clean
      _showSafeSnackBar('Filtru eliminat.', Colors.grey);
      return;
    }

    setState(() {
      _selectedPoiCategory = category;
      _isLoadingPois = true;
    });

    try {
      // Ensure we have a camera center for proximity
      final cameraState = await _mapboxMap!.getCameraState();
      final center = {
        'latitude': cameraState.center.coordinates.lat.toDouble(),
        'longitude': cameraState.center.coordinates.lng.toDouble(),
      };

      Logger.debug('Fetching ${category.displayName} via Mapbox Search (București-Ilfov)...');
      final fetchedPois = await _poiService.fetchPoisFromApi(center, category);

      if (!mounted) return;

      if (fetchedPois.isEmpty) {
        _showSafeSnackBar('Nu am găsit rezultate pentru ${category.displayName} în București-Ilfov.', Colors.orange);
      return;
    }

      _showPoisForCategoryBottomSheet(category, fetchedPois);
    } catch (e) {
      if (mounted) {
        _showSafeSnackBar('Eroare la încărcarea datelor: $e', Colors.red);
      }
      Logger.error('Eroare la _onPoiCategoryTapped: $e', error: e);
    } finally {
      if (mounted) {
        setState(() { _isLoadingPois = false; });
      }
    }
  }

  void _showPoisForCategoryBottomSheet(PoiCategory category, List<PointOfInterest> pois) {
    // Sortează după distanță curentă și cap la N (pentru listă; nu se actualizează harta aici)
    List<PointOfInterest> listPois = List<PointOfInterest>.from(pois);
    if (_currentPositionObject != null) {
      listPois.sort((a, b) {
        final da = _calculateDirectDistance(
            _currentPositionObject!.latitude,
            _currentPositionObject!.longitude,
            a.location.latitude,
            a.location.longitude);
        final db = _calculateDirectDistance(
            _currentPositionObject!.latitude,
            _currentPositionObject!.longitude,
            b.location.latitude,
            b.location.longitude);
        return da.compareTo(db);
      });
    }
    listPois = listPois.take(_poiMaxMarkers).toList();

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('${category.emoji} ${category.displayName}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('${listPois.length} rezultate', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: listPois.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final poi = listPois[index];
                  String? distanceLabel;
                  if (_currentPositionObject != null) {
                    final meters = _calculateDirectDistance(
                              _currentPositionObject!.latitude,
                              _currentPositionObject!.longitude,
                              poi.location.latitude,
                      poi.location.longitude,
                    );
                    final localeName = Localizations.localeOf(context).toString();
                    if (meters < 1000) {
                      final mFmt = NumberFormat.decimalPatternDigits(locale: localeName, decimalDigits: 0);
                      distanceLabel = '${mFmt.format(meters.round())} m';
                    } else {
                      final kmFmt = NumberFormat.decimalPatternDigits(locale: localeName, decimalDigits: 1);
                      distanceLabel = '${kmFmt.format(meters / 1000.0)} km';
                    }
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey.shade200,
                      child: Text(category.emoji, style: const TextStyle(fontSize: 18)),
                    ),
                    title: Text(poi.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      poi.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: distanceLabel == null
                        ? null
                        : Text(distanceLabel, style: TextStyle(color: Colors.grey.shade700)),
                    onTap: () {
                      // Închide sheet-ul apoi arată markerul pentru itemul selectat
                      Navigator.of(context).pop();
                      _onPoiTapped(poi);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  // =================
  // POI METHODS - INTERACTIVE POINTS OF INTEREST
  // =================

  // În noul flux, încărcarea automată de POI nu mai este utilizată

  // Eliminat: nu se mai folosește în noul flux (lista -> selecție singulară)

  Future<void> _updatePoiGeoJson(List<PointOfInterest> pois) async {
    if (_mapboxMap == null) return;
    try {
      final features = pois.map((p) => {
            'type': 'Feature',
            'geometry': {
              'type': 'Point',
              'coordinates': [p.location.longitude, p.location.latitude]
            },
            'properties': {
              'id': p.id,
              'name': p.name,
              'emoji': p.category.emoji,
              'category': p.category.displayName,
            }
          }).toList();
      final fc = {'type': 'FeatureCollection', 'features': features};
      await _mapboxMap!.style.setStyleSourceProperty(
        _poiSourceId,
        'data',
        json.encode(fc),
      );
    } catch (e) {
      Logger.error('Failed to update POI GeoJSON: $e', error: e);
    }
  }

  // REMOVED: _clearExistingPois was unused after switching to SymbolLayer-based rendering.

  // REMOVED: _getCategoryColor was only used by the old PointAnnotation rendering path.

  /// ✅ Schedulează actualizări POI — dezactivat în noul flux (doar listă)
  void _schedulePoiUpdate({Duration delay = const Duration(milliseconds: 450)}) {
    _poiUpdateTimer?.cancel();
    _poiUpdateTimer = Timer(delay, () async {
      if (!mounted) return;
      // NOP: POI-urile nu se mai încarcă automat pe mișcare cameră
    });
  }

  // Called when camera stops moving; în noul flux nu declanșează încărcări de POI
  void _onMapIdle(MapIdleEventData data) {
    // Afișează chip "Caută în această zonă" doar dacă deplasarea e semnificativă
    _updateSearchAreaChipVisibility();
  }

  void _updateSearchAreaChipVisibility() async {
    if (_mapboxMap == null) return;
    try {
      final cam = await _mapboxMap!.getCameraState();
      final center = cam.center;
      final lat = center.coordinates.lat.toDouble();
      final lng = center.coordinates.lng.toDouble();
      // Scale bar simplu (approx) – 1° ~ 111km
      final zoom = cam.zoom;
      final kmPerScreen = 40075 / (1 << zoom.toInt());
      final kmText = kmPerScreen < 1 ? '${(kmPerScreen * 1000).round()} m' : '${kmPerScreen.toStringAsFixed(1)} km';
      setState(() {
        _scaleBarText = kmText;
      });
      final lastLat = _lastSearchCenterLat;
      final lastLng = _lastSearchCenterLng;
      if (lastLat == null || lastLng == null) {
        setState(() { _showSearchAreaChip = true; });
        return;
      }
      final movedMeters = MapboxUtils.calculateDistance(
        MapboxUtils.createPoint(lastLat, lastLng),
        MapboxUtils.createPoint(lat, lng),
      );
      final shouldShow = movedMeters > 150.0; // prag mic
      if (shouldShow != _showSearchAreaChip) {
        setState(() { _showSearchAreaChip = shouldShow; });
      }
    } catch (_) {}
  }

  /// ✅ Handler pentru tap-uri pe hartă (Widget-based approach)
  void _handleMapTap(Point tappedPoint) {
    _checkForPOIAtPoint(tappedPoint);
  }

  /// Verifică dacă tap-ul este pe un POI
  void _checkForPOIAtPoint(Point tappedPoint) {
    final pois = _currentPois;
    
    // Verifică distanța față de fiecare POI (raza de detectare: ~50 metri)
    const double detectionRadiusMeters = 50.0;
    
    for (int i = 0; i < pois.length; i++) {
      final poi = pois[i];
      final poiPoint = Point(
        coordinates: Position(poi.location.longitude, poi.location.latitude)
      );
      
      // Calculează distanța aproximativă
      final distance = _calculateDistanceBetweenPoints(tappedPoint, poiPoint);
      
      if (distance <= detectionRadiusMeters) {
        Logger.debug('POI detected: ${poi.name}');
        _onPoiTapped(poi);
        return; // Stop la primul POI găsit
      }
    }
  }

  /// Calculează distanța aproximativă între două puncte în metri
  double _calculateDistanceBetweenPoints(Point point1, Point point2) {
    const double earthRadius = 6371000; // metri
    final lat1Rad = point1.coordinates.lat * (math.pi / 180);
    final lat2Rad = point2.coordinates.lat * (math.pi / 180);
    final deltaLatRad = (point2.coordinates.lat - point1.coordinates.lat) * (math.pi / 180);
    final deltaLngRad = (point2.coordinates.lng - point1.coordinates.lng) * (math.pi / 180);

    final a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Handler pentru POI selectat
  void _onPoiTapped(PointOfInterest poi) {
    Logger.info('POI tapped: ${poi.name}');
    HapticFeedback.selectionClick();
    
    setState(() {
      _selectedPoi = poi;
      _showPoiCard = true;
      // Reset position so the card starts in a visible spot
      _poiCardPosition = const Offset(16, 180);
    });

    // Ensure zoom to de-cluster and center (debounced and thresholded)
    _cameraFlyToTimer?.cancel();
    _cameraFlyToTimer = Timer(const Duration(milliseconds: 250), () async {
      final map = _mapboxMap;
      if (map == null) return;
      try {
        final cam = await map.getCameraState();
        final currentCenter = cam.center;
        final double currentLat = currentCenter.coordinates.lat.toDouble();
        final double currentLng = currentCenter.coordinates.lng.toDouble();
        final double targetLat = poi.location.latitude;
        final double targetLng = poi.location.longitude;

        final double dMeters = MapboxUtils.calculateDistance(
          MapboxUtils.createPoint(currentLat, currentLng),
          MapboxUtils.createPoint(targetLat, targetLng),
        );
        final double zoomDelta = (cam.zoom - 16.0).abs();

        // Skip tiny moves to avoid camera churn
        if (dMeters < 80.0 && zoomDelta < 0.15) return;

        unawaited(map.flyTo(
          CameraOptions(
            center: MapboxUtils.createPoint(targetLat, targetLng),
            zoom: 16.0,
            padding: MbxEdgeInsets(
              top: 80.0,
              left: 16.0,
              bottom: 320.0, // spațiu pentru cardurile de jos
              right: 16.0,
            ),
          ),
          MapAnimationOptions(duration: AppDrawer.lowDataMode ? 350 : 600),
        ));
      } catch (_) {}
    });

    // Update selected POI highlight
    _updateSelectedPoiHighlight(poi);

    // ✅ Auto-hide: dacă nu se inițiază nicio acțiune (pickup/destination/stop),
    // curățăm highlight-ul și cardul după 60 secunde pentru a elibera memorie
    _selectedPoiAutoHideTimer?.cancel();
    _selectedPoiAutoHideTimer = Timer(const Duration(seconds: 60), () async {
      if (!mounted) return;
      if (_selectedPoi?.id == poi.id) {
        await _clearSelectedPoiHighlight();
        if (mounted) {
          setState(() {
            _selectedPoi = null;
            _showPoiCard = false;
          });
        }
        Logger.debug('Auto-hide POI ${poi.name} după 5s (fără navigare)');
      }
    });

    // Optional: alege intrarea pentru POI-uri mari
    _maybeShowEntrancePicker(poi);

    // Sugestii pickup în jurul POI
    _generatePickupSuggestionsAround(poi);
  }

  Future<void> _updateSelectedPoiHighlight(PointOfInterest poi) async {
    if (_mapboxMap == null) return;
    try {
      final feature = {
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [poi.location.longitude, poi.location.latitude]
        },
        'properties': {
          'id': poi.id,
          'name': poi.name,
        }
      };
      final fc = {'type': 'FeatureCollection', 'features': [feature]};
      // Update highlight but don't block UI
      unawaited(_mapboxMap!.style.setStyleSourceProperty(
        _selectedPoiSourceId,
        'data',
        json.encode(fc),
      ));
    } catch (e) {
      Logger.error('Failed to update selected POI highlight: $e', error: e);
    }
  }

  Future<void> _clearSelectedPoiHighlight() async {
    if (_mapboxMap == null) return;
    try {
      final empty = {'type': 'FeatureCollection', 'features': []};
      await _mapboxMap!.style.setStyleSourceProperty(
        _selectedPoiSourceId,
        'data',
        json.encode(empty),
      );
    } catch (e) {
      Logger.error('Failed to clear selected POI highlight: $e', error: e);
    }
  }





  /// Setează POI ca punct de plecare
  void _setPOIAsPickup(PointOfInterest poi) {
    Logger.info('Setting POI as pickup: ${poi.name}');
    
    try {
      // ✅ PERFORMANCE: Cancel previous operations
      _poiOperationTimer?.cancel();
      
      // ✅ PERFORMANCE: Quick UI update - batch all setState calls
      setState(() {
        Logger.info('Updating pickup state...');
        _pickupController.text = poi.name;
        _pickupLatitude = poi.location.latitude;
        _pickupLongitude = poi.location.longitude;
        // ✅ PERFORMANCE: Close POI card in same setState
        _selectedPoi = null;
        _showPoiCard = false;
        Logger.info('Pickup state updated: lat=$_pickupLatitude, lng=$_pickupLongitude');
      });

      // ✅ PERFORMANCE: Close POI card immediately - no additional navigation
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // ✅ PERFORMANCE: Show SnackBar immediately
      _showSafeSnackBar(
        '${poi.name} setat ca punct de plecare',
        Colors.blue,
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () => _clearPickup(),
        ),
      );

      // ✅ PERFORMANCE: Debounce heavy operations
      _poiOperationTimer = Timer(Duration(milliseconds: 300), () {
        if (mounted) {
          Logger.info('Executing deferred operations for pickup...');
          _updateRideRequestPanelPickup(poi);
          _updateMapWithNewPickup();
          // ✅ CONECTARE: Folosește batch map updates
          _batchMapUpdates();
          // ✅ CONECTARE: Folosește _routingService pentru route update
          _updateRouteAfterPOI();
        }
      });

      // Afișează automat ruta dacă avem pickup + destinație
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) _checkAndShowRouteAutomatically();
      });
      
    } catch (e) {
      Logger.error('CRASH in _setPOIAsPickup: $e', error: e);
      Logger.error('Stack trace: ${StackTrace.current}');
      if (mounted) {
        _closePoiCard();
        _showSafeSnackBar('Eroare la setarea pickup: $e', Colors.red);
      }
    }
  }

  /// Setează POI ca punct de destinație
  void _setPOIAsDestination(PointOfInterest poi) {
    Logger.info('Setting POI as destination: ${poi.name}');
    
    try {
      // ✅ PERFORMANCE: Cancel previous operations
      _poiOperationTimer?.cancel();
      
      // ✅ PERFORMANCE: Quick UI update - batch all setState calls
      setState(() {
        Logger.info('Updating destination state...');
        _destinationController.text = poi.name;
        _destinationLatitude = poi.location.latitude;
        _destinationLongitude = poi.location.longitude;
        // ✅ PERFORMANCE: Close POI card in same setState
        _selectedPoi = null;
        _showPoiCard = false;
        Logger.info('Destination state updated: lat=$_destinationLatitude, lng=$_destinationLongitude');
      });

      // ✅ PERFORMANCE: Close POI card immediately - no additional navigation
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // ✅ PERFORMANCE: Show SnackBar immediately
      _showSafeSnackBar(
        '${poi.name} setat ca destinație',
        Colors.green,
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () => _clearDestination(),
        ),
      );

      // ✅ PERFORMANCE: Debounce heavy operations
      _poiOperationTimer = Timer(Duration(milliseconds: 300), () {
        if (mounted) {
          Logger.info('Executing deferred operations for destination...');
          _updateRideRequestPanelDestination(poi);
          _updateMapWithNewDestination();
          // ✅ CONECTARE: Folosește batch map updates
          _batchMapUpdates();
          // ✅ CONECTARE: Folosește _routingService pentru route update
          _updateRouteAfterPOI();
        }
      });

      // Afișează automat ruta dacă avem pickup + destinație
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) _checkAndShowRouteAutomatically();
      });
      
    } catch (e) {
      Logger.error('CRASH in _setPOIAsDestination: $e', error: e);
      Logger.error('Stack trace: ${StackTrace.current}');
      if (mounted) {
        _closePoiCard();
        _showSafeSnackBar('Eroare la setarea destinației: $e', Colors.red);
      }
    }
  }

    /// Adaugă POI ca oprire intermediară
  void _addPOIAsStop(PointOfInterest poi) {
    Logger.debug('Adding POI as stop: ${poi.name}');
    
    try {
      // ✅ PERFORMANCE: Cancel previous operations
      _poiOperationTimer?.cancel();
      
      // Validation
      if (_intermediateStops.length >= _maxIntermediateStops) {
        _showSafeSnackBar('Maximum $_maxIntermediateStops opriri intermediare permise', Colors.orange);
        return;
      }

      // Check for duplicates
      final existingStop = _intermediateStops.any((stop) =>
          stop == poi.name);
      
      if (existingStop) {
        _showSafeSnackBar('Această oprire este deja adăugată', Colors.orange);
        return;
      }

      // ✅ PERFORMANCE: Quick UI update - batch all setState calls
      setState(() {
        Logger.debug('Adding stop to list...');
        _intermediateStops.add(poi.name);
        // ✅ PERFORMANCE: Close POI card in same setState
        _selectedPoi = null;
        _showPoiCard = false;
        Logger.debug('Stop added. Total stops: ${_intermediateStops.length}');
      });

      // ✅ PERFORMANCE: Close POI card immediately - no additional navigation
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // ✅ PERFORMANCE: Show SnackBar immediately
      _showSafeSnackBar(
        '${poi.name} adăugat ca oprire intermediară',
        Colors.orange,
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () => _removeLastStop(),
        ),
      );

      // ✅ PERFORMANCE: Debounce heavy operations
      _poiOperationTimer = Timer(Duration(milliseconds: 300), () {
        if (mounted) {
          Logger.debug('Executing deferred operations for stop...');
          _updateMapWithAllPoints();
          // ✅ CONECTARE: Folosește batch map updates
          _batchMapUpdates();
          // ✅ CONECTARE: Folosește _routingService pentru route update
          _updateRouteAfterPOI();
        }
      });

      // Afișează automat ruta dacă avem pickup + destinație
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) _checkAndShowRouteAutomatically();
      });
      
    } catch (e) {
      Logger.error('CRASH in _addPOIAsStop: $e', error: e);
      Logger.error('Stack trace: ${StackTrace.current}');
      if (mounted) {
        _closePoiCard();
        _showSafeSnackBar('Eroare la adăugarea opririi: $e', Colors.red);
      }
    }
  }

  /// Metodă helper pentru a șterge ultimul stop adăugat
  void _removeLastStop() {
    if (_intermediateStops.isNotEmpty) {
      setState(() {
        _intermediateStops.removeLast();
      });
      
      // Update ruta după ștergere
      if (_pickupLatitude != null && _destinationLatitude != null) {
        _updateRouteWithAllPoints();
      }
    }
  }

  /// Șterge un stop specific din listă
  void _removeStop(String stopName) {
    setState(() {
      _intermediateStops.removeWhere((s) => s == stopName);
    });
    
    // Feedback vizual
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$stopName eliminat din opriri'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    // Update ruta după ștergere
    if (_pickupLatitude != null && _destinationLatitude != null) {
      _updateRouteWithAllPoints();
    }
  }

  /// Widget pentru afișarea listei de opriri intermediare
  Widget _buildIntermediateStopsList() {
    if (_intermediateStops.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Opriri intermediare (${_intermediateStops.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _intermediateStops.length,
            itemBuilder: (context, index) {
              final stop = _intermediateStops[index];
              return ListTile(
                leading: Icon(Icons.location_on, color: Colors.orange),
                title: Text(stop),
                subtitle: Text(
                  'Oprire ${index + 1}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeStop(stop),
                  tooltip: 'Șterge oprirea',
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Curăță pickup-ul
  void _clearPickup() {
    setState(() {
      _pickupController.clear();
      _pickupLatitude = null;
      _pickupLongitude = null;


    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Punctul de plecare a fost șters')),
      );
    }
    
    _updateMapWithAllPoints();
  }

  /// Curăță destinația
  void _clearDestination() {
    setState(() {
      _destinationController.clear();
      _destinationLatitude = null;
      _destinationLongitude = null;

    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Destinația a fost ștearsă')),
      );
    }
    
    _updateMapWithAllPoints();
  }



  /// Update hartă cu noul pickup
  void _updateMapWithNewPickup() {
    if (_pickupLatitude != null && _pickupLongitude != null) {
      // Center camera pe pickup
      _mapboxMap?.flyTo(
        CameraOptions(
          center: MapboxUtils.createPoint(_pickupLatitude!, _pickupLongitude!),
          zoom: 15.0,
        ),
        MapAnimationOptions(duration: 1000)
      );
      
      // Update route dacă avem și destinația
      if (_destinationLatitude != null && _destinationLongitude != null) {
        _updateRouteWithAllPoints();
      }
    }
  }

  /// Update hartă cu noua destinație
  void _updateMapWithNewDestination() {
    if (_destinationLatitude != null && _destinationLongitude != null) {
      // Update route dacă avem și pickup-ul
      if (_pickupLatitude != null && _pickupLongitude != null) {
        _updateRouteWithAllPoints();
      }
    }
  }



  /// Update hartă cu toate punctele
  void _updateMapWithAllPoints() {
    List<Point> allPoints = [];
    
    // Adaugă pickup
    if (_pickupLatitude != null && _pickupLongitude != null) {
      allPoints.add(Point(coordinates: Position(_pickupLongitude!, _pickupLatitude!)));
    }
    
    // Adaugă destination
    if (_destinationLatitude != null && _destinationLongitude != null) {
      allPoints.add(Point(coordinates: Position(_destinationLongitude!, _destinationLatitude!)));
    }
    
    // Fit camera pentru toate punctele
    if (allPoints.isNotEmpty) {
      _fitCameraToPoints(allPoints);
    }
    
    // Update route dacă avem pickup și destination
    if (_pickupLatitude != null && _destinationLatitude != null) {
      _updateRouteWithAllPoints();
    }
  }

  /// Fit camera pentru toate punctele
  void _fitCameraToPoints(List<Point> points) {
    if (points.isEmpty || _mapboxMap == null) return;
    
    double minLat = points.first.coordinates.lat.toDouble();
    double maxLat = points.first.coordinates.lat.toDouble();
    double minLng = points.first.coordinates.lng.toDouble();
    double maxLng = points.first.coordinates.lng.toDouble();
    
    for (var point in points) {
      minLat = math.min(minLat, point.coordinates.lat.toDouble());
      maxLat = math.max(maxLat, point.coordinates.lat.toDouble());
      minLng = math.min(minLng, point.coordinates.lng.toDouble());
      maxLng = math.max(maxLng, point.coordinates.lng.toDouble());
    }
    
    // Adaugă padding
    const double padding = 0.01; // ~1km
    minLat -= padding;
    maxLat += padding;
    minLng -= padding;
    maxLng += padding;
    
    final center = Point(
      coordinates: Position(
        (minLng + maxLng) / 2,
        (minLat + maxLat) / 2,
      )
    );
    
    _mapboxMap?.flyTo(
      CameraOptions(center: center, zoom: 12.0),
      MapAnimationOptions(duration: AppDrawer.lowDataMode ? 600 : 1000)
    );
  }

  /// ✅ PERFORMANCE: Update route cu toate punctele - optimized with async
  void _updateRouteWithAllPoints() async {
    Logger.debug('Starting route update...');
    
    if (_pickupLatitude == null || _destinationLatitude == null) {
      Logger.debug('Missing pickup or destination - skipping route update');
      return;
    }
    
    try {
      // ✅ PERFORMANCE: Give UI time to settle before heavy operations
      await Future.delayed(Duration(milliseconds: 100));
      
      if (!mounted) return;
      
      Logger.debug('Building waypoints...');
      final waypoints = await _buildWaypoints(); // ✅ CONECTARE: Folosește helper method
      Logger.debug('Built ${waypoints.length} waypoints');

      Logger.debug('Calculating route with ${waypoints.length} waypoints...');
      
      // ✅ PERFORMANCE: Execute in next frame to avoid blocking
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        
        try {
          // ✅ CONECTARE: Folosește _routingService helper method
          await _calculateRouteWithService(waypoints);
          // ✅ Ne-blocant: rute alternative pentru UI
          if (!AppDrawer.lowDataMode) {
            unawaited(_fetchAlternativeRoutes(waypoints));
          }
        } catch (e) {
          Logger.error('Route calculation failed: $e', error: e);
          if (mounted) {
            _showSafeSnackBar('Eroare la calcularea rutei: $e', Colors.red);
          }
        }
      });
      
    } catch (e) {
      Logger.error('Route setup failed: $e', error: e);
      Logger.error('Stack trace: ${StackTrace.current}');
      if (mounted) {
        _showSafeSnackBar('Eroare la configurarea rutei: $e', Colors.red);
      }
    }
  }

  /// ✅ PERFORMANCE: Helper method pentru building waypoints
  Future<List<Point>> _buildWaypoints() async {
    List<Point> waypoints = [];
    
    // Pickup
    if (_pickupLatitude != null && _pickupLongitude != null) {
      waypoints.add(Point(
        coordinates: Position(_pickupLongitude!, _pickupLatitude!)
      ));
      Logger.debug('Added pickup waypoint');
    }
    
    // Stops
    if (_intermediateStops.isNotEmpty) {
      for (var stop in _intermediateStops) {
        // Implementează geocoding pentru opririle intermediare
        final coordinates = await _getCoordinatesForDestination(stop);
        if (coordinates != null) {
          waypoints.add(coordinates);
          Logger.debug('Added intermediate stop: $stop');
        }
      }
      Logger.debug('Found ${_intermediateStops.length} intermediate stops');
    }
    
    // Destination
    if (_destinationLatitude != null && _destinationLongitude != null) {
      waypoints.add(Point(
        coordinates: Position(_destinationLongitude!, _destinationLatitude!)
      ));
      Logger.debug('Added destination waypoint');
    }
    
    return waypoints;
  }

  /// Start ride request complet
  void _startRideRequest() async {
    // Validare
    if (_pickupLatitude == null || _destinationLatitude == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selectează punctul de plecare și destinația'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      // Creează obiectul Ride
      final newRide = Ride(
        id: '',
        passengerId: FirebaseAuth.instance.currentUser?.uid ?? '',  // ✅ MODIFICAT: userId → passengerId
        startAddress: _pickupController.text,
        destinationAddress: _destinationController.text,
        distance: 0, // Va fi calculat de serviciu
        startLatitude: _pickupLatitude!,
        startLongitude: _pickupLongitude!,
        destinationLatitude: _destinationLatitude!,
        destinationLongitude: _destinationLongitude!,
        durationInMinutes: 0, // Va fi calculat de serviciu
        baseFare: 0, // Va fi calculat de serviciu
        perKmRate: 0, // Va fi calculat de serviciu
        perMinRate: 0, // Va fi calculat de serviciu
        totalCost: 0, // Va fi calculat de serviciu
        appCommission: 0, // Va fi calculat de serviciu
        driverEarnings: 0, // Va fi calculat de serviciu
        timestamp: DateTime.now(),
        status: 'pending',
        category: RideCategory.standard,
        stops: await Future.wait(_intermediateStops.map<Future<Map<String, dynamic>>>((stop) async {
          // ✅ FIX: Geocoding real pentru opriri (nu coordonate default)
          final coordinates = await _getCoordinatesForDestination(stop);
          return {
            'address': stop,
            'name': stop,
            'latitude': coordinates?.coordinates.lat ?? 44.4268, // Fallback doar dacă geocoding eșuează
            'longitude': coordinates?.coordinates.lng ?? 26.1025, // Fallback doar dacă geocoding eșuează
          };
        })),
      );
      
      final rideId = await _firestoreService.requestRide(newRide);
      if (!mounted) return;
      
      // Success feedback
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => SearchingForDriverScreen(rideId: rideId),
      ));
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare la crearea cursei: $e')),
      );
    }
  }

  /// Widget pentru butonul de start ride
  Widget _buildStartRideButton() {
    final canStartRide = _pickupLatitude != null && _destinationLatitude != null;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: canStartRide ? _startRideRequest : null, // ✅ AICI se folosește funcția!
        style: ElevatedButton.styleFrom(
          backgroundColor: canStartRide ? Colors.green : Colors.grey,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        child: Text(
          canStartRide ? '🚗 Începe călătoria' : 'Selectează pickup și destinația',
          style: const TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Închide card-ul POI
  void _closePoiCard() {
    Logger.debug('Closing POI card safely...');
    if (mounted) {
      try {
        setState(() {
          // Doar închide cardul; NU afecta adresele sau selecția din AddressInputView
          _showPoiCard = false;
        });
        // Curăță highlight la închiderea cardului
        unawaited(_clearSelectedPoiHighlight());
        Logger.debug('POI card closed successfully');
      } catch (e) {
        Logger.error('Error closing POI card: $e', error: e);
      }
    }
  }

  /// ✅ PERFORMANCE: Deferred RideRequestPanel update for pickup
  void _updateRideRequestPanelPickup(PointOfInterest poi) {
    Logger.info('Calling RideRequestPanel setPickup...');
          if (_rideRequestPanelKey.currentState != null) {
        Logger.info('RideRequestPanel state found, calling setPickup...');
        _rideRequestPanelKey.currentState!.setPickup(
          address: poi.name,
          latitude: poi.location.latitude,
          longitude: poi.location.longitude,
        );
        Logger.info('RideRequestPanel setPickup called successfully');
      } else {
        Logger.error('RideRequestPanel state is null! Cannot update panel');
      }
  }

  /// ✅ PERFORMANCE: Deferred RideRequestPanel update for destination
  void _updateRideRequestPanelDestination(PointOfInterest poi) {
    Logger.info('Calling RideRequestPanel setDestination...');
          if (_rideRequestPanelKey.currentState != null) {
        Logger.info('RideRequestPanel state found, calling setDestination...');
        _rideRequestPanelKey.currentState!.setDestination(
          address: poi.name,
          latitude: poi.location.latitude,
          longitude: poi.location.longitude,
        );
        Logger.info('RideRequestPanel setDestination called successfully');
      } else {
        Logger.error('RideRequestPanel state is null! Cannot update panel');
      }
  }

  /// ✅ PERFORMANCE: Batch map updates pentru a reduce overhead-ul
  void _batchMapUpdates() async {
    if (!mounted) return;
    
    Logger.debug('Starting batch map updates...');
    
    // ✅ PERFORMANCE: Collect all updates
    final List<Future<void> Function()> updates = [];
    
    if (_pickupLatitude != null && _pickupLongitude != null) {
      updates.add(() async {
        Logger.debug('Updating pickup marker...');
        await _addPickupMarker();
      });
    }
    
    if (_destinationLatitude != null && _destinationLongitude != null) {
      updates.add(() async {
        Logger.debug('Updating destination marker...');
        final coordinates = Point(coordinates: Position(_destinationLongitude!, _destinationLatitude!));
        await _addDestinationMarker(coordinates, 'Destinație');
      });
    }
    
    if (_intermediateStops.isNotEmpty) {
      updates.add(() async {
        Logger.debug('Updating stop markers...');
        await _addStopMarkers();
      });
    }
    
    // ✅ PERFORMANCE: Execute all updates with frame delays
    for (int i = 0; i < updates.length; i++) {
      if (!mounted) break;
      
      try {
        await updates[i]();
        // ✅ PERFORMANCE: One frame delay between operations
        if (i < updates.length - 1) {
          await Future.delayed(Duration(milliseconds: 16)); // 60fps = 16ms per frame
        }
      } catch (e) {
        Logger.error('Map update $i failed: $e', error: e);
      }
    }
    
    Logger.info('Batch map updates completed');
  }

  /// ✅ PERFORMANCE: Add pickup marker with performance optimization
  Future<void> _addPickupMarker() async {
    // Implementation for adding pickup marker
    // This would replace existing map marker logic
    Logger.info('Pickup marker added');
  }

  /// ✅ PERFORMANCE: Add destination marker with performance optimization


  /// ✅ PERFORMANCE: Add stop markers with performance optimization
  Future<void> _addStopMarkers() async {
    // Implementation for adding stop markers
    // This would replace existing map marker logic
    Logger.info('Stop markers added');
  }

  Future<void> _fetchAlternativeRoutes(List<Point> waypoints) async {
    if (!mounted) return;
    setState(() { _isFetchingAlternatives = true; _alternativeRoutes = []; _selectedAltRouteIndex = 0; });
    try {
      final data = await _routingService.getAlternativeRoutes(waypoints);
      if (!mounted) return;
      final routes = (data?['routes'] as List?) ?? const [];
      setState(() { _alternativeRoutes = routes.cast<Map<String, dynamic>>(); });
    } catch (e) {
      Logger.error('Alternative routes fetch failed: $e', error: e);
    } finally {
      if (mounted) setState(() { _isFetchingAlternatives = false; });
    }
  }

  // Heuristic entrance picker (client-only)
  void _maybeShowEntrancePicker(PointOfInterest poi) {
    final name = poi.name.toLowerCase();
    final largePoiKeywords = ['mall', 'spital', 'hospital', 'university', 'campus', 'aeroport'];
    final isLarge = largePoiKeywords.any((k) => name.contains(k));
    if (!isLarge) return;
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final entries = ['Nord', 'Est', 'Sud', 'Vest'];
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text('Alege intrarea', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: entries.map((e) {
                return ActionChip(
                  label: Text(e),
                  onPressed: () {
                    Navigator.pop(ctx);
                    // Heuristică: offset mic pe direcție
                    final delta = 0.0008; // ~80m
                    double lat = poi.location.latitude;
                    double lng = poi.location.longitude;
                    switch (e) {
                      case 'Nord': lat += delta; break;
                      case 'Sud': lat -= delta; break;
                      case 'Est': lng += delta; break;
                      case 'Vest': lng -= delta; break;
                    }
                    final adjustedPoi = PointOfInterest(
                      id: poi.id,
                      name: '${poi.name} - $e',
                      description: poi.description,
                      imageUrl: poi.imageUrl,
                      location: geolocator.Position(
                        latitude: lat,
                        longitude: lng,
                        timestamp: DateTime.now(),
                        accuracy: 0,
                        altitude: 0,
                        altitudeAccuracy: 0,
                        heading: 0,
                        headingAccuracy: 0,
                        speed: 0,
                        speedAccuracy: 0,
                      ),
                      category: poi.category,
                      isStatic: poi.isStatic,
                      additionalInfo: poi.additionalInfo,
                    );
                    _onPoiTapped(adjustedPoi);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  void _generatePickupSuggestionsAround(PointOfInterest poi) async {
    if (_pickupSuggestionsManager == null) return;
    try {
      await _pickupSuggestionsManager?.deleteAll();
      final baseLat = poi.location.latitude;
      final baseLng = poi.location.longitude;
      const deltas = [
        [0.0005, 0.0],
        [0.0, 0.0005],
        [-0.0005, 0.0],
        [0.0, -0.0005],
      ];
      final points = <Point>[];
      final options = <CircleAnnotationOptions>[];
      for (final d in deltas) {
        final lat = baseLat + d[0];
        final lng = baseLng + d[1];
        final p = MapboxUtils.createPoint(lat, lng);
        points.add(p);
        options.add(CircleAnnotationOptions(
          geometry: p,
          circleRadius: 8,
          circleColor: Colors.orange.toARGB32(),
          circleStrokeWidth: 2,
          circleStrokeColor: Colors.white.toARGB32(),
        ));
      }
      setState(() {
        _pickupSuggestionPoints = points;
        _showPickupSuggestions = true;
      });
      await _pickupSuggestionsManager?.createMulti(options);
    } catch (e) {
      Logger.error('Failed to generate pickup suggestions: $e', error: e);
    }
  }

  /// ✅ CONECTARE: Helper method pentru route calculation cu _routingService
  Future<void> _calculateRouteWithService(List<Point> waypoints) async {
    if (!mounted) return;
    
    try {
      Logger.debug('Calculating route with service for ${waypoints.length} waypoints...');
      
      // ✅ FOLOSEȘTE _routingService instance
      final routeData = await _routingService.getRoute(waypoints);
      
      if (!mounted) return;
      
      if (routeData != null) {
        Logger.debug('Route calculated successfully with service');
        await _onRouteCalculated(routeData);
        // AUTO-PROGRESSION: dacă voice este activ, încearcă auto-booking după calcul rută
        try {
          if (!mounted) return;
          try {
            final voice = Provider.of<FriendsRideVoiceIntegration>(context, listen: false);
            if (voice.isVoiceActive && routeData.isNotEmpty) {
              voice.updateBookingProgress('Ruta calculată cu succes! Estimez prețul și pornesc rezervarea...');
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted && voice.isVoiceActive) {
                  _autoProgressToBooking(voice);
                }
              });
            }
          } catch (_) {}
        } catch (_) {}
      } else {
        Logger.debug('Route calculation returned null');
        if (mounted) {
          _showSafeSnackBar('Nu s-a putut calcula ruta', Colors.orange);
        }
      }
    } catch (e) {
      Logger.error('Route calculation with service failed: $e', error: e);
      if (mounted) {
        _showSafeSnackBar('Eroare la calcularea rutei: $e', Colors.red);
      }
    }
  }

  Future<void> _autoProgressToBooking(FriendsRideVoiceIntegration voice) async {
    try {
      if (_pickupLatitude == null || _destinationLatitude == null) {
        voice.updateBookingProgress('Nu pot continua - informații de locație incomplete.');
        return;
      }
      final newRide = Ride(
        id: '',
        passengerId: FirebaseAuth.instance.currentUser?.uid ?? '',
        startAddress: _pickupController.text.isNotEmpty ? _pickupController.text : 'Locația curentă',
        destinationAddress: _destinationController.text,
        distance: (_currentRouteDistanceMeters ?? 0) / 1000,
        startLatitude: _pickupLatitude!,
        startLongitude: _pickupLongitude!,
        destinationLatitude: _destinationLatitude!,
        destinationLongitude: _destinationLongitude!,
        durationInMinutes: (_currentRouteDurationSeconds ?? 0) / 60,
        baseFare: 0,
        perKmRate: 0,
        perMinRate: 0,
        totalCost: 0,
        appCommission: 0,
        driverEarnings: 0,
        timestamp: DateTime.now(),
        status: 'pending',
        category: RideCategory.standard,
        stops: await Future.wait(_intermediateStops.map<Future<Map<String, dynamic>>>((stop) async {
          // ✅ FIX: Geocoding real pentru opriri (nu coordonate default)
          final coordinates = await _getCoordinatesForDestination(stop);
          return {
            'address': stop,
            'name': stop,
            'latitude': coordinates?.coordinates.lat ?? 44.4268, // Fallback doar dacă geocoding eșuează
            'longitude': coordinates?.coordinates.lng ?? 26.1025, // Fallback doar dacă geocoding eșuează
          };
        })),
      );
      voice.updateBookingProgress('Creez solicitarea de cursă...');
      final rideId = await _firestoreService.requestRide(newRide);
      voice.updateBookingProgress('✅ Solicitarea de cursă a fost trimisă! Caut șoferi disponibili...');
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => SearchingForDriverScreen(rideId: rideId),
        ));
        voice.stopVoiceInteraction();
      });
    } catch (e) {
      Logger.error('Auto-booking error: $e', tag: 'MAP_SCREEN', error: e);
      voice.updateBookingProgress('A apărut o eroare la crearea rezervării. Vă rog să încercați manual.');
    }
  }

  /// ✅ CONECTARE: Quick route update pentru POI changes
  Future<void> _updateRouteAfterPOI() async {
    if (_pickupLatitude != null && _destinationLatitude != null) {
      try {
        // Folosește helper method pentru waypoints
        final waypoints = await _buildWaypoints();
        
        // ✅ FOLOSEȘTE helper method cu _routingService
        await _calculateRouteWithService(waypoints);
        
      } catch (e) {
        Logger.error('Route update after POI error: $e', error: e);
      }
    }
  }

  /// Afișează SnackBar
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Widget pentru afișarea informațiilor despre ride
  Widget _buildRideInfoPanel() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informații călătorie',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12.0),
            
            // Pickup info
            if (_pickupLatitude != null) ...[
              Row(
                children: [
                  Icon(Icons.my_location, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Plecare: ${_pickupController.text}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.clear, color: Colors.red, size: 20),
                    onPressed: () {
                      _clearPickup();
                      _showSnackBar('Punctul de plecare a fost șters'); // ✅ AICI se folosește funcția!
                    },
                    tooltip: 'Șterge pickup',
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
            ],
            
            // Destination info
            if (_destinationLatitude != null) ...[
              Row(
                children: [
                  Icon(Icons.flag, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Destinație: ${_destinationController.text}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.clear, color: Colors.red, size: 20),
                    onPressed: () {
                      _clearDestination();
                      _showSnackBar('Destinația a fost ștearsă'); // ✅ AICI se folosește funcția!
                    },
                    tooltip: 'Șterge destinația',
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
            ],
            
            // Intermediate stops info
            if (_intermediateStops.isNotEmpty) ...[
              Text(
                'Opriri: ${_intermediateStops.length}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 8.0),
            ],
            
            // Start ride button
            _buildStartRideButton(),
          ],
        ),
      ),
    );
  }

  void _showSafeSnackBar(String message, Color backgroundColor, {SnackBarAction? action}) {
    if (!mounted) {
      Logger.error('Cannot show SnackBar - widget not mounted');
      return;
    }
    
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          action: action,
        ),
      );
      Logger.info('SnackBar shown: $message');
    } catch (e) {
      Logger.error('SnackBar error: $e', error: e);
    }
  }

  // ✅ NOU: Funcții pentru butonul de confirmare adrese
  // bool _canConfirmAddresses() {
  //   // Butonul e activ doar dacă ambele câmpuri sunt completate
  //       // ✅ NOU: Voice controllers eliminate - folosite din PassengerVoiceController
  //   return context.watch<PassengerVoiceController>().currentDestination.isNotEmpty;
  // }



  /// Afișează dialogul de ajutor pentru comenzi vocale
  // void _showVoiceHelpDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Row(
  //           children: [
  //             Icon(Icons.help_outline, color: Colors.blue),
  //             SizedBox(width: 8),
  //             Text('🎤 Comenzi Vocale Disponibile'),
  //           ],
  //         ),
  //         content: SingleChildScrollView(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Text('📍 DESTINAȚII:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
  //               Text('• "Vreau să merg la [destinație]"'),
  //               Text('• "Cursă la Piața Victoriei"'),
  //               Text('• "Du-mă la Mall Băneasa"'),
  //               SizedBox(height: 12),
  //               
  //               Text('🚗 CONTROL CURSĂ:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
  //               Text('• "Confirmă cursa"'),
  //               Text('• "Anulează cursa"'),
  //               Text('• "Modifică destinația"'),
  //               SizedBox(height: 12),
  //               
  //               Text('🛑 OPRIRI:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
  //               Text('• "Oprire la [locație]"'),
  //               Text('• "Oprire la [locație]"'),
  //               Text('• "Șterge ultima oprire"'),
  //               SizedBox(height: 12),
  //               
  //               Text('📱 APLICAȚIE:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
  //               Text('• "Deschide meniul"'),
  //               Text('• "Închide overlay"'),
  //               Text('• "Testează microfonul"'),
  //               SizedBox(height: 8),
  //               
  //               Container(
  //                 padding: EdgeInsets.all(8),
  //                 decoration: BoxDecoration(
  //                   color: Colors.blue.withValues(alpha: 0.1),
  //                   borderRadius: BorderRadius.circular(8),
  //               ),
  //                 child: Text(
  //                   '💡 Sfat: Vorbește clar și așteptă răspunsul AI înainte de următoarea comandă.',
  //                   style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.of(context).pop(),
  //             child: Text('Înțeles', style: TextStyle(fontSize: 16)),
  //           ),
  //           ElevatedButton.icon(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //               // Pornește voice interaction
  //               context.read<PassengerVoiceController>().startVoiceInteraction();
  //             },
  //             icon: Icon(Icons.mic),
  //             label: Text('Încearcă Acum'),
  //             style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  /// Rezervă cursă folosind voice controller
  // void _bookRideWithVoice() {
  //   final voiceController = context.read<PassengerVoiceController>();
  //   
  //   try {
  //     // Verifică dacă avem datele necesare
  //     if (voiceController.currentDestination.isEmpty) {
  //       _showSafeSnackBar(
  //         'Te rog să specifici destinația mai întâi', 
  //         Colors.orange
  //       );
  //       return;
  //     }
  //     
  //     // Creează ride request din voice data
  //     final pickup = voiceController.currentPickup.isNotEmpty 
  //         ? voiceController.currentPickup 
  //         : 'Locația curentă';
  //           
  //     final destination = voiceController.currentDestination;
  //     
  //     Logger.debug('Booking voice ride: $pickup → $destination');
  //     
  //     // Navighează la SearchingForDriverScreen
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) => SearchingForDriverScreen(
  //           rideId: DateTime.now().millisecondsSinceEpoch.toString(),
  //           ),
  //         ),
  //       );
  //     
  //     // Feedback vocal
  //     voiceController.updateAIResponseExternal(
  //       '✅ Perfect! Caut un șofer pentru cursa de la $pickup la $destination.'
  //     );
  //     
  //   } catch (e) {
  //     Logger.error('Voice booking error: $e', error: e);
  //     _showSafeSnackBar(
  //       'Eroare la rezervarea cursei: ${e.toString()}', 
  //         Colors.red
  //       );
  //     }
  //   }

  // void _confirmAddresses() {
  //   // Navighează la ecranul "Alege o cursă" cu tipurile de mașini
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => SearchingForDriverScreen(
  //         rideId: '', // Va fi generat automat
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildConfirmButton() {
  //   return Container(
  //     width: double.infinity,
  //     margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //     child: ElevatedButton(
  //       onPressed: _canConfirmAddresses() ? _confirmAddresses : null,
  //       style: ElevatedButton.styleFrom(
  //         backgroundColor: Colors.blue,
  //         padding: const EdgeInsets.symmetric(vertical: 16),
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(12),
  //         ),
  //       ),
  //       child: const Text(
  //         'Confirmă adresele selectate',
  //         style: TextStyle(
  //           fontSize: 16,
  //           fontWeight: FontWeight.bold,
  //           color: Colors.white,
  //         ),
  //       ),
  //     ),
  //   );
  // }
  
  // ✅ NOU: Metode helper pentru overlay-ul de voce
  // ignore: unused_element
  Widget _buildVoiceIcon(VoiceProcessingState state) {
    switch (state) {
      case VoiceProcessingState.listening:
        return Icon(Icons.mic, color: Colors.red, size: 64); // roșu când ascultă
      case VoiceProcessingState.thinking:
        return CircularProgressIndicator(color: Colors.white); // loading când procesează
      case VoiceProcessingState.speaking:
        return Icon(Icons.volume_up, color: Colors.green, size: 64); // verde când vorbește
      case VoiceProcessingState.waiting:
        return Icon(Icons.hourglass_empty, color: Colors.yellow, size: 64); // galben când așteaptă
      case VoiceProcessingState.waitingForConfirmation:
        return Icon(Icons.question_answer, color: Colors.purple, size: 64); // violet când așteaptă confirmarea
      case VoiceProcessingState.confirmationReceived:
        return Icon(Icons.check_circle, color: Colors.green, size: 64); // verde când confirmarea e primită
      case VoiceProcessingState.error:
        return Icon(Icons.error, color: Colors.red, size: 64); // roșu pentru eroare
      case VoiceProcessingState.idle:
        return Icon(Icons.mic_off, color: Colors.grey, size: 64);
    }
  }

  // ignore: unused_element
  String _getStatusText(VoiceProcessingState state) {
    switch (state) {
      case VoiceProcessingState.listening:
        return "Te ascult...";
      case VoiceProcessingState.thinking:
        return "Procesez...";
      case VoiceProcessingState.speaking:
        return "Îți răspund...";
      case VoiceProcessingState.waiting:
        return "Aștept...";
      case VoiceProcessingState.waitingForConfirmation:
        return "Aștept confirmarea...";
      case VoiceProcessingState.confirmationReceived:
        return "Confirmarea primită!";
      case VoiceProcessingState.error:
        return "Eroare - încearcă din nou";
      case VoiceProcessingState.idle:
        return "Apasă pentru a începe";
    }
  }

  /// 🎤 ÎMBUNĂTĂȚIT: Construiește overlay-ul vocal cu feedback vizual complet
  Widget _buildVoiceOverlay(FriendsRideVoiceIntegration voiceIntegration) {
    final l10n = AppLocalizations.of(context)!;
    final state = voiceIntegration.currentContext.processingState;
    final voiceContext = voiceIntegration.currentContext;
    
    // ✅ EXTRAGE INFORMAȚII DIN CONTEXT
    final lastAiMessage = _getLastAIResponse(voiceContext.conversationHistory);
    // Note: Destination and pickup will be extracted from voice controller when available
    // final destination = voiceIntegration.voiceDestination ?? '';
    // final pickup = voiceIntegration.voicePickup ?? '';
    // final estimatedPrice = 0.0;
    
    // Determină culoarea ecranului în funcție de stare
    Color backgroundColor;
    IconData icon;
    String statusText;
    String instructionText;
    
    switch (state) {
      case VoiceProcessingState.speaking:
        backgroundColor = Colors.green.shade600; // Fond verde mai clar, fără negru
        icon = Icons.volume_up;
        statusText = l10n.aiSpeaking;
        instructionText = lastAiMessage.isNotEmpty ? lastAiMessage : '🗣️ ${l10n.pleaseListenToResponse}';
        break;
        
      case VoiceProcessingState.listening:
        backgroundColor = Colors.red.shade600; // Fond roșu mai clar, fără negru
        icon = Icons.mic;
        statusText = l10n.aiListening;
        instructionText = '🎤 ${l10n.speakNow}';
        break;
        
      case VoiceProcessingState.thinking:
        backgroundColor = Colors.orange.shade600; // Fond portocaliu mai clar, fără negru
        icon = Icons.psychology;
        statusText = l10n.aiProcessing;
        instructionText = '🧠 ${l10n.processingInformation}';
        break;
        
      case VoiceProcessingState.waiting:
      case VoiceProcessingState.waitingForConfirmation:
        backgroundColor = Colors.blue.shade600; // Fond albastru mai clar, fără negru
        icon = Icons.hourglass_empty;
        statusText = l10n.waitingForResponse;
        instructionText = lastAiMessage.isNotEmpty ? lastAiMessage : '⏳ ${l10n.pleaseWait}';
        break;
        
      case VoiceProcessingState.idle:
      default:
        backgroundColor = Colors.blue.shade600; // Fond albastru mai clar, fără negru
        icon = Icons.mic_none;
        statusText = l10n.voiceAssistant;
        instructionText = l10n.pressButtonToStart;
        break;
    }
    
    final mediaQuery = MediaQuery.of(this.context);
    final bottomInset = mediaQuery.padding.bottom;

    return Positioned(
      left: 16,
      right: 16,
      bottom: bottomInset + 24,
      child: AnimatedScale(
        scale: 1,
        duration: const Duration(milliseconds: 200),
        child: Material(
          elevation: 12,
          borderRadius: BorderRadius.circular(24),
          color: backgroundColor, // Fond colorat solid, fără transparență care ar putea părea negru
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.95, end: 1.05),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeInOut,
                      builder: (context, scale, child) => Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(icon, size: 36, color: Colors.white),
                        ),
                      ),
                      onEnd: () {
                        if (mounted) setState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      statusText,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      instructionText,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.visible,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // ✅ AFIȘEAZĂ INFORMAȚII DESPRE CURSĂ (dacă sunt disponibile)
                    // Note: Will be enabled when voice context provides pickup/destination/price
                    // if (destination.isNotEmpty || pickup.isNotEmpty || estimatedPrice > 0)
                    //   Container(...)
                    if (voiceIntegration.currentContext.conversationHistory.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(maxHeight: 72),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25), // Mai vizibil, nu negru
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.2),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            _getLastAIResponse(voiceIntegration.currentContext.conversationHistory),
                            textAlign: TextAlign.center,
                            maxLines: 4,
                            overflow: TextOverflow.fade,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13, // Font puțin mai mare pentru lizibilitate
                              fontWeight: FontWeight.w500, // Puțin mai bold
                              height: 1.3,
                            ),
                          ),
                        ),
                      ),
                    if (voiceIntegration.currentContext.conversationHistory.isNotEmpty)
                      const SizedBox(height: 16),
                    if (state == VoiceProcessingState.listening || state == VoiceProcessingState.speaking)
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.3, end: 1.0),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeInOut,
                        builder: (context, value, child) => Container(
                          width: 48,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: value),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        onEnd: () {
                          if (mounted) setState(() {});
                        },
                      ),
                    const SizedBox(height: 18),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        _buildColorLegendItem(Colors.green, 'AI vorbește'),
                        _buildColorLegendItem(Colors.red, 'Dvs. vorbiți'),
                        _buildColorLegendItem(Colors.orange, 'Procesează'),
                      ],
                    ),
                  ],
                ),
                if (state != VoiceProcessingState.listening && state != VoiceProcessingState.speaking)
                  Positioned(
                    top: -8,
                    right: -8,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () async {
                        Logger.debug('DEBUG: Close button pressed');
                        try {
                          await voiceIntegration.stopVoiceInteraction();
                        } catch (e) {
                          Logger.error('DEBUG:  Eroare la oprirea voice interaction: $e', error: e);
                        }
                      },
                      tooltip: 'Închide asistent vocal',
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// 🎨 Element de legendă pentru culori - COMPACT
  Widget _buildColorLegendItem(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 0.5),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  // ignore: unused_element
  Widget _buildOldVoiceOverlay(FriendsRideVoiceIntegration voiceIntegration) {
    // 📝 DEPRECATED: Funcție veche păstrată pentru referință
    // Noua implementare folosește ecran complet cu culori: verde/roșu/orange
    return const SizedBox.shrink();
  }

  /// 🎯 Extrage ultimul răspuns AI din istoricul conversației
  String _getLastAIResponse(List<String> conversationHistory) {
    if (conversationHistory.isEmpty) {
      return 'Salutare! Unde doriți să mergeți?';
    }
    
    // Caută ultimul mesaj de la AI (începe cu "AI:")
    for (int i = conversationHistory.length - 1; i >= 0; i--) {
      final message = conversationHistory[i];
      if (message.startsWith('AI:')) {
        return message.substring(3).trim(); // Elimină "AI:" și spațiile
      }
    }
    
    return 'Salutare! Unde doriți să mergeți?';
  }

  /// 🎤 Construiește indicatorul pentru starea de procesare
  // ignore: unused_element
  Widget _buildProcessingStateIndicator(VoiceProcessingState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getStateColor(state).withAlpha(51),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getStateColor(state)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _getStateIcon(state),
          const SizedBox(width: 8),
          Text(
            _getStatusText(state),
            style: TextStyle(
              color: _getStateColor(state),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 🎨 Returnează culoarea pentru starea de procesare
  Color _getStateColor(VoiceProcessingState state) {
    switch (state) {
      case VoiceProcessingState.listening:
        return Colors.red;
      case VoiceProcessingState.thinking:
        return Colors.orange;
      case VoiceProcessingState.speaking:
        return Colors.green;
      case VoiceProcessingState.waiting:
        return Colors.yellow;
      case VoiceProcessingState.waitingForConfirmation:
        return Colors.purple;
      case VoiceProcessingState.confirmationReceived:
        return Colors.green;
      case VoiceProcessingState.error:
        return Colors.red;
      case VoiceProcessingState.idle:
        return Colors.grey;
    }
  }

  /// 🎨 Returnează iconița pentru starea de procesare
  Widget _getStateIcon(VoiceProcessingState state) {
    switch (state) {
      case VoiceProcessingState.listening:
        return const Icon(Icons.mic, color: Colors.red, size: 20);
      case VoiceProcessingState.thinking:
        return const Icon(Icons.psychology, color: Colors.orange, size: 20);
      case VoiceProcessingState.speaking:
        return const Icon(Icons.volume_up, color: Colors.green, size: 20);
      case VoiceProcessingState.waiting:
        return const Icon(Icons.hourglass_empty, color: Colors.yellow, size: 20);
      case VoiceProcessingState.waitingForConfirmation:
        return const Icon(Icons.question_answer, color: Colors.purple, size: 20);
      case VoiceProcessingState.confirmationReceived:
        return const Icon(Icons.check_circle, color: Colors.green, size: 20);
      case VoiceProcessingState.error:
        return const Icon(Icons.error, color: Colors.red, size: 20);
      case VoiceProcessingState.idle:
        return const Icon(Icons.mic_off, color: Colors.grey, size: 20);
    }
  }
}