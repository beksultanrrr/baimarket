import 'dart:io';

import 'package:bai_market/core/app_pallete.dart';
import 'package:bai_market/features/cart/presentation/widgets/cart_empty_state.dart';
import 'package:bai_market/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Пустая корзина по макету: иконка bag-2, заголовок 20/w500, подпись
/// 14/w400 #00000066, чёрная кнопка 20/w600.
///
/// Ширина кнопки не фиксирована (была 220pt) — тест следит, чтобы подпись
/// влезала во всех локалях и на узком экране.
Future<void> _loadGilroy() async {
  final loader = FontLoader('Gilroy');
  for (final path in const [
    'fonts/Gilroy-Semibold.ttf',
    'fonts/Gilroy-Medium.ttf',
    'fonts/Gilroy-Regular.ttf',
  ]) {
    loader.addFont(
      File(path).readAsBytes().then((b) => ByteData.view(b.buffer)),
    );
  }
  await loader.load();
}

void main() {
  setUpAll(_loadGilroy);

  Widget harness(Locale locale) => MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: CartEmptyState(onGoShopping: () {}),
          ),
        ),
      );

  testWidgets('типографика по макету', (tester) async {
    await tester.pumpWidget(harness(const Locale('ru')));

    final title = tester.widget<Text>(find.text('В корзине пусто')).style!;
    expect(title.fontSize, 20);
    expect(title.fontWeight, FontWeight.w500);

    final subtitle = tester
        .widget<Text>(find.text('Добавленные товары будут\nотображаться тут'))
        .style!;
    expect(subtitle.fontSize, 14);
    expect(subtitle.fontWeight, FontWeight.w400);
    expect(subtitle.color, const Color(0x66000000), reason: '#00000066');

    final button = tester.widget<Text>(find.text('К покупкам')).style!;
    expect(button.fontSize, 20);
    expect(button.fontWeight, FontWeight.w600);
    expect(button.color, Colors.white);

    final box = tester
        .widget<Container>(
          find
              .ancestor(
                of: find.text('К покупкам'),
                matching: find.byType(Container),
              )
              .first,
        )
        .decoration! as BoxDecoration;
    expect(box.color, darkButtonColor, reason: 'кнопка чёрная');
  });

  for (final locale in const [Locale('ru'), Locale('kk'), Locale('en')]) {
    testWidgets('кнопка не переполняется — ${locale.languageCode}',
        (tester) async {
      // Узкий экран: iPhone SE.
      tester.view
        ..physicalSize = const Size(320, 700)
        ..devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(harness(locale));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(CartEmptyState), findsOneWidget);
    });
  }
}
