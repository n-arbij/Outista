import 'package:device_calendar/device_calendar.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_enums.dart';
import 'models/calendar_event_summary.dart';

/// Reads today's device calendar events to determine the relevant
/// [CalendarEventType] for outfit scoring.
///
/// All permission errors are handled gracefully and never propagate to
/// callers. Calendar event titles are classified locally and never stored,
/// logged, or transmitted beyond the [_classifyEvent] call.
class CalendarService {
  final DeviceCalendarPlugin _plugin;

  CalendarService({DeviceCalendarPlugin? plugin})
      : _plugin = plugin ?? DeviceCalendarPlugin();

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Returns the highest-priority [CalendarEventType] found in today's events.
  ///
  /// Returns [CalendarEventType.casual] when permission is denied, when no
  /// events are found, or on any error.
  Future<CalendarEventType> getTodaysEventType() async {
    if (!await hasCalendarPermission()) {
      final granted = await requestCalendarPermission();
      if (!granted) return CalendarEventType.casual;
    }

    try {
      final summaries = await _fetchTodaySummaries();
      if (summaries.isEmpty) return CalendarEventType.casual;
      return _prioritizeEventType(summaries.map((s) => s.eventType).toList());
    } catch (_) {
      return CalendarEventType.casual;
    }
  }

  /// Compatibility shim matching the Module 5 [GenerateOutfitUseCase] call.
  Future<CalendarEventType> getTodayEventType() => getTodaysEventType();

  /// Returns a classified summary list for every event today.
  ///
  /// Event titles are used only for local classification inside
  /// [_classifyEvent] and are discarded immediately afterwards.
  Future<List<CalendarEventSummary>> getTodaysEventSummaries() async {
    if (!await hasCalendarPermission()) {
      final granted = await requestCalendarPermission();
      if (!granted) return [];
    }

    try {
      return _fetchTodaySummaries();
    } catch (_) {
      return [];
    }
  }

  /// Returns `true` if the READ_CALENDAR permission is currently granted.
  Future<bool> hasCalendarPermission() async {
    try {
      final result = await _plugin.hasPermissions();
      return result.data == true;
    } catch (_) {
      return false;
    }
  }

  /// Requests the READ_CALENDAR permission and returns whether it was granted.
  Future<bool> requestCalendarPermission() async {
    try {
      final result = await _plugin.requestPermissions();
      return result.data == true;
    } catch (_) {
      return false;
    }
  }

  // ─── Internal ──────────────────────────────────────────────────────────────

  Future<List<CalendarEventSummary>> _fetchTodaySummaries() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final calendarsResult = await _plugin.retrieveCalendars();
    final calendars = calendarsResult.data?.toList() ?? [];

    final summaries = <CalendarEventSummary>[];

    for (final calendar in calendars) {
      if (calendar.id == null) continue;
      final eventsResult = await _plugin.retrieveEvents(
        calendar.id,
        RetrieveEventsParams(startDate: startOfDay, endDate: endOfDay),
      );
      final events = eventsResult.data?.toList() ?? [];

      for (final event in events) {
        // Classify using title locally; never store or transmit it.
        final eventType = _classifyEvent(event.title ?? '');
        summaries.add(CalendarEventSummary(
          calendarId: calendar.id!,
          eventType: eventType,
          startTime: event.start ?? startOfDay,
          endTime: event.end ?? endOfDay,
          isAllDay: event.allDay ?? false,
        ));
      }
    }

    return summaries;
  }

  /// Classifies an event [title] into a [CalendarEventType] via keyword
  /// matching on the lowercased title only.
  ///
  /// The title is never stored, logged, or returned to callers.
  CalendarEventType _classifyEvent(String title) {
    final lower = title.toLowerCase();

    const workKeywords = [
      'meeting', 'standup', 'review', 'interview', 'presentation',
      'call', 'sync', 'conference', 'client', 'office', '1:1',
      'sprint', 'demo', 'debrief', 'workshop', 'webinar', 'deadline',
    ];
    if (workKeywords.any(lower.contains)) return CalendarEventType.work;

    const socialKeywords = [
      'party', 'dinner', 'wedding', 'date', 'birthday', 'celebration',
      'gala', 'event', 'brunch', 'drinks', 'lunch', 'reunion',
      'ceremony', 'reception', 'gathering', 'hangout', 'outing',
    ];
    if (socialKeywords.any(lower.contains)) return CalendarEventType.social;

    const casualKeywords = [
      'gym', 'errand', 'walk', 'coffee', 'home', 'casual', 'rest',
      'shopping', 'appointment', 'dentist', 'doctor', 'pickup',
      'run', 'yoga', 'class', 'study',
    ];
    if (casualKeywords.any(lower.contains)) return CalendarEventType.casual;

    return CalendarEventType.unknown;
  }

  /// Returns the highest-priority type from [types].
  ///
  /// Priority: work (3) > social (2) > casual (1) > unknown (0).
  /// Returns [CalendarEventType.casual] when [types] is empty or when all
  /// types are [CalendarEventType.unknown] (treated as no preference).
  CalendarEventType _prioritizeEventType(List<CalendarEventType> types) {
    if (types.isEmpty) return CalendarEventType.casual;

    int priority(CalendarEventType t) {
      switch (t) {
        case CalendarEventType.work:
          return 3;
        case CalendarEventType.social:
          return 2;
        case CalendarEventType.casual:
          return 1;
        case CalendarEventType.unknown:
          return 0;
      }
    }

    final best = types.reduce(
      (best, t) => priority(t) > priority(best) ? t : best,
    );

    // Unknown means no keyword match — treat as casual (safe default).
    return best == CalendarEventType.unknown
        ? CalendarEventType.casual
        : best;
  }
}
