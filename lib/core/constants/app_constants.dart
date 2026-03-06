/// App-wide constants for scoring, API config, image capture, and database.
class AppConstants {
  AppConstants._();

  // --- Outfit Scoring Weights ---
  static const int seasonMatchScore = 40;
  static const int occasionMatchScore = 35;
  static const int usageBalanceMaxScore = 25;
  static const int emotionalTagBonus = 15;

  /// Number of days over which recent-wear penalty fades to zero.
  static const double recentWearPenaltyDays = 7.0;

  // --- Weather API ---
  static const String weatherApiBaseUrl = 'https://api.open-meteo.com/v1';

  /// How long a weather response is considered fresh before re-fetching.
  static const int weatherCacheDurationHours = 3;

  // --- Temperature Thresholds (°C) ---
  static const double hotTempThreshold = 25.0;
  static const double coldTempThreshold = 15.0;

  // --- Image Capture ---
  static const double imageCaptureQuality = 0.85;
  static const int imageMaxWidth = 800;
  static const int imageMaxHeight = 800;

  // --- Database ---
  static const String databaseName = 'outista.db';
  static const int databaseVersion = 1;
}
