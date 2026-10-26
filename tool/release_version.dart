// Проставляет версию из pubspec.yaml в манифест обновлений и показывает, что
// после деплоя увидят пользователи.
//
//   fvm dart run tool/release_version.dart              # только показать
//   fvm dart run tool/release_version.dart --apply      # записать в манифест
//   fvm dart run tool/release_version.dart --apply --min 1.1.0
//
// Зачем скрипт, если правка одна: руками легко проставить версию, которой ещё
// нет в магазине, — и запереть людей в диалоге, ведущем в никуда. Здесь этот
// порядок хотя бы проговаривается вслух, а severity считается той же таблицей
// разрядов, что и в приложении.

import 'dart:convert';
import 'dart:io';

const _pubspecPath = 'pubspec.yaml';
const _manifestPath = 'hosting/public/app-version.json';

void main(List<String> args) {
  final apply = args.contains('--apply');
  final min = _flag(args, '--min');

  final pubspecVersion = _pubspecVersion();
  if (pubspecVersion == null) {
    _fail('не нашёл строку `version:` в $_pubspecPath');
  }

  final manifestFile = File(_manifestPath);
  if (!manifestFile.existsSync()) _fail('нет файла $_manifestPath');

  final Map<String, dynamic> manifest;
  try {
    manifest = jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
  } catch (e) {
    _fail('$_manifestPath не парсится: $e');
  }

  stdout.writeln('pubspec       : $pubspecVersion');
  for (final platform in const ['android', 'ios']) {
    final block = manifest[platform];
    if (block is! Map) continue;
    stdout.writeln(
      '$platform${' ' * (14 - platform.length)}: '
      'latest=${block['latestVersion']} min=${block['minSupportedVersion']}',
    );
  }
  stdout.writeln('');

  if (!apply) {
    stdout.writeln('Прогон вхолостую. Что произойдёт с --apply:');
    stdout.writeln('  latestVersion → $pubspecVersion в обоих блоках');
    if (min != null) stdout.writeln('  minSupportedVersion → $min');
    stdout.writeln('');
    _printImpact(pubspecVersion, min);
    stdout.writeln('Записать: добавьте --apply');
    return;
  }

  for (final platform in const ['android', 'ios']) {
    final block = manifest[platform];
    if (block is! Map) continue;
    block['latestVersion'] = pubspecVersion;
    if (min != null) block['minSupportedVersion'] = min;
  }

  manifestFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
  );
  stdout.writeln('✓ $_manifestPath обновлён на $pubspecVersion');
  stdout.writeln('');
  _printImpact(pubspecVersion, min);
  stdout.writeln('Дальше — и только в этом порядке:');
  stdout.writeln('  1. Убедиться, что $pubspecVersion УЖЕ лежит в магазинах.');
  stdout.writeln('     Манифест впереди релиза = диалог, ведущий в никуда.');
  stdout.writeln('  2. firebase deploy --only hosting');
  stdout.writeln('  3. curl -i https://hibai-8a160.web.app/app-version.json');
}

/// Та же таблица разрядов, что в `AppUpdateInfo.severityFor`.
void _printImpact(String latest, String? min) {
  final parts = _parse(latest);
  if (parts == null) return;
  final (major, minor, patch) = parts;
  stdout.writeln('Кто что увидит после деплоя:');
  stdout.writeln(
    '  версии $major.$minor.* ниже .$patch  → ничего (разошёлся только PATCH)',
  );
  stdout.writeln(
    '  версии $major.<$minor.*             → мягкий диалог с «Позже»',
  );
  stdout.writeln(
    '  версии <$major.*.*                  → БЛОКИРУЮЩИЙ диалог без выхода',
  );
  if (min != null) {
    stdout.writeln('  всё ниже $min${' ' * 22}→ БЛОКИРУЮЩИЙ диалог (minSupportedVersion)');
  }
  stdout.writeln('');
}

String? _pubspecVersion() {
  final file = File(_pubspecPath);
  if (!file.existsSync()) return null;
  for (final line in file.readAsLinesSync()) {
    final match = RegExp(r'^version:\s*(\S+)').firstMatch(line);
    if (match == null) continue;
    // Build-номер (`+23`) в манифест не идёт: сравниваются только разряды.
    return match.group(1)!.split('+').first;
  }
  return null;
}

(int, int, int)? _parse(String v) {
  final nums = RegExp(r'\d+')
      .allMatches(v.split('+').first.split('-').first)
      .map((m) => int.parse(m.group(0)!))
      .toList();
  if (nums.isEmpty) return null;
  int at(int i) => i < nums.length ? nums[i] : 0;
  return (at(0), at(1), at(2));
}

String? _flag(List<String> args, String name) {
  final i = args.indexOf(name);
  if (i == -1 || i + 1 >= args.length) return null;
  return args[i + 1];
}

Never _fail(String message) {
  stderr.writeln('✗ $message');
  exit(1);
}
