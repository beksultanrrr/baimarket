import 'dart:io';

import 'package:bai_market/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Экраны адресов доставки локализованы: раньше все подписи были вшиты в код
/// по-русски и на kk/en не переводились.
void main() {
  const locales = [Locale('ru'), Locale('kk'), Locale('en')];

  test('во всех локалях ключи адресов заполнены и различаются', () async {
    final byLocale = <String, List<String>>{};
    for (final locale in locales) {
      final l10n = await AppLocalizations.delegate.load(locale);
      byLocale[locale.languageCode] = [
        l10n.deliveryAddressesTitle,
        l10n.deliveryAddressTitle,
        l10n.addMoreAddress,
        l10n.saveAddress,
        l10n.newAddress,
        l10n.addressAdded,
        l10n.addressDeleted,
        l10n.deleteAddressTitle,
        l10n.deleteAddressMessage,
        l10n.deleteAction,
        l10n.addAction,
        l10n.addressNameLabel,
        l10n.apartmentLabel,
        l10n.entranceLabel,
        l10n.floorLabel,
        l10n.selectRegion,
        l10n.selectCityFirst,
        l10n.addressesLoadError,
        l10n.addressAddError,
        l10n.addressDeleteError,
      ];
    }

    for (final entry in byLocale.entries) {
      expect(
        entry.value.every((s) => s.trim().isNotEmpty),
        isTrue,
        reason: 'пустой перевод в ${entry.key}',
      );
    }
    // Переводы реальные, а не скопированный русский.
    expect(byLocale['kk'], isNot(equals(byLocale['ru'])));
    expect(byLocale['en'], isNot(equals(byLocale['ru'])));
  });

  test('подпись карточки подставляет название адреса', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('ru'));
    expect(l10n.addressLabeled('Дом'), contains('Дом'));
    expect(l10n.postalIndex('1201023'), contains('1201023'));
  });

  // Только presentation: в data-слое русские строки лежат внутри Exception —
  // они уходят в лог, а пользователю кубит отдаёт MyAddressErrorKind, который
  // страница переводит сама.
  test('в UI экранов адресов не осталось русских литералов', () {
    final dir = Directory('lib/features/my_address/presentation');
    // Строку адреса для бэка собираем по-русски намеренно — её читает курьер.
    const allowed = {'кв. ', 'подъезд ', 'этаж ', 'КазПочта'};
    final cyrillic = RegExp(r"'[^']*[А-Яа-яЁё][^']*'");

    final offenders = <String>[];
    for (final file in dir.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      for (final line in file.readAsLinesSync()) {
        final trimmed = line.trim();
        if (trimmed.startsWith('//') || trimmed.startsWith('///')) continue;
        for (final match in cyrillic.allMatches(line)) {
          final literal = match.group(0)!;
          if (allowed.any(literal.contains)) continue;
          offenders.add('${file.path}: $literal');
        }
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
