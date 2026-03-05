import 'package:flutter/material.dart';

class MapRideInfoPanel extends StatelessWidget {
  final double? pickupLatitude;
  final double? destinationLatitude;
  final String pickupText;
  final String destinationText;
  final int stopsCount;
  final VoidCallback onClearPickup;
  final VoidCallback onClearDestination;
  final VoidCallback onStartRide;

  const MapRideInfoPanel({
    super.key,
    this.pickupLatitude,
    this.destinationLatitude,
    required this.pickupText,
    required this.destinationText,
    required this.stopsCount,
    required this.onClearPickup,
    required this.onClearDestination,
    required this.onStartRide,
  });

  @override
  Widget build(BuildContext context) {
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
            if (pickupLatitude != null) ...[
              Row(
                children: [
                  Icon(Icons.my_location, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Plecare: $pickupText',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.clear, color: Colors.red, size: 20),
                    onPressed: () {
                      onClearPickup();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Punctul de plecare a fost șters'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    },
                    tooltip: 'Șterge pickup',
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
            ],

            // Destination info
            if (destinationLatitude != null) ...[
              Row(
                children: [
                  Icon(Icons.flag, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Destinație: $destinationText',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.clear, color: Colors.red, size: 20),
                    onPressed: () {
                      onClearDestination();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Destinația a fost ștearsă'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    },
                    tooltip: 'Șterge destinația',
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
            ],

            // Intermediate stops info
            if (stopsCount > 0) ...[
              Text(
                'Opriri: $stopsCount',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 8.0),
            ],

            // Start ride button
            _buildStartRideButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStartRideButton(BuildContext context) {
    final canStartRide = pickupLatitude != null && destinationLatitude != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: canStartRide ? onStartRide : null,
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
}
