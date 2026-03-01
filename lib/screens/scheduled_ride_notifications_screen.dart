import 'package:flutter/material.dart';
import 'package:friendsride_app/services/local_notifications_service.dart';
import 'package:friendsride_app/theme/app_colors.dart';
import 'package:friendsride_app/theme/app_text_styles.dart';
import 'package:intl/intl.dart';

/// Model simplu pentru o cursă programată
class _ScheduledRide {
  final String id;
  final String destination;
  final DateTime scheduledAt;
  bool notificationsEnabled;

  _ScheduledRide({
    required this.id,
    required this.destination,
    required this.scheduledAt,
    this.notificationsEnabled = true,
  });
}

/// Ecran pentru gestionarea curselor programate cu notificări
class ScheduledRideNotificationsScreen extends StatefulWidget {
  const ScheduledRideNotificationsScreen({super.key});

  @override
  State<ScheduledRideNotificationsScreen> createState() =>
      _ScheduledRideNotificationsScreenState();
}

class _ScheduledRideNotificationsScreenState
    extends State<ScheduledRideNotificationsScreen> {
  final LocalNotificationsService _notifService = LocalNotificationsService();
  final List<_ScheduledRide> _rides = [];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _notifService.initialize();
    setState(() => _isInitialized = true);
  }

  Future<void> _addScheduledRide() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => const _AddRideDialog(),
    );

    if (result == null || !mounted) return;

    final ride = _ScheduledRide(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      destination: result['destination'] as String,
      scheduledAt: result['scheduledAt'] as DateTime,
      notificationsEnabled: true,
    );

    setState(() => _rides.add(ride));

    if (ride.notificationsEnabled) {
      await _scheduleNotification(ride);
    }
  }

  Future<void> _scheduleNotification(_ScheduledRide ride) async {
    final minutesBefore = ride.scheduledAt
        .difference(DateTime.now())
        .inMinutes;

    if (minutesBefore > 0) {
      await _notifService.showSimple(
        title: 'Cursă programată',
        body:
            'Cursa ta spre ${ride.destination} este programată pentru ${DateFormat('HH:mm').format(ride.scheduledAt)}.',
        payload: ride.id,
      );
    }
  }

  Future<void> _removeRide(String id) async {
    setState(() => _rides.removeWhere((r) => r.id == id));
  }

  Future<void> _toggleNotifications(_ScheduledRide ride, bool value) async {
    setState(() => ride.notificationsEnabled = value);
    if (value) {
      await _scheduleNotification(ride);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Curse Programate'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isInitialized ? _addScheduledRide : null,
        icon: const Icon(Icons.add),
        label: const Text('Adaugă cursă'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _rides.isEmpty ? _buildEmptyState() : _buildRideList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.schedule, size: 72, color: AppColors.textDisabled),
          const SizedBox(height: 16),
          Text('Nicio cursă programată', style: AppTextStyles.headingSmall),
          const SizedBox(height: 8),
          Text(
            'Apasă butonul + pentru a adăuga\no cursă programată.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRideList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _rides.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _buildRideCard(_rides[index]),
    );
  }

  Widget _buildRideCard(_ScheduledRide ride) {
    final isPast = ride.scheduledAt.isBefore(DateTime.now());
    final dateStr = DateFormat('dd.MM.yyyy, HH:mm').format(ride.scheduledAt);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isPast
              ? AppColors.textDisabled.withValues(alpha: 0.2)
              : AppColors.primary.withValues(alpha: 0.1),
          child: Icon(
            Icons.schedule,
            color: isPast ? AppColors.textDisabled : AppColors.primary,
          ),
        ),
        title: Text(
          ride.destination,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: isPast ? AppColors.textDisabled : AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateStr, style: AppTextStyles.bodySmall),
            if (isPast)
              Text(
                'Cursă trecută',
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.textDisabled),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isPast)
              Switch(
                value: ride.notificationsEnabled,
                onChanged: (v) => _toggleNotifications(ride, v),
                activeColor: AppColors.primary,
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => _removeRide(ride.id),
              tooltip: 'Șterge',
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog pentru adăugarea unei curse programate
class _AddRideDialog extends StatefulWidget {
  const _AddRideDialog();

  @override
  State<_AddRideDialog> createState() => _AddRideDialogState();
}

class _AddRideDialogState extends State<_AddRideDialog> {
  final _destController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _selectedTime = TimeOfDay.fromDateTime(
    DateTime.now().add(const Duration(hours: 1)),
  );

  @override
  void dispose() {
    _destController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  DateTime get _combinedDateTime => DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd.MM.yyyy').format(_selectedDate);
    final timeStr = _selectedTime.format(context);

    return AlertDialog(
      title: const Text('Adaugă cursă programată'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _destController,
            decoration: const InputDecoration(
              labelText: 'Destinație',
              prefixIcon: Icon(Icons.location_on_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(dateStr),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.access_time, size: 18),
                  label: Text(timeStr),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anulează'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_destController.text.trim().isEmpty) return;
            Navigator.of(context).pop({
              'destination': _destController.text.trim(),
              'scheduledAt': _combinedDateTime,
            });
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('Adaugă', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
