/// Domain exceptions surfaced by repositories. The UI maps these to
/// friendly messages (`files/ARCHITECTURE.md` section 7).
final class CategoryInUseException implements Exception {
  const CategoryInUseException(this.categoryName);

  final String categoryName;

  @override
  String toString() =>
      'Category "$categoryName" is used by purchases. Archive it instead.';
}

final class ColorInUseException implements Exception {
  const ColorInUseException(this.colorName);

  final String colorName;

  @override
  String toString() =>
      'Color "$colorName" is used by purchases. Archive it instead.';
}

final class SaleExceedsStockException implements Exception {
  const SaleExceedsStockException(this.stockLeft);

  final int stockLeft;

  @override
  String toString() => 'Cannot sell more than the $stockLeft left in stock.';
}

final class SaleQuantityException implements Exception {
  const SaleQuantityException();

  @override
  String toString() => 'Quantity must be greater than 0.';
}

final class NotFoundException implements Exception {
  const NotFoundException(this.message);

  final String message;

  @override
  String toString() => message;
}
