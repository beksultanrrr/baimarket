import 'package:bai_market/core/widgets/app_refresh_indicator.dart';
import 'package:bai_market/core/widgets/load_more_listener.dart';
import 'package:bai_market/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:bai_market/features/catalog/data/models/category_product_model.dart';
import 'package:bai_market/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:bai_market/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:bai_market/features/seller/presentation/cubit/seller_store_cubit.dart';
import 'package:bai_market/features/seller/presentation/widgets/seller_products_section.dart';
import 'package:bai_market/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Магазин без товаров: белая карточка должна доходить до низа экрана, а не
/// обрываться по контенту, оставляя полосу зелёного фона `Scaffold`.
void main() {
  const viewport = Size(390, 844);
  const headerHeight = 200.0;

  // photoUrls пустой намеренно: сетевых картинок в тесте быть не должно.
  List<CategoryProductModel> products(int count) => List.generate(
        count,
        (i) => CategoryProductModel(
          id: i + 1,
          name: 'Товар ${i + 1}',
          price: 1000,
          oldPrice: null,
          photoUrls: const [],
          inStockCount: 5,
          descriptionKz: null,
          descriptionRu: null,
          descriptionEn: null,
          collections: null,
          isInFavorite: false,
        ),
      );

  Widget harness({
    required SellerStoreStatus status,
    required List<CategoryProductModel> models,
  }) {
    final section = SellerProductsSection(
      models: models,
      total: models.length,
      sort: 'popular',
      status: status,
      onSortChanged: (_) {},
    );

    return MaterialApp(
      locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // ProductCard читает эти кубиты; конструкторы у всех чистые — в сеть
      // ходят только явные методы, которые тест не вызывает.
      home: MultiBlocProvider(
        providers: [
          BlocProvider<CartCubit>(create: (_) => CartCubit()),
          BlocProvider<FavoritesCubit>(create: (_) => FavoritesCubit()),
          BlocProvider<ProfileCubit>(create: (_) => ProfileCubit()),
        ],
        child: Scaffold(
          backgroundColor: const Color(0xFF6ECB2E),
          // Обвязка как на странице: белая подложка снизу + pull-to-refresh
          // поверх того же скролла.
          body: Stack(
            children: [
              const Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: 0.5,
                  widthFactor: 1,
                  child: ColoredBox(color: Colors.white),
                ),
              ),
              AppRefreshIndicator(
                onRefresh: () async {},
                dark: true,
                child: LoadMoreListener(
                  hasMore: false,
                  onLoadMore: () async {},
                  child: CustomScrollView(
                    // Ровно как в seller_store_page.dart: bouncing + always
                    // scrollable, то есть overscroll возможен даже на пустой
                    // странице.
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      const SliverToBoxAdapter(
                        child: SizedBox(height: headerHeight),
                      ),
                      if (section.fillsViewport)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          fillOverscroll: true,
                          child: section,
                        )
                      else
                        SliverToBoxAdapter(child: section),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('пустой магазин: свайп не роняет layout и не открывает фон',
      (tester) async {
    tester.view
      ..physicalSize = viewport
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(harness(status: SellerStoreStatus.loaded, models: []));
    await tester.pumpAndSettle();

    final scroll = find.byType(CustomScrollView);

    // Тянем вверх (контент уезжает) и вниз (overscroll сверху) — на bouncing
    // физике оба направления живые даже без прокручиваемого контента.
    for (final dy in [-300.0, 300.0, -120.0, 120.0]) {
      await tester.drag(scroll, Offset(0, dy));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'drag $dy уронил кадр');

      // Главное: между низом уехавшей секции и белой подложкой не должно
      // оставаться зазора — в нём был бы виден зелёный фон Scaffold.
      final during = tester.getRect(find.byType(SellerProductsSection));
      final backdrop = tester.getRect(find.byType(FractionallySizedBox));
      expect(backdrop.bottom, viewport.height);
      expect(backdrop.top, lessThanOrEqualTo(during.bottom),
          reason: 'на overscroll ($dy) снизу открылся зелёный фон');

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'settle после $dy');
    }

    // После затухания bounce всё возвращается на место: белый снова до низа.
    final section = tester.getRect(find.byType(SellerProductsSection));
    expect(section.bottom, viewport.height);

    semantics.dispose();
  });

  testWidgets('пустой магазин: белый блок до низа, текст по центру остатка',
      (tester) async {
    tester.view
      ..physicalSize = viewport
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Семантика включена намеренно: с ней SliverFillRemaining прогоняет фазу
    // компиляции semantics, где и всплывали ассерты `!parentDataDirty` /
    // `!_needsLayout`, если layout секции невалиден.
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(harness(status: SellerStoreStatus.loaded, models: []));
    await tester.pumpAndSettle();

    final section = tester.getRect(find.byType(SellerProductsSection));
    expect(section.top, headerHeight, reason: 'начинается сразу под шапкой');
    expect(
      section.bottom,
      viewport.height,
      reason: 'белый блок доходит до низа экрана — зелёного под ним нет',
    );

    // Текст стоит по центру тела — области под строкой сортировки, — а не
    // прижат к её низу, как было до растяжки.
    final sortRow = tester.getRect(find.text('Популярное'));
    final text = tester.getRect(find.text('В этом магазине пока нет товаров'));
    final bodyCenter = (sortRow.bottom + section.bottom) / 2;
    expect((text.center.dy - bodyCenter).abs(), lessThan(24),
        reason: 'текст по центру пустого тела');
    expect(text.center.dy - sortRow.bottom, greaterThan(200),
        reason: 'заметно оторван от шапки, а не сразу под ней');

    semantics.dispose();
  });

  // Ловит рассинхрон между веткой `models.isEmpty` в build и геттером
  // fillsViewport: если Expanded окажется под SliverToBoxAdapter, Column
  // получит unbounded height и layout упадёт.
  for (final status in [
    SellerStoreStatus.loaded,
    SellerStoreStatus.sorting,
    SellerStoreStatus.loadingMore,
    SellerStoreStatus.error,
  ]) {
    testWidgets('магазин с товарами не падает на unbounded height — $status',
        (tester) async {
      tester.view
        ..physicalSize = viewport
        ..devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(harness(status: status, models: products(6)));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(SliverFillRemaining), findsNothing);
    });
  }

  testWidgets('первая загрузка растяжку не включает (скелет — GridView)',
      (tester) async {
    tester.view
      ..physicalSize = viewport
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness(status: SellerStoreStatus.loading, models: []));
    await tester.pump();

    expect(find.byType(SliverFillRemaining), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
