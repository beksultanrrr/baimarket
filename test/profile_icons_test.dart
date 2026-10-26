import 'dart:io';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

/// Иконки профиля приходят экспортом из Figma. Тест ловит битый файл и
/// опечатку в пути: SvgPicture.asset падает в рантайме, а не при сборке.
void main() {
  const icons = [
    'assets/icons/profile_page/ticket-star.svg',
    'assets/icons/profile_page/location-2.svg',
    'assets/icons/profile_page/bag.svg',
    'assets/icons/profile_page/headphone.svg',
    'assets/icons/profile_page/language-circle.svg',
    'assets/icons/profile_page/logout.svg',
    'assets/icons/location.svg',
  ];

  for (final path in icons) {
    test('$path существует и парсится', () async {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: 'нет файла $path');

      final info = await vg.loadPicture(
        SvgStringLoader(file.readAsStringSync()),
        null,
      );
      addTearDown(info.picture.dispose);
      expect(info.size.width, 24);
      expect(info.size.height, 24);
    });
  }
}
