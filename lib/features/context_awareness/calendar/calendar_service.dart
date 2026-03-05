import 'package:device_calendar/device_calendar.dart';
import 'package:outista/core/constants/app_enums.dart';

// Module 6 — Device calendar integration
class CalendarService {
  final DeviceCalendarPlugin _plugin;

  CalendarService({DeviceCalendarPlugin? plugin})
      : _plugin = plugin ?? DeviceCalendarPlugin();

  /// Returns the formality inferred from today's calendar events.
  Future<Formality> getTodayFormality() async {
    final permissionResult = await _plugin.requestPermissions();
    if (permissionResult.data != true) return Formality.casual;

    final now = DateTime.now();
    final events = await _plugin.retrieveEvents(
      null,
      RetrieveEventsParams(
        startDate: DateTime(now.year, now.month, now.day),
        endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
      ),
    );

    final titles = events.data
            ?.map((e) => e.title?.toLowerCase() ?? '')
            .toList() ??
        [];

    if (titles.any((t) => t.contains('meeting') || t.contains('interview'))) {
      return Formality.formal;
    }
    if (titles.any((t) => t.contains('gym') || t.contains('workout'))) {
      return Formality.athletic;
    }
    if (titles.any((t) => t.contains('office') || t.contains('work'))) {
      return Formality.smart;
    }
    return Formality.casual;
  }
}
