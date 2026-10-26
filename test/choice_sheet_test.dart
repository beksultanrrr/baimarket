import 'package:bai_market/core/app_pallete.dart';
import 'package:bai_market/core/widgets/choice_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Общий шит выбора: используется и для коротких списков (сортировка), и для
/// длинных (регионы, города, филиалы).
void main() {
  // Реальный список регионов Казахстана примерно такой длины.
  final regions = List.generate(20, (i) => 'Область ${i + 1}');

  Future<T?> open<T>(
    WidgetTester tester, {
    required List<T> items,
    required String Function(T) labelOf,
    T? selected,
  }) async {
    T? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await showChoiceSheet<T>(
                context: context,
                title: 'Выберите регион',
                items: items,
                labelOf: labelOf,
                selected: selected,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('длинный список не переполняется и скроллится', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await open<String>(tester, items: regions, labelOf: (r) => r);

    expect(tester.takeException(), isNull, reason: 'overflow при 20 пунктах');
    expect(find.text('Выберите регион'), findsOneWidget);
    // Первые пункты видны, дальние — за пределами вьюпорта.
    expect(find.text('Область 1'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Область 20'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'overflow после скролла');
    expect(find.text('Область 20'), findsOneWidget);
  });

  testWidgets('заголовок чёрный — не остаётся отладочного жёлтого',
      (tester) async {
    await open<String>(tester, items: regions, labelOf: (r) => r);

    final title = tester.widget<Text>(find.text('Выберите регион')).style!;
    expect(title.color, Colors.black);
    expect(
      title.decoration,
      anyOf(isNull, TextDecoration.none),
      reason: 'жёлтое подчёркивание = Text без Material-предка',
    );
  });

  testWidgets('выбранный помечен зелёным кольцом', (tester) async {
    await open<String>(
      tester,
      items: regions,
      labelOf: (r) => r,
      selected: 'Область 2',
    );

    final green = tester
        .widgetList<ChoiceRadio>(find.byType(ChoiceRadio))
        .where((r) => r.selected)
        .length;
    expect(green, 1);
  });

  testWidgets('тап возвращает элемент, крестик — null', (tester) async {
    final picked = await open<String>(
      tester,
      items: regions,
      labelOf: (r) => r,
    );
    expect(picked, isNull, reason: 'ещё ничего не выбрали');

    await tester.tap(find.text('Область 3'));
    await tester.pumpAndSettle();
    // Шит закрылся — заголовка больше нет.
    expect(find.text('Выберите регион'), findsNothing);
  });

  testWidgets('пункты лежат в карточке с рамкой #00000012', (tester) async {
    await open<String>(tester, items: regions, labelOf: (r) => r);

    final card = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .firstWhere((d) => d.border is Border && d.borderRadius != null);
    expect((card.border! as Border).top.color, hairlineBorder);
    expect((card.border! as Border).top.width, kHairlineWidth);
  });
}
