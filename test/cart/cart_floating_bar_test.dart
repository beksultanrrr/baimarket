import 'package:bai_market/features/cart/presentation/widgets/cart_floating_bar.dart';
import 'package:bai_market/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Плашка живёт в `MaterialApp.builder`, то есть без Material-предка и с
/// фиксированной высотой 64. Проверяем, что содержимое в неё влезает: при
/// длинной подписи кнопки счётчик товаров переносился на вторую строку и
/// плашка переполнялась на 8px.
Future<void> _pump(
  WidgetTester tester, {
  required double width,
  required int itemsCount,
  required int totalPrice,
  required Locale locale,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: width,
            child: CartFloatingBar(
              itemsCount: itemsCount,
              totalPrice: totalPrice,
              thumbnails: const ['a.jpg', 'b.jpg', 'c.jpg'],
              busy: false,
              onOpenCart: () {},
              onCheckout: () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  // Самый узкий актуальный экран (iPhone SE 375) минус горизонтальные отступы
  // плашки по 16.
  const narrow = 375.0 - 32;

  for (final locale in const [Locale('ru'), Locale('kk'), Locale('en')]) {
    testWidgets('не переполняется на узком экране — ${locale.languageCode}',
        (tester) async {
      await _pump(
        tester,
        width: narrow,
        itemsCount: 12,
        totalPrice: 568000,
        locale: locale,
      );

      expect(
        tester.takeException(),
        isNull,
        reason: 'RenderFlex overflow — содержимое не влезло в плашку',
      );
      expect(tester.getSize(find.byType(CartFloatingBar)).height, 64);
    });
  }

  testWidgets('счётчик и цена всегда в одну строку', (tester) async {
    await _pump(
      tester,
      width: narrow,
      itemsCount: 12,
      totalPrice: 568000,
      locale: const Locale('ru'),
    );

    // Именно эти две строки живут в колонке фиксированной высоты: их перенос
    // и переполнял плашку.
    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .where((t) => (t.data ?? '').contains('товар') || (t.data ?? '').contains('₸'));

    expect(texts, hasLength(2), reason: 'счётчик и цена должны быть на месте');
    for (final text in texts) {
      expect(
        text.maxLines,
        1,
        reason: 'перенос строки ломает высоту плашки: "${text.data}"',
      );
    }
  });

  testWidgets('несёт свой Material — иначе текст с жёлтым подчёркиванием',
      (tester) async {
    // Как в бою: плашка живёт в MaterialApp.builder, Scaffold над ней нет.
    // Без собственного Material Flutter рисует Text отладочным стилем.
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (_, __) => Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: narrow,
            child: CartFloatingBar(
              itemsCount: 1,
              totalPrice: 3,
              thumbnails: const ['a.jpg'],
              busy: false,
              onOpenCart: () {},
              onCheckout: () {},
            ),
          ),
        ),
        home: const SizedBox.shrink(),
      ),
    );
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(CartFloatingBar),
        matching: find.byType(Material),
      ),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('лишние миниатюры схлопываются в счётчик', (tester) async {
    await _pump(
      tester,
      width: narrow,
      itemsCount: 12,
      totalPrice: 568000,
      locale: const Locale('ru'),
    );
    // Показываем 2 фото, остальные 10 — чипом «+10».
    expect(find.text('+10'), findsOneWidget);
  });
}
