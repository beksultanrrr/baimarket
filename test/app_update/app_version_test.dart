import 'package:bai_market/features/app_update/data/models/app_update_info.dart';
import 'package:bai_market/features/app_update/data/models/app_version.dart';
import 'package:flutter_test/flutter_test.dart';

AppVersion v(String s) => AppVersion.tryParse(s)!;

void main() {
  group('AppVersion.tryParse', () {
    test('обычная тройка', () {
      final parsed = v('1.0.7');
      expect(parsed.major, 1);
      expect(parsed.minor, 0);
      expect(parsed.patch, 7);
      expect(parsed.raw, '1.0.7');
    });

    test('недостающие разряды — нули', () {
      expect(v('3.0'), v('3.0.0'));
      expect(v('2'), v('2.0.0'));
    });

    test('build-номер и pre-release отбрасываются', () {
      expect(v('1.0.7+23'), v('1.0.7'));
      expect(v('1.0.7-beta.2'), v('1.0.7'));
      expect(v('1.0.7-rc1+45'), v('1.0.7'));
    });

    test('лишние символы вокруг числа', () {
      expect(v('v1.2.3'), v('1.2.3'));
      expect(v(' 1.2.3 '), v('1.2.3'));
      expect(v('1.2.3.4'), v('1.2.3'));
    });

    test('мусор даёт null, а не нули', () {
      expect(AppVersion.tryParse(null), isNull);
      expect(AppVersion.tryParse(''), isNull);
      expect(AppVersion.tryParse('   '), isNull);
      expect(AppVersion.tryParse('latest'), isNull);
    });
  });

  group('AppVersion.compareTo', () {
    test('числовое сравнение, а не строковое', () {
      // Ровно тот случай, ради которого заведён отдельный тип: лексикографически
      // '1.0.10' < '1.0.9'.
      expect(v('1.0.10') > v('1.0.9'), isTrue);
      expect(v('1.10.0') > v('1.9.0'), isTrue);
      expect(v('10.0.0') > v('9.0.0'), isTrue);
    });

    test('равенство при разной длине записи', () {
      expect(v('3.0') == v('3.0.0'), isTrue);
      expect(v('3.0.0') >= v('3.0'), isTrue);
      expect(v('3.0.0') <= v('3.0'), isTrue);
    });
  });

  group('severityFor — правило разрядов', () {
    final current = v('1.0.7');

    AppUpdateSeverity check(String latest, {String? min, bool force = true}) {
      return AppUpdateInfo.severityFor(
        current: current,
        latest: v(latest),
        minSupported: min == null ? null : v(min),
        allowForce: force,
      );
    }

    test('меняется MAJOR → обязательное', () {
      expect(check('2.0.0'), AppUpdateSeverity.forced);
      expect(check('2.0.7'), AppUpdateSeverity.forced);
      // MAJOR выше, а MINOR/PATCH ниже — всё равно обязательное.
      expect(check('2.0.0'), AppUpdateSeverity.forced);
      expect(check('3.0'), AppUpdateSeverity.forced);
    });

    test('меняется MINOR → рекомендованное', () {
      expect(check('1.1.0'), AppUpdateSeverity.recommended);
      expect(check('1.1.7'), AppUpdateSeverity.recommended);
      expect(check('1.2.0'), AppUpdateSeverity.recommended);
    });

    test('меняется только PATCH → ничего', () {
      expect(check('1.0.8'), AppUpdateSeverity.none);
      expect(check('1.0.99'), AppUpdateSeverity.none);
    });

    test('версия та же или ниже → ничего', () {
      expect(check('1.0.7'), AppUpdateSeverity.none);
      expect(check('1.0.6'), AppUpdateSeverity.none);
      expect(check('1.0'), AppUpdateSeverity.none);
      // Откат релиза в магазине не должен звать «обновиться» вниз.
      expect(check('0.9.9'), AppUpdateSeverity.none);
    });

    test('minSupportedVersion делает обязательным даже PATCH', () {
      expect(check('1.0.8', min: '1.0.8'), AppUpdateSeverity.forced);
      // Текущая уже не ниже минимума — работает обычное правило разрядов.
      expect(check('1.0.8', min: '1.0.7'), AppUpdateSeverity.none);
      expect(check('1.1.0', min: '1.0.0'), AppUpdateSeverity.recommended);
    });

    test('источник без права блокировать не выдаёт forced', () {
      // Фолбэк на App Store Lookup: расхождение в MAJOR смягчается до
      // рекомендованного, иначе чужая нумерация заперла бы живых пользователей.
      expect(check('3.0', force: false), AppUpdateSeverity.recommended);
      expect(
        check('3.0', min: '2.0.0', force: false),
        AppUpdateSeverity.recommended,
      );
      expect(check('1.0.8', force: false), AppUpdateSeverity.none);
    });
  });

  group('RemoteAppVersion.tryParse', () {
    test('полный блок манифеста', () {
      final parsed = RemoteAppVersion.tryParse({
        'latestVersion': '1.1.0',
        'minSupportedVersion': '1.0.0',
        'storeUrl': 'https://example.com/app',
        'releaseNotes': {'ru': 'Починили корзину', 'en': 'Cart fixes'},
      })!;
      expect(parsed.latest, v('1.1.0'));
      expect(parsed.minSupported, v('1.0.0'));
      expect(parsed.storeUrl, 'https://example.com/app');
      expect(parsed.releaseNotes['ru'], 'Починили корзину');
      expect(parsed.allowForce, isTrue);
    });

    test('без latestVersion блок непригоден', () {
      expect(RemoteAppVersion.tryParse({'minSupportedVersion': '1.0.0'}), isNull);
      expect(RemoteAppVersion.tryParse(null), isNull);
      expect(RemoteAppVersion.tryParse('1.1.0'), isNull);
    });

    test('битые поля не роняют разбор', () {
      final parsed = RemoteAppVersion.tryParse({
        'latestVersion': '1.1.0',
        'minSupportedVersion': 'скоро',
        'storeUrl': '',
        'releaseNotes': ['не', 'та', 'форма'],
      })!;
      expect(parsed.latest, v('1.1.0'));
      expect(parsed.minSupported, isNull);
      expect(parsed.storeUrl, isNull);
      expect(parsed.releaseNotes, isEmpty);
    });

    test('строка вместо словаря заметок читается как общая', () {
      final parsed = RemoteAppVersion.tryParse({
        'latestVersion': '1.1.0',
        'releaseNotes': 'Общий текст',
      })!;
      expect(parsed.releaseNotes['*'], 'Общий текст');
    });
  });

  group('AppUpdateInfo.notesFor', () {
    AppUpdateInfo info(Map<String, String> notes) => AppUpdateInfo(
      severity: AppUpdateSeverity.recommended,
      currentVersion: v('1.0.7'),
      latestVersion: v('1.1.0'),
      storeUrl: 'https://example.com',
      releaseNotes: notes,
    );

    test('точная локаль', () {
      expect(info({'kk': 'қазақша', 'ru': 'по-русски'}).notesFor('kk'), 'қазақша');
    });

    test('откат на русский, потом на общий', () {
      expect(info({'ru': 'по-русски'}).notesFor('kk'), 'по-русски');
      expect(info({'*': 'общий'}).notesFor('kk'), 'общий');
      expect(info({}).notesFor('ru'), isNull);
    });

    test('пустая строка не считается текстом', () {
      expect(info({'ru': '   ', 'en': 'text'}).notesFor('ru'), 'text');
    });
  });
}
