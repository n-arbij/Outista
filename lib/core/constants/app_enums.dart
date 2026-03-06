/// All shared enums for clothing attributes, weather, and calendar context.

enum ClothingCategory {
  top('Top'),
  bottom('Bottom'),
  shoes('Shoes'),
  outerwear('Outerwear');

  const ClothingCategory(this.label);
  final String label;
}

enum ClothingSeason {
  hot('Hot Weather'),
  cold('Cold Weather'),
  allWeather('All Weather');

  const ClothingSeason(this.label);
  final String label;
}

enum ClothingOccasion {
  casual('Casual'),
  work('Work'),
  formal('Formal'),
  social('Social');

  const ClothingOccasion(this.label);
  final String label;
}

enum EmotionalTag {
  none('None'),
  favorite('Favorite'),
  confident('Confident');

  const EmotionalTag(this.label);
  final String label;
}

enum WeatherSeason {
  hot,
  cold,
  allWeather,
}

enum CalendarEventType {
  work,
  casual,
  social,
  unknown,
}
