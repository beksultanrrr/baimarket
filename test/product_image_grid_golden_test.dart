import 'package:bai_market/features/product/data/models/product_model.dart';
import 'package:bai_market/features/product/presentation/widgets/product_image_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProductModel _model(List<String>? photos) => ProductModel(
      id: 9002,
      collections: null,
      deal: false,
      descriptionEn: null,
      descriptionKz: null,
      descriptionRu: null,
      detailedDescriptionEn: null,
      detailedDescriptionKz: null,
      detailedDescriptionRu: null,
      inStockCount: 5,
      isInFavorite: false,
      name: 'Серьги с бриллиантом',
      oldPrice: 150000,
      photoUrls: photos,
      price: 120000,
      product: null,
      weightInKg: 0.1,
    );

void main() {
  // iPhone 14 Pro Max — как на скриншоте пользователя.
  const size = Size(430, 300);

  testWidgets('hero renders on white, centered, 210pt', (tester) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Align(
            alignment: Alignment.topCenter,
            // Дохлый absolute-url -> заглушка, ровно как у пользователя.
            child: ProductImageGrid(
              model: _model(
                ['https://placeholder.co/400x400/silver/black?text=Earrings'],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final hero = tester.getSize(find.byType(ProductImageGrid));
    expect(hero.height, 210, reason: 'высота блока по макету');
    expect(hero.width, 430, reason: 'во всю ширину');
    expect(find.byType(PageView), findsOneWidget);

    // Заглушка: белый фон вместо серой карточки.
    final box = tester.widget<Container>(
      find.descendant(
        of: find.byType(ProductImageGrid),
        matching: find.byType(Container),
      ),
    );
    expect(box.color, Colors.white);

    // Мок рисуется 210×210 по центру -> бутылёк ~200pt, как в Figma.
    final img = tester.getSize(find.byType(Image));
    expect(img.width, 210);
    expect(img.height, 210);

    final rect = tester.getRect(find.byType(Image));
    expect(rect.center.dx, 215, reason: 'по центру экрана 430pt');
  });
}
