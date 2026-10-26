import 'package:bai_market/core/app_pallete.dart';
import 'package:bai_market/core/widgets/sort_sheet.dart';
import 'package:bai_market/features/raffle/presentation/widgets/raffle_sort_sheet.dart';
import 'package:bai_market/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Единый шит сортировки: один вид на коллекции, розыгрышах и витрине
/// магазина, набор пунктов у каждого экрана свой.
void main() {
  Future<String?> open(
    WidgetTester tester, {
    required List<String> options,
    required String current,
  }) async {
    String? result;
    var opened = false;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                opened = true;
                result = await showSortSheet(
                  context: context,
                  current: current,
                  options: options,
                  labelOf: raffleSortLabel,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(opened, isTrue);
    return result;
  }

  testWidgets('показывает все переданные пункты и заголовок', (tester) async {
    await open(tester, options: raffleSortOptions, current: 'popular');

    expect(find.text('Вначале показывать'), findsOneWidget);
    expect(find.text('Популярное'), findsOneWidget);
    expect(find.text('Дешевые'), findsOneWidget);
    expect(find.text('Дорогие'), findsOneWidget);
    expect(find.text('Скидка'), findsOneWidget);
  });

  testWidgets('коллекция открывает тот же шит, но с тремя пунктами',
      (tester) async {
    await open(
      tester,
      options: const ['popular', 'cheap', 'expensive'],
      current: 'popular',
    );

    expect(find.text('Вначале показывать'), findsOneWidget);
    expect(find.text('Скидка'), findsNothing, reason: 'discount тут не шлём');
  });

  testWidgets('заголовок чёрный, как в макете (был зелёным)', (tester) async {
    await open(tester, options: raffleSortOptions, current: 'popular');

    final title = tester.widget<Text>(find.text('Вначале показывать')).style!;
    expect(title.color, Colors.black);
    expect(title.fontSize, 20);
    expect(title.fontWeight, FontWeight.w600);
  });

  testWidgets('тап по пункту возвращает его слаг', (tester) async {
    String? picked;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => picked = await showSortSheet(
                context: context,
                current: 'popular',
                options: raffleSortOptions,
                labelOf: raffleSortLabel,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Дорогие'));
    await tester.pumpAndSettle();

    expect(picked, 'expensive');
  });

  testWidgets('выбранный пункт помечен зелёным, остальные — нет',
      (tester) async {
    await open(tester, options: raffleSortOptions, current: 'cheap');

    // Кружки радио — Container'ы с круглой рамкой; зелёная ровно одна.
    final circles = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .where((d) => d.shape == BoxShape.circle && d.border != null)
        .toList();

    final green = circles
        .where((d) => (d.border! as Border).top.color == mainColorLight)
        .length;
    expect(green, 1, reason: 'выбран ровно один пункт');
  });
}
