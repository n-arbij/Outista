/// Route path constants for GoRouter configuration and navigation.
class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String wardrobe = '/wardrobe';

  // Relative segments used in nested GoRoute definitions.
  static const String wardrobeItem = 'item/:id';
  static const String wardrobeItemEdit = 'edit';

  static const String addItem = '/add-item';

  // Relative segments for add-item sub-routes.
  static const String addItemCamera = 'camera';
  static const String addItemTagging = 'tagging';

  // Full-path helpers for context.go() calls.
  static String wardrobeItemPath(String id) => '/wardrobe/item/$id';
  static String wardrobeItemEditPath(String id) => '/wardrobe/item/$id/edit';
  static const String addItemCameraPath = '/add-item/camera';
  static const String addItemTaggingPath = '/add-item/tagging';
}
