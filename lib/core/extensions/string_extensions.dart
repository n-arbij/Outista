/// String helper extensions used across the app.
extension StringExtensions on String {
  /// Returns the string with the first character uppercased.
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Truncates to [maxLength] characters, appending [ellipsis] when cut.
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$ellipsis';
  }
}
