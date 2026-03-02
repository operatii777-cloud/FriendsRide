import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:friendsride_app/models/ride_model.dart';
import 'package:friendsride_app/utils/logger.dart';

/// Serviciu pentru integrare calendar (import curse programate, reminders)
class CalendarService {
  /// Adaugă o cursă programată în calendar
  Future<bool> addScheduledRideToCalendar(Ride ride) async {
    try {
      if (!ride.isScheduled || ride.scheduledPickupTime == null) {
        Logger.warning('Ride is not scheduled or does not have scheduled pickup time', tag: 'Calendar');
        return false;
      }

      final event = Event(
        title: 'Cursă FriendsRide',
        description: 'De la: ${ride.startAddress}\nLa: ${ride.destinationAddress}',
        location: ride.startAddress,
        startDate: ride.scheduledPickupTime!,
        endDate: ride.scheduledPickupTime!.add(Duration(minutes: (ride.durationInMinutes ?? 30).toInt())),
        iosParams: const IOSParams(
          reminder: Duration(minutes: 15),
        ),
        androidParams: const AndroidParams(
          emailInvites: [],
        ),
      );

      final result = await Add2Calendar.addEvent2Cal(event);
      Logger.info('Ride added to calendar: ${ride.id}', tag: 'Calendar');
      return result;
    } catch (e) {
      Logger.error('Error adding ride to calendar', error: e, tag: 'Calendar');
      return false;
    }
  }

  /// Adaugă reminder pentru o cursă programată
  Future<bool> addRideReminder(Ride ride, {Duration reminderBefore = const Duration(minutes: 15)}) async {
    try {
      if (ride.scheduledPickupTime == null) {
        Logger.warning('Ride does not have scheduled pickup time', tag: 'Calendar');
        return false;
      }

      final reminderTime = ride.scheduledPickupTime!.subtract(reminderBefore);

      final event = Event(
        title: 'Reminder: Cursă FriendsRide',
        description: 'Curse programată la ${ride.scheduledPickupTime!.toString()}',
        location: ride.startAddress,
        startDate: reminderTime,
        endDate: reminderTime.add(const Duration(minutes: 5)),
        iosParams: const IOSParams(
          reminder: Duration(minutes: 0),
        ),
        androidParams: const AndroidParams(
          emailInvites: [],
        ),
      );

      final result = await Add2Calendar.addEvent2Cal(event);
      Logger.info('Reminder added for ride: ${ride.id}', tag: 'Calendar');
      return result;
    } catch (e) {
      Logger.error('Error adding reminder', error: e, tag: 'Calendar');
      return false;
    }
  }
}

