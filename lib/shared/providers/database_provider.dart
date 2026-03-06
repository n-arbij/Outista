import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';

/// Global provider for the [AppDatabase] singleton.
///
/// **Must** be overridden in [main.dart] via [ProviderScope] overrides
/// before [runApp] is called. Throws if accessed without an override.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError(
    'databaseProvider has not been overridden. '
    'Ensure ProviderScope in main.dart supplies the initialised AppDatabase.',
  ),
);
