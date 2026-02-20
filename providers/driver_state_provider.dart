import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:friendsride_app/models/ride_model.dart';
import 'package:friendsride_app/services/firestore_service.dart';

/// Provider pentru gestionarea stării șoferului
/// Extrage logica de driver din map_screen.dart
class DriverStateProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  // Driver state
  bool _isDriverAvailable = false;
  Map<String, dynamic>? _driverProfile;
  RideCategory? _driverCategory;
  List<Ride> _pendingRides = [];
  Ride? _currentRideOffer;
  Timer? _rideOfferTimer;
  int _remainingSeconds = 30;

  // Subscriptions pentru cleanup
  StreamSubscription<List<Ride>>? _pendingRidesSubscription;
  StreamSubscription? _driverProfileSubscription;

  // Getters
  bool get isDriverAvailable => _isDriverAvailable;
  Map<String, dynamic>? get driverProfile => _driverProfile;
  RideCategory? get driverCategory => _driverCategory;
  List<Ride> get pendingRides => _pendingRides;
  Ride? get currentRideOffer => _currentRideOffer;
  int get remainingSeconds => _remainingSeconds;
  bool get hasActiveRideOffer => _currentRideOffer != null;

  /// Inițializează driver state și subscriptions
  Future<void> initializeDriverState(String? userId) async {
    if (userId == null) return;

    debugPrint('🚗 Initializing driver state...');

    try {
      // Încarcă profilul șoferului
      await _loadDriverProfile(userId);
      
      // Inițializează listening-ul pentru ride-uri
      _initializeDriverRideSystem();
      
      debugPrint('✅ Driver state initialized');
    } catch (e) {
      debugPrint('⚠️ Error initializing driver state: $e');
    }
  }

  /// Încarcă profilul șoferului din Firestore
  Future<void> _loadDriverProfile(String userId) async {
    try {
      _driverProfileSubscription?.cancel();
      _driverProfileSubscription = _firestoreService.getUserProfileStream().listen((snapshot) {
        if (snapshot.exists) {
          _driverProfile = snapshot.data();
          _driverCategory = _getCategoryFromProfile(_driverProfile!);
          debugPrint('✅ Driver profile loaded: ${_driverProfile?['displayName']}');
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('⚠️ Error loading driver profile: $e');
    }
  }

  /// Convertește category string la enum
  RideCategory _getCategoryFromProfile(Map<String, dynamic> profile) {
    final categoryStr = profile['driverCategory'] as String?;
    switch (categoryStr) {
      case 'standard': return RideCategory.standard;
      case 'energy': return RideCategory.energy;
      case 'best': return RideCategory.best;
      default: return RideCategory.standard;
    }
  }

  /// Inițializează sistemul de ascultare pentru ride-uri
  void _initializeDriverRideSystem() {
    if (_driverCategory == null) {
      debugPrint('⚠️ Cannot start ride system - no driver category');
      return;
    }

    debugPrint('🎧 Starting ride listening system for category: ${_driverCategory!.name}');
    
    _pendingRidesSubscription?.cancel();
    _pendingRidesSubscription = _firestoreService
        .getPendingRideRequests(_driverCategory!)
        .listen(_handleNewRideOffers);
  }

  /// Procesează ride offers noi
  void _handleNewRideOffers(List<Ride> rides) {
    _pendingRides = rides;
    
    if (_currentRideOffer == null && rides.isNotEmpty && _isDriverAvailable) {
      _showRideOffer(rides.first);
    }
    
    debugPrint('📋 Received ${rides.length} pending rides');
    notifyListeners();
  }

  /// Afișează o ofertă de cursă cu timer
  void _showRideOffer(Ride ride) {
    _currentRideOffer = ride;
    _remainingSeconds = 30;
    
    debugPrint('🔔 New ride offer: ${ride.id}');
    
    _rideOfferTimer?.cancel();
    _rideOfferTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSeconds--;
      notifyListeners();
      
      if (_remainingSeconds <= 0) {
        _declineRideOffer();
      }
    });
    
    notifyListeners();
  }

  /// Toggle driver availability
  Future<void> toggleDriverAvailability(bool value) async {
    if (_driverProfile == null) {
      debugPrint('⚠️ Cannot toggle availability - no driver profile');
      return;
    }

    debugPrint('🚗 Toggling driver availability to: $value');

    try {
      if (value) {
        await _firestoreService.updateDriverAvailability(
          true,
          displayName: _driverProfile!['displayName'],
          licensePlate: _driverProfile!['licensePlate'],
          category: _driverCategory!,
        );
        _initializeDriverRideSystem();
      } else {
        await _firestoreService.updateDriverAvailability(false);
        _stopListeningForRides();
      }
      
      _isDriverAvailable = value;
      notifyListeners();
      
      debugPrint('✅ Driver availability updated to: $value');
    } catch (e) {
      debugPrint('⚠️ Error updating driver availability: $e');
      // Revert state on error
      _isDriverAvailable = !value;
      notifyListeners();
      rethrow;
    }
  }

  /// Acceptă o ofertă de cursă
  Future<void> acceptRideOffer() async {
    if (_currentRideOffer == null) return;

    final ride = _currentRideOffer!;
    debugPrint('✅ Accepting ride offer: ${ride.id}');

    try {
      await _firestoreService.acceptRide(ride.id);
      _clearCurrentRideOffer();
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Error accepting ride: $e');
      rethrow;
    }
  }

  /// Refuză o ofertă de cursă
  Future<void> declineRideOffer() async {
    _declineRideOffer();
  }

  void _declineRideOffer() {
    if (_currentRideOffer == null) return;

    debugPrint('❌ Declining ride offer: ${_currentRideOffer!.id}');
    _clearCurrentRideOffer();
    
    // Caută următoarea cursă disponibilă
    if (_pendingRides.length > 1) {
      final nextRide = _pendingRides.skip(1).first;
      _showRideOffer(nextRide);
    }
    
    notifyListeners();
  }

  /// Șterge oferta curentă și oprește timer-ul
  void _clearCurrentRideOffer() {
    _rideOfferTimer?.cancel();
    _rideOfferTimer = null;
    _currentRideOffer = null;
    _remainingSeconds = 30;
  }

  /// Oprește ascultarea pentru ride-uri
  void _stopListeningForRides() {
    _pendingRidesSubscription?.cancel();
    _pendingRidesSubscription = null;
    _clearCurrentRideOffer();
    _pendingRides.clear();
    debugPrint('🔇 Stopped listening for rides');
  }

  /// Cleanup la dispose
  @override
  void dispose() {
    debugPrint('🧹 Disposing DriverStateProvider');
    
    // Cancel all timers
    _rideOfferTimer?.cancel();
    
    // Cancel all subscriptions
    _stopListeningForRides();
    _driverProfileSubscription?.cancel();
    
    super.dispose();
  }
}
