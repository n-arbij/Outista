/// All shared enums for clothing attributes, weather, and calendar context.

enum ClothingCategory {
  top('Top'),
  bottom('Bottom'),
  shoes('Shoes'),
  outerwear('Outerwear'),
  onePiece('One Piece');

  const ClothingCategory(this.label);
  final String label;
}

/// Subcategory refinement for each [ClothingCategory].
///
/// Use [none] as the default/fallback when the user has not selected a
/// subcategory, or when the item was added before subcategories were
/// introduced.
enum ClothingSubcategory {
  // Tops
  tee('T-Shirt'),
  shirt('Shirt'),
  blouse('Blouse'),
  sweater('Sweater'),
  hoodie('Hoodie'),
  tank('Tank Top'),
  polo('Polo'),
  // Bottoms
  trousers('Trousers'),
  jeans('Jeans'),
  skirt('Skirt'),
  shorts('Shorts'),
  leggings('Leggings'),
  chinos('Chinos'),
  // One-Piece
  dress('Dress'),
  jumpsuit('Jumpsuit'),
  romper('Romper'),
  playsuit('Playsuit'),
  dungarees('Dungarees'),
  maxi('Maxi Dress'),
  midi('Midi Dress'),
  // Footwear
  heels('Heels'),
  oxfords('Oxfords'),
  loafers('Loafers'),
  sneakers('Sneakers'),
  sandals('Sandals'),
  boots('Boots'),
  flats('Flats'),
  trainers('Trainers'),
  mules('Mules'),
  // Outerwear
  jacket('Jacket'),
  coat('Coat'),
  blazer('Blazer'),
  cardigan('Cardigan'),
  denimJacket('Denim Jacket'),
  trench('Trench Coat'),
  bomber('Bomber Jacket'),
  // Default fallback
  none('None');

  const ClothingSubcategory(this.label);
  final String label;
}

/// Formality level of a pair of shoes.
///
/// Only relevant when [ClothingCategory] is [ClothingCategory.shoes].
/// Items without an explicit formality default to [casual].
enum ShoeFormality {
  formal('Formal'),
  casual('Casual'),
  sporty('Sporty');

  const ShoeFormality(this.label);
  final String label;
}

/// Structural archetype of a generated outfit combination.
///
/// Determines which items are used and how the outfit is displayed.
enum OutfitArchetype {
  separates('Separates'),
  onePiece('One Piece'),
  onePieceLayered('One Piece Layered'),
  coordSet('Co-ord Set'),
  smartCasual('Smart Casual');

  const OutfitArchetype(this.label);
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
