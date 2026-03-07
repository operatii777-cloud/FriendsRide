import 'package:flutter/material.dart';
import 'package:friendsride_app/screens/admin/admin_document_review_screen.dart';
import 'package:friendsride_app/screens/admin/admin_selfie_review_screen.dart';
import 'package:friendsride_app/services/analytics_service.dart';
import 'package:friendsride_app/theme/app_text_styles.dart';
import 'package:share_plus/share_plus.dart';

/// Dashboard pentru Business Intelligence și Analytics
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  Map<String, dynamic>? _analytics;
  bool _isLoading = false;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final analytics = await _analyticsService.getGlobalAnalytics(
        startDate: _startDate,
        endDate: _endDate,
      );
      if (mounted) {
        setState(() {
          _analytics = analytics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la încărcarea analytics: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportData() async {
    if (_analytics == null) return;

    try {
      final jsonData = await _analyticsService.exportAnalyticsAsJson(_analytics!);
      await SharePlus.instance.share(ShareParams(text: jsonData));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Intelligence Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.badge),
            tooltip: 'Verificare Documente Șoferi',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AdminDocumentReviewScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.face),
            tooltip: 'Verificare Selfie',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AdminSelfieReviewScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _exportData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analytics == null
              ? const Center(child: Text('Nu există date'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDateRangeSelector(),
                      const SizedBox(height: 24),
                      _buildMetricsGrid(),
                      const SizedBox(height: 24),
                      _buildChartsSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('De la:', style: TextStyle(fontSize: 12)),
                  TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _startDate = date;
                        });
                        _loadAnalytics();
                      }
                    },
                    child: Text('${_startDate.day}/${_startDate.month}/${_startDate.year}'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Până la:', style: TextStyle(fontSize: 12)),
                  TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _endDate = date;
                        });
                        _loadAnalytics();
                      }
                    },
                    child: Text('${_endDate.day}/${_endDate.month}/${_endDate.year}'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    final data = _analytics!;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildMetricCard(
          'Total Curse',
          data['totalRides'].toString(),
          Icons.directions_car,
          Colors.blue,
        ),
        _buildMetricCard(
          'Venit Total',
          '${data['totalRevenue'].toStringAsFixed(2)} RON',
          Icons.attach_money,
          Colors.green,
        ),
        _buildMetricCard(
          'Comision',
          '${data['totalCommission'].toStringAsFixed(2)} RON',
          Icons.account_balance,
          Colors.orange,
        ),
        _buildMetricCard(
          'Șoferi Activi',
          data['activeDrivers'].toString(),
          Icons.person,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.headingMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistici Detaliate',
              style: AppTextStyles.headingMedium,
            ),
            const SizedBox(height: 16),
            _buildStatRow('Câștiguri Șoferi', '${_analytics!['totalDriverEarnings'].toStringAsFixed(2)} RON'),
            _buildStatRow('Valoare Medie Cursă', '${_analytics!['averageRideValue'].toStringAsFixed(2)} RON'),
            _buildStatRow('Pasageri Activi', _analytics!['activePassengers'].toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

