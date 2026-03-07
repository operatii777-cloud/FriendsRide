import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:friendsride_app/services/driver_incentives_service.dart';
import 'package:friendsride_app/models/driver_incentive_model.dart';
import 'package:friendsride_app/widgets/driver_incentives_list_widget.dart';
import 'package:friendsride_app/theme/app_colors.dart';
import 'package:friendsride_app/utils/logger.dart';

/// Ecran dedicat pentru incentives-urile șoferului.
/// Afișează toate incentives-urile (quests, streak-uri, câștiguri garantate)
/// precum și progresul curent și bonusurile disponibile.
class DriverIncentivesScreen extends StatefulWidget {
  const DriverIncentivesScreen({super.key});

  @override
  State<DriverIncentivesScreen> createState() => _DriverIncentivesScreenState();
}

class _DriverIncentivesScreenState extends State<DriverIncentivesScreen>
    with SingleTickerProviderStateMixin {
  final DriverIncentivesService _incentivesService = DriverIncentivesService();
  late TabController _tabController;
  String? _driverId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _driverId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incentives & Bonusuri'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.flash_on), text: 'Active'),
            Tab(icon: Icon(Icons.check_circle_outline), text: 'Completate'),
          ],
        ),
      ),
      body: _driverId == null
          ? const Center(child: Text('Utilizatorul nu este autentificat.'))
          : StreamBuilder<List<DriverIncentive>>(
              stream: _incentivesService.getDriverIncentivesStream(_driverId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  Logger.error('Error loading incentives: ${snapshot.error}');
                  return _buildErrorState();
                }

                final incentives = snapshot.data ?? [];
    final active =
                    incentives.where((i) => i.isActive && !i.isCompleted).toList();
                final completed =
                    incentives.where((i) => i.isCompleted).toList();

                return Column(
                  children: [
                    _buildSummaryCard(active, completed),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildIncentivesList(active, isActive: true),
                          _buildIncentivesList(completed, isActive: false),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildSummaryCard(
      List<DriverIncentive> active, List<DriverIncentive> completed) {
    final totalBonus = active.fold<double>(
        0, (sum, i) => sum + i.reward);
    return Semantics(
      label:
          '${active.length} incentives active, câștiguri potențiale: ${totalBonus.toStringAsFixed(0)} RON',
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF1565C0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(76),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _summaryItem(
              Icons.flash_on,
              '${active.length}',
              'Active',
              Colors.amber,
            ),
            Container(
              height: 50,
              width: 1,
              color: Colors.white30,
            ),
            _summaryItem(
              Icons.attach_money,
              '${totalBonus.toStringAsFixed(0)} RON',
              'Bonus potențial',
              Colors.lightGreenAccent,
            ),
            Container(
              height: 50,
              width: 1,
              color: Colors.white30,
            ),
            _summaryItem(
              Icons.check_circle,
              '${completed.length}',
              'Completate',
              Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(
      IconData icon, String value, String label, Color iconColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildIncentivesList(List<DriverIncentive> incentives,
      {required bool isActive}) {
    if (incentives.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? Icons.hourglass_empty : Icons.emoji_events_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              isActive
                  ? 'Nu există incentives active momentan.\nVerifică din nou mai târziu!'
                  : 'Nu ai completat niciun incentive încă.\nÎncepe să conduci!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return DriverIncentivesListWidget(
      incentives: incentives,
      onIncentiveTap: _onIncentiveTapped,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          const Text('Eroare la încărcarea incentives-urilor.'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: const Text('Reîncearcă'),
          ),
        ],
      ),
    );
  }

  void _onIncentiveTapped(DriverIncentive incentive) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _IncentiveDetailSheet(incentive: incentive),
    );
  }
}

class _IncentiveDetailSheet extends StatelessWidget {
  final DriverIncentive incentive;

  const _IncentiveDetailSheet({required this.incentive});

  @override
  Widget build(BuildContext context) {
    final progress = incentive.targetRides != null && incentive.targetRides! > 0
        ? ((incentive.currentProgress ?? 0) / incentive.targetRides!).clamp(0.0, 1.0)
        : 0.0;

    return Semantics(
      label: 'Detalii incentive: ${incentive.title}',
      child: DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.flash_on,
                          color: AppColors.primary, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            incentive.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            incentive.description,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (incentive.reward > 0) ...[
                  _detailRow(
                    Icons.attach_money,
                    'Recompensă',
                    '${incentive.reward.toStringAsFixed(2)} RON',
                  ),
                  const Divider(),
                ],
                if (incentive.targetRides != null) ...[
                  _detailRow(
                    Icons.directions_car,
                    'Progres',
                    '${incentive.currentProgress ?? 0} / ${incentive.targetRides} curse',
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress >= 1.0 ? Colors.green : AppColors.primary,
                      ),
                    ),
                  ),
                  const Divider(),
                ],
                _detailRow(
                    Icons.calendar_today,
                    'Expiră',
                    _formatDate(incentive.endDate.toDate()),
                  ),
                if (incentive.isCompleted)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Incentive completat! Felicitări!',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
