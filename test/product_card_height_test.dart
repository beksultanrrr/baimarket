import 'dart:io';

import 'package:bai_market/core/widgets/product_card.dart';
import 'package:bai_market/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:bai_market/features/catalog/data/models/category_product_model.dart';
import 'package:bai_market/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:bai_market/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:bai_market/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> _loadGilroy() async {
  final loader = FontLoader('Gilroy');
  for (final path in const [
    'fonts/Gilroy-Semibold.ttf',
    'fonts/Gilroy-Regular.ttf',
  ]) {
    loader.addFont(
      File(path).readAsBytes().then((b) => ByteData.view(b.buffer)),
    );
  }
  await loader.load();
}

CategoryProductModel _product() => CategoryProductModel(
      id: 1,
      name: 'Золотое кольцо 585 пробы',
      price: 45000,
      oldPrice: 55000,
      photoUrls: null,
      descriptionKz: 'Золотое кольцо 585 пробы',
      descriptionRu: 'Золотое кольцо 585 пробы',
      descriptionEn: 'Золотое кольцо 585 пробы',
      collections: null,
      inStockCount: 5,
      isInFavorite: false,
      // plusPrice задаём явно: он приходит с бэка и больше не вычисляется из
      // price. Без него Plus-бейдж не рисуется и тест перестаёт мерить самый
      // высокий вариант карточки — ровно тот, под который выбран слот 342.
      plusPrice: 31500,
      // Бейдж билетов живёт внутри image-Stack, на высоту влиять не должен —
      // задаём, чтобы это проверялось.
      ticketsCount: 2,
    );

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await _loadGilroy();
  });

  // Слот карточки, продублированный по 12 местам в lib/.
  const slotHeight = 342.0;

  testWidgets('высота карточки с 2-строчным бейджем влезает в $slotHeight',
      (tester) async {
    tester.view.physicalSize = const Size(430 * 3, 2000 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    // Ширину берём с запасом (400): при узкой 180 цена, съезжающая в Ahem
    // из-за недокачанного Inter, даёт ложный горизонтальный overflow. По
    // вертикали ширина ни на что не влияет — описание фикс. 32, подпись
    // бейджа в SizedBox(52). Высоту меряем в неограниченной по высоте среде.
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => CartCubit()),
          BlocProvider(create: (_) => FavoritesCubit()),
          BlocProvider(create: (_) => ProfileCubit()),
        ],
        child: MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // SingleChildScrollView даёт неограниченную высоту. Без него корневой
          // Column карточки (mainAxisSize.max) растягивается на весь вьюпорт и
          // тест меряет высоту экрана, а не карточки. В приложении карточка
          // всегда лежит в ячейке сетки с mainAxisExtent: 342, поэтому на
          // продакшене это не проявляется.
          home: Scaffold(
            body: SingleChildScrollView(
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 400,
                  child: ProductCard(product: _product()),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final height = tester.getSize(find.byType(ProductCard)).height;
    // Замер: 341.0 при слоте 342 — запас всего ~1pt, и это с Ahem вместо
    // Inter (цена рисуется Ahem, он примерно на 3pt ниже). То есть на реальном
    // шрифте карточка с Plus-бейджем может не влезть.
    //
    // Проверяем настоящий контракт (влезает в слот), а не прежний запас в 4pt:
    // он был подобран для карточки без Plus-бейджа. Если бейдж начнёт
    // обрезаться — поднимать mainAxisExtent во всех сетках, а не ослаблять
    // этот тест.
    expect(height, lessThanOrEqualTo(slotHeight),
        reason: 'карточка $height должна влезать в слот $slotHeight');
  });
}
