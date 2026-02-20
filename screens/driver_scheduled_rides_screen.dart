import 'package:flutter/material.dart';
import 'package:friendsride_app/models/ride_model.dart';
import 'package:friendsride_app/services/firestore_service.dart';
import 'package:friendsride_app/services/calendar_service.dart';
import 'package:friendsride_app/screens/driver_ride_pickup_screen.dart';
import 'package:intl/intl.dart';

class DriverScheduledRidesScreen extends StatelessWidget {
  const DriverScheduledRidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Curse Programate'),
      ),
      body: StreamBuilder<List<Ride>>(
        stream: firestoreService.getDriverAcceptedRides(),
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
                  'Nu aveți nicio cursă programată acceptată.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          final acceptedRides = snapshot.data!;

          return ListView.builder(
            itemCount: acceptedRides.length,
            itemBuilder: (context, index) {
              final ride = acceptedRides[index];
              final formattedDate = DateFormat('EEE, dd MMMM, HH:mm', 'ro_RO')
                  .format(ride.scheduledPickupTime!);
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.hail, color: Colors.green),
                  title: Text(
                    'Preluare de la: ${ride.startAddress}',
                     style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Programată pentru: $formattedDate'),
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
                    // Navighează către ecranul de preluare cursă
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => DriverRidePickupScreen(
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