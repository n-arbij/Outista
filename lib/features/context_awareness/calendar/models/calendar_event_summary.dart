import '../../../../core/constants/app_enums.dart';

/// Lightweight classification of a single device calendar event.
///
/// Title and description are never stored — privacy by design.
class CalendarEventSummary {
  /// Platform identifier of the originating calendar.
  final String calendarId;

  /// Inferred type of the event based on keyword matching.
  final CalendarEventType eventType;

  /// Start time of the event.
  final DateTime startTime;

  /// End time of the event.
  final DateTime endTime;

  /// Whether this is an all-day event.
  final bool isAllDay;

  const CalendarEventSummary({
    required this.calendarId,
    required this.eventType,
    required this.startTime,
    required this.endTime,
    required this.isAllDay,
  });

  /// `true` if the event starts after the current moment.
  bool get isUpcoming => startTime.isAfter(DateTime.now());

  /// Duration of the event expressed in whole hours.
  int get durationHours => endTime.difference(startTime).inHours;
}
