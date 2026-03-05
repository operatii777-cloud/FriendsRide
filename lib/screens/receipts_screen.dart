import 'package:flutter/material.dart';
import 'package:friendsride_app/models/ride_model.dart';
import 'package:friendsride_app/screens/receipt_details_screen.dart';
import 'package:friendsride_app/screens/map_screen.dart';
import 'package:friendsride_app/services/firestore_service.dart';
import 'package:friendsride_app/services/pdf_receipt_service.dart';
import 'package:friendsride_app/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:friendsride_app/utils/logger.dart';

class ReceiptsScreen extends StatefulWidget {
  const ReceiptsScreen({super.key});

  @override
  State<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends State<ReceiptsScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final PdfReceiptService _pdfService = PdfReceiptService();
  DateFilter _selectedFilter = DateFilter.all;
  
  bool _isSelectionMode = false;
  final Set<String> _selectedRideIds = <String>{};
  bool _isGeneratingReport = false;
  bool _isDeletingRides = false;
  
  UserRole? _userRole;
  bool _isLoadingRole = true;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _fetchUserRole() async {
    try {
      final role = await _firestoreService.getUserRole();
      if (mounted) {
        setState(() {
          _userRole = role;
          _isLoadingRole = false;
          if (role == UserRole.driver) {
            _tabController = TabController(length: 2, vsync: this);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRole = false);
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorLoadingRole(e.toString())))
        );
      }
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedRideIds.clear();
      }
    });
  }

  void _toggleRideSelection(String rideId) {
    setState(() {
      if (_selectedRideIds.contains(rideId)) {
        _selectedRideIds.remove(rideId);
      } else {
        _selectedRideIds.add(rideId);
      }
    });
  }

  void _selectAllRides(List<Ride> rides) {
    setState(() {
      if (_selectedRideIds.length == rides.length) {
        _selectedRideIds.clear();
      } else {
        _selectedRideIds.clear();
        _selectedRideIds.addAll(rides.map((ride) => ride.id));
      }
    });
  }

  Future<void> _deleteSelectedRides() async {
    if (_selectedRideIds.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await _showDeleteConfirmationDialog(
      l10n.deleteSelectedReceipts(_selectedRideIds.length),
      l10n.deleteSelectedReceiptsWarning,
    );

    if (confirmed != true) return;

    setState(() => _isDeletingRides = true);

    int deletedCount = 0;
    int errorCount = 0;

    for (final rideId in _selectedRideIds) {
      try {
        await _firestoreService.deleteRide(rideId);
        if (!mounted) return;
        deletedCount++;
      } catch (e) {
        if (!mounted) return;
        errorCount++;
        Logger.error('Error deleting ride $rideId: $e', error: e);
      }
    }

    if (!mounted) return;
    
    String message;
    Color backgroundColor;
    if (errorCount == 0) {
      message = l10n.receiptsDeletedSuccess(deletedCount);
      backgroundColor = Colors.green;
    } else {
      message = l10n.receiptsDeletedPartial(deletedCount, errorCount);
      backgroundColor = Colors.orange;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
    _toggleSelectionMode();
    
    if (mounted) setState(() => _isDeletingRides = false);
  }

  Future<void> _deleteAllRides(List<Ride> rides) async {
    if (rides.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await _showDeleteConfirmationDialog(
      l10n.deleteAllReceipts(rides.length),
      l10n.deleteAllReceiptsWarning,
    );

    if (confirmed != true) return;
    
    setState(() => _isDeletingRides = true);

    int deletedCount = 0;
    for (final ride in rides) {
      try {
        await _firestoreService.deleteRide(ride.id);
        if (!mounted) return;
        deletedCount++;
      } catch (e) {
        if (!mounted) return;
        // Ignorăm erorile individuale
      }
    }

    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.allReceiptsDeleted(deletedCount)), backgroundColor: Colors.green),
    );
    
    if (mounted) setState(() => _isDeletingRides = false);
  }

  Future<bool?> _showDeleteConfirmationDialog(String title, String content) async {
    final l10n = AppLocalizations.of(context)!;
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _generateMonthlyReport({required bool isDriver}) async {
    setState(() => _isGeneratingReport = true);
    
    try {
      final monthlyRides = await _getMonthlyRides(isDriver: isDriver);

      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      
      if (monthlyRides.isEmpty) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(l10n.noRidesForReport),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final pdfBytes = await _pdfService.generateMonthlyReport(monthlyRides, isDriver);
      if (!mounted) return;
      final locale = Localizations.localeOf(context);
      final monthName = DateFormat('MMMM_yyyy', locale.languageCode == 'en' ? 'en_US' : 'ro_RO').format(DateTime.now());
      final rolePrefix = isDriver ? (locale.languageCode == 'en' ? 'driver' : 'sofer') : (locale.languageCode == 'en' ? 'passenger' : 'pasager');
      
      await Printing.sharePdf(
        bytes: pdfBytes, 
        filename: '${locale.languageCode == 'en' ? 'monthly_report' : 'raport_lunar'}_${rolePrefix}_$monthName.pdf'
      );

      if (mounted) {
        _showReturnToMapDialog();
      }

    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGeneratingReport(e.toString())), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingReport = false);
    }
  }

  Future<List<Ride>> _getMonthlyRides({required bool isDriver}) async {
    final ridesStream = isDriver
        ? _firestoreService.getDriverRidesHistory(filter: DateFilter.lastMonth)
        : _firestoreService.getRidesHistory(filter: DateFilter.lastMonth);
    
    return await ridesStream.first;
  }

  void _showReturnToMapDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l10n.reportGenerated),
        content: Text(l10n.returnToMapQuestion),
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

  Widget _buildFilterChips() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text(l10n.filterAllReceipts),
              selected: _selectedFilter == DateFilter.all,
              onSelected: (selected) {
                if (selected) setState(() => _selectedFilter = DateFilter.all);
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text(l10n.filterLastMonth),
              selected: _selectedFilter == DateFilter.lastMonth,
              onSelected: (selected) {
                if (selected) setState(() => _selectedFilter = DateFilter.lastMonth);
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text(l10n.filterLast3Months),
              selected: _selectedFilter == DateFilter.last3Months,
              onSelected: (selected) {
                if (selected) setState(() => _selectedFilter = DateFilter.last3Months);
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text(l10n.filterThisYear),
              selected: _selectedFilter == DateFilter.thisYear,
              onSelected: (selected) {
                if (selected) setState(() => _selectedFilter = DateFilter.thisYear);
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildActionToolbar(List<Ride> rides, {required bool isDriver}) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isGeneratingReport ? null : () => _generateMonthlyReport(isDriver: isDriver),
              icon: _isGeneratingReport 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.picture_as_pdf),
              label: Text(_isGeneratingReport ? l10n.generating : l10n.monthlyReportPDF),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: rides.isEmpty ? null : _toggleSelectionMode,
            icon: Icon(_isSelectionMode ? Icons.close : Icons.checklist),
            label: Text(_isSelectionMode ? l10n.cancel : l10n.select),
            style: ElevatedButton.styleFrom(backgroundColor: _isSelectionMode ? Colors.orange : Colors.green, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionToolbar(List<Ride> rides) {
    if (!_isSelectionMode) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.blue.withValues(alpha: 0.1),
      child: Row(
        children: [
          Text(l10n.selectedCount(_selectedRideIds.length), style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 16),
          TextButton(
            onPressed: () => _selectAllRides(rides),
            child: Text(_selectedRideIds.length == rides.length ? l10n.deselectAll : l10n.selectAll),
          ),
          const Spacer(),
          if (_selectedRideIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              color: Colors.red,
              tooltip: l10n.deleteSelected,
              onPressed: _isDeletingRides ? null : _deleteSelectedRides,
            ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            color: Colors.red.shade700,
            tooltip: l10n.deleteAll,
            onPressed: _isDeletingRides ? null : () => _deleteAllRides(rides),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptsView({required bool isDriver}) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<List<Ride>>(
      stream: isDriver
          ? _firestoreService.getDriverRidesHistory(filter: _selectedFilter)
          : _firestoreService.getRidesHistory(filter: _selectedFilter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    l10n.errorLoadingReceipts,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.errorDetails(snapshot.error.toString()),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noReceiptsInPeriod,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final rides = snapshot.data!;
        return Column(
          children: [
            if (!isDriver) _buildActionToolbar(rides, isDriver: isDriver),
            if (!isDriver) _buildSelectionToolbar(rides),
            if (!isDriver) const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: rides.length,
                itemBuilder: (context, index) {
                  final ride = rides[index];
                  final locale = Localizations.localeOf(context);
                  final formattedDate = DateFormat('dd MMMM yyyy, HH:mm', locale.languageCode == 'en' ? 'en_US' : 'ro_RO').format(ride.timestamp);
                  final isSelected = _selectedRideIds.contains(ride.id);
                  final l10n = AppLocalizations.of(context)!;
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      leading: _isSelectionMode
                          ? Checkbox(value: isSelected, onChanged: (bool? value) => _toggleRideSelection(ride.id))
                          : const Icon(Icons.receipt_long_outlined, color: Colors.blueGrey, size: 36),
                      title: Text(
                        l10n.rideTo(ride.destinationAddress),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 2,
                        overflow: TextOverflow.visible,
                      ),
                      subtitle: Text(
                        formattedDate,
                        style: const TextStyle(fontSize: 14),
                      ),
                      trailing: _isSelectionMode ? null : const Icon(Icons.arrow_forward_ios, size: 18),
                      onTap: _isSelectionMode
                          ? () => _toggleRideSelection(ride.id)
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ReceiptDetailsScreen(ride: ride)),
                              );
                            },
                      tileColor: isSelected ? Colors.blue.withValues(alpha: 0.1) : null,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoadingRole) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.receiptsTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_userRole == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.receiptsTitle)),
        body: Center(
          child: Text(l10n.errorLoadingUserRole),
        ),
      );
    }

    if (_userRole == UserRole.driver) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.receiptsTitle),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: l10n.asDriver),
              Tab(text: l10n.asPassenger),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            Column(
              children: [
                _buildFilterChips(),
                const Divider(height: 1),
                _buildActionToolbar([], isDriver: true),
                Expanded(child: _buildReceiptsView(isDriver: true)),
              ],
            ),
            Column(
              children: [
                _buildFilterChips(),
                const Divider(height: 1),
                Expanded(child: _buildReceiptsView(isDriver: false)),
              ],
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.receiptsTitlePassenger)),
        body: Column(
          children: [
            _buildFilterChips(),
            const Divider(height: 1),
            Expanded(child: _buildReceiptsView(isDriver: false)),
          ],
        ),
      );
    }
  }
}