import 'package:flutter/material.dart';
import 'package:friendsride_app/models/ride_model.dart';
import 'package:friendsride_app/services/firestore_service.dart';
import 'package:friendsride_app/services/calendar_service.dart';
import 'package:friendsride_app/screens/passenger_ride_details_screen.dart';
import 'package:intl/intl.dart';

class PassengerScheduledRidesScreen extends StatelessWidget {
  const PassengerScheduledRidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rezervările Mele'),
      ),
      body: StreamBuilder<List<Ride>>(
        stream: firestoreService.getPassengerScheduledRides(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Eroare: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Nu aveți nicio cursă programată în viitor.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          final scheduledRides = snapshot.data!;

          return ListView.builder(
            itemCount: scheduledRides.length,
            itemBuilder: (context, index) {
              final ride = scheduledRides[index];
              final formattedDate = DateFormat('EEE, dd MMMM, HH:mm', 'ro_RO')
                  .format(ride.scheduledPickupTime!);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.event_available, color: Colors.blue),
                  title: Text(
                    'Către: ${ride.destinationAddress}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Programată pentru: $formattedDate'),
                      const SizedBox(height: 2),
                      Text(
                        'Status: ${ride.status}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: ride.status == 'accepted'
                                ? Colors.green.shade700
                                : Colors.orange.shade800),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final calendarService = CalendarService();
                      final success = await calendarService.addScheduledRideToCalendar(ride);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? 'Cursă adăugată în calendar'
                                : 'Eroare la adăugarea în calendar'),
                            backgroundColor: success ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    },
                    tooltip: 'Adaugă în calendar',
                  ),
                  onTap: () {
                    // Navighează către ecranul de detalii cursă
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PassengerRideDetailsScreen(
                          rideId: ride.id,
                          ride: ride,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}