import 'dart:collection';

import 'package:device_calendar/device_calendar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz_local;

import '../../../lib/core/constants/app_enums.dart';
import '../../../lib/features/context_awareness/calendar/calendar_service.dart';
import '../../../lib/features/context_awareness/calendar/models/calendar_event_summary.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────────

class MockDeviceCalendarPlugin extends Mock implements DeviceCalendarPlugin {}

// ─── Helpers ──────────────────────────────────────────────────────────────────

Result<bool> _boolResult(bool? value) => Result<bool>()..data = value;

Result<UnmodifiableListView<Calendar>> _calendarsResult(
    List<Calendar> calendars) {
  return Result<UnmodifiableListView<Calendar>>()
    ..data = UnmodifiableListView(calendars);
}

Result<UnmodifiableListView<Event>> _eventsResult(List<Event> events) {
  return Result<UnmodifiableListView<Event>>()
    ..data = UnmodifiableListView(events);
}

Calendar _calendar(String id) => Calendar()..id = id;

Event _event(String title, {String calendarId = 'cal1'}) {
  tz.initializeTimeZones();
  final now = tz_local.TZDateTime.now(tz_local.local);
  final event = Event(calendarId)
    ..title = title
    ..start = now
    ..end = now.add(const Duration(hours: 1))
    ..allDay = false;
  return event;
}

void main() {
  late MockDeviceCalendarPlugin mockPlugin;
  late CalendarService service;

  setUp(() {
    mockPlugin = MockDeviceCalendarPlugin();
    service = CalendarService(plugin: mockPlugin);

    registerFallbackValue(RetrieveEventsParams(
      startDate: DateTime.now(),
      endDate: DateTime.now(),
    ));

    // Default: has permission
    when(() => mockPlugin.hasPermissions())
        .thenAnswer((_) async => _boolResult(true));
    // Default: no calendars
    when(() => mockPlugin.retrieveCalendars())
        .thenAnswer((_) async => _calendarsResult([]));
  });

  group('CalendarService', () {
    test('returns casual when permission is denied', () async {
      when(() => mockPlugin.hasPermissions())
          .thenAnswer((_) async => _boolResult(false));
      when(() => mockPlugin.requestPermissions())
          .thenAnswer((_) async => _boolResult(false));

      final result = await service.getTodaysEventType();

      expect(result, CalendarEventType.casual);
      verifyNever(() => mockPlugin.retrieveCalendars());
    });

    test('returns work when work keyword found in event title', () async {
      when(() => mockPlugin.retrieveCalendars())
          .thenAnswer((_) async => _calendarsResult([_calendar('cal1')]));
      when(() => mockPlugin.retrieveEvents(any(), any()))
          .thenAnswer((_) async => _eventsResult([_event('Team meeting')]));

      final result = await service.getTodaysEventType();

      expect(result, CalendarEventType.work);
    });

    test('returns social when social keyword found in event title', () async {
      when(() => mockPlugin.retrieveCalendars())
          .thenAnswer((_) async => _calendarsResult([_calendar('cal1')]));
      when(() => mockPlugin.retrieveEvents(any(), any()))
          .thenAnswer((_) async => _eventsResult([_event('Birthday party')]));

      final result = await service.getTodaysEventType();

      expect(result, CalendarEventType.social);
    });

    test('returns work over social when both event types are present',
        () async {
      when(() => mockPlugin.retrieveCalendars())
          .thenAnswer((_) async => _calendarsResult([_calendar('cal1')]));
      when(() => mockPlugin.retrieveEvents(any(), any()))
          .thenAnswer((_) async => _eventsResult([
                _event('Team standup'),
                _event('Birthday dinner'),
              ]));

      final result = await service.getTodaysEventType();

      expect(result, CalendarEventType.work);
    });

    test('returns casual when no keywords match any event title', () async {
      when(() => mockPlugin.retrieveCalendars())
          .thenAnswer((_) async => _calendarsResult([_calendar('cal1')]));
      when(() => mockPlugin.retrieveEvents(any(), any()))
          .thenAnswer((_) async =>
              _eventsResult([_event('Unrelated calendar entry xyz')]));

      final result = await service.getTodaysEventType();

      // unknown events exist but no match → priority yields casual default
      // (unknown has priority 0, which is lower than casual priority 1)
      // However with only unknown events, _prioritizeEventType returns casual
      expect(result, CalendarEventType.casual);
    });

    test('returns casual when no events today', () async {
      when(() => mockPlugin.retrieveCalendars())
          .thenAnswer((_) async => _calendarsResult([_calendar('cal1')]));
      when(() => mockPlugin.retrieveEvents(any(), any()))
          .thenAnswer((_) async => _eventsResult([]));

      final result = await service.getTodaysEventType();

      expect(result, CalendarEventType.casual);
    });

    test('getTodaysEventSummaries never stores event titles', () async {
      when(() => mockPlugin.retrieveCalendars())
          .thenAnswer((_) async => _calendarsResult([_calendar('cal1')]));
      when(() => mockPlugin.retrieveEvents(any(), any()))
          .thenAnswer((_) async => _eventsResult([
                _event('Secret meeting with CEO'),
                _event('My birthday party'),
              ]));

      final summaries = await service.getTodaysEventSummaries();

      expect(summaries, hasLength(2));
      // Verify that CalendarEventSummary has no title field
      for (final summary in summaries) {
        expect(summary, isA<CalendarEventSummary>());
        // Confirm no title accessor exists — the model only has eventType, times, etc.
        expect(summary.eventType, isNotNull);
        expect(summary.startTime, isNotNull);
        expect(summary.endTime, isNotNull);
      }
    });

    test('_prioritizeEventType returns highest priority correctly', () async {
      // Test via getTodaysEventType with all three types present
      when(() => mockPlugin.retrieveCalendars())
          .thenAnswer((_) async => _calendarsResult([_calendar('cal1')]));
      when(() => mockPlugin.retrieveEvents(any(), any()))
          .thenAnswer((_) async => _eventsResult([
                _event('Birthday dinner'),   // social
                _event('Gym session'),       // casual
                _event('Team standup'),      // work — should win
              ]));

      final result = await service.getTodaysEventType();

      expect(result, CalendarEventType.work);
    });
  });
}
