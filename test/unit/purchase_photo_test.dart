import 'package:firabonda/data/models/shop_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Purchase Multi-Photo Models', () {
    test('PurchaseOverview parses null or empty photoPath as empty list', () {
      final p1 = PurchaseOverview(
        id: 'p1',
        categoryId: 'cat1',
        categoryName: 'Dresses',
        colorId: 'col1',
        colorName: 'Red',
        colorHex: 0xFFFF0000,
        supplierId: null,
        supplierName: null,
        size: null,
        quantity: 1,
        unitCostCents: 10000,
        totalCostCents: 10000,
        sellingPriceCents: 15000,
        photoPath: null,
        note: null,
        date: DateTime.now(),
        stockLeft: 1,
      );
      expect(p1.photoPaths, isEmpty);
      expect(p1.firstPhotoPath, isNull);

      final p2 = PurchaseOverview(
        id: 'p2',
        categoryId: 'cat1',
        categoryName: 'Dresses',
        colorId: 'col1',
        colorName: 'Red',
        colorHex: 0xFFFF0000,
        supplierId: null,
        supplierName: null,
        size: null,
        quantity: 1,
        unitCostCents: 10000,
        totalCostCents: 10000,
        sellingPriceCents: 15000,
        photoPath: '   ',
        note: null,
        date: DateTime.now(),
        stockLeft: 1,
      );
      expect(p2.photoPaths, isEmpty);
      expect(p2.firstPhotoPath, isNull);
    });

    test('PurchaseOverview parses single photoPath correctly', () {
      final p = PurchaseOverview(
        id: 'p1',
        categoryId: 'cat1',
        categoryName: 'Dresses',
        colorId: 'col1',
        colorName: 'Red',
        colorHex: 0xFFFF0000,
        supplierId: null,
        supplierName: null,
        size: null,
        quantity: 1,
        unitCostCents: 10000,
        totalCostCents: 10000,
        sellingPriceCents: 15000,
        photoPath: '/path/to/img1.jpg',
        note: null,
        date: DateTime.now(),
        stockLeft: 1,
      );
      expect(p.photoPaths, ['/path/to/img1.jpg']);
      expect(p.firstPhotoPath, '/path/to/img1.jpg');
    });

    test('PurchaseOverview parses multiple pipe-delimited photoPaths', () {
      final p = PurchaseOverview(
        id: 'p1',
        categoryId: 'cat1',
        categoryName: 'Dresses',
        colorId: 'col1',
        colorName: 'Red',
        colorHex: 0xFFFF0000,
        supplierId: null,
        supplierName: null,
        size: null,
        quantity: 3,
        unitCostCents: 10000,
        totalCostCents: 30000,
        sellingPriceCents: 15000,
        photoPath: '/photos/item1.jpg|/photos/item2.jpg|/photos/item3.jpg',
        note: null,
        date: DateTime.now(),
        stockLeft: 3,
      );
      expect(p.photoPaths, [
        '/photos/item1.jpg',
        '/photos/item2.jpg',
        '/photos/item3.jpg',
      ]);
      expect(p.firstPhotoPath, '/photos/item1.jpg');
    });

    test('BatchItemInput holds optional photoPath', () {
      const item = BatchItemInput(
        categoryId: 'cat1',
        colorId: 'col1',
        quantity: 2,
        photoPath: '/photos/a.jpg|/photos/b.jpg',
      );
      expect(item.photoPath, '/photos/a.jpg|/photos/b.jpg');
    });
  });
}
