import 'package:device_calendar/device_calendar.dart';
import '../../../core/constants/app_enums.dart';

/// Reads today's device calendar events to determine the relevant
/// [CalendarEventType] for outfit scoring.
class CalendarService {
  final DeviceCalendarPlugin _plugin;

  CalendarService({DeviceCalendarPlugin? plugin})
      : _plugin = plugin ?? DeviceCalendarPlugin();

  /// Returns the most relevant [CalendarEventType] for today.
  ///
  /// Returns [CalendarEventType.unknown] if calendar permission is denied.
  Future<CalendarEventType> getTodayEventType() async {
    final permission = await _plugin.requestPermissions();
    if (permission.data != true) return CalendarEventType.unknown;

    final now = DateTime.now();
    final result = await _plugin.retrieveEvents(
      null,
      RetrieveEventsParams(
        startDate: DateTime(now.year, now.month, now.day),
        endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
      ),
    );

    final titles = result.data
            ?.map((e) => e.title?.toLowerCase() ?? '')
            .toList() ??
        [];

    if (titles.any((t) =>
        t.contains('meeting') ||
        t.contains('interview') ||
        t.contains('office') ||
        t.contains('work'))) {
      return CalendarEventType.work;
    }
    if (titles.any((t) =>
        t.contains('party') ||
        t.contains('dinner') ||
        t.contains('date') ||
        t.contains('social'))) {
      return CalendarEventType.social;
    }
    return CalendarEventType.casual;
  }
}
