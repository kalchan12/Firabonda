/// Spacing scale per `files/DESIGN.md` section 5. Use for all padding/gaps.
final class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Standard screen horizontal padding.
  static const double screenPadding = 20;
}

/// Corner radius tokens per `files/DESIGN.md` section 5 and Fix Plan V2.1 Task 2.
final class AppRadius {
  const AppRadius._();

  static const double radiusCard = 24;
  static const double radiusHero = 28;
  static const double radiusButton = 16;
  static const double radiusSheet = 28;
  static const double radiusChip = 999;

  // Convenient aliases
  static const double card = radiusCard;
  static const double hero = radiusHero;
  static const double button = radiusButton;
  static const double sheet = radiusSheet;
  static const double chip = radiusChip;

  // Backwards compatibility
  static const double bottomSheet = sheet;
  static const double pill = chip;
}
