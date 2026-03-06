import 'package:intl/intl.dart';

/// Date and time formatting helpers for Outista.
///
/// Named [AppDateUtils] to avoid collision with Flutter's built-in [DateUtils].
class AppDateUtils {
  AppDateUtils._();

  static final _dateFormatter = DateFormat('MMM d, yyyy');
  static final _shortFormatter = DateFormat('MMM d');
  static final _timeFormatter = DateFormat('h:mm a');

  /// Formats a date as "Jan 1, 2024".
  static String formatDate(DateTime date) => _dateFormatter.format(date);

  /// Formats a date as "Jan 1".
  static String formatShortDate(DateTime date) => _shortFormatter.format(date);

  /// Formats a time as "9:00 AM".
  static String formatTime(DateTime date) => _timeFormatter.format(date);

  /// Returns true if [date] falls on today's calendar day.
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Returns the absolute number of whole days between [from] and [to].
  static int daysBetween(DateTime from, DateTime to) {
    final a = DateTime(from.year, from.month, from.day);
    final b = DateTime(to.year, to.month, to.day);
    return b.difference(a).inDays.abs();
  }
}
