import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Visibility;
import 'package:friendsride_app/models/ride_model.dart';
import 'package:friendsride_app/screens/ride_summary_screen.dart';
import 'package:friendsride_app/services/firestore_service.dart';
import 'package:friendsride_app/services/routing_service.dart';
import 'package:friendsride_app/services/navigation_service.dart';
import 'package:friendsride_app/services/tts_service.dart';
import 'package:friendsride_app/services/voip_service.dart';
import 'package:friendsride_app/services/audio_service.dart';
import 'package:friendsride_app/services/performance_monitor.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:friendsride_app/screens/driver_ride_details_screen.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:friendsride_app/theme/app_colors.dart';
import 'package:friendsride_app/widgets/theme_toggle_button.dart';
// import 'package:friendsride_app/widgets/draggable_ai_button.dart'; // AI button ascuns temporar
import 'package:friendsride_app/widgets/ride/ride_emergency_card.dart';
import 'package:friendsride_app/widgets/ride/ride_stuck_panel.dart';
import 'package:friendsride_app/widgets/ride/ride_driver_navigation_overlay.dart';
import 'package:friendsride_app/widgets/ride/draggable_chat_window.dart';
import 'package:friendsride_app/widgets/ride/ride_passenger_tracking.dart';
import 'package:friendsride_app/widgets/ride/ride_turn_by_turn_widget.dart';
import 'package:friendsride_app/widgets/ride/ride_destination_entrance_chips.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:friendsride_app/l10n/app_localizations.dart';

import '../utils/mapbox_utils.dart';
import '../utils/deprecated_apis_fix.dart';
import 'package:friendsride_app/helpers/formatters.dart';
import 'package:friendsride_app/helpers/safety_preferences.dart';
import 'package:friendsride_app/screens/safety_screen.dart';
import 'package:friendsride_app/screens/map_screen.dart';
import 'package:friendsride_app/models/stop_location.dart';
import 'package:friendsride_app/screens/search_location_screen.dart';

import 'package:intl/intl.dart';
import 'package:friendsride_app/widgets/chat/whatsapp_message_bubble.dart';
import 'package:friendsride_app/widgets/chat/voice_record_button.dart';
import 'package:friendsride_app/widgets/chat/quick_replies_widget.dart';
import 'package:friendsride_app/widgets/chat/typing_indicator_widget.dart';
import 'package:friendsride_app/widgets/chat/emoji_picker_widget.dart';
import 'package:friendsride_app/widgets/chat/gif_picker_widget.dart';
import 'package:friendsride_app/models/chat_message_model.dart';
import 'package:friendsride_app/services/email_receipt_service.dart';
import 'package:friendsride_app/services/driver_incentives_service.dart';
import 'package:friendsride_app/services/loyalty_program_service.dart';
import 'package:friendsride_app/widgets/cancellation_policy_widget.dart';
import 'package:friendsride_app/widgets/voice/active_ride_voice_panel.dart';
import 'package:friendsride_app/widgets/rate_passenger_widget.dart';
import 'package:friendsride_app/widgets/real_time_eta_widget.dart';
import 'package:friendsride_app/widgets/turn_by_turn_navigation_widget.dart';
import 'package:friendsride_app/utils/logger.dart';

class ActiveRideScreen extends StatefulWidget {
  final String rideId;
  // CORECTAT: Am adăugat routeGeoJSON în constructor
  final Map<String, dynamic>? routeGeoJSON;

  const ActiveRideScreen({super.key, required this.rideId, this.routeGeoJSON});

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  static const int _stuckRideThresholdMinutes = 10;
  
  final FirestoreService _firestoreService = FirestoreService();
  final RoutingService _routingService = RoutingService();
  final NavigationService _navigationService = NavigationService();
  final TtsService _ttsService = TtsService();
  final VoipService _voipService = VoipService();
  // final EtaService _etaService = EtaService(); // Eliminat
  final AudioService _audioService = AudioService();

  MapboxMap? _mapboxMap;
  PointAnnotationManager? _markersManager;
  bool _isNavigationActive = false;

  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  Point? _passengerLocation;
  Point? _destinationLocation;
  Point? _currentDriverLocation;
  double? _pickupDistanceKm;
  Duration? _pickupEta;
  DateTime? _pickupArrivalTime;
  double? _destinationDistanceKm;
  Duration? _destinationEta;
  DateTime? _destinationArrivalTime;
  String? _routeTrafficSummary;
  String? _activeEmergencyEventId;
  bool _isEmergencyPromptVisible = false;
  Point? _lastEtaRequestDriverPosition;
  DateTime? _lastEtaRequestTime;
  bool _isFetchingPreciseEta = false;
  static const Duration _etaRoutingThrottle = Duration(seconds: 10);
  static const double _etaRoutingDistanceThresholdMeters = 80.0;
  String _otherUserPhone = "";
  String _otherUserName = "";

  StreamSubscription<Ride>? _rideStatusSubscription;
  StreamSubscription<geo.Position>? _positionSubscription;
  StreamSubscription<DocumentSnapshot>? _driverLocationSubscription;
  StreamSubscription<QuerySnapshot>? _chatSubscription;

  Ride? _previousRide;

  List<Point> _originalRoutePoints = [];
  Point? _lastDriverPosition;
  // double? _lastDriverBearing; // reserved for future smoother bearing transitions



  final ScrollController _chatScrollController = ScrollController();
  final TextEditingController _chatController = TextEditingController();

  bool _isChatListenerActive = false;
  Timer? _typingTimer; // Timer pentru typing indicator
  bool _showEmojiPicker = false;
  bool _showGifPicker = false;
  
  AnimationController? _animationController;

  // ✅ BOLT/UBER-LIKE: Smooth camera system
  AnimationController? _cameraAnimationController;
  AnimationController? _carAnimationController;
  bool _shouldShowDriverMarker = false;
  bool _isDriverNavigationMode = false;
  bool _isPassengerTrackingMode = false;
  double _currentSpeed = 0.0;
  bool _isCameraTransitioning = false;
  DateTime? _lastGPSUpdate;
  bool _isGpsLost = false;
  Timer? _gpsWatchdogTimer;

  PointAnnotation? _driverAnnotation;
  final Map<String, PointAnnotation> _staticAnnotations = {};

  final Map<String, Map<String, String>> _driverInfoCache = <String, Map<String, String>>{};

  bool _isAddingStop = false;

  final bool _isDriverView = false;
  NavigationStep? _currentNavigationStep;
  bool _showTurnByTurnUI = false;
  Timer? _ttsTimer;
  final PerformanceMonitor _perf = PerformanceMonitor();
  
  // NOU: Debouncing pentru a evita frame skip-urile
  Timer? _cameraUpdateDebounceTimer;
  Timer? _routeUpdateDebounceTimer;
  // ✅ FIX: Reduce debouncing pentru updates mai rapide
  static const Duration _debounceDelay = Duration(milliseconds: 25);
  
  // CORECTAT: Am adăugat variabila pentru a stoca ruta
  // ignore: unused_field
  Map<String, dynamic>? _routeGeoJSON;
  
  // 🗺️ FIX: Variabilă pentru loading state routing
  bool _isLoadingRoute = false;
  bool _showRecenterButton = false;
  bool _voiceMuted = false;
  // DateTime? _lastHapticAt; // reserved for throttling haptics
  Timer? _recenterHideTimer;
  bool _showRecenterHint = false;

  final int _selectedTab = 0;
  int _unreadMessageCount = 0;
  // NEW: Speed limit state and throttling for haptics
  int _currentSpeedLimitKmh = 50;
  DateTime? _lastOverspeedHapticAt;
  DateTime? _lastA11yAnnounceAt;
  // NEW: Periodic traffic refresh
  Timer? _trafficRefreshTimer;
  static const Duration _trafficRefreshInterval = Duration(seconds: 60);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _routeGeoJSON = widget.routeGeoJSON;

    // ✅ EXISTING: Animation controller (modify duration)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // Reduced from 2 seconds
    );

    // ✅ NEW: Smooth camera animation controller
    _cameraAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // ✅ NEW: Car movement animation controller
    _carAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _initializeNavigationService();
    _initializeRideAndSubscribe();

    // Screen on for driver navigation
    WakelockPlus.enable();

    // Load saved prefs
    () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (!mounted) return;
        setState(() {
          _voiceMuted = prefs.getBool('nav_voice_muted') ?? false;
          _currentSpeedLimitKmh = prefs.getInt('nav_speed_limit_kmh') ?? 50;
        });
      } catch (_) {}
    }();
    // Start periodic traffic refresh
    _trafficRefreshTimer?.cancel();
    _trafficRefreshTimer = Timer.periodic(_trafficRefreshInterval, (_) async {
      try {
        if (!mounted) return;
        final ride = await _firestoreService.getRideStream(widget.rideId).first;
        if (!mounted) return;
        await _initializeRoutingAutomatic(ride); // redraw with traffic coloring
      } catch (e) {
        Logger.error('Traffic refresh failed: $e', error: e);
      }
    });
    // Keep screen on during active ride (especially for driver)
    WakelockPlus.enable();
    // Start GPS watchdog for tunnel/GPS-loss smoothing UI
    _startGpsWatchdog();
    
    // 🗺️ FIX: Adaugă inițializarea routing-ului
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeRouting();
        // Demo: Test the UI overlay functionality
        _buildRoleBasedUIOverlay();
        
        // Demo: Activate Waze-like experience for testing
        Future.delayed(const Duration(seconds: 2), () async {
          if (mounted) {
            try {
              final ride = await _firestoreService.getRideStream(widget.rideId).first;
              final demoPosition = Point(coordinates: Position(26.0997, 44.4267)); // Bucharest
              _activateWazeLikeExperience(demoPosition, 45.0, ride);
            } catch (e) {
              Logger.error('Demo activation failed: $e', error: e);
            }
          }
        });
      }
    });
  }

  void _startGpsWatchdog() {
    _gpsWatchdogTimer?.cancel();
    _gpsWatchdogTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      bool lost = false;
      if (_lastGPSUpdate != null) {
        final gap = DateTime.now().difference(_lastGPSUpdate!);
        // Consider GPS lost if no updates for > 6 seconds
        lost = gap.inSeconds >= 6;
      }
      if (_isGpsLost != lost) {
        setState(() {
          _isGpsLost = lost;
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onAppResumed();
    }
  }

  Future<void> _onAppResumed() async {
    try {
      Logger.debug('ActiveRideScreen resumed: restoring state');
      // Re-enable screen-on in case the OS disabled it
      WakelockPlus.enable();
      // Restart GPS watchdog
      _startGpsWatchdog();
      // Re-subscribe to driver location if needed
      final ride = await _firestoreService.getRideStream(widget.rideId).first;
      _previousRide = ride;
      if (_driverLocationSubscription == null && ride.driverId != null) {
        _startDriverLocationTracking(ride.driverId!);
      }
      // Redraw route overlay if we have it cached
      if (_routeGeoJSON != null) {
        await _drawRouteOnMapOptimized(_routeGeoJSON!);
      }
      // Ensure periodic traffic refresh is running
      _trafficRefreshTimer ??= Timer.periodic(_trafficRefreshInterval, (_) async {
        try {
          if (!mounted) return;
          final r = await _firestoreService.getRideStream(widget.rideId).first;
          if (!mounted) return;
          await _initializeRoutingAutomatic(r);
        } catch (e) {
          Logger.error('Traffic refresh (resume) failed: $e', error: e);
        }
      });
      setState(() {});
    } catch (e) {
      Logger.error('Failed to restore state on resume: $e', error: e);
    }
  }

  // ✅ FIX: Robust routing initialization
  Future<void> _initializeRoutingRobust() async {
    Logger.debug('Starting robust routing initialization...', tag: 'ROUTING');
    
    // Wait for widget to be fully built
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (!mounted) {
      Logger.debug('Widget unmounted during delay, aborting', tag: 'ROUTING');
      return;
    }
    
    // Try multiple times if needed
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        Logger.debug('Attempt $attempt to initialize routing...', tag: 'ROUTING');
        
        await _initializeRoutingSafe();
        Logger.info('Routing initialized successfully on attempt $attempt', tag: 'ROUTING');
        return; // Success, exit loop
        
      } catch (e) {
        Logger.error('Attempt $attempt failed: $e', tag: 'ROUTING', error: e);
        
        if (attempt < 3) {
          // Wait before retry
          await Future.delayed(Duration(milliseconds: 500 * attempt));
          if (!mounted) return;
        } else {
          Logger.error('All attempts failed, showing fallback', tag: 'ROUTING');
          _showRoutingError();
        }
      }
    }
  }

  // ✅ FIX: Safe routing initialization with error handling
  Future<void> _initializeRoutingSafe() async {
    if (!mounted) {
      throw Exception('Widget not mounted');
    }
    
    // Get current ride data
    final ride = await _firestoreService.getRideStream(widget.rideId).first;
    
    if (!mounted) {
      throw Exception('Widget unmounted after getting ride data');
    }
    
    // Validate required coordinates
    if (ride.startLatitude == null || ride.startLongitude == null ||
        ride.destinationLatitude == null || ride.destinationLongitude == null) {
      throw Exception('Missing pickup or destination coordinates');
    }
    
    Logger.debug('Building route with coordinates...', tag: 'ROUTING');
    Logger.debug('Pickup: ${ride.startLatitude}, ${ride.startLongitude}', tag: 'ROUTING');
    Logger.debug('Destination: ${ride.destinationLatitude}, ${ride.destinationLongitude}', tag: 'ROUTING');
    
    // Build waypoints
    final waypoints = <Point>[];
    
    // Add pickup
    waypoints.add(Point(
      coordinates: Position(ride.startLongitude!, ride.startLatitude!)
    ));
    
    // Add intermediate stops if any
    if (ride.stops.isNotEmpty) {
      for (final stopMap in ride.stops) {
        final stop = StopLocation.fromMap(stopMap);
        waypoints.add(Point(
          coordinates: Position(stop.longitude, stop.latitude)
        ));
      }
      Logger.debug('Added ${ride.stops.length} intermediate stops', tag: 'ROUTING');
    }
    
    // Add destination
    waypoints.add(Point(
      coordinates: Position(ride.destinationLongitude!, ride.destinationLatitude!)
    ));
    
    Logger.debug('Calculating route with ${waypoints.length} waypoints...', tag: 'ROUTING');
    
    // Calculate route
    final route = await _routingService.getRoute(waypoints);
    
    if (!mounted) {
      throw Exception('Widget unmounted after route calculation');
    }
    
    if (route != null) {
      Logger.debug('Route calculated successfully, drawing on map...', tag: 'ROUTING');
      
      // Store route for later use
      _routeGeoJSON = route;
      
      // Draw route on map (simplified version)
      await _drawRouteSimple(route);
      
      // Fit camera to route (simplified version)
      await _fitCameraSimple(route);
      
      if (mounted) {
        Logger.info('Route drawn and camera fitted successfully', tag: 'ROUTING');
      }
    } else {
      throw Exception('Route calculation returned null');
    }
  }

  // ✅ FIX: Show routing error with retry option
  void _showRoutingError() {
    if (!mounted) return;
    
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.routeNotLoadedAuto),
        backgroundColor: Colors.orange,
        action: SnackBarAction(
          label: 'RETRY',
          textColor: Colors.white,
          onPressed: () {
            Logger.warning('Manual retry requested', tag: 'ROUTING');
            _initializeRoutingRobust();
          },
        ),
        duration: const Duration(seconds: 8),
      ),
    );
  }

  // ✅ WAZE-LIKE: Smooth camera controller
  Future<void> _smoothCameraTransition(Point targetPosition, double targetBearing, {bool isDriver = false}) async {
    if (_mapboxMap == null || !mounted || _isCameraTransitioning) return;

    _isCameraTransitioning = true;
    
    try {
      // Calculate optimal zoom and pitch based on speed and role
      final optimalZoom = _calculateOptimalZoom(_currentSpeed, isDriver);
      final optimalPitch = _calculateOptimalPitch(_currentSpeed, isDriver);
      
      // Set up smooth animations
      final targetZoom = optimalZoom;
      final targetPitch = optimalPitch;
      
      // Create bearing animation
      final bearingAnimation = Tween<double>(
        begin: 0.0, // Default value
        end: _normalizeAngle(targetBearing),
      ).animate(CurvedAnimation(
        parent: _cameraAnimationController!,
        curve: Curves.easeOutCubic,
      ));
      
      // Animation listener for smooth updates
      void animationListener() {
        if (!mounted || _mapboxMap == null) return;
        
        final currentBearing = bearingAnimation.value;
        final currentPosition = targetPosition;
        final currentZoom = _lerp(16.0, targetZoom, _cameraAnimationController!.value);
        final currentPitch = _lerp(0.0, targetPitch, _cameraAnimationController!.value);
        
        _mapboxMap?.setCamera(CameraOptions(
          center: MapboxUtils.convertToPoint(currentPosition),
          zoom: currentZoom,
          bearing: currentBearing,
          pitch: currentPitch,
          padding: MbxEdgeInsets(
            top: 100,
            left: 50,
            bottom: MediaQuery.of(context).size.height * (isDriver ? 0.25 : 0.30),
            right: 50,
        ),
        ));
      }
      
      _cameraAnimationController!.addListener(animationListener);
      
      // Start animation
      await _cameraAnimationController!.forward(from: 0.0);
      
      // Cleanup
      _cameraAnimationController!.removeListener(animationListener);
      
    } catch (e) {
      Logger.error('Smooth camera transition error: $e', error: e);
    } finally {
      _isCameraTransitioning = false;
    }
  }

  // ✅ WAZE-LIKE: Calculate optimal zoom based on speed
  double _calculateOptimalZoom(double speed, bool isDriver) {
    if (!isDriver) return 15.0; // Passenger: stabil, wide view

    // Driver: adaptez zoomul mai gradual pe praguri de viteză (~m/s)
    // >27 m/s (~97 km/h): foarte wide pentru context
    if (speed > 27) return 16.2;
    // >22 m/s (~79 km/h)
    if (speed > 22) return 16.4;
    // >16 m/s (~58 km/h)
    if (speed > 16) return 16.8;
    // >10 m/s (~36 km/h)
    if (speed > 10) return 17.2;
    // >5 m/s (~18 km/h)
    if (speed > 5) return 17.6;
    // staționare / viteze mici
    return 18.2;
  }

  // ✅ WAZE-LIKE: Calculate optimal pitch based on speed and role
  double _calculateOptimalPitch(double speed, bool isDriver) {
    if (!isDriver) return 0.0; // Passenger: top-down

    // Driver: crește perspectiva odată cu viteza
    if (speed > 27) return 70.0;  // Autostradă
    if (speed > 22) return 65.0;  // Drum rapid
    if (speed > 16) return 58.0;  // Urban rapid
    if (speed > 10) return 52.0;  // Urban mediu
    if (speed > 5) return 48.0;   // Urban lent
    return 42.0;                  // Aproape staționare
  }

  // ✅ HELPER: Linear interpolation
  double _lerp(double start, double end, double t) {
    return start + (end - start) * t;
  }

  // ✅ HELPER: Normalize angle to prevent spinning
  double _normalizeAngle(double angle) {
    while (angle > 180) {
      angle -= 360;
    }
    while (angle < -180) {
      angle += 360;
    }
    return angle;
  }

  // ✅ FIX: Legacy routing method delegates to robust version
  Future<void> _initializeRouting() async {
    Logger.debug('Legacy _initializeRouting called, delegating to robust version', tag: 'ROUTING');
    await _initializeRoutingRobust();
  }

  // ✅ FIX: Simplified route drawing
  Future<void> _drawRouteSimple(Map<String, dynamic> route) async {
    if (!mounted || _mapboxMap == null) return;
    
    try {
      Logger.debug('Drawing route on map...', tag: 'ROUTING');
      
      // Remove existing route layer if it exists
      try {
        await _mapboxMap!.style.removeStyleLayer('route-layer');
        await _mapboxMap!.style.removeStyleSource('route-source');
      } catch (e) {
        // Layer doesn't exist, that's fine
        Logger.debug('No existing route layer to remove', tag: 'ROUTING');
      }
      
      // Add route source
      final routeSource = {
        'type': 'geojson',
        'data': route,
      };
      
      await _mapboxMap!.style.addStyleSource('route-source', json.encode(routeSource));
      
      // Add route layer
      final routeLayer = {
        'id': 'route-layer',
        'type': 'line',
        'source': 'route-source',
        'layout': {
          'line-join': 'round',
          'line-cap': 'round',
        },
        'paint': {
          'line-color': '#3B82F6', // Blue color
          'line-width': 6,
          'line-opacity': 0.8,
        },
      };
      
      await _mapboxMap!.style.addStyleLayer(json.encode(routeLayer), null);
      
      Logger.info('Route drawn successfully on map', tag: 'ROUTING');
      
    } catch (e) {
      Logger.error('Failed to draw route on map: $e', tag: 'ROUTING', error: e);
      throw Exception('Failed to draw route: $e');
    }
  }

  // ✅ FIX: Simplified camera fitting
  Future<void> _fitCameraSimple(Map<String, dynamic> route) async {
    if (!mounted || _mapboxMap == null) return;
    
    try {
      Logger.debug('Fitting camera to route...', tag: 'ROUTING');
      
      // Extract coordinates from route
      final coordinates = route['geometry']['coordinates'] as List;
      
      if (coordinates.isEmpty) {
        Logger.error('No coordinates found in route', tag: 'ROUTING');
        return;
      }
      
      // Calculate bounds
      double minLat = double.infinity;
      double maxLat = -double.infinity;
      double minLng = double.infinity;
      double maxLng = -double.infinity;
      
      for (final coord in coordinates) {
        final lng = coord[0] as double;
        final lat = coord[1] as double;
        
        minLat = math.min(minLat, lat);
        maxLat = math.max(maxLat, lat);
        minLng = math.min(minLng, lng);
        maxLng = math.max(maxLng, lng);
      }
      
      // Add padding
      const padding = 0.01; // Roughly 1km
      minLat -= padding;
      maxLat += padding;
      minLng -= padding;
      maxLng += padding;
      
      // Calculate center and zoom
      final centerLat = (minLat + maxLat) / 2;
      final centerLng = (minLng + maxLng) / 2;
      
      // Calculate appropriate zoom level
      final latDiff = maxLat - minLat;
      final lngDiff = maxLng - minLng;
      final maxDiff = math.max(latDiff, lngDiff);
      
      double zoom = 10.0;
      if (maxDiff > 0.1) {
        zoom = 8.0;
      } else if (maxDiff > 0.05) {
        zoom = 9.0;
      } else if (maxDiff > 0.02) {
        zoom = 11.0;
      } else if (maxDiff > 0.01) {
        zoom = 12.0;
      } else {
        zoom = 13.0;
      }
      
      // Animate camera to fit route
      final cameraOptions = CameraOptions(
        center: MapboxUtils.createPoint(centerLat, centerLng),
        zoom: zoom,
        bearing: 0,
        pitch: 0,
      );
      
      await _mapboxMap!.flyTo(cameraOptions, MapAnimationOptions(duration: 2000));
      
      Logger.info('Camera fitted to route successfully', tag: 'ROUTING');
      
    } catch (e) {
      Logger.error('Failed to fit camera to route: $e', tag: 'ROUTING', error: e);
      // Don't throw here, camera fitting is not critical
    }
  }

  // ✅ WAZE-LIKE: Predictive positioning for smooth movement
  Point _calculatePredictivePosition(Point currentPosition, double bearing, double speed) {
    if (speed < 1.0) return currentPosition; // Not moving
    
    // Predict position 2 seconds ahead based on current speed and bearing
    const double predictionSeconds = 2.0;
    const double earthRadius = 6371000; // Earth radius in meters
    
    final distanceAhead = speed * predictionSeconds; // meters
    final bearingRad = bearing * (math.pi / 180);
    
    final lat1 = currentPosition.coordinates.lat * (math.pi / 180);
    final lng1 = currentPosition.coordinates.lng * (math.pi / 180);
    
    final lat2 = math.asin(
      math.sin(lat1) * math.cos(distanceAhead / earthRadius) +
      math.cos(lat1) * math.sin(distanceAhead / earthRadius) * math.cos(bearingRad)
    );
    
    final lng2 = lng1 + math.atan2(
      math.sin(bearingRad) * math.sin(distanceAhead / earthRadius) * math.cos(lat1),
      math.cos(distanceAhead / earthRadius) - math.sin(lat1) * math.sin(lat2)
    );
    
    return Point(
      coordinates: Position(
        lng2 * (180 / math.pi),
        lat2 * (180 / math.pi),
      )
    );
  }

  // ✅ WAZE-LIKE: Speed calculation and history tracking
  void _updateSpeedTracking(Point newPosition, double bearing) {
    final now = DateTime.now();
    
    if (_lastGPSUpdate != null && _lastDriverPosition != null) {
      final timeDiff = now.difference(_lastGPSUpdate!).inMilliseconds / 1000.0; // seconds
      final distance = _calculateDirectDistance(
        _lastDriverPosition!.coordinates.lat,
        _lastDriverPosition!.coordinates.lng,
        newPosition.coordinates.lat,
        newPosition.coordinates.lng,
      ) * 1000; // convert to meters
      
      if (timeDiff > 0) {
        _currentSpeed = distance / timeDiff; // meters per second

        // Throttle overspeed haptics (once per 3 seconds)
        final speedKmh = _currentSpeed * 3.6;
        if (speedKmh > _currentSpeedLimitKmh + 3) {
          final now2 = DateTime.now();
          if (_lastOverspeedHapticAt == null || now2.difference(_lastOverspeedHapticAt!).inSeconds >= 3) {
            HapticFeedback.heavyImpact();
            _lastOverspeedHapticAt = now2;
          }
        }

        debugPrint('🚗 Speed: ${(_currentSpeed * 3.6).toStringAsFixed(1)} km/h');
        
        Logger.debug('Speed: ${(_currentSpeed * 3.6).toStringAsFixed(1)} km/h');
      }
    }
    
    _lastGPSUpdate = now;
  }

  // ✅ PHASE 2: Integration method to connect our systems
  void _activateWazeLikeExperience(Point position, double bearing, Ride ride) {
    // Determine user role and activate appropriate mode
    final isDriver = _currentUserId == ride.driverId;
    _isDriverNavigationMode = isDriver;
    _isPassengerTrackingMode = !isDriver;
    _shouldShowDriverMarker = !isDriver;
    
    // Update speed tracking
    _updateSpeedTracking(position, bearing);
    
    // Apply smooth camera based on role
    if (_isDriverNavigationMode) {
      final predictivePosition = _calculatePredictivePosition(position, bearing, _currentSpeed);
      _smoothCameraTransition(predictivePosition, bearing, isDriver: true);
    } else {
      _smoothCameraTransition(position, bearing, isDriver: false);
    }
    
    Logger.info('Waze-like experience activated for ${isDriver ? "driver" : "passenger"}');
    
    // Trigger UI rebuild to show the new overlays
    if (mounted) {
      setState(() {});
    }
  }

  // ✅ PHASE 3: Enhanced role-based UI helper
  Widget _buildRoleBasedUIOverlay() {
    if (_isDriverNavigationMode) {
      return RideDriverNavigationOverlay(
        currentSpeed: _currentSpeed,
        currentSpeedLimit: _currentSpeedLimitKmh,
        onSpeedLimitChanged: (newLimit) async {
          if (mounted) setState(() { _currentSpeedLimitKmh = newLimit; });
          try { final prefs = await SharedPreferences.getInstance(); await prefs.setInt('nav_speed_limit_kmh', newLimit); } catch (_) {}
        },
      );
    } else if (_isPassengerTrackingMode) {
      return RidePassengerTracking(
        isPassengerTrackingMode: _isPassengerTrackingMode,
        currentSpeed: _currentSpeed,
        shouldShowDriverMarker: _shouldShowDriverMarker,
        pickupEta: _pickupEta,
        destinationEta: _destinationEta,
        pickupArrivalTime: _pickupArrivalTime,
        destinationArrivalTime: _destinationArrivalTime,
        pickupDistanceKm: _pickupDistanceKm,
        destinationDistanceKm: _destinationDistanceKm,
        routeTrafficSummary: _routeTrafficSummary,
      );
    }
    return const SizedBox.shrink();
  }

  // ✅ Determină rolul și aplică camera corespunzătoare
  void _applyRoleBasedCameraView(Point driverPosition, Ride ride) {
    final isDriver = _currentUserId == ride.driverId;
    
    Logger.info('Applying camera for: ${isDriver ? "DRIVER" : "PASSENGER"}');
    
    if (isDriver) {
      // Șofer: perspectivă 3D pentru navigație
      _setDriverNavigationCamera(driverPosition);
    } else {
      // Pasager: vedere de sus pentru tracking
      _setPassengerTrackingCamera(driverPosition, ride);
    }
  }

  // ✅ Camera pentru șofer - perspectivă 3D ca Waze
  void _setDriverNavigationCamera(Point driverPosition) {
    if (_mapboxMap == null) return;
    
    Logger.debug('Setting DRIVER navigation camera');
    
    // ✅ FIX: Calculează bearing-ul dinamic sau folosește 0 ca default
    final bearing = _lastDriverPosition != null 
        ? _calculateBearing(_lastDriverPosition!, driverPosition)
        : 0.0;
    
    _mapboxMap?.flyTo(
      CameraOptions(
        center: MapboxUtils.convertToPoint(driverPosition),
        zoom: 17.5,          // Zoom apropiat pentru navigație
        bearing: bearing,     // Direcția de mers
        pitch: 60.0,         // Perspectivă 3D ca Waze
        padding: MbxEdgeInsets(
          top: 120,
          left: 50,
          bottom: MediaQuery.of(context).size.height * 0.25,
          right: 50,
        ),
      ),
      MapAnimationOptions(duration: 800)
    );
    
    Logger.info('Driver navigation camera applied: bearing=${bearing.toStringAsFixed(1)}°, pitch=60°');
  }

  // ✅ Camera pentru pasager - vedere de sus pentru tracking
  void _setPassengerTrackingCamera(Point driverPosition, Ride ride) {
    if (_mapboxMap == null) return;
    
    Logger.debug('Setting PASSENGER tracking camera');
    
    Point? destination;
    if (ride.status == 'accepted' || ride.status == 'arrived') {
      destination = _passengerLocation; // Spre pickup
    } else if (ride.status == 'in_progress') {
      destination = _destinationLocation; // Spre destinație
    }
    
    if (destination != null) {
      // Calculează bounds pentru a vedea ambele puncte
      final minLat = math.min(driverPosition.coordinates.lat, destination.coordinates.lat) - 0.005;
      final maxLat = math.max(driverPosition.coordinates.lat, destination.coordinates.lat) + 0.005;
      final minLng = math.min(driverPosition.coordinates.lng, destination.coordinates.lng) - 0.005;
      final maxLng = math.max(driverPosition.coordinates.lng, destination.coordinates.lng) + 0.005;
      
      final centerLat = (minLat + maxLat) / 2;
      final centerLng = (minLng + maxLng) / 2;
      
      // Calculează zoom pentru distanță
      final latDiff = maxLat - minLat;
      final lngDiff = maxLng - minLng;
      final maxDiff = math.max(latDiff, lngDiff);
      
      double zoom = 15.0;
      if (maxDiff < 0.01) zoom = 16.0;
      if (maxDiff < 0.005) zoom = 17.0;
      
      _mapboxMap?.flyTo(
        CameraOptions(
          center: MapboxUtils.createPoint(centerLat, centerLng),
          zoom: zoom,
          bearing: 0.0,    // Nord în sus pentru pasager
          pitch: 0.0,      // Vedere de sus pentru pasager
          padding: MbxEdgeInsets(top: 120, left: 50, bottom: 350, right: 50),
        ),
        MapAnimationOptions(duration: 1000)
      );
    } else {
      // Fallback: centrare pe șofer
      _mapboxMap?.flyTo(
        CameraOptions(
                  center: MapboxUtils.convertToPoint(driverPosition),
        zoom: 16.0,
        bearing: 0.0,
        pitch: 0.0,
        padding: MbxEdgeInsets(top: 120, left: 50, bottom: 350, right: 50),
        ),
        MapAnimationOptions(duration: 1000)
      );
    }
    
    Logger.info('Passenger tracking camera applied: pitch=0°, bearing=0°');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Dispose all controllers
    _animationController?.dispose();
    _cameraAnimationController?.dispose(); // ✅ NEW
    _carAnimationController?.dispose();     // ✅ NEW
    
    // Cancel all subscriptions
    _rideStatusSubscription?.cancel();
    _positionSubscription?.cancel();
    _driverLocationSubscription?.cancel();
    _chatSubscription?.cancel();
    
    // Oprește typing indicator
    _typingTimer?.cancel();
    _firestoreService.setTypingIndicator(widget.rideId, false);
    _chatController.removeListener(_onChatTextChanged);
    
    // Dispose all services
    _navigationService.dispose();
    _recenterHideTimer?.cancel();
    // Allow screen to sleep again
    WakelockPlus.disable();
    _chatScrollController.dispose();
    _chatController.dispose();
    _voipService.dispose();
    _audioService.dispose();
    
    // Clear cache
    _driverInfoCache.clear();
    
    // Cancel all timers
    _cameraUpdateDebounceTimer?.cancel();
    _routeUpdateDebounceTimer?.cancel();
    _ttsTimer?.cancel();
    _gpsWatchdogTimer?.cancel();
    
    Logger.debug('ActiveRideScreen disposed with cleanup');
    super.dispose();
  }

  bool _isRideStuck(Ride ride) {
    final stuckStates = ['accepted', 'driver_found'];
    if (stuckStates.contains(ride.status)) {
      final now = DateTime.now();
      final rideTimestamp = ride.timestamp; 
      final differenceInMinutes = now.difference(rideTimestamp).inMinutes;
      if (differenceInMinutes > _stuckRideThresholdMinutes) {
        return true;
      }
    }
    return false;
  }

  void _showStopAddedNotification() async {
    _audioService.playMessageReceivedSound(); 
    await _centerMapIfReady();
    
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.routeUpdated),
          content: Text(l10n.passengerAddedNewStop),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.ok),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _subscribeToRideStatusChanges() {
    _rideStatusSubscription = _firestoreService.getRideStream(widget.rideId).listen((ride) {
      if (!mounted) return;
      
      final isDriver = _currentUserId == ride.driverId;

      if (_previousRide != null) {
        if (isDriver && ride.stops.length > _previousRide!.stops.length) {
          _showStopAddedNotification();
        }
        if (!isDriver && ride.stops.length > _previousRide!.stops.length) {
          _centerMapIfReady(ride: ride);
        }
      }
      
      final hadPreviousRide = _previousRide != null;
      _previousRide = ride;
      
      if (hadPreviousRide && ride.status != _previousRide!.status) {
          _updateStaticMarkers(ride);
      }

      // ✅ FIX: Pornește chat-ul pentru șoferi și pasageri
      // ✅ FIX: Verifică driverId - passengerId este întotdeauna non-null
      if (!_isChatListenerActive && ride.driverId != null) {
        _isChatListenerActive = true;
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
             _startChatListening();
          }
        });
      }

      if (ride.driverId != null && 
          ['accepted', 'arrived', 'in_progress'].contains(ride.status) &&
          _driverLocationSubscription == null) {
        _cacheDriverInfo(ride.driverId!);
        _startDriverLocationTracking(ride.driverId!);
      }

      if (ride.status == 'completed') {
        _rideStatusSubscription?.cancel();
        _stopDriverLocationTracking();

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          if (isDriver) {
            // Show rate-passenger dialog before navigating away
            await RatePassengerWidget.show(
              context: context,
              rideId: widget.rideId,
            );
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (ctx) => DriverRideDetailsScreen(ride: ride)),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (ctx) => RideSummaryScreen(rideId: widget.rideId)),
            );
          }
        });
      } else if (ride.status == 'cancelled' || ride.status == 'expired' || ride.status == 'anulată_de_sistem') {
        _rideStatusSubscription?.cancel();
        _stopDriverLocationTracking();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final l10n = AppLocalizations.of(context);
            final message = ride.status == 'cancelled'
                ? (l10n?.rideCancelled ?? 'Cursă anulată')
                : (l10n?.rideExpired ?? 'Cursă expirată');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$message!')),
            );
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        });
      }
    }, onError: (error) {
      Logger.error('ActiveRideScreen Stream Error: $error', error: error);
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                '${l10n?.errorMonitoringRide ?? 'Eroare la monitorizarea cursei'}: ${error.toString()}')));
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  Future<void> _addStop() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const SearchLocationScreen(isDestination: false)),
    );

    if (result == null || !mounted) return;

    setState(() => _isAddingStop = true);

    try {
      final stopLocation = StopLocation(
        address: result['address'],
        latitude: result['latitude'],
        longitude: result['longitude'],
      );
      
      await _firestoreService.addStopToRide(widget.rideId, stopLocation);

      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.stopAddedRouteUpdated),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorAddingStop(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isAddingStop = false);
      }
    }
  }

  Future<void> _cacheDriverInfo(String driverId) async {
    if (_driverInfoCache.containsKey(driverId)) return;
    try {
      final driverDoc = await _firestoreService.getProfileByIdStream(driverId).first;
      if (driverDoc.exists) {
        final driverData = driverDoc.data()!;
        _driverInfoCache[driverId] = {
          'name': driverData['displayName'] ?? 'Șofer',
          'licensePlate': driverData['licensePlate'] ?? '',
        };
      }
    } catch (e) {
      _driverInfoCache[driverId] = {'name': 'Șofer', 'licensePlate': ''};
    }
  }

  void _startChatListening() {
    if (_isChatListenerActive) return;
    
    // Marchează toate mesajele ca citite când chat-ul este deschis
    _firestoreService.markAllMessagesAsRead(widget.rideId);
    
    // Adaugă listener pentru typing indicator
    _chatController.addListener(_onChatTextChanged);
    
    _chatSubscription = _firestoreService.getChatMessages(widget.rideId).listen((snapshot) {
      if (!mounted) return;
      
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;
      
      // ✅ FIX: Verifică toate mesajele NOI (nu doar ultimul) folosind docChanges
      for (var change in snapshot.docChanges) {
        // ✅ FIX: Procesează doar mesajele NOI adăugate (nu cele modificate sau șterse)
        if (change.type == DocumentChangeType.added) {
          final messageData = change.doc.data();
          final senderId = messageData?['senderId'] as String?;
          
          // ✅ FIX: Redă sunetul doar pentru mesajele de la alți utilizatori (șofer către pasager sau invers)
          if (senderId != null && senderId != currentUserId) {
            final messageText = messageData?['message'] as String? ?? messageData?['text'] as String?;
            
            // 🔊 Redă sunetul doar pentru mesajele de chat reale (nu pentru actualizări de locație sau mesaje de sistem)
            if (messageText != null && 
                messageText.isNotEmpty && 
                !messageText.contains('location_update') &&
                !messageText.startsWith('system:')) {
              
              Logger.debug('New message from $senderId to $currentUserId - playing sound notification', tag: 'CHAT');
              
              // ✅ FIX: Redă sunetul pentru pasager când primește mesaj de la șofer
              _audioService.playMessageReceivedSound().catchError((e) async {
                Logger.error('Error playing chat sound: $e', tag: 'CHAT', error: e);
                // ✅ FALLBACK: Încearcă sunetul de sistem dacă audio custom eșuează
                try {
                  await SystemSound.play(SystemSoundType.alert);
                } catch (e2) {
                  Logger.error('Even system sound failed: $e2', tag: 'CHAT');
                }
              });
              
              // ✅ FIX: Adaugă feedback haptic
              HapticFeedback.mediumImpact();
              
              // ✅ UPDATE: Incrementează numărul de mesaje necitite doar dacă nu sunt în tab-ul de chat
              if (_selectedTab != 1) { // Dacă nu sunt în tab-ul de chat
                if (mounted) {
                  setState(() {
                    _unreadMessageCount++;
                  });
                }
              }
            }
          }
        }
      }
      
      // ✅ FIX: Marchează mesajele noi ca citite
      for (final doc in snapshot.docs) {
        try {
          final msg = ChatMessage.fromMap(doc.data());
          if (msg.senderId != _currentUserId && msg.status != MessageStatus.read) {
            _firestoreService.markMessageAsRead(widget.rideId, doc.id);
          }
        } catch (e) {
          Logger.error('Error marking message as read: $e', error: e);
        }
      }
    });
    
    _isChatListenerActive = true;
    Logger.info('Chat listening started');
  }

  /// Handler pentru typing indicator
  void _onChatTextChanged() {
    if (!mounted) return;
    
    final text = _chatController.text;
    
    if (text.isNotEmpty) {
      // Setează typing indicator
      _firestoreService.setTypingIndicator(widget.rideId, true);
      
      // Anulează timer-ul anterior
      _typingTimer?.cancel();
      
      // Setează typing = false după 3 secunde de inactivitate
      _typingTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          _firestoreService.setTypingIndicator(widget.rideId, false);
        }
      });
    } else {
      // Dacă text-ul este gol, oprește typing imediat
      _typingTimer?.cancel();
      _firestoreService.setTypingIndicator(widget.rideId, false);
    }
  }

  void _sendMessage() {
    final messageText = _chatController.text.trim();
    if (messageText.isEmpty) return;

    try {
      // Setează typing = false
      _firestoreService.setTypingIndicator(widget.rideId, false);
      _typingTimer?.cancel();
      
      // Trimite mesajul
      unawaited(_firestoreService.sendChatMessage(
        widget.rideId,
        messageText,
        // quickReplyId: null, // Sau ID-ul dacă este mesaj rapid
        // locationData: null, // Sau datele dacă este mesaj cu locație
      ));
      
      _chatController.clear();
      HapticFeedback.lightImpact();
      FocusScope.of(context).unfocus();
      
      // ✅ Resetează badge-ul mesajelor necitite când utilizatorul trimite mesaj
      if (mounted) {
        setState(() {
          _unreadMessageCount = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la trimiterea mesajului: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



  Future<void> _launchGoogleMapsNavigation(double lat, double lng) async {
    try {
      final uri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw Exception('Could not launch Google Maps');
      }
    } catch (e) {
      _showNavigationError('Nu s-a putut deschide Google Maps.');
    }
  }

  Future<void> _launchWazeNavigation(double lat, double lng) async {
    try {
      final uri = Uri.parse('waze://?ll=$lat,$lng&navigate=yes');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw Exception('Could not launch Waze');
      }
    } catch (e) {
      _showNavigationError('Nu s-a putut deschide Waze.');
    }
  }

  void _showNavigationOptions(double lat, double lng) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text(l10n?.chooseNavigationApp ?? 'Alege aplicația de navigație', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.map, color: Colors.blue.shade700)),
                title: Text(l10n?.googleMaps ?? 'Google Maps'),
                subtitle: Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context)!;
                    return Text(l10n.navigationWithGoogleMaps);
                  },
                ),
                onTap: () {
                  Navigator.pop(context);
                  _launchGoogleMapsNavigation(lat, lng);
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.purple.shade100, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.navigation, color: Colors.purple.shade700)),
                title: Text(l10n?.waze ?? 'Waze'),
                subtitle: Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context)!;
                    return Text(l10n.navigationWithWaze);
                  },
                ),
                onTap: () {
                  Navigator.pop(context);
                  _launchWazeNavigation(lat, lng);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showNavigationError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _initializeNavigationService() {
    _navigationService.onNavigationUpdate = (update) {
      if (!mounted) return;
      setState(() {
        // Trigger UI rebuild for banner and camera adjustments
      });
      // Maneuver-aware camera: mild zoom-in/pitch-up close to turn for driver
      try {
        if (_isDriverView) {
          final distanceRemaining = (update['distanceRemaining'] as num?)?.toDouble();
          if (distanceRemaining != null && distanceRemaining > 0) {
            // Telemetry: navigation step update
            _perf.recordNavTelemetry('step_update', {
              'distance_remaining_m': distanceRemaining,
              'timestamp': DateTime.now().toIso8601String(),
            });
            // At ~100m to next turn: haptics and slight camera focus
            if (distanceRemaining <= 100) {
              HapticFeedback.selectionClick();
            }
            // Accessibility: brief announcement approaching maneuver (throttled)
            final now = DateTime.now();
            if (distanceRemaining <= 120 && (_lastA11yAnnounceAt == null || now.difference(_lastA11yAnnounceAt!).inSeconds >= 4)) {
              _lastA11yAnnounceAt = now;
              try { SemanticsService.announce('Aproape de următoarea manevră', ui.TextDirection.ltr); } catch (_) {}
            }
            // Smooth camera adjustment based on proximity
            final clamp = distanceRemaining.clamp(50.0, 200.0);
            final t = 1.0 - ((clamp - 50.0) / 150.0); // 0..1
            final targetZoom = _calculateOptimalZoom(_currentSpeed, true) + (t * 0.3);
            final targetPitch = _calculateOptimalPitch(_currentSpeed, true) + (t * 5.0);
            if (_lastDriverPosition != null) {
              _smoothCameraTransition(_lastDriverPosition!, 0.0, isDriver: true);
              _mapboxMap?.flyTo(
                CameraOptions(
                  center: MapboxUtils.convertToPoint(_lastDriverPosition!),
                  zoom: targetZoom,
                  pitch: targetPitch,
                ),
                MapAnimationOptions(duration: 400),
              );
            }
          }
        }
      } catch (_) {}
    };
    _navigationService.onArrival = (message) {
      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
        // Arrival mode: shift to top-down and highlight destination
        try {
          if (_destinationLocation != null) {
            _mapboxMap?.flyTo(
              CameraOptions(center: _destinationLocation, zoom: 18.0, bearing: 0.0, pitch: 0.0),
              MapAnimationOptions(duration: 800),
            );
          }
        } catch (_) {}
      }
    };
    _navigationService.onRouteDeviation = (message) {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      _perf.startTimer('reroute');
      // Debounced/hysteresis re-route: avoid rapid recalculations and keep camera state
      _scheduleRerouteDebounced();
    };
  }

  // Debounce/hysteresis for rerouting
  Timer? _rerouteDebounceTimer;
  DateTime? _lastRerouteAt;
  static const Duration _rerouteDebounce = Duration(seconds: 2);
  static const Duration _rerouteMinGap = Duration(seconds: 6);

  void _scheduleRerouteDebounced() {
    final now = DateTime.now();
    if (_lastRerouteAt != null && now.difference(_lastRerouteAt!) < _rerouteMinGap) {
      return; // hysteresis window
    }
    _rerouteDebounceTimer?.cancel();
    _rerouteDebounceTimer = Timer(_rerouteDebounce, () async {
      if (!mounted) return;
      _lastRerouteAt = DateTime.now();
      // Preserve camera
      final currentCamera = await _mapboxMap?.getCameraState();
      await _recalculateRouteDebouncedImpl(keepCamera: true, cameraState: currentCamera);
    });
  }

  Future<void> _recalculateRouteDebouncedImpl({bool keepCamera = false, CameraState? cameraState}) async {
    try {
      final ride = await _firestoreService.getRideStream(widget.rideId).first;
      if (!mounted) return;
      await _initializeRoutingAutomatic(ride);
      _perf.endTimer('reroute');
      _perf.recordNavTelemetry('reroute_completed', {
        'keep_camera': keepCamera,
        'timestamp': DateTime.now().toIso8601String(),
      });
      if (keepCamera && cameraState != null) {
        try {
          _mapboxMap?.flyTo(
            CameraOptions(
              center: cameraState.center,
              zoom: cameraState.zoom,
              bearing: cameraState.bearing,
              pitch: cameraState.pitch,
            ),
            MapAnimationOptions(duration: 300),
          );
        } catch (_) {}
      }
    } catch (e) {
      Logger.error('Reroute failed: $e', error: e);
    }
  }

  Future<void> _handleEmergencyTriggered() async {
    final ride = _previousRide;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (ride == null || currentUserId == null) {
      return;
    }

    GeoPoint? location;
    if (_currentDriverLocation != null) {
      final lat = _currentDriverLocation!.coordinates.lat.toDouble();
      final lng = _currentDriverLocation!.coordinates.lng.toDouble();
      location = GeoPoint(lat, lng);
    } else if (_passengerLocation != null) {
      final lat = _passengerLocation!.coordinates.lat.toDouble();
      final lng = _passengerLocation!.coordinates.lng.toDouble();
      location = GeoPoint(lat, lng);
    }

    final role =
        currentUserId == ride.driverId ? 'driver' : 'passenger';

    final metadata = <String, dynamic>{
      'devicePlatform': Theme.of(context).platform.name,
    };

    final eventId = await _firestoreService.logEmergencyEvent(
      rideId: ride.id,
      triggeredByUserId: currentUserId,
      userRole: role,
      eventType: 'sos_call',
      location: location,
      rideStatus: ride.status,
      metadata: metadata,
    );

    if (!mounted) return;

    if (eventId != null) {
      setState(() {
        _activeEmergencyEventId = eventId;
        _isEmergencyPromptVisible = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Text(l10n.safetyTeamNotified);
            },
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _resolveEmergencyAlert({bool falseAlarm = false}) async {
    final eventId = _activeEmergencyEventId;
    if (eventId == null) return;

    await _firestoreService.updateEmergencyEventStatus(
      eventId,
      status: falseAlarm ? 'cancelled' : 'resolved',
      note: falseAlarm ? 'Utilizatorul a confirmat că a fost o alarmă falsă.' : 'Utilizatorul a confirmat că este în siguranță.',
      metadata: {
        'resolvedAt': DateTime.now().toIso8601String(),
        'resolutionType': falseAlarm ? 'false_alarm' : 'user_confirmed_safe',
      },
    );

    if (!mounted) return;

    setState(() {
      _activeEmergencyEventId = null;
      _isEmergencyPromptVisible = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          falseAlarm
              ? 'Am notat că a fost o alarmă falsă.'
              : 'Ne bucurăm că ești în siguranță.',
        ),
      ),
    );
  }

  Future<void> _openSafetyShareSheet() async {
    final ride = _previousRide;
    final contacts = await SafetyPreferences.loadTrustedContacts();
    if (!mounted) return;

    final liveUrl = _buildLiveLocationUrl();
    final shareMessage = _buildShareMessage(ride, liveUrl);

    if (liveUrl == null) {
      final l10n = AppLocalizations.of(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.locationNotAvailable ??
                  'Locația nu este încă disponibilă pentru partajare.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Partajează cursa',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.share),
                  title: Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context)!;
                      return Text(l10n.sendViaApps);
                    },
                  ),
                  subtitle: const Text('WhatsApp, Messenger, Mail etc.'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    DeprecatedAPIsFix.shareText(shareMessage);
                  },
                ),
                if (contacts.isNotEmpty)
                  ...contacts.map((contact) {
                    return ListTile(
                      leading: const Icon(Icons.sms_outlined),
                      title: Text(contact.name),
                      subtitle: Text(contact.phoneNumber),
                      onTap: () async {
                        Navigator.of(sheetContext).pop();
                        await _shareWithTrustedContact(contact, shareMessage);
                      },
                    );
                  }),
                if (contacts.isEmpty)
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context)!;
                        return Text(l10n.noTrustedContacts);
                      },
                    ),
                    subtitle: const Text(
                      'Adăugați persoane din Centru de Siguranță pentru a partaja rapid cursele.',
                    ),
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      Navigator.of(sheetContext).pop();
                      if (!mounted) return;
                      await navigator.push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SafetyScreen(),
                        ),
                      );
                    },
                  )
                else
                  TextButton.icon(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      Navigator.of(sheetContext).pop();
                      if (!mounted) return;
                      await navigator.push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SafetyScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.manage_accounts_outlined),
                    label: Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context)!;
                        return Text(l10n.manageContacts);
                      },
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  String? _buildLiveLocationUrl() {
    // Feature: Share trip (live link) — use FriendsRide tracking URL with ride ID
    // This link allows recipients to follow the real-time progress of the ride
    return 'https://friendsride.app/track/${widget.rideId}';
  }

  String _buildShareMessage(Ride? ride, String? liveUrl) {
    final buffer = StringBuffer('Sunt într-o cursă FriendsRide.');

    if (ride != null) {
      buffer.write(
          '\n• Plecare: ${ride.startAddress}\n• Destinație: ${ride.destinationAddress}');
      buffer.write('\n• Cod cursă: ${ride.id}');
    }

    if (liveUrl != null) {
      buffer.write('\n🛰️ Urmărește cursa live: $liveUrl');
    }

    buffer.write(
        '\nDacă observi ceva nelalocul lui, contactează-mă sau alertează autoritățile.');
    return buffer.toString();
  }

  Future<void> _shareWithTrustedContact(
    TrustedContact contact,
    String message,
  ) async {
    final uri = Uri(
      scheme: 'sms',
      path: contact.phoneNumber,
      queryParameters: <String, String>{'body': message},
    );
    final success =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nu am putut trimite mesajul către ${contact.name}.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    _markersManager = await _mapboxMap?.annotations.createPointAnnotationManager(id: "markers-manager");
    _centerMapIfReady();
  }

  void _followDriverWithCamera(Point driverPosition) {
    if (_mapboxMap == null) return;
    if (_lastDriverPosition != null) {
      final distance = _calculateDirectDistance(_lastDriverPosition!.coordinates.lat, _lastDriverPosition!.coordinates.lng, driverPosition.coordinates.lat, driverPosition.coordinates.lng);
      if (distance * 1000 < 10) return;
    }
    _lastDriverPosition = driverPosition;
    _mapboxMap?.flyTo(
        CameraOptions(
          center: MapboxUtils.convertToPoint(driverPosition),
          zoom: 16.0,
          padding: MbxEdgeInsets(top: 50, left: 50, bottom: MediaQuery.of(context).size.height * 0.30, right: 50),
        ),
        MapAnimationOptions(duration: 1200));
  }


  double _calculateBearing(Point from, Point to) {
    final lat1 = from.coordinates.lat * math.pi / 180;
    final lat2 = to.coordinates.lat * math.pi / 180;
    final dLng = (to.coordinates.lng - from.coordinates.lng) * math.pi / 180;
    
    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    
    final bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360;
  }




  Future<void> _drawRouteOnMap(List<Point> routePoints, {bool isDriverView = false}) async {
    if (_mapboxMap == null || !mounted) return;
    
    _originalRoutePoints = List.from(routePoints);
    
    const sourceId = 'route-source';
    const layerId = 'route-layer';

    final geoJson = {
      'type': 'Feature',
      'properties': {},
      'geometry': {'type': 'LineString', 'coordinates': routePoints.map((point) => [point.coordinates.lng, point.coordinates.lat]).toList()}
    };
    
    try {
      if (await _mapboxMap!.style.styleLayerExists(layerId)) {
        await _mapboxMap!.style.removeStyleLayer(layerId);
      }
      if (await _mapboxMap!.style.styleSourceExists(sourceId)) {
        await _mapboxMap!.style.removeStyleSource(sourceId);
      }
      
      await _mapboxMap!.style.addSource(GeoJsonSource(id: sourceId, data: json.encode(geoJson)));
      
      final routeColor = isDriverView 
          ? AppColors.primaryLight.toARGB32()
          : Colors.green.toARGB32();
      
      await _mapboxMap!.style.addLayer(LineLayer(
        id: layerId,
        sourceId: sourceId,
        lineColor: routeColor,
        lineWidth: isDriverView ? 10.0 : 8.0,
        lineOpacity: 1.0,
      ));

    } catch (e) {
      Logger.error("Error drawing route: $e", error: e);
    }
  }

  // 🗺️ FIX: Metoda pentru desenarea traseului optimizată
  Future<void> _drawRouteOnMapOptimized(Map<String, dynamic> route) async {
    if (!mounted || _mapboxMap == null) return;
    
    try {
      // Capture theme color before any async awaits (lint: use_build_context_synchronously)
      final themePrimaryColor = Theme.of(context).primaryColor;
      final int themePrimaryArgb = themePrimaryColor.toARGB32();
      final String themePrimaryHex = '#'
          '${(themePrimaryArgb & 0x00FFFFFF).toRadixString(16).padLeft(6, '0')}';
      // Extrage coordonatele și, dacă există, congestion annotations
      final coordinates = _routingService.extractRouteCoordinates(route);
      final routesList = (route['routes'] as List?) ?? const [];
      final leg = routesList.isNotEmpty ? ((routesList.first as Map<String, dynamic>)['legs'] as List?)?.first as Map<String, dynamic>? : null;
      final annotation = leg != null ? leg['annotation'] as Map<String, dynamic>? : null;
      final congestion = (annotation?['congestion'] as List?)?.map((e) => (e ?? '').toString()).toList();
      
      if (coordinates.isEmpty) {
        Logger.debug('Nu s-au găsit coordonate pentru traseu');
        return;
      }
      
      // 🗺️ FIX: Creează polyline pentru traseu
      const sourceId = 'active-route-source';
      const layerId = 'active-route-layer';
      
      // Șterge layerul existent dacă există
      try {
        if (await _mapboxMap!.style.styleLayerExists(layerId)) {
          await _mapboxMap!.style.removeStyleLayer(layerId);
        }
        if (await _mapboxMap!.style.styleSourceExists(sourceId)) {
          await _mapboxMap!.style.removeStyleSource(sourceId);
        }
      } catch (e) {
        Logger.error('Cleanup error: $e', error: e);
      }
      
      // Creează GeoJSON pentru traseu segmentat pe culori (dacă avem congestion)
      List<List<double>> coords = coordinates.map((p) => [p.coordinates.lng.toDouble(), p.coordinates.lat.toDouble()]).toList();
      List<Map<String, dynamic>> features = [];
      if (congestion != null && congestion.length == coords.length) {
        // Creează segmente consecutive coord[i] -> coord[i+1] cu proprietate color
        Color colorFor(String level) {
          switch (level.toLowerCase()) {
            case 'low':
            case 'free':
              return Colors.green;
            case 'moderate':
              return Colors.orange;
            case 'heavy':
            case 'severe':
              return Colors.red;
            default:
              return themePrimaryColor;
          }
        }
        for (int i = 0; i < coords.length - 1; i++) {
          final c1 = coords[i];
          final c2 = coords[i + 1];
          final col = colorFor(congestion[i]);
          final int argb = col.toARGB32();
          final String hex = '#${(argb & 0x00FFFFFF).toRadixString(16).padLeft(6, '0')}';
          features.add({
            'type': 'Feature',
            'properties': {
              'color': hex
            },
            'geometry': {
              'type': 'LineString',
              'coordinates': [c1, c2]
            }
          });
        }
      } else {
        // fallback: un singur feature, culoare implicită
        final fallbackColor = themePrimaryHex;
        features.add({
          'type': 'Feature',
          'properties': {
            'color': fallbackColor
          },
          'geometry': {
            'type': 'LineString',
            'coordinates': coords
          }
        });
      }
      final geoJson = {
        'type': 'FeatureCollection',
        'features': features
      };
      
      // Adaugă source și layer
      await _mapboxMap!.style.addSource(GeoJsonSource(
        id: sourceId,
        data: json.encode(geoJson)
      ));
      
      // ✅ FIX: Verifică mounted înainte de a folosi context
      if (mounted) {
        await _mapboxMap!.style.addLayer(LineLayer(
          id: layerId,
          sourceId: sourceId,
          lineColorExpression: ['get', 'color'],
          lineWidth: 6.0,
          lineOpacity: 1.0,
        ));
      }
      
      Logger.info('Traseu desenat cu ${coordinates.length} puncte');
      // Prefetch disabled in emergency mode
    } catch (e) {
      Logger.error('Eroare la desenarea traseului: $e', error: e);
    }
  }

  // 🗺️ FIX: Metoda pentru fitting camera
  Future<void> _fitCameraToRoute(Map<String, dynamic> route) async {
    if (!mounted || _mapboxMap == null) return;
    
    try {
      final coordinates = _routingService.extractRouteCoordinates(route);
      if (coordinates.isEmpty) return;
      
      // 🗺️ FIX: Calculează bounds pentru toate punctele
      double minLat = coordinates.first.coordinates.lat.toDouble();
      double maxLat = coordinates.first.coordinates.lat.toDouble();
      double minLng = coordinates.first.coordinates.lng.toDouble();
      double maxLng = coordinates.first.coordinates.lng.toDouble();
      
      for (final coord in coordinates) {
        minLat = math.min(minLat, coord.coordinates.lat.toDouble());
        maxLat = math.max(maxLat, coord.coordinates.lat.toDouble());
        minLng = math.min(minLng, coord.coordinates.lng.toDouble());
        maxLng = math.max(maxLng, coord.coordinates.lng.toDouble());
      }
      
      // 🗺️ FIX: Adaugă padding pentru vizibilitate
      const double padding = 0.01;
      final bounds = CoordinateBounds(
        southwest: MapboxUtils.createPoint(minLat - padding, minLng - padding),
        northeast: MapboxUtils.createPoint(maxLat + padding, maxLng + padding),
        infiniteBounds: false,
      );
      
      final cameraOptions = await _mapboxMap!.cameraForCoordinateBounds(
        bounds,
        MbxEdgeInsets(top: 100.0, left: 50.0, bottom: 250.0, right: 50.0),
        0.0, 0.0, null, null
      );
      
      await _mapboxMap!.flyTo(
        cameraOptions,
        MapAnimationOptions(duration: 1000)
      );
    } catch (e) {
      Logger.error('Eroare la fitting camera: $e', error: e);
    }
  }

  Future<void> _drawPassengerRouteWithProgress(List<Point> fullRoute, Point driverPosition) async {
    if (_mapboxMap == null || !mounted) return;
    
    double minDistance = double.infinity;
    int closestPointIndex = 0;
    for (int i = 0; i < fullRoute.length; i++) {
      final routePoint = fullRoute[i];
      final distance = _calculateDirectDistance(
        driverPosition.coordinates.lat, 
        driverPosition.coordinates.lng, 
        routePoint.coordinates.lat, 
        routePoint.coordinates.lng
      );
      if (distance < minDistance) {
        minDistance = distance;
        closestPointIndex = i;
      }
    }
    
    final completedRoute = fullRoute.sublist(0, closestPointIndex + 1);
    final remainingRoute = fullRoute.sublist(closestPointIndex);
    
    const completedSourceId = 'completed-route-source';
    const completedLayerId = 'completed-route-layer';
    const remainingSourceId = 'remaining-route-source';
    const remainingLayerId = 'remaining-route-layer';
    
    try {
      if (await _mapboxMap!.style.styleLayerExists(completedLayerId)) {
        await _mapboxMap!.style.removeStyleLayer(completedLayerId);
      }
      if (await _mapboxMap!.style.styleLayerExists(remainingLayerId)) {
        await _mapboxMap!.style.removeStyleLayer(remainingLayerId);
      }
      
      if (await _mapboxMap!.style.styleSourceExists(completedSourceId)) {
        await _mapboxMap!.style.removeStyleSource(completedSourceId);
      }
      if (await _mapboxMap!.style.styleSourceExists(remainingSourceId)) {
        await _mapboxMap!.style.removeStyleSource(remainingSourceId);
      }
      
      if (completedRoute.length > 1) {
        final completedGeoJson = {
          'type': 'Feature',
          'properties': {},
          'geometry': {'type': 'LineString', 'coordinates': completedRoute.map((point) => [point.coordinates.lng, point.coordinates.lat]).toList()}
        };
        
        await _mapboxMap!.style.addSource(GeoJsonSource(id: completedSourceId, data: json.encode(completedGeoJson)));
        await _mapboxMap!.style.addLayer(LineLayer(
          id: completedLayerId,
          sourceId: completedSourceId,
          lineColor: Colors.grey.shade400.toARGB32(),
          lineWidth: 6.0,
          lineOpacity: 0.7,
        ));
      }
      
      if (remainingRoute.length > 1) {
        final remainingGeoJson = {
          'type': 'Feature',
          'properties': {},
          'geometry': {'type': 'LineString', 'coordinates': remainingRoute.map((point) => [point.coordinates.lng, point.coordinates.lat]).toList()}
        };
        
        await _mapboxMap!.style.addSource(GeoJsonSource(id: remainingSourceId, data: json.encode(remainingGeoJson)));
        await _mapboxMap!.style.addLayer(LineLayer(
          id: remainingLayerId,
          sourceId: remainingSourceId,
          lineColor: Colors.green.toARGB32(),
          lineWidth: 8.0,
          lineOpacity: 1.0,
        ));
      }
      
    } catch (e) {
      Logger.error("Error drawing passenger route with progress: $e", error: e);
    }
  }

  void _updateDynamicRoute(Point driverPosition) {
    if (_originalRoutePoints.isEmpty) return;
    
    // NOU: Debouncing pentru a evita frame skip-urile
    if (_routeUpdateDebounceTimer?.isActive == true) {
      _routeUpdateDebounceTimer?.cancel();
    }
    
    _routeUpdateDebounceTimer = Timer(_debounceDelay, () {
      if (!mounted) return;
      
      if (_isDriverView) {
    double minDistance = double.infinity;
    int closestPointIndex = 0;
    for (int i = 0; i < _originalRoutePoints.length; i++) {
      final routePoint = _originalRoutePoints[i];
      final distance = _calculateDirectDistance(driverPosition.coordinates.lat, driverPosition.coordinates.lng, routePoint.coordinates.lat, routePoint.coordinates.lng);
      if (distance < minDistance) {
        minDistance = distance;
        closestPointIndex = i;
      }
    }
    if (closestPointIndex < _originalRoutePoints.length) {
      final remainingRoute = _originalRoutePoints.sublist(closestPointIndex);
      if (remainingRoute.length > 1) {
            _drawRouteOnMap(remainingRoute, isDriverView: true);
          }
        }
      } else {
        _drawPassengerRouteWithProgress(_originalRoutePoints, driverPosition);
      }
    });
  }
  
  Future<void> _updateStaticMarkers(Ride ride) async {
    if (_markersManager == null || !mounted) return;

    if (_staticAnnotations.isNotEmpty) {
        for (final annotation in _staticAnnotations.values) {
          await _markersManager?.delete(annotation);
        }
        _staticAnnotations.clear();
    }
    
    try {
        final newStaticAnnotations = <PointAnnotationOptions>[];
        if (_passengerLocation != null && ride.status != 'in_progress') {
            final ByteData startIcon = await rootBundle.load("assets/images/passenger_icon.png");
            newStaticAnnotations.add(PointAnnotationOptions(
                geometry: MapboxUtils.convertToPoint(_passengerLocation!), image: startIcon.buffer.asUint8List(), iconAnchor: IconAnchor.BOTTOM, 
                iconSize: 0.25,
                textField: "Start", textSize: 12.0, textColor: Colors.green.shade700.toARGB32(), textHaloColor: Colors.white.toARGB32(),
                textHaloWidth: 1.5, textAnchor: TextAnchor.TOP, textOffset: [0.0, 1.2],
            ));
        }

        if (_destinationLocation != null) {
            final ByteData destIcon = await rootBundle.load("assets/images/pin_icon.png");
            newStaticAnnotations.add(PointAnnotationOptions(
                geometry: MapboxUtils.convertToPoint(_destinationLocation!), image: destIcon.buffer.asUint8List(), iconAnchor: IconAnchor.BOTTOM, iconSize: 0.25,
                textField: "Destinație", textSize: 12.0, textColor: Colors.red.shade700.toARGB32(), textHaloColor: Colors.white.toARGB32(),
                textHaloWidth: 1.5, textAnchor: TextAnchor.TOP, textOffset: [0.0, 1.2],
            ));
        }

if (newStaticAnnotations.isNotEmpty) {
    final createdAnnotations = await _markersManager?.createMulti(newStaticAnnotations);
    if(createdAnnotations != null) {
        for (var i = 0; i < createdAnnotations.length; i++) {
            final annotation = createdAnnotations[i];
                  _staticAnnotations['static_$i'] = annotation!;
        }
    }
}
    } catch (e) {
      Logger.error('Error updating static markers: $e', error: e);
    }
  }
  
    // ✅ FIX: Metodă nouă pentru bearing continuu din Firebase
  Future<void> _createOrAnimateDriverMarkerWithBearing(Point newPosition, Ride ride, double? firebaseBearing) async {
    if (!mounted || _markersManager == null) return;
    
    _currentDriverLocation = newPosition;
    
    if (_driverAnnotation == null) {
        final driverInfo = _driverInfoCache[ride.driverId!];
        
        if (!mounted) return;
        
        final brightness = Theme.of(context).brightness;
        final textColor = brightness == Brightness.dark ? Colors.white.toARGB32() : Colors.black.toARGB32();
        final haloColor = brightness == Brightness.dark ? Colors.black.toARGB32() : Colors.white.toARGB32();
        
        final driverName = driverInfo?['name'] ?? (_otherUserName.isNotEmpty ? _otherUserName : 'Șofer');
        final licensePlate = driverInfo?['licensePlate'] ?? '';
        final ByteData driverIcon = await rootBundle.load("assets/images/driver_icon.png");

        // ✅ FIX: Folosește bearing-ul din Firebase sau 0
        final initialBearing = firebaseBearing ?? 0.0;

        final options = PointAnnotationOptions(
            geometry: MapboxUtils.convertToPoint(newPosition),
            image: driverIcon.buffer.asUint8List(),
            iconAnchor: IconAnchor.BOTTOM,
            iconSize: 0.25,
            iconRotate: initialBearing, // ✅ FIX: Setează bearing-ul inițial
            textField: "$driverName\n$licensePlate",
            textSize: 14.0,
            textColor: textColor,
            textHaloColor: haloColor,
            textHaloWidth: 2.0,
            textAnchor: TextAnchor.TOP,
            textOffset: [0.0, 2.5],
            textJustify: TextJustify.CENTER,
        );
        
        _driverAnnotation = await _markersManager?.create(options);
        
        Logger.info('Driver marker created with bearing: $initialBearing°');
        
    } else {
        final startPoint = MapboxUtils.convertToPoint(_driverAnnotation!.geometry);
        final endPoint = newPosition;

        // ✅ FIX: Prioritizează bearing-ul din Firebase, apoi calculează
        double finalBearing;
        
        if (firebaseBearing != null) {
          // Folosește bearing-ul din Firebase (GPS actual)
          finalBearing = firebaseBearing;
          Logger.debug('Using Firebase bearing: ${finalBearing.toStringAsFixed(1)}°');
        } else {
          // Fallback: calculează bearing-ul bazat pe mișcare
          finalBearing = _calculateBearing(startPoint, endPoint);
          Logger.debug('Calculated bearing from movement: ${finalBearing.toStringAsFixed(1)}°');
        }

        // ✅ FIX: Animează poziția ȘI rotația cu bearing continuu
        final latTween = Tween<double>(
          begin: startPoint.coordinates.lat.toDouble(), 
          end: endPoint.coordinates.lat.toDouble()
        );
        final lngTween = Tween<double>(
          begin: startPoint.coordinates.lng.toDouble(), 
          end: endPoint.coordinates.lng.toDouble()
        );
        
        if (_animationController == null) return;

        // ✅ FIX: Resetează animația înainte de fiecare update
        _animationController!.reset();
        
        final animation = CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut);

        late VoidCallback animationListener;
        animationListener = () {
            if (_driverAnnotation != null && mounted) {
                final animatedLng = lngTween.evaluate(animation);
                final animatedLat = latTween.evaluate(animation);
                final animatedPoint = Point(coordinates: Position(animatedLng, animatedLat));
                
                // ✅ FIX: Actualizează poziția ȘI bearing-ul continuu
                _driverAnnotation!.geometry = MapboxUtils.convertToPoint(animatedPoint);
                _driverAnnotation!.iconRotate = finalBearing; // ✅ Bearing continuu!
                _markersManager?.update(_driverAnnotation!);
                
                // ✅ FIX: Update poziția curentă în timpul animației
                _currentDriverLocation = animatedPoint;
            }
        };
        
        animation.addListener(animationListener);
        
        // ✅ FIX: Cleanup după animație
        _animationController!.addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            animation.removeListener(animationListener);
            _currentDriverLocation = newPosition;
          }
        });
        
        _animationController!.forward();
    }

    // ✅ APLICĂ camera pe baza rolului
    _applyRoleBasedCameraView(newPosition, ride);

    // ✅ Update UI state
    if (mounted) setState(() {});
  }




  Future<void> _initializeRideAndSubscribe() async {
    try {
      Logger.debug('Initializing ride and routing...');
      final ride = await _firestoreService.getRideStream(widget.rideId).first;
      
      _previousRide = ride;

      await _getCoordinatesFromAddresses(ride);
      await _loadOtherUserInfo(ride);
      if (mounted) {
        await _updateStaticMarkers(ride);
        
        // ✅ FIX: Inițializează routing-ul AUTOMAT după coordonate
        await _initializeRoutingAutomatic(ride);
        
        _subscribeToRideStatusChanges();
      }
    } catch (e) {
      Logger.error('Error initializing ride: $e', error: e);
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n?.errorInitializingRide ?? 'Eroare la inițializarea cursei'}: $e')));
        Navigator.pop(context);
      }
    }
  }

  // ✅ FIX: Metodă nouă pentru routing automat
  Future<void> _initializeRoutingAutomatic(Ride ride) async {
    if (ride.startLatitude == null || ride.startLongitude == null ||
        ride.destinationLatitude == null || ride.destinationLongitude == null) {
      Logger.error('Missing coordinates for routing');
      return;
    }

    try {
      setState(() => _isLoadingRoute = true);
      Logger.debug('Auto-initializing routing...');
      
      final pickupPoint = Point(coordinates: Position(ride.startLongitude!, ride.startLatitude!));
      final destinationPoint = Point(coordinates: Position(ride.destinationLongitude!, ride.destinationLatitude!));
      
      List<Point> waypoints = [pickupPoint];
      
      // Adaugă opriri intermediare
      if (ride.stops.isNotEmpty) {
        for (final stopMap in ride.stops) {
          final stop = StopLocation.fromMap(stopMap);
          waypoints.add(Point(coordinates: Position(stop.longitude, stop.latitude)));
        }
      }
      
      waypoints.add(destinationPoint);
      
      Logger.debug('Calculating route with ${waypoints.length} waypoints...');
      final route = await _routingService.getRoute(waypoints);
      
      if (route != null && mounted) {
        Logger.info('Route calculated, drawing on map...');
        _routeGeoJSON = route;
        await _drawRouteOnMapOptimized(route);
        await _fitCameraToRoute(route);
        
        // ✅ FIX: Inițializează navigația vocală automat
        _initializeVoiceNavigation(route);
        
        Logger.info('Auto-routing completed successfully');
      }
    } catch (e) {
      Logger.error('Auto-routing failed: $e', error: e);
    } finally {
      if (mounted) {
        setState(() => _isLoadingRoute = false);
      }
    }
  }



  // ✅ FIX: Metodă nouă pentru inițializarea navigației vocale
  void _initializeVoiceNavigation(Map<String, dynamic> route) {
    try {
      Logger.debug('Initializing voice navigation...');
      
      // Parse navigation steps
      final steps = _navigationService.parseMapboxRoute(route);
      _navigationService.setNavigationSteps(steps);
      
      // ✅ FIX: Pornește navigația vocală automat pentru șoferi
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      final isDriver = _previousRide?.driverId == currentUserId;
      
      if (isDriver) {
        Logger.debug('Starting voice navigation for driver...');
        _navigationService.startNavigation(route);
        
        // ✅ FIX: Primul anunț vocal cu metoda robustă
        if (steps.isNotEmpty) {
          final firstStep = steps.first;
          _announceNavigationInstructionRobust(firstStep);
        }
      }
      
    } catch (e) {
      Logger.error('Voice navigation initialization failed: $e', error: e);
    }
  }

  // ✅ FIX: Metodă robustă pentru anunțuri vocale
  void _announceNavigationInstructionRobust(NavigationStep step) {
    Logger.debug('Announcing: ${step.instruction}');
    
    _ttsTimer?.cancel();
    _ttsTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        await _ttsService.speak(step.instruction);
        Logger.info('TTS announced successfully');
        _perf.recordNavTelemetry('tts_ok', {
          'instruction': step.instruction,
        });
      } catch (e) {
        Logger.error('TTS failed: $e', error: e);
        _perf.recordNavTelemetry('tts_fail', {
          'error': e.toString(),
        });
        // Fallback: vibration pattern for turns
        try {
          if (step.type == 'turn') {
            HapticFeedback.heavyImpact();
            Future.delayed(Duration(milliseconds: 300), () {
              HapticFeedback.heavyImpact();
            });
          }
        } catch (e2) {
          Logger.error('Haptic fallback failed: $e2');
        }
      }
    });
  }

  Future<void> _loadOtherUserInfo(Ride ride) async {
    final isDriver = _currentUserId == ride.driverId;
    final otherUserId = isDriver ? ride.passengerId : ride.driverId;  // ✅ MODIFICAT: userId → passengerId
    if (otherUserId != null) {
      await _cacheDriverInfo(otherUserId);
      final userDoc = await _firestoreService.getProfileByIdStream(otherUserId).first;
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        if (mounted) {
          setState(() {
            _otherUserName = userData['displayName'] ?? (isDriver ? 'Pasager' : 'Șofer');
            _otherUserPhone = userData['phone'] ?? '+40 700 000 000';
          });
        }
      }
    }
  }

  Future<void> _getCoordinatesFromAddresses(Ride ride) async {
    try {
      if (ride.startLatitude != null && ride.startLongitude != null) {
        _passengerLocation = Point(coordinates: Position(ride.startLongitude!, ride.startLatitude!));
      }
      if (ride.destinationLatitude != null && ride.destinationLongitude != null) {
        _destinationLocation = Point(coordinates: Position(ride.destinationLongitude!, ride.destinationLatitude!));
      }
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      Logger.error("Geocoding failed initially: $e", error: e);
    }
  }

  void _startDriverLocationTracking(String driverId) {
    _driverLocationSubscription?.cancel();
    Logger.debug('Starting driver location tracking for: $driverId');
    
    _driverLocationSubscription = _firestoreService.getDriverLocationStream(driverId).listen((snapshot) {
      if (!mounted) return;
      
      if (!snapshot.exists) {
        Logger.warning('Driver location snapshot does not exist');
        return;
      }
      
      if (_previousRide == null) {
        Logger.warning('No ride data available for location tracking');
        return;
      }
      
      try {
        final data = snapshot.data()!;
        final pos = data['position'] as GeoPoint;
        final newDriverPosition = Point(coordinates: Position(pos.longitude, pos.latitude));
      _currentDriverLocation = newDriverPosition;
        
        // ✅ FIX: Extrage bearing-ul din Firestore dacă există
        final bearing = data['bearing'] as double?;
        
        Logger.debug('Driver location update: ${newDriverPosition.coordinates.lat}, ${newDriverPosition.coordinates.lng}, bearing: $bearing');
        
        // ✅ FIX: Actualizează marker-ul cu bearing din Firestore
        _createOrAnimateDriverMarkerWithBearing(newDriverPosition, _previousRide!, bearing);
        _updateEtaAndDistance(newDriverPosition);
        
        final ride = _previousRide;
        if (ride != null && _currentUserId == ride.driverId) {
           _updateDynamicRoute(newDriverPosition);
           _followDriverWithCamera(newDriverPosition);
        }
      } catch (e) {
        Logger.error('Error processing driver location update: $e', error: e);
      }
    }, onError: (error) {
      Logger.error('Driver location tracking error: $error', error: error);
    });
  }

  void _stopDriverLocationTracking() {
    _driverLocationSubscription?.cancel();
    _driverLocationSubscription = null;
  }

  void _updateEtaAndDistance(Point driverPosition) {
    if (!mounted) return;

    double? pickupDistanceMeters;
    double? destinationDistanceMeters;

    if (_passengerLocation != null) {
      pickupDistanceMeters = _calculateDirectDistance(
            driverPosition.coordinates.lat,
            driverPosition.coordinates.lng,
            _passengerLocation!.coordinates.lat,
            _passengerLocation!.coordinates.lng,
          ) *
          1000.0;
    }

    if (_destinationLocation != null) {
      destinationDistanceMeters = _calculateDirectDistance(
            driverPosition.coordinates.lat,
            driverPosition.coordinates.lng,
            _destinationLocation!.coordinates.lat,
            _destinationLocation!.coordinates.lng,
          ) *
          1000.0;
    }

    const averageSpeedMps = 10.0;
    Duration? pickupEta;
    Duration? destinationEta;
    DateTime? pickupArrival;
    DateTime? destinationArrival;

    if (pickupDistanceMeters != null) {
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
      _currentDriverLocation = driverPosition;
      _pickupDistanceKm =
          pickupDistanceMeters != null ? pickupDistanceMeters / 1000.0 : null;
      _pickupEta = pickupEta;
      _pickupArrivalTime = pickupArrival;

      _destinationDistanceKm = destinationDistanceMeters != null
          ? destinationDistanceMeters / 1000.0
          : null;
      _destinationEta = destinationEta;
      _destinationArrivalTime = destinationArrival;

      if (pickupDistanceMeters == null && destinationDistanceMeters == null) {
        _routeTrafficSummary = null;
      }
    });

    final now = DateTime.now();
    final hasRecentRequest = _lastEtaRequestTime != null &&
        now.difference(_lastEtaRequestTime!) < _etaRoutingThrottle;

    final bool movedEnough;
    if (_lastEtaRequestDriverPosition == null) {
      movedEnough = true;
    } else {
      final movedMeters = _calculateDirectDistance(
            driverPosition.coordinates.lat,
            driverPosition.coordinates.lng,
            _lastEtaRequestDriverPosition!.coordinates.lat,
            _lastEtaRequestDriverPosition!.coordinates.lng,
          ) *
          1000.0;
      movedEnough = movedMeters >= _etaRoutingDistanceThresholdMeters;
    }

    if (hasRecentRequest || !movedEnough || _isFetchingPreciseEta) {
      return;
    }

    _lastEtaRequestTime = now;
    _lastEtaRequestDriverPosition = driverPosition;
    unawaited(_fetchPreciseEta(driverPosition));
  }

  Future<void> _fetchPreciseEta(Point driverPosition) async {
    if (_isFetchingPreciseEta) return;

    _isFetchingPreciseEta = true;
    try {
      final waypoints = <Point>[driverPosition];
      final hasPickup = _passengerLocation != null;
      final hasDestination = _destinationLocation != null;

      if (hasPickup) {
        waypoints.add(_passengerLocation!);
      }
      if (hasDestination) {
        waypoints.add(_destinationLocation!);
      }

      if (waypoints.length < 2) {
        return;
      }

      final routeResult = await _routingService.getRoute(waypoints);
      if (!mounted) return;

      if (routeResult != null &&
          routeResult['routes'] != null &&
          routeResult['routes'].isNotEmpty) {
        final dynamic routeDynamic = routeResult['routes'][0];
        if (routeDynamic is Map<String, dynamic>) {
          final totalDistance = (routeDynamic['distance'] as num?)?.toDouble();
          final totalDuration = (routeDynamic['duration'] as num?)?.toDouble();

          double? pickupDistance;
          double? pickupDuration;
          double? destinationDistance = totalDistance;
          double? destinationDuration = totalDuration;

          String? traffic;
          if (routeDynamic['legs'] is List && routeDynamic['legs'].isNotEmpty) {
            final legs = routeDynamic['legs'] as List;
            if (legs.isNotEmpty) {
              final leg0 = legs[0];
              if (leg0 is Map<String, dynamic>) {
                pickupDistance = (leg0['distance'] as num?)?.toDouble();
                pickupDuration = (leg0['duration'] as num?)?.toDouble();
                final annotation = leg0['annotation'];
                if (annotation is Map<String, dynamic>) {
                  final congestion = annotation['congestion'];
                  if (congestion is List) {
                    final counts = <String, int>{};
                    for (final entry in congestion) {
                      if (entry is String && entry.isNotEmpty) {
                        counts.update(entry, (value) => value + 1, ifAbsent: () => 1);
                      }
                    }
                    if (counts.isNotEmpty) {
                      final dominant = counts.entries.reduce(
                        (a, b) => a.value >= b.value ? a : b,
                      );
                      traffic = switch (dominant.key) {
                        'low' => 'Trafic lejer',
                        'moderate' => 'Trafic moderat',
                        'heavy' => 'Trafic aglomerat',
                        'severe' => 'Trafic foarte aglomerat',
                        _ => null,
                      };
                    }
                  }
                }
              }
            }
          }

          setState(() {
            if (pickupDistance != null) {
              _pickupDistanceKm = pickupDistance / 1000.0;
            }
            if (pickupDuration != null) {
              _pickupEta = Duration(seconds: pickupDuration.round());
              _pickupArrivalTime = DateTime.now().add(_pickupEta!);
            }

            if (destinationDistance != null) {
              _destinationDistanceKm = destinationDistance / 1000.0;
            }
            if (destinationDuration != null) {
              _destinationEta = Duration(seconds: destinationDuration.round());
              _destinationArrivalTime = DateTime.now().add(_destinationEta!);
            }

            if (traffic != null) {
              _routeTrafficSummary = traffic;
            }
          });
        }
      }
    } catch (e) {
      Logger.error('Precise ETA calculation failed: $e', error: e);
    } finally {
      _isFetchingPreciseEta = false;
    }
  }

  // (Removed legacy _recalculateRoute to enforce zero warnings)

  void _callNumber(String phoneNumber) async {
    final l10n = AppLocalizations.of(context);
    _audioService.playIncomingCallSound();

    final ctx = context; // capture context to avoid using State.context across async gaps
    String dialNumber = phoneNumber;
    String displayNumber = phoneNumber;

    final bool isEmergencyCall = phoneNumber == '112';

    if (isEmergencyCall) {
      await _handleEmergencyTriggered();
    }

    try {
      // Încearcă să folosești un număr mascat din Firestore, dacă există
      if (!isEmergencyCall) {
        final isDriver = _currentUserId == _previousRide?.driverId;
        final otherUserId =
            isDriver ? _previousRide?.passengerId : _previousRide?.driverId;
        if (otherUserId != null && widget.rideId.isNotEmpty) {
          final masked = await _firestoreService.getMaskedPhoneForRide(
            rideId: widget.rideId,
            otherUserId: otherUserId,
          );
          if (masked != null && masked.isNotEmpty) {
            dialNumber = masked; // Se apelează numărul proxy
            displayNumber = phoneNumber; // Afișăm totuși numărul real în UI
          } else {
            // Fallback la suprimarea ID-ului apelant (#31#) unde este suportat
            if (phoneNumber.startsWith('+')) {
              dialNumber = '#31#$phoneNumber';
            }
          }
        }
      }
    } catch (e) {
      Logger.error('Anonymization fallback error: $e', error: e);
    }

    if (!mounted || !ctx.mounted) return;
    final result = await _voipService.startCall(
      phoneNumber: displayNumber,
      contactName: _otherUserName,
      context: ctx,
      dialNumber: dialNumber == displayNumber ? null : dialNumber,
    );

    if (!mounted || !ctx.mounted) return;
    if (!result) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(l10n?.cannotMakeCall ?? 'Nu s-a putut iniția apelul.'), backgroundColor: Colors.red),
      );
    }
  }

  void _handleDriverArrived() {
    _firestoreService.updateRideStatus(widget.rideId, 'arrived');
    
    // Trimite mesaj de sistem
    _firestoreService.sendSystemMessage(
      widget.rideId,
      'Șoferul a ajuns la locația de preluare',
    );
  }

  void _handleStartRide() async {
    _firestoreService.updateRideStatus(widget.rideId, 'in_progress');
    _ttsService.speak("Am pornit");
    
    // Trimite mesaj de sistem
    _firestoreService.sendSystemMessage(
      widget.rideId,
      'Cursa a început',
    );
    
    if (_destinationLocation != null) {
      final lat = _destinationLocation!.coordinates.lat;
      final lng = _destinationLocation!.coordinates.lng;
      _showNavigationOptions(lat.toDouble(), lng.toDouble());
    } else {
      _showNavigationError('Destinația nu este disponibilă pentru navigație.');
    }
  }

  void _handleEndRide() async {
    await _firestoreService.updateRideStatus(widget.rideId, 'completed');
    if (!mounted) return;
    final ride = await _firestoreService.getRideStream(widget.rideId).first;
    final isDriver = _currentUserId == ride.driverId;
    
    // ✅ NOU: Trimite receipt automat pe email
    try {
      final emailReceiptService = EmailReceiptService();
      await emailReceiptService.sendReceiptsForRide(widget.rideId, ride);
      Logger.info('Receipt emails sent for ride: ${widget.rideId}');
    } catch (e) {
      Logger.error('Error sending receipt emails: $e', error: e);
      // Nu blocăm finalizarea cursei dacă email-ul eșuează
    }
    
    // ✅ NOU: Actualizează driver incentives după finalizarea cursei
    if (isDriver && ride.driverId != null) {
      try {
        final incentivesService = DriverIncentivesService();
        await incentivesService.updateIncentivesAfterRideCompletion(ride.driverId!);
        Logger.info('Driver incentives updated for ride: ${widget.rideId}');
      } catch (e) {
        Logger.error('Error updating driver incentives: $e', error: e);
        // Nu blocăm finalizarea cursei dacă incentives eșuează
      }
    }

    // ✅ Actualizează programul de loialitate al pasagerului după finalizarea cursei
    if (!isDriver && ride.passengerId.isNotEmpty) {
      try {
        final loyaltyService = LoyaltyProgramService();
        await loyaltyService.updateLoyaltyAfterRide(ride.passengerId, ride);
        Logger.info('Loyalty program updated for passenger: ${ride.passengerId}');
      } catch (e) {
        Logger.error('Error updating loyalty program: $e', error: e);
        // Nu blocăm finalizarea cursei dacă loyalty eșuează
      }
    }
    
    if (!isDriver) {
      try {
        await _ttsService.speak("Ai sosit");
      } catch (e) {
        Logger.error('Error playing audio notification for passenger: $e', error: e);
      }
    }
  }







  Future<void> _handleCancelRide(String rideId, Ride ride) async {
    if (!mounted) return;

    // Check if a 5 RON cancellation fee applies (driver assigned > 3 min ago)
    final feeApplicable = await _firestoreService.getCancellationFeeApplicable(rideId);

    if (!mounted) return;

    if (feeApplicable && _currentUserId != ride.driverId) {
      // Show fee warning dialog before the normal cancellation flow
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Taxă de anulare'),
          content: const Text(
            'Vei fi taxat cu 5 RON dacă anulezi acum. Ești sigur?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Nu'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Da, anulează', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Record the cancellation fee on the ride document before cancelling
      try {
        await _firestoreService.updateRideFields(rideId, {'cancellationFee': 5.0});
      } catch (e) {
        // Non-fatal — proceed with cancellation anyway
      }
    }

    if (!mounted) return;

    // ✅ ÎMBUNĂTĂȚIT: Folosește CancellationPolicyDialog
    await showDialog<bool>(
      context: context,
      builder: (context) => CancellationPolicyDialog(
        ride: ride,
        isDriver: _currentUserId == ride.driverId,
        onConfirmCancel: () async {
          // Capture Navigator and ScaffoldMessenger before any async operations
          final navigator = Navigator.of(context);
          final messenger = ScaffoldMessenger.of(context);
          
          try {
            await _firestoreService.cancelRide(rideId);
            
            if (!mounted) return;
            navigator.popUntil((route) => route.isFirst);
            
            messenger.showSnackBar(
              SnackBar(
                content: Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context)!;
                    return Text(l10n.rideCancelledSuccess);
                  },
                ),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            if (!mounted) return;
            messenger.showSnackBar(
              SnackBar(
                content: Text('Eroare la anulare: ${e.toString()}'), 
                backgroundColor: Colors.red
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _centerMapIfReady({Ride? ride}) async {
    if (_mapboxMap == null) return;
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    final currentRide = ride ?? await _firestoreService.getRideStream(widget.rideId).first;
    
    final List<Point> waypoints = [];
    Point? driverPos;

    if (_driverAnnotation != null) {
      driverPos = MapboxUtils.convertToPoint(_driverAnnotation!.geometry);
    } else if (currentRide.driverId != null) {
      try {
        final driverLocationSnapshot = await _firestoreService.getDriverLocationStream(currentRide.driverId!).first;
        if (driverLocationSnapshot.exists) {
          final pos = driverLocationSnapshot.data()!['position'] as GeoPoint;
          driverPos = Point(coordinates: Position(pos.longitude, pos.latitude));
        }
      } catch (e) {
        Logger.debug("Could not get initial driver location for centering: $e");
      }
    }

    if (driverPos == null && _currentUserId != currentRide.driverId) return;

    final rideStartPoint = Point(coordinates: Position(currentRide.startLongitude!, currentRide.startLatitude!));
    final rideEndPoint = Point(coordinates: Position(currentRide.destinationLongitude!, currentRide.destinationLatitude!));

    if (currentRide.status == 'accepted' || currentRide.status == 'arrived') {
      if(driverPos != null) waypoints.add(driverPos);
      waypoints.add(rideStartPoint);
    } else if (currentRide.status == 'in_progress') {
      if(driverPos != null) waypoints.add(driverPos);
      for (final stopMap in currentRide.stops) {
        final stop = StopLocation.fromMap(stopMap);
        waypoints.add(Point(coordinates: Position(stop.longitude, stop.latitude)));
      }
      waypoints.add(rideEndPoint);
    }

    if (waypoints.length >= 2) {
      try {
        final routeData = await _routingService.getRoute(waypoints);
        if (!mounted || routeData == null) return;
        
        final steps = _navigationService.parseMapboxRoute(routeData);
        _navigationService.setNavigationSteps(steps);
        final routePoints = _routingService.extractRouteCoordinates(routeData);
        await _drawRouteOnMap(routePoints);

        if (_currentUserId == currentRide.driverId && !_isNavigationActive) {
          _isNavigationActive = true;
          await _navigationService.startNavigation(routeData);
        }

        if (!mounted) return;
        final bounds = CoordinateBounds(
          southwest: MapboxUtils.createPoint(
            waypoints.map((p) => p.coordinates.lat).reduce(math.min).toDouble(),
            waypoints.map((p) => p.coordinates.lng).reduce(math.min).toDouble()
          ),
          northeast: MapboxUtils.createPoint(
            waypoints.map((p) => p.coordinates.lat).reduce(math.max).toDouble(),
            waypoints.map((p) => p.coordinates.lng).reduce(math.max).toDouble()
          ),
          infiniteBounds: false,
        );
        final cameraOptions = await _mapboxMap?.cameraForCoordinateBounds(bounds, MbxEdgeInsets(top: 100.0, left: 50.0, bottom: 250.0, right: 50.0), 0.0, 0.0, null, null);
        if (mounted && cameraOptions != null) {
          _mapboxMap?.flyTo(cameraOptions, MapAnimationOptions(duration: 1500));
        }
      } catch (e) {
        Logger.error('Error getting route for fitCamera: $e', error: e);
      }
    } else if (waypoints.length == 1) {
       _mapboxMap?.flyTo(CameraOptions(center: MapboxUtils.convertToPoint(waypoints.first), zoom: 15), MapAnimationOptions(duration: 1500));
    }
  }

  @override
  Widget build(BuildContext context) {
     final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.activeRide ?? 'Cursă Activă'),
        actions: [
          const ThemeToggleButton(key: ValueKey('theme_toggle_active_ride')),
          IconButton(
            onPressed: _openSafetyShareSheet,
            icon: const Icon(Icons.share_location),
            tooltip: l10n?.shareLocation ?? 'Partajează locația',
          ),
          IconButton(
            onPressed: () => _callNumber("112"),
            icon: const Text("112", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            style: IconButton.styleFrom(backgroundColor: Colors.red),
            tooltip: l10n?.emergency ?? 'Apelează 112',
          )
        ],
      ),
      body: StreamBuilder<Ride>(
        stream: _firestoreService.getRideStream(widget.rideId),
        builder: (context, rideSnapshot) {
          if (!rideSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (rideSnapshot.hasError) {
            return Center(child: Text('Eroare: ${rideSnapshot.error}'));
          }
          final ride = rideSnapshot.data!;
          final isDriver = _currentUserId == ride.driverId;

          if (_isRideStuck(ride)) {
            return Center(child: RideStuckPanel(ride: ride, firestoreService: _firestoreService));
          }

          // Compute arrival panel visibility: driver approaching passenger (< 100 m)
          final bool showArrivalPanel = () {
            if (!isDriver) return false;
            if (ride.status != 'accepted') return false;
            if (_currentDriverLocation == null || _passengerLocation == null) return false;
            final meters = _calculateDirectDistance(
              _currentDriverLocation!.coordinates.lat,
              _currentDriverLocation!.coordinates.lng,
              _passengerLocation!.coordinates.lat,
              _passengerLocation!.coordinates.lng,
            ) * 1000.0;
            return meters <= 100.0;
          }();

          return Stack(
            children: [
              MapWidget(
                onMapCreated: _onMapCreated,
                onCameraChangeListener: (event) {
                  // If user pans in passenger view, show recenter button
                  if (!_isDriverView) {
                    if (!_showRecenterButton) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() { _showRecenterButton = true; });
                        }
                      });
                    }
                    // Show transient recenter hint once after pan
                    if (!_showRecenterHint) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        setState(() { _showRecenterHint = true; });
                        _recenterHideTimer?.cancel();
                        _recenterHideTimer = Timer(const Duration(seconds: 3), () {
                          if (mounted) setState(() { _showRecenterHint = false; });
                        });
                      });
                    }
                  }
                },
                cameraOptions: CameraOptions(center: MapboxUtils.convertToPoint(_passengerLocation ?? MapboxUtils.createPoint(44.4268, 26.1025)), zoom: 14),
                styleUri: Theme.of(context).brightness == Brightness.dark ? MapboxStyles.DARK : MapboxStyles.MAPBOX_STREETS,
              ),
              
              // AI button ascuns temporar

              if (_showTurnByTurnUI && _isDriverView && _currentNavigationStep != null)
                RideTurnByTurnWidget(
                  currentNavigationStep: _currentNavigationStep!,
                  voiceMuted: _voiceMuted,
                  ttsService: _ttsService,
                  onVoiceMutedChanged: (muted) => setState(() { _voiceMuted = muted; }),
                  onDismiss: () => setState(() { _showTurnByTurnUI = false; }),
                ),

              // Recenter button for passenger when map is moved
              if (_showRecenterButton && !_isDriverView)
                Positioned(
                  bottom: 120,
                  right: 16,
                  child: Semantics(
                    label: 'Recentrează harta',
                    button: true,
                    child: FloatingActionButton.small(
                      heroTag: 'recenter_fab',
                      onPressed: () {
                        if (_passengerLocation != null) {
                          _mapboxMap?.flyTo(
                            CameraOptions(center: _passengerLocation, zoom: 15.0, bearing: 0.0, pitch: 0.0),
                            MapAnimationOptions(duration: 700),
                          );
                          setState(() { _showRecenterButton = false; });
                        }
                      },
                      child: const Icon(Icons.my_location),
                    ),
                  ),
                ),

              // Passenger recenter hint (transient)
              if (_showRecenterHint && !_isDriverView)
                Positioned(
                  bottom: 180,
                  right: 16,
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.swipe, size: 16),
                          const SizedBox(width: 6),
                          Builder(
                            builder: (context) {
                              final l10n = AppLocalizations.of(context)!;
                              return Text(l10n.mapMovedTapToRecenter);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              if (_isEmergencyPromptVisible && _activeEmergencyEventId != null)
                Positioned(
                  top: 96,
                  left: 16,
                  right: 16,
                  child: RideEmergencyCard(
                    onIAmSafe: () => _resolveEmergencyAlert(),
                    onFalseAlarm: () => _resolveEmergencyAlert(falseAlarm: true),
                    onShareRoute: _openSafetyShareSheet,
                  ),
                ),
              
              // 🗺️ FIX: Loading indicator pentru routing
              if (_isLoadingRoute)
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((255 * 0.1).round()),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Se calculează traseul...',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
              ),
              
              Positioned(
                top: 40, // ✅ FIX: Poziționat la 30px pentru a evita suprapunerea cu busola
                right: 16,
                child: FloatingActionButton.small(
                  heroTag: "center_location",
                  onPressed: () => _centerMapIfReady(ride: ride),
                  backgroundColor: Theme.of(context).cardColor,
                  child: Icon(Icons.my_location, color: Theme.of(context).colorScheme.primary),
                ),
              ),

              // GPS-loss (tunnel) banner with paused ETA
              if (_isGpsLost)
                Positioned(
                  top: 70,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.sensors_off, color: Colors.white),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Semnal GPS slab — ETA în pauză temporar',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              DraggableScrollableSheet(
                initialChildSize: 0.25,
                minChildSize: 0.25,
                maxChildSize: 0.6,
                builder: (BuildContext context, ScrollController scrollController) {
                  return buildInfotainmentPanel(ride, isDriver, scrollController);
                },
              ),

              // Arrival actions panel under 100m
              if (showArrivalPanel)
                Positioned(
                  bottom: 24,
                  left: 16,
                  right: 16,
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _handleDriverArrived, // existing handler, not duplicating logic
                                  child: Text(l10n?.iArrived ?? 'Am ajuns'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () async {
                                    // Reuse existing entrance picker flow from MapScreen by navigating to it temporarily
                                    // and returning a selected entrance location (if available)
                                    final result = await Navigator.push<Map<String, dynamic>>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const SearchLocationScreen(isDestination: false),
                                      ),
                                    );
                                    if (!context.mounted) return;
                                    if (result != null) {
                                      // Optionally, we could update passenger pickup point here; keeping minimal for now
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Builder(
                                          builder: (context) {
                                            final l10n = AppLocalizations.of(context)!;
                                            return Text(l10n.entrySelected);
                                          },
                                        )),
                                      );
                                    }
                                  },
                                  child: const Text('Alege intrare'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: l10n?.call ?? 'Sună',
                                  onPressed: () => _callNumber(_otherUserPhone),
                                  icon: const Icon(Icons.call, color: Colors.blue),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  tooltip: l10n?.shareLocation ?? 'Partajează locația',
                                  onPressed: _openSafetyShareSheet,
                                  icon: const Icon(Icons.ios_share, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Destination entrance chips near destination (driver, in_progress)
              if (_shouldShowDestinationEntranceChips(ride))
                Positioned(
                  bottom: 96,
                  left: 16,
                  right: 16,
                  child: RideDestinationEntranceChips(onEntrySelected: _onSelectDestinationEntrance),
                ),

              // Voice assistant panel for passenger: call driver, cancel, share location.
              if (!isDriver)
                Positioned(
                  bottom: 200,
                  right: 0,
                  child: ActiveRideVoicePanel(
                    onCallDriver: () => _callNumber(_otherUserPhone),
                    onCancelRide: () => _handleCancelRide(widget.rideId, ride),
                    onShareLocation: _openSafetyShareSheet,
                  ),
                ),


            ],
          );
        },
      ),
    );
  }

  Widget buildInfotainmentPanel(Ride ride, bool isDriver, ScrollController scrollController) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.2).round()),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 12),
              
              // ✅ RESTAURAT: Panelul original cu informațiile cursei
              _buildStatusAndActionRow(ride, isDriver),
              
              // ✅ NOU: Turn-by-turn Navigation Widget
              if (isDriver && _isNavigationActive && widget.routeGeoJSON != null)
                TurnByTurnNavigationWidget(
                  navigationService: _navigationService,
                  isDriver: true,
                ),
              
              const SizedBox(height: 16),
              
              // ✅ NOU: Chat integrat în stilul ferestrei de destinație
              _buildIntegratedChatField(ride),
            ],
          ),
        ),
      ),
    );
  }















  // ✅ NOU: Chat integrat în stilul ferestrei de destinație
  Widget _buildIntegratedChatField(Ride ride) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha((255 * 0.3).round()),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.05).round()),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header cu simbol mesaje
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Chat cu $_otherUserName',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // Badge pentru mesaje necitite
                if (_unreadMessageCount > 0)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      _unreadMessageCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
          
          // Câmp de text pentru chat
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Simbol mesaje în stânga
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withAlpha((255 * 0.3).round()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.message,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Buton emoji
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showEmojiPicker = !_showEmojiPicker;
                      _showGifPicker = false;
                    });
                  },
                  icon: Icon(
                    _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  tooltip: 'Emoji',
                ),
                
                // Buton GIF
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showGifPicker = !_showGifPicker;
                      _showEmojiPicker = false;
                    });
                  },
                  icon: Icon(
                    Icons.gif_box_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  tooltip: 'GIF',
                ),
                
                // Buton voice recording
                VoiceRecordButton(
                  rideId: widget.rideId,
                  onRecordingComplete: () {
                    // Scroll la ultimul mesaj după trimitere
                    // (se va face automat prin stream)
                  },
                ),
                
                const SizedBox(width: 12),
                
                // Câmp de text pentru scrierea mesajelor
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    decoration: InputDecoration(
                      hintText: "Scrie un mesaj...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.outline.withAlpha((255 * 0.3).round()),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.outline.withAlpha((255 * 0.3).round()),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: null,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Butonul de trimitere în dreapta
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: Icon(
                      Icons.send,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 20,
                    ),
                    tooltip: 'Trimite',
                  ),
                ),
              ],
            ),
          ),
          
          // ✅ EMOJI PICKER
          if (_showEmojiPicker)
            EmojiPickerWidget(
              onEmojiSelected: (emoji) {
                final currentText = _chatController.text;
                _chatController.text = currentText + emoji;
                _chatController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _chatController.text.length),
                );
              },
              onBackspace: () {
                final currentText = _chatController.text;
                if (currentText.isNotEmpty) {
                  _chatController.text = currentText.substring(0, currentText.length - 1);
                }
              },
            ),
          
          // ✅ GIF PICKER
          if (_showGifPicker)
            GifPickerWidget(
              onGifSelected: (gifUrl, gifId) async {
                setState(() {
                  _showGifPicker = false;
                });
                try {
                  await _firestoreService.sendChatMessage(
                    widget.rideId,
                    'GIF',
                    type: MessageType.gif,
                    gifUrl: gifUrl,
                    gifId: gifId,
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Eroare la trimiterea GIF-ului: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              giphyApiKey: null, // Poate fi adăugat în .env
            ),
          
          // ✅ MESAJE RAPIDE (Quick Replies)
          QuickRepliesWidget(
            rideId: widget.rideId,
            isDriver: _currentUserId == _previousRide?.driverId,
            onQuickReplySent: () {
              HapticFeedback.lightImpact();
              if (mounted) {
                setState(() {
                  _unreadMessageCount = 0;
                });
              }
            },
          ),
          
          // ✅ CONVERSAȚIA COMPLETĂ - StreamBuilder pentru toate mesajele
          Container(
            constraints: const BoxConstraints(maxHeight: 200, minHeight: 120),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestoreService.getChatMessages(widget.rideId),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 32,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Începe conversația!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                final messages = snapshot.data!.docs;
                
                return Column(
                  children: [
                    // Typing indicator
                    TypingIndicatorWidget(
                      rideId: widget.rideId,
                      otherUserName: _otherUserName,
                    ),
                    // Mesaje
                    Expanded(
                      child: ListView.builder(
                        reverse: true, // Mesajele noi în jos
                        shrinkWrap: true,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final doc = messages[index];
                          try {
                            final msg = ChatMessage.fromMap(doc.data());
                            final isMe = msg.senderId == _currentUserId;
                            
                            return WhatsAppMessageBubble(
                              message: msg,
                              isMe: isMe,
                              otherUserName: isMe ? null : _otherUserName,
                              onLongPress: isMe ? () => _editMessage(doc.id, msg.text) : null,
                            );
                          } catch (e) {
                            Logger.error('Error parsing chat message: $e', error: e);
                            // Fallback la vechiul format
                            final msgData = doc.data();
                            final isMe = msgData['senderId'] == _currentUserId;
                            final timestamp = msgData['timestamp'] as Timestamp?;
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Align(
                                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: isMe 
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        msgData['message'] ?? msgData['text'] ?? '',
                                        style: TextStyle(
                                          color: isMe 
                                            ? Theme.of(context).colorScheme.onPrimary
                                            : Theme.of(context).colorScheme.onSurfaceVariant,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (timestamp != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          "${timestamp.toDate().hour.toString().padLeft(2, '0')}:${timestamp.toDate().minute.toString().padLeft(2, '0')}",
                                          style: TextStyle(
                                            color: (isMe 
                                              ? Theme.of(context).colorScheme.onPrimary
                                              : Theme.of(context).colorScheme.onSurfaceVariant).withAlpha((255 * 0.7).round()),
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusAndActionRow(Ride ride, bool isDriver) {
    final l10n = AppLocalizations.of(context);
    String message;
    Widget? mainActionButton;
    bool isSuccess = false;
    
    if (isDriver) {
      switch (ride.status) {
        case 'accepted':
          message = l10n?.headingToPassenger ?? 'Mergi spre pasager.';
          mainActionButton = ElevatedButton(onPressed: _handleDriverArrived, child: Text(l10n?.iArrived ?? "Am ajuns"));
          break;
        case 'arrived':
          message = l10n?.waitingForPassenger ?? 'Așteaptă pasagerul.';
          mainActionButton = ElevatedButton.icon(
            onPressed: _handleStartRide,
            icon: const Icon(Icons.navigation, color: Colors.white, size: 18),
            label: Text(l10n?.startRide ?? "Începe Cursa"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
          );
          break;
        case 'in_progress':
          message = l10n?.rideInProgress ?? 'Cursă în desfășurare.';
          mainActionButton = Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              ElevatedButton.icon(
                onPressed: () { if (_destinationLocation != null) { final lat = _destinationLocation!.coordinates.lat; final lng = _destinationLocation!.coordinates.lng; _showNavigationOptions(lat.toDouble(), lng.toDouble()); } },
                icon: const Icon(Icons.navigation, color: Colors.white, size: 16),
                label: Text(l10n?.navigation ?? "Navigație"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), textStyle: const TextStyle(fontSize: 14)),
              ),
              ElevatedButton(
                onPressed: _handleEndRide,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), textStyle: const TextStyle(fontSize: 14)),
                child: Text(l10n?.endRide ?? "Termină Cursa"),
              ),
            ],
          );
          break;
        default:
          message = "Stare: ${ride.status}";
          mainActionButton = const SizedBox.shrink();
      }
    } else { // VIZUALIZARE PASAGER
      switch (ride.status) {
        case 'driver_found':
          message = l10n?.confirmDriver ?? 'Confirmă șoferul.';
          mainActionButton = Wrap(
            spacing: 8.0,
            children: [
              ElevatedButton(onPressed: () => _firestoreService.passengerConfirmDriver(ride.id), child: Text(l10n?.confirmButton ?? "Confirmă")),
              TextButton(onPressed: () => _firestoreService.passengerDeclineDriver(ride.id), child: Text(l10n?.declineButton ?? "Refuză")),
            ],
          );
          break;
        case 'accepted':
          message = l10n?.driverHeadingToYou ?? 'Șoferul vine spre tine...';
          break;
        case 'arrived':
          message = l10n?.driverArrived ?? 'Șoferul a sosit!';
          isSuccess = true;
          break;
        case 'in_progress':
          message = l10n?.rideInProgress ?? 'Călătorie plăcută!';
          break;
        default:
          message = 'Stare: ${ride.status}';
      }
    }
    
    final actionButtons = <Widget>[];
    if (mainActionButton != null) {
      actionButtons.add(mainActionButton);
    }
    if (!isDriver && ride.status == 'in_progress') {
       actionButtons.add(
         _isAddingStop
              ? const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator())
              : OutlinedButton.icon(
                  onPressed: _addStop,
                  icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                  label: Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context)!;
                      return Text(l10n.addStop);
                    },
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                  ),
                )
       );
    }
    
    // ✅ NOU: Real-Time ETA Widget
    final etaWidget = RealTimeETAWidget(
      ride: ride,
      driverLocation: _currentDriverLocation != null
          ? Point(coordinates: Position(_currentDriverLocation!.coordinates.lng, _currentDriverLocation!.coordinates.lat))
          : null,
      pickupLocation: ride.startLatitude != null && ride.startLongitude != null
          ? Point(coordinates: Position(ride.startLongitude!, ride.startLatitude!))
          : null,
      destinationLocation: ride.destinationLatitude != null && ride.destinationLongitude != null
          ? Point(coordinates: Position(ride.destinationLongitude!, ride.destinationLatitude!))
          : null,
      isDriver: isDriver,
    );
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(message, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isSuccess ? Colors.green : Theme.of(context).textTheme.bodyLarge?.color), maxLines: 3, overflow: TextOverflow.visible)),
            const SizedBox(width: 8),
            _buildInlineRealTimeTracking(ride, isDriver),
          ],
        ),
        // ✅ NOU: Real-Time ETA Widget
        if (ride.status == 'accepted' || ride.status == 'arrived' || ride.status == 'in_progress')
          etaWidget,
        const Divider(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: actionButtons,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (ride.status != 'driver_found') ...[
                  IconButton(onPressed: () => _callNumber(_otherUserPhone), icon: const Icon(Icons.call, color: Colors.blue), tooltip: l10n?.call ?? "Sună"),
                ],
                if (isDriver && ['accepted', 'arrived', 'in_progress'].contains(ride.status))
                  IconButton(onPressed: () => _handleCancelRide(widget.rideId, ride), icon: const Icon(Icons.cancel_outlined, color: Colors.red), tooltip: "Anulează"),
              ],
            )
          ],
        ),
      ],
    );
  }

  Widget _buildInlineRealTimeTracking(Ride ride, bool isDriver) {
    if (ride.driverId == null || _currentDriverLocation == null) return const SizedBox.shrink();
    
    final driverPos = _currentDriverLocation!;
    Point? targetLocation;

    if (ride.status == 'accepted' || ride.status == 'arrived') {
        targetLocation = _passengerLocation;
    } else if (ride.status == 'in_progress') {
        targetLocation = _destinationLocation;
    }

    if (targetLocation == null) return const SizedBox.shrink();

    final distance = _calculateDirectDistance(driverPos.coordinates.lat, driverPos.coordinates.lng, targetLocation.coordinates.lat, targetLocation.coordinates.lng);
    
    // CORECTAT: Folosim o viteză medie constantă
    const double averageSpeed = 40.0; // Viteza medie in km/h
    final estimatedTimeMinutes = (distance / averageSpeed * 60).round();

    return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text("${distance.toStringAsFixed(1)} km • ${formatTravelDuration(estimatedTimeMinutes)}", style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.w600), overflow: TextOverflow.visible, maxLines: 1),
        ],
    );
  }

  double _calculateDirectDistance(num lat1, num lon1, num lat2, num lon2) {
    const double earthRadius = 6371; // km
    final dLat = (lat2.toDouble() - lat1.toDouble()) * (math.pi / 180);
    final dLon = (lon2.toDouble() - lon1.toDouble()) * (math.pi / 180);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) + math.cos(lat1.toDouble() * math.pi / 180) * math.cos(lat2.toDouble() * math.pi / 180) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }
  


  bool _shouldShowDestinationEntranceChips(Ride ride) {
    if (_currentUserId != ride.driverId) return false;
    if (ride.status != 'in_progress') return false;
    if (_currentDriverLocation == null || _destinationLocation == null) return false;
    final meters = _calculateDirectDistance(
      _currentDriverLocation!.coordinates.lat,
      _currentDriverLocation!.coordinates.lng,
      _destinationLocation!.coordinates.lat,
      _destinationLocation!.coordinates.lng,
    ) * 1000.0;
    return meters <= 200.0; // show chips when close to destination
  }

  Future<void> _onSelectDestinationEntrance(String label) async {
    if (_destinationLocation == null) return;
    // Heuristic offset ~80m depending on label
    const double delta = 0.0008;
    double lat = _destinationLocation!.coordinates.lat.toDouble();
    double lng = _destinationLocation!.coordinates.lng.toDouble();
    switch (label) {
      case 'Nord':
        lat += delta;
        break;
      case 'Sud':
        lat -= delta;
        break;
      case 'Est':
        lng += delta;
        break;
      case 'Vest':
        lng -= delta;
        break;
    }
    final Point newDest = Point(coordinates: Position(lng, lat));
    setState(() {
      _destinationLocation = newDest;
    });
    await _recalculateRouteToCustomDestination(newDest);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context)!;
          return Text(l10n.entrySelectedWithLabel(label));
        },
      )), 
    );
  }

  Future<void> _recalculateRouteToCustomDestination(Point customDest) async {
    try {
      if (_currentDriverLocation == null) return;
      final driverPos = _currentDriverLocation!;
      final routeData = await _routingService.getRoute([driverPos, customDest]);
      if (!mounted || routeData == null) return;
      final steps = _navigationService.parseMapboxRoute(routeData);
      _navigationService.setNavigationSteps(steps);
      _routeGeoJSON = routeData;
      await _drawRouteOnMapOptimized(routeData);
    } catch (e) {
      Logger.error('Failed to recalc route to entrance: $e', error: e);
    }
  }

  void _editMessage(String messageId, String currentText) {
    final editController = TextEditingController(text: currentText);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return Text(l10n.editMessage);
          },
        ),
        content: TextField(
          controller: editController,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)?.writeNewText ?? 'Scrie noul text...',
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Text(l10n.cancel);
              },
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newText = editController.text.trim();
              
              if (newText.isNotEmpty && newText != currentText) {
                final navigator = Navigator.of(dialogContext);
                final scaffoldMessenger = ScaffoldMessenger.of(dialogContext);
                
                try {
                  await FirestoreService().editChatMessage(widget.rideId, messageId, newText);
                  
                  if (mounted) {
                    navigator.pop();
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context)!;
                            return Text(l10n.messageEditedSuccess);
                          },
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    navigator.pop();
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context)!;
                            return Text(l10n.errorEditingMessage(e.toString()));
                          },
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } else {
                Navigator.pop(dialogContext);
              }
            },
            child: Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return Text(l10n.save);
              },
            ),
          ),
        ],
      ),
    );
  }
  
}
