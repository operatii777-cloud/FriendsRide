import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:friendsride_app/models/ride_model.dart';
import 'package:friendsride_app/services/firestore_service.dart';
// ✅ IMPORT NOU: Necesar pentru navigația corectă
import 'package:friendsride_app/screens/active_ride_screen.dart';
import 'package:friendsride_app/screens/map_screen.dart';
import 'package:friendsride_app/screens/ride_summary_screen.dart'; 

class SearchingForDriverScreen extends StatefulWidget {
  final String rideId;

  const SearchingForDriverScreen({
    super.key,
    required this.rideId,
  });

  @override
  State<SearchingForDriverScreen> createState() => _SearchingForDriverScreenState();
}

class _SearchingForDriverScreenState extends State<SearchingForDriverScreen>
    with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription<Ride>? _rideSubscription;
  Timer? _searchTimeoutTimer;
  Timer? _confirmationTimeoutTimer;

  // Animation Controllers
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  
  // Animations
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  String _statusMessage = 'Se caută șoferi în apropiere...';
  bool _isSearching = true;
  
  // ✅ DEFENSIVE PROGRAMMING: Operation lock pentru a preveni multiple operations
  bool _isOperationInProgress = false;
  
  // ✅ FIX: Adaugă variabila _isLoading care lipsea
  bool _isLoading = false;

  String? _foundDriverDisplayName;
  String? _foundDriverLicensePlate;
  String? _foundDriverCategory;
  double? _foundDriverRating;
  String? _foundDriverId;

  @override
  void initState() {
    super.initState();
    debugPrint('🔍 SearchingForDriverScreen created with rideId: ${widget.rideId}');
    debugPrint('🔍 SearchingForDriverScreen initState');
    
    _initializeAnimations();
    _startMonitoringRideStatus();
    _searchTimeoutTimer = Timer(const Duration(minutes: 1), _handleSearchTimeout);
  }

  void _initializeAnimations() {
    const mediumAnimation = Duration(milliseconds: 500);
    // Pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Rotation animation
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    // Slide animation
    _slideController = AnimationController(
      duration: mediumAnimation,
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    // Fade animation
    _fadeController = AnimationController(
      duration: mediumAnimation,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    // Start animations
    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
    _fadeController.forward();
  }

  void _startMonitoringRideStatus() {
    debugPrint('🔍 [SEARCHING] Starting ride status monitoring for ride: ${widget.rideId}');
    _rideSubscription = _firestoreService.getRideStream(widget.rideId).listen((ride) async {
      debugPrint('🔍 [SEARCHING] Ride status updated to: ${ride.status} for ride: ${ride.id}');

      if (!mounted) {
        _rideSubscription?.cancel();
        return;
      }

      switch (ride.status) {
        case 'pending':
          if (!_isSearching) {
            setState(() {
              _statusMessage = 'Se caută șoferi în apropiere...';
              _isSearching = true;
              _foundDriverDisplayName = null;
              _searchTimeoutTimer?.cancel();
              _searchTimeoutTimer = Timer(const Duration(minutes: 1), _handleSearchTimeout);
            });
            _startSearchAnimations();
          }
          _confirmationTimeoutTimer?.cancel();
          break;

        case 'driver_found':
          debugPrint('🎯 [SEARCHING] Driver found for ride ${ride.id} - Driver ID: ${ride.driverId}');
          _searchTimeoutTimer?.cancel();
          _stopSearchAnimations();
          
          if (_confirmationTimeoutTimer == null || !_confirmationTimeoutTimer!.isActive) {
            _confirmationTimeoutTimer = Timer(const Duration(minutes: 2), _handleConfirmationTimeout);
            debugPrint('⏰ [SEARCHING] Confirmation timer started - 2 minutes');
          }

          setState(() {
            _isSearching = false;
            _statusMessage = 'Șofer găsit! Așteaptă confirmarea ta.';
            _foundDriverId = ride.driverId;
          });
          
          debugPrint('✅ [SEARCHING] UI updated - Driver found message displayed');

          _slideController.forward();

          if (ride.driverId != null) {
            final driverProfileSnapshot = await _firestoreService.getProfileByIdStream(ride.driverId!).first;
            if (!mounted) return;
            final driverData = driverProfileSnapshot.data();
            if (driverData != null) {
              setState(() {
                _foundDriverDisplayName = driverData['displayName'] ?? 'N/A';
                _foundDriverLicensePlate = driverData['licensePlate'] ?? 'N/A';
                _foundDriverCategory = driverData['driverCategory'] ?? 'Standard';
                _foundDriverRating = (driverData['averageRating'] as num?)?.toDouble();
              });
            }
          }
          break;

        // ==========================================================
        // AICI ESTE MODIFICAREA CHEIE
        // ==========================================================
        case 'accepted':
        case 'arrived':
        case 'in_progress':
          _searchTimeoutTimer?.cancel();
          _confirmationTimeoutTimer?.cancel();
          if (mounted) {
            // Înlocuim ecranul curent direct cu ecranul cursei active
            // Aceasta este o tranziție sigură și previne ecranul negru
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => ActiveRideScreen(rideId: ride.id)),
            );
          }
          break;
        // ==========================================================
        
        case 'completed':
          // ✅ FIX: Navighează la RideSummaryScreen pentru evaluare (caz rar când cursa se completează înainte de a ajunge la ActiveRideScreen)
          _searchTimeoutTimer?.cancel();
          _confirmationTimeoutTimer?.cancel();
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => RideSummaryScreen(rideId: ride.id)),
            );
          }
          break;

        case 'cancelled':
        case 'expired':
          _searchTimeoutTimer?.cancel();
          _confirmationTimeoutTimer?.cancel();
          if (mounted) {
            setState(() {
              _statusMessage = ride.status == 'cancelled' 
                  ? 'Cursa a fost anulată.' 
                  : 'Ne pare rău, niciun șofer nu a fost disponibil.';
              _isSearching = false;
              _foundDriverDisplayName = null;
            });
            _stopSearchAnimations();
          }
          break;
        
        default:
          if (mounted) {
            setState(() {
              _statusMessage = 'Stare cursă necunoscută: ${ride.status}';
              _isSearching = false;
            });
            _stopSearchAnimations();
          }
          break;
      }
    }, onError: (error) {
      debugPrint('Error listening to ride stream: $error');
      if (mounted) {
        setState(() {
          _statusMessage = 'Eroare la monitorizarea cursei.';
          _isSearching = false;
        });
        _stopSearchAnimations();
      }
    });
  }

  void _startSearchAnimations() {
    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
  }

  void _stopSearchAnimations() {
    _pulseController.stop();
    _rotationController.stop();
  }

  @override
  void dispose() {
    debugPrint('🧹 SearchingForDriverScreen dispose - cleaning up');
    
    // ✅ DEFENSIVE PROGRAMMING: Cancel toate operațiunile active
    _rideSubscription?.cancel();
    _searchTimeoutTimer?.cancel();
    _confirmationTimeoutTimer?.cancel();
    
    // ✅ DEFENSIVE PROGRAMMING: Dispose toate animațiile
    _pulseController.dispose();
    _rotationController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    
    // ✅ DEFENSIVE PROGRAMMING: Reset operation lock
    _isOperationInProgress = false;
    
    super.dispose();
  }

  /// ✅ DEFENSIVE PROGRAMMING: Safe search timeout handling
  void _handleSearchTimeout() async {
    if (!mounted || !_isSearching) return;
    
    try {
      debugPrint('⏰ Search timeout triggered - updating ride status');
      
      // ✅ TIMEOUT PROTECTION pentru Firestore operation
      final currentRide = await _firestoreService.getRideStream(widget.rideId)
          .first
          .timeout(Duration(seconds: 10));
      
      if (!mounted) return;
      
      if (currentRide.status == 'pending') {
        // ✅ TIMEOUT PROTECTION pentru update operation
        await _firestoreService.updateRideStatus(widget.rideId, 'expired')
            .timeout(Duration(seconds: 10));
        
        debugPrint('✅ Ride status updated to expired');
      }
    } catch (e) {
      debugPrint('🚨 Error handling search timeout: $e');
      // Nu facem nimic la eroare - doar log
    }
  }

  /// ✅ DEFENSIVE PROGRAMMING: Safe confirmation timeout handling
  void _handleConfirmationTimeout() async {
    if (!mounted) return;
    
    try {
      debugPrint('⏰ [TIMEOUT] Confirmation timeout triggered after 2 minutes - declining driver');
      
      // ✅ TIMEOUT PROTECTION pentru Firestore operation
      final currentRide = await _firestoreService.getRideStream(widget.rideId)
          .first
          .timeout(Duration(seconds: 10));
      
      if (!mounted) return;
      
      if (currentRide.status == 'driver_found') {
        debugPrint('⏰ [TIMEOUT] Ride still in driver_found status - declining driver automatically');
        // ✅ TIMEOUT PROTECTION pentru decline operation
        await _firestoreService.passengerDeclineDriver(widget.rideId)
            .timeout(Duration(seconds: 10));
        
        debugPrint('✅ [TIMEOUT] Driver declined due to timeout - resuming search');
      } else {
        debugPrint('⏰ [TIMEOUT] Ride status changed to ${currentRide.status} - no action needed');
      }
    } catch (e) {
      debugPrint('🚨 [TIMEOUT] Error handling confirmation timeout: $e');
      // Nu facem nimic la eroare - doar log
    }
  }

  /// ✅ DEFENSIVE PROGRAMMING: Safe driver confirmation
  void _confirmDriver() async {
    if (_foundDriverId != null && mounted) {
      try {
        debugPrint('✅ Passenger confirming ride ${widget.rideId}');
        
        // Cancel confirmation timeout
        _confirmationTimeoutTimer?.cancel();
        
        // ✅ TIMEOUT PROTECTION pentru confirmation operation
        await _firestoreService.passengerConfirmDriver(widget.rideId)
            .timeout(Duration(seconds: 10));
        
        debugPrint('✅ Driver confirmed successfully');
      } catch (e) {
        debugPrint('🚨 Error confirming driver: $e');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Eroare la confirmarea șoferului: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// ✅ DEFENSIVE PROGRAMMING: Safe driver decline
  void _declineDriver() async {
    if (_foundDriverId != null && mounted) {
      try {
        debugPrint('❌ Passenger declining driver for ride ${widget.rideId}');
        
        // Cancel confirmation timeout
        _confirmationTimeoutTimer?.cancel();
        
        // ✅ TIMEOUT PROTECTION pentru decline operation
        await _firestoreService.passengerDeclineDriver(widget.rideId)
            .timeout(Duration(seconds: 10));
        
        if (mounted) {
          setState(() {
            _foundDriverDisplayName = null;
            _statusMessage = 'Ai refuzat șoferul. Se reia căutarea...';
            _isSearching = true;
            _searchTimeoutTimer?.cancel();
            _searchTimeoutTimer = Timer(const Duration(minutes: 1), _handleSearchTimeout);
          });
          _slideController.reset();
          _startSearchAnimations();
        }
        
        debugPrint('✅ Driver declined successfully');
      } catch (e) {
        debugPrint('🚨 Error declining driver: $e');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Eroare la refuzarea șoferului: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// ✅ DEFENSIVE PROGRAMMING: Safe ride cancellation with proper navigation
  Future<void> _cancelRideEarly() async {
    // 1. VALIDATION
    if (!mounted) return;
    if (_isOperationInProgress) return;
    
    try {
      // 2. LOCK
      _isOperationInProgress = true;
      
      debugPrint('🚫 User pressed cancel - starting cleanup...');
      
      // 3. TIMEOUT PROTECTION pentru Firestore operation
      await _firestoreService.cancelRide(widget.rideId)
          .timeout(Duration(seconds: 10));
      
      if (!mounted) return;
      
      // 4. Cancel toate timer-ele și stream-urile
      _searchTimeoutTimer?.cancel();
      _confirmationTimeoutTimer?.cancel();
      _rideSubscription?.cancel();
      
      // 5. Stop toate animațiile
      _stopSearchAnimations();
      
      debugPrint('🚫 Cancel completed - navigating to MapScreen');
      
      // 6. Safe navigation cu pushAndRemoveUntil pentru clean stack
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MapScreen()),
          (route) => false, // Remove toate route-urile anterioare
        );
      }
      
    } catch (e) {
      debugPrint('🚨 Error cancelling search: $e');
      
      // 7. ERROR HANDLING - Fallback navigation chiar și la eroare
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la anulare: $e'),
            backgroundColor: Colors.red,
          ),
        );
        
        // Forțează navigarea înapoi
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MapScreen()),
          (route) => false,
        );
      }
    } finally {
      // 8. CLEANUP
      _isOperationInProgress = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                if (_isSearching)
                  Align(
                    alignment: Alignment.topLeft,
                    child: _buildCancelButton(),
                  ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_foundDriverDisplayName != null && !_isSearching) 
                        _buildDriverFoundContent()
                      else if (_isSearching) 
                        _buildSearchingContent()
                      else 
                        _buildErrorContent(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ✅ DEFENSIVE PROGRAMMING: Safe cancel button cu loading state
  Widget _buildCancelButton() {
    final theme = Theme.of(context);
    return TextButton.icon(
      onPressed: _isOperationInProgress || _isLoading ? null : () async {
        // ✅ PREVENIRE: Prevent multiple taps
        if (_isOperationInProgress) return;
        
        debugPrint('🚫 Cancel button pressed - starting operation...');
        
        // ✅ DEFENSIVE PROGRAMMING: Set loading state
        setState(() {
          _isLoading = true;
        });
        
        // ✅ DEFENSIVE PROGRAMMING: Safe operation execution
        await _cancelRideEarly();
        
        // Nu mai setez _isLoading = false pentru că widget-ul se dispose
      },
      icon: Icon(
        Icons.close_rounded,
        color: theme.colorScheme.error,
        size: 20,
      ),
      label: Text(
        _isOperationInProgress || _isLoading ? 'Se anulează...' : 'Anulează',
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.error,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        backgroundColor: theme.colorScheme.error.withAlpha((255 * 0.1).round()),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0)
        )
      ),
    );
  }

  Widget _buildSearchingContent() {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSearchAnimation(),
        const SizedBox(height: 48.0),
        Text(
          _statusMessage,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16.0),
        Text(
          'Căutăm cel mai apropiat șofer disponibil pentru tine',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32.0),
      ],
    );
  }

  Widget _buildSearchAnimation() {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.colorScheme.primary.withAlpha((255 * 0.1).round()),
                      theme.colorScheme.primary.withAlpha((255 * 0.05).round()),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _rotationAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationAnimation.value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withAlpha((255 * 0.4).round()),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.search_rounded,
                      color: theme.colorScheme.onPrimary,
                      size: 40,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDriverFoundContent() {
    final theme = Theme.of(context);
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withAlpha((255 * 0.3).round()),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 16.0),
          Text(
            _statusMessage,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24.0),
          _buildDriverCard(),
          const SizedBox(height: 24.0),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildDriverCard() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withAlpha((255 * 0.1).round()),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.primary.withAlpha((255 * 0.1).round()),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: theme.colorScheme.primary,
            child: Icon(
              Icons.person_rounded,
              color: theme.colorScheme.onPrimary,
              size: 32,
            ),
          ),
          const SizedBox(height: 16.0),
          Text(
            _foundDriverDisplayName ?? 'N/A',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8.0),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              _foundDriverLicensePlate ?? 'N/A',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDetailItem(
                icon: Icons.directions_car_rounded,
                label: 'Categorie',
                value: _foundDriverCategory ?? 'Standard',
                color: theme.colorScheme.primary,
              ),
              if (_foundDriverRating != null)
                _buildDetailItem(
                  icon: Icons.star_rounded,
                  label: 'Rating',
                  value: '${_foundDriverRating!.toStringAsFixed(1)}/5.0',
                  color: Colors.amber,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: color.withAlpha((255 * 0.1).round()),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _declineDriver,
            icon: const Icon(Icons.close_rounded, size: 20),
            label: const Text('Refuză'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            ),
          ),
        ),
        const SizedBox(width: 16.0),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _confirmDriver,
            icon: const Icon(Icons.check_rounded, size: 20),
            label: const Text('Confirmă Șoferul'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorContent() {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.sentiment_dissatisfied_rounded,
          color: theme.colorScheme.error,
          size: 64,
        ),
        const SizedBox(height: 16.0),
        Text(
          _statusMessage,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 24.0),
        ElevatedButton.icon(
          onPressed: () async {
            debugPrint('🔄 User pressed back to map from error state');
            
            // ✅ DEFENSIVE PROGRAMMING: Safe navigation cu cleanup
            try {
              // Cancel toate operațiunile active
              _searchTimeoutTimer?.cancel();
              _confirmationTimeoutTimer?.cancel();
              _rideSubscription?.cancel();
              _stopSearchAnimations();
              
              if (mounted) {
                // Safe navigation cu pushAndRemoveUntil
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const MapScreen()),
                  (route) => false,
                );
              }
            } catch (e) {
              debugPrint('🚨 Error navigating back: $e');
              // Fallback navigation
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const MapScreen()),
                  (route) => false,
                );
              }
            }
          },
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          label: const Text('Înapoi la Hartă'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
          ),
        ),
      ],
    );
  }
}