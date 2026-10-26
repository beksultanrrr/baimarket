import 'dart:io';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

/// Плитки главной приходят экспортом из Figma и содержат градиенты,
/// clipPath и `<filter>`. Фильтры flutter_svg не поддерживает — важно, что
/// он на них не падает, а просто игнорирует. Тест ловит битый экспорт.
void main() {
  const tiles = [
    'assets/icons/main/tile_prize.svg',
    'assets/icons/main/tile_new.svg',
    'assets/icons/main/tile_hit.svg',
    'assets/icons/main/tile_sales.svg',
    'assets/icons/main/tile_all.svg',
  ];

  for (final path in tiles) {
    test('$path парсится flutter_svg и не содержит текстовых путей', () async {
      final source = File(path).readAsStringSync();

      // Подписи локализуются Flutter-текстом поверх плитки, поэтому в
      // ассете их быть не должно — ни <text>, ни запечённых белых путей.
      expect(source.contains('<text'), isFalse, reason: 'в $path остался <text>');

      final info = await vg.loadPicture(SvgStringLoader(source), null);
      addTearDown(info.picture.dispose);
      expect(info.size.width, greaterThan(0));
      expect(info.size.height, 80);
    });
  }
}
