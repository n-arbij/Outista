/// Typed exception for all local data-layer failures.
///
/// Every datasource method catches low-level errors and re-throws
/// a [DataException] so callers receive a uniform error type.
class DataException implements Exception {
  final String message;
  final Object? cause;

  const DataException(this.message, {this.cause});

  @override
  String toString() =>
      'DataException: $message${cause != null ? ' | cause: $cause' : ''}';
}
