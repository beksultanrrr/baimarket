import 'dart:io';

import 'package:bai_market/core/widgets/plus_price_badge.dart';
import 'package:bai_market/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Виджет-тесты по умолчанию рисуют шрифтом Ahem, где каждый глиф — квадрат
/// в 1em. Переносы строк тогда считаются неверно (\"алсаңыз\" = 7*11 = 77pt
/// вместо реальных ~38pt). Поэтому грузим настоящий Gilroy.
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

void main() {
  setUpAll(() async {
    // google_fonts не умеет качать Inter в тестах и молча падает в Ahem,
    // где цена меряется ~93pt вместо реальных ~50. Ширину берём с запасом,
    // чтобы этот артефакт не ломал замер подписи (она в SizedBox(width: 52)
    // и от цены не зависит).
    GoogleFonts.config.allowRuntimeFetching = false;
    await _loadGilroy();
  });

  Widget harness(Locale locale) => MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: Center(
            child: SizedBox(
              width: 260,
              child: PlusPriceBadge(plusPrice: 84000),
            ),
          ),
        ),
      );

  // «Plus пен алсаңыз» / «Plus-пен алсаңыз» не влезают в 52pt и переносятся
  // на две строки. Английское «With Plus» короткое — ложится в одну.
  const expectedLines = {'ru': 2, 'kk': 2, 'en': 1};

  expectedLines.forEach((code, want) {
    testWidgets('подпись в $want стр. — $code', (tester) async {
      await tester.pumpWidget(harness(Locale(code)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'без overflow');

      final label = find.byWidgetPredicate((w) => w is Text && w.maxLines == 2);
      final paragraph = tester.renderObject<RenderParagraph>(label);

      // Высота строки = fontSize 11 * height 1.1 = 12.1
      final lines = (tester.getSize(label).height / (11 * 1.1)).round();

      expect(lines, want, reason: 'строк в локали $code');
      expect(paragraph.didExceedMaxLines, isFalse, reason: 'без обрезки');
    });
  });

  testWidgets('высота бейджа = 34.2 (2 строки 11pt + padding 5)',
      (tester) async {
    await tester.pumpWidget(harness(const Locale('ru')));
    await tester.pumpAndSettle();

    final h = tester.getSize(find.byType(PlusPriceBadge)).height;
    expect(h, closeTo(34.2, 0.5));
  });
}
