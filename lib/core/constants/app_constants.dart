class AppConstants {
  AppConstants._();

  // Scoring weights (Module 5)
  static const double weightWeather = 0.4;
  static const double weightCalendar = 0.3;
  static const double weightRecency = 0.2;
  static const double weightPreference = 0.1;

  // Weather API
  static const String openMeteoBaseUrl = 'https://api.open-meteo.com/v1';

  // Outfit engine thresholds
  static const int maxOutfitSuggestions = 5;
  static const int recentWearCooldownDays = 3;
}
