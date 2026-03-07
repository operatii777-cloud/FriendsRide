import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:friendsride_app/models/ride_model.dart';
import 'package:friendsride_app/screens/driver_ride_details_screen.dart';
import 'package:friendsride_app/screens/driver_incentives_screen.dart';
import 'package:friendsride_app/screens/map_screen.dart';
import 'package:friendsride_app/services/firestore_service.dart';
import 'package:friendsride_app/services/pdf_receipt_service.dart';
import 'package:friendsride_app/widgets/driver_achievements_widget.dart';
import 'package:friendsride_app/widgets/driver_incentives_list_widget.dart';
import 'package:friendsride_app/services/driver_incentives_service.dart';
import 'package:friendsride_app/models/driver_incentive_model.dart';
import 'package:friendsride_app/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:friendsride_app/utils/logger.dart';

// Enum pentru a gestiona starea filtrului listei
enum DriverListFilter { all, today }

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final PdfReceiptService _pdfService = PdfReceiptService();

  double _earningsToday = 0.0;
  int _ridesToday = 0;
  String _averageRating = "N/A";
  bool _isGeneratingDailyReport = false;

  // Stări pentru a gestiona filtrarea și afișarea listei
  DriverListFilter _activeFilter = DriverListFilter.all;
  List<Ride> _allRides = []; // Stocăm toate cursele aici pentru a le putea filtra rapid

  // 🚀 DOAR PENTRU CURSA ACTIVĂ (Cursele în așteptare sunt acum pe hartă)
  Ride? _activeRide;
  StreamSubscription? _activeRideSubscription;
  StreamSubscription? _ridesHistorySubscription;
  bool _isDriverAvailable = false;
  
  // ✅ NOU: Incentives
  final DriverIncentivesService _incentivesService = DriverIncentivesService();
  List<DriverIncentive> _incentives = [];
  StreamSubscription? _incentivesSubscription;

  @override
  void initState() {
    super.initState();
    
    // Ascultăm la stream-ul de curse finalizate
    _ridesHistorySubscription = _firestoreService.getDriverRidesHistory().listen((rides) {
      if (mounted) {
        setState(() {
          _allRides = rides;
          _calculateStats(rides);
        });
      }
    });

    // 🚀 INIȚIALIZĂM DOAR SISTEMUL PENTRU CURSA ACTIVĂ
    _initializeDriverSystem();
    
    // ✅ NOU: Încarcă incentives
    _loadIncentives();
  }
  
  // ✅ NOU: Încarcă incentives pentru șofer
  void _loadIncentives() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    _incentivesSubscription?.cancel();
    _incentivesSubscription = _incentivesService
        .getDriverIncentivesStream(userId)
        .listen(
          (incentives) {
            if (mounted) {
              setState(() {
                _incentives = incentives;
              });
            }
          },
          onError: (error) {
            Logger.error('Error loading incentives: $error', tag: 'DASHBOARD', error: error);
            // Nu facem crash - doar logăm eroarea și continuăm cu lista goală
            if (mounted) {
              setState(() {
                _incentives = [];
              });
            }
          },
        );
  }

  @override
  void dispose() {
    _activeRideSubscription?.cancel();
    _ridesHistorySubscription?.cancel();
    _incentivesSubscription?.cancel();
    super.dispose();
  }

  // 🚀 FUNCȚIE SIMPLIFICATĂ - Doar pentru cursa activă
  Future<void> _initializeDriverSystem() async {
    try {
      // Verificăm disponibilitatea
      _isDriverAvailable = await _firestoreService.getDriverAvailability();
      
      // Ascultăm doar pentru cursa activă
      _listenForActiveRide();
      
      if (mounted) setState(() {});
    } catch (e) {
      Logger.error('Error initializing driver system: $e', tag: 'DASHBOARD', error: e);
    }
  }

  // 🚀 FUNCȚIE PĂSTRATĂ - Ascultă pentru cursa activă
  void _listenForActiveRide() {
    _activeRideSubscription?.cancel();
    _activeRideSubscription = _firestoreService
        .getActiveDriverRideStream()
        .listen(
          (ride) {
            Logger.debug('Active ride status: ${ride?.status}', tag: 'DASHBOARD');
            if (mounted) {
              setState(() {
                _activeRide = ride;
              });
            }
          },
          onError: (error) {
            Logger.error('Error listening for active ride: $error', tag: 'DASHBOARD', error: error);
            // Nu facem crash - doar logăm eroarea și continuăm cu null
            if (mounted) {
              setState(() {
                _activeRide = null;
              });
            }
          },
        );
  }

  void _calculateStats(List<Ride> rides) {
    double tempEarnings = 0.0;
    int tempRidesCount = 0;
    double totalRating = 0;
    int ratingCount = 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var ride in rides) {
      final rideDate = DateTime(ride.timestamp.year, ride.timestamp.month, ride.timestamp.day);

      if (rideDate.isAtSameMomentAs(today)) {
        tempEarnings += ride.driverEarnings;
        tempRidesCount++;
      }

      if (ride.passengerRating != null) {
        totalRating += ride.passengerRating!;
        ratingCount++;
      }
    }

    if (mounted) {
      setState(() {
        _earningsToday = tempEarnings;
        _ridesToday = tempRidesCount;
        if (ratingCount > 0) {
          _averageRating = (totalRating / ratingCount).toStringAsFixed(2);
        }
      });
    }
  }

  Future<void> _generateDailyReport() async {
    setState(() {
      _isGeneratingDailyReport = true;
    });

    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final todayRides = _allRides.where((ride) {
        return ride.timestamp.isAfter(startOfDay) && ride.timestamp.isBefore(endOfDay);
      }).toList();

      final l10n = AppLocalizations.of(context)!;
      
      if (todayRides.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.noRidesTodayForReport),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final pdfBytes = await _pdfService.generateDailyDriverReport(todayRides);
      final dateString = DateFormat('dd_MMMM_yyyy', 'ro_RO').format(today);
      
      await Printing.sharePdf(
        bytes: pdfBytes, 
        filename: 'raport_zilnic_sofer_$dateString.pdf'
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.dailyReportGeneratedSuccess.split('.')[0]}!'),
            backgroundColor: Colors.green,
          ),
        );
        _showReturnToMapDialog();
      }

    } catch (e) {
      if (mounted) {
        final l10nError = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10nError.errorGeneratingReport(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingDailyReport = false;
        });
      }
    }
  }

  void _showReturnToMapDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l10n.reportGenerated),
        content: Text(l10n.dailyReportGeneratedSuccess),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.stayHere),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MapScreen()),
                (Route<dynamic> route) => false,
              );
            },
            child: Text(l10n.goToMap),
          ),
        ],
      ),
    );
  }

  List<Ride> _getFilteredRides() {
    if (_activeFilter == DriverListFilter.today) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      return _allRides.where((ride) {
        final rideDate = DateTime(ride.timestamp.year, ride.timestamp.month, ride.timestamp.day);
        return rideDate.isAtSameMomentAs(today);
      }).toList();
    }
    return _allRides;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filteredRides = _getFilteredRides();
    final listTitle = _activeFilter == DriverListFilter.today 
        ? l10n.completedRidesToday 
        : l10n.lastCompletedRides;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.driverDashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            tooltip: l10n.goToMap,
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MapScreen()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                l10n.driverOptions,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: Text(l10n.goToMap),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MapScreen()),
                );
              },
            ),
            ListTile(
              leading: _isGeneratingDailyReport 
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.today_outlined, color: Colors.green),
              title: Text(_isGeneratingDailyReport ? l10n.generatingReport : l10n.generateDailyReport),
              onTap: _isGeneratingDailyReport ? null : () {
                Navigator.pop(context);
                _generateDailyReport();
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildStatsSection(),
            const Divider(height: 1),
            
            // 🚀 SECȚIUNEA SIMPLIFICATĂ - Doar cursa activă sau status offline
            if (_activeRide != null)
              _buildActiveRideSection()
            else if (!_isDriverAvailable)
              _buildDriverOfflineSection()
            else
              _buildDriverOnlineSection(),
            
            const Divider(height: 1),
            
            // ✅ NOU: Tabel câștiguri pe săptămână
            if (_allRides.isNotEmpty) ...[
              _buildWeeklyEarningsTable(),
            ],
            
            // ✅ NOU: Achievements
            if (_allRides.isNotEmpty) ...[
              DriverAchievementsWidget(
                rides: _allRides,
                averageRating: double.tryParse(_averageRating) ?? 0.0,
              ),
            ],
            
            // ✅ NOU: Incentives cu link către ecranul dedicat
            DriverIncentivesListWidget(
              incentives: _incentives,
              onIncentiveTap: (incentive) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DriverIncentivesScreen(),
                  ),
                );
              },
            ),
            
              Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    listTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (_activeFilter != DriverListFilter.all)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _activeFilter = DriverListFilter.all;
                        });
                      },
                      child: Text(l10n.showAll),
                    )
                ],
              ),
            ),
            if (filteredRides.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(child: Text(l10n.noRidesMatchFilter)),
              )
            else
              ...filteredRides.take(10).map((ride) {
                return ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text('${l10n.to} ${ride.destinationAddress}'),
                  subtitle: Text(DateFormat('dd MMM, HH:mm').format(ride.timestamp)),
                  trailing: Text(
                    '${ride.driverEarnings.toStringAsFixed(2)} RON',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DriverRideDetailsScreen(ride: ride),
                      ),
                    );
                  },
                );
              }),
            if (filteredRides.length > 10)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: () {
                    // Navigate to full history screen - to be implemented
                  },
                  child: Text('Vezi toate ${filteredRides.length} curse'),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // 🚀 WIDGET PĂSTRAT - Afișează cursa activă
  Widget _buildActiveRideSection() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.drive_eta, color: Colors.blue.shade700, size: 24),
              const SizedBox(width: 8),
              Text(
                l10n.activeRide,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${l10n.destination} ${_activeRide!.destinationAddress}',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Status: ${_getRideStatusText(_activeRide!.status, l10n)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DriverRideDetailsScreen(ride: _activeRide!),
                ),
              );
            },
            icon: const Icon(Icons.visibility),
            label: Text(l10n.viewDetails),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // 🚀 WIDGET PĂSTRAT - Șofer offline
  Widget _buildDriverOfflineSection() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(Icons.pause_circle_outline, color: Colors.grey.shade600, size: 48),
          const SizedBox(height: 12),
          Text(
            l10n.driverModeDeactivated,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.goToMapAndActivate,
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MapScreen()),
              );
            },
            icon: const Icon(Icons.map),
            label: Text(l10n.goToMap),
          ),
        ],
      ),
    );
  }

  // 🚀 WIDGET NOU - Șofer online, fără cursă activă
  Widget _buildDriverOnlineSection() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade700, size: 48),
          const SizedBox(height: 12),
          Text(
            l10n.youAreAvailable,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.newRidesWillAppear,
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MapScreen()),
              );
            },
            icon: const Icon(Icons.map),
            label: Text(l10n.goToMap),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // 🚀 FUNCȚIE HELPER PĂSTRATĂ - Convertește status-ul în text citibil
  String _getRideStatusText(String status, AppLocalizations l10n) {
    switch (status) {
      case 'driver_found': return l10n.waitingForPassengerConfirmation;
      case 'accepted': return l10n.confirmedGoToPassenger;
      case 'arrived': return l10n.driverArrived;
      case 'in_progress': return l10n.rideInProgress;
      default: return status;
    }
  }

  Widget _buildStatsSection() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard(
            l10n.earningsTodayShort,
            '${_earningsToday.toStringAsFixed(2)} RON',
            Icons.account_balance_wallet_outlined,
            onTap: () {
              setState(() {
                _activeFilter = DriverListFilter.today;
              });
            },
          ),
          _buildStatCard(
            l10n.ridesTodayShort,
            _ridesToday.toString(),
            Icons.drive_eta_outlined,
            onTap: () {
              setState(() {
                _activeFilter = DriverListFilter.today;
              });
            },
          ),
          _buildStatCard(l10n.averageRatingShort, _averageRating, Icons.star_border_outlined),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, {VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Icon(icon, size: 30, color: Colors.blue),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyEarningsTable() {
    final weeklyEarnings = _calculateWeeklyEarnings();
    
    if (weeklyEarnings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.1).round()),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: Colors.green,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Câștiguri pe Săptămână',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withAlpha((255 * 0.3).round()),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      'Zi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      'Câștig',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              ...weeklyEarnings.entries.map((entry) {
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        '${entry.value.toStringAsFixed(2)} RON',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withAlpha((255 * 0.2).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total săptămână:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  '${weeklyEarnings.values.fold(0.0, (sum, value) => sum + value).toStringAsFixed(2)} RON',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, double> _calculateWeeklyEarnings() {
    final Map<String, double> weeklyData = {};
    final now = DateTime.now();
    final daysSinceMonday = now.weekday - 1;
    final monday = now.subtract(Duration(days: daysSinceMonday));
    
    // Inițializează toate zilele săptămânii cu 0
    final daysOfWeek = ['Luni', 'Marți', 'Miercuri', 'Joi', 'Vineri', 'Sâmbătă', 'Duminică'];
    for (int i = 0; i < 7; i++) {
      final dayName = daysOfWeek[i];
      weeklyData[dayName] = 0.0;
    }
    
    // Calculează câștigurile pentru fiecare zi
    for (var ride in _allRides) {
      final rideDate = DateTime(ride.timestamp.year, ride.timestamp.month, ride.timestamp.day);
      final daysDiff = rideDate.difference(monday).inDays;
      
      if (daysDiff >= 0 && daysDiff < 7) {
        final dayName = daysOfWeek[daysDiff];
        weeklyData[dayName] = (weeklyData[dayName] ?? 0.0) + ride.driverEarnings;
      }
    }
    
    return weeklyData;
  }
}