import 'package:flutter/material.dart';

import '../utils/deprecated_apis_fix.dart';
import 'package:friendsride_app/models/ride_model.dart';


/// Ecran de chitanță pentru cursele finalizate
class RideReceiptScreen extends StatelessWidget {
  final Ride ride;

  const RideReceiptScreen({
    super.key,
    required this.ride,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Chitanță Cursă'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _shareReceipt(),
            icon: const Icon(Icons.share),
            tooltip: 'Trimite chitanța',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildRideDetails(context),
                const SizedBox(height: 24),
                _buildFareBreakdown(context),
                const SizedBox(height: 24),
                _buildFooter(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.green.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.check_circle,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Cursă Finalizată',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        Text(
          'ID: ${ride.id.substring(0, 8).toUpperCase()}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildRideDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detalii Cursă',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildDetailRow(
          context,
          icon: Icons.radio_button_checked,
          iconColor: Colors.green,
          label: 'Pornire',
          value: ride.startAddress,
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          context,
          icon: Icons.location_on,
          iconColor: Colors.red,
          label: 'Destinație',
          value: ride.destinationAddress,
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          context,
          icon: Icons.access_time,
          iconColor: Theme.of(context).colorScheme.primary,
          label: 'Data & Ora',
          value: _formatDateTime(ride.timestamp),
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          context,
          icon: Icons.directions_car,
          iconColor: Theme.of(context).colorScheme.primary,
          label: 'Categorie',
          value: ride.category.displayName,
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFareBreakdown(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detalii Plată',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildFareItem(context, 'Tarif de bază', '${ride.totalCost.toStringAsFixed(2)} RON'),
        _buildFareItem(context, 'Distanța', '${ride.distance.toStringAsFixed(1)} km'),
        _buildFareItem(context, 'Durata', '${ride.durationInMinutes?.toStringAsFixed(0) ?? 'N/A'} minute'),
        const Divider(height: 32),
        _buildFareItem(
          context,
          'Total Plătit',
          '${ride.totalCost.toStringAsFixed(2)} RON',
          isTotal: true,
        ),
      ],
    );
  }

  Widget _buildFareItem(BuildContext context, String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: isTotal ? 18 : 14,
              color: isTotal ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Mulțumim că ai ales FriendsRide! Această chitanță poate fi folosită pentru decontări.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'FriendsRide - Călătorii sigure și rapide',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Data necunoscută';
    
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} la ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _shareReceipt() {
    final receiptText = '''
🚗 FriendsRide - Chitanță Cursă

ID Cursă: ${ride.id.substring(0, 8).toUpperCase()}
Data: ${_formatDateTime(ride.timestamp)}

📍 Pornire: ${ride.startAddress}
🎯 Destinație: ${ride.destinationAddress}

💰 Total: ${ride.totalCost.toStringAsFixed(2)} RON
📏 Distanța: ${ride.distance.toStringAsFixed(1)} km
⏱️ Durata: ${ride.durationInMinutes?.toStringAsFixed(0) ?? 'N/A'} minute

Mulțumim că ai ales FriendsRide!
    ''';
    
          DeprecatedAPIsFix.shareText(receiptText);
  }
}
