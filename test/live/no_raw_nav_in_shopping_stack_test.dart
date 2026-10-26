import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Страховка от возврата бага «покупка выкидывает из эфира».
///
/// Весь путь покупки рендерится шитами поверх идущего стрима (и поверх
/// сториз). Любой сырой `context.push` / `Navigator.push` внутри этого стека
/// кладёт полноэкранный маршрут — WebRTC-сессия рвётся, а пользователь
/// оказывается неизвестно где. Ходить надо через `liveAwarePush` /
/// `liveAwarePushWidget` / `liveAwareGo` / `liveAwareDismiss`.
///
/// Если навигация здесь действительно нужна и она безопасна, пометьте её
/// комментарием `// live-nav-ok` — на той же строке либо на строке выше (вызов
/// часто разбит по строкам). Список исключений по файлам намеренно не заводим:
/// решение должно приниматься в самом месте вызова.
void main() {
  const scannedDirs = <String>[
    'lib/features/product',
    'lib/features/cart',
    'lib/features/create_order',
    'lib/features/payment',
    'lib/features/order_success',
    'lib/features/seller',
    'lib/features/reviews',
    'lib/features/live',
    'lib/features/stories',
  ];

  const scannedFiles = <String>[
    'lib/core/widgets/product_card.dart',
    'lib/core/push/push_message_router.dart',
    'lib/core/auth/auth_gate.dart',
  ];

  final patterns = <RegExp>[
    RegExp(r'context\.push\('),
    RegExp(r'context\.go\('),
    RegExp(r'Navigator\.(of\([^)]*\)\.)?push\('),
    RegExp(r'router\.push\('),
    RegExp(r'router\.go\('),
  ];

  test('в стеке покупки нет сырой навигации без пометки', () {
    final offenders = <String>[];

    for (final file in _dartFiles(scannedDirs, scannedFiles)) {
      // Сам модуль навигации и есть то место, где сырые вызовы легальны.
      if (file.path.endsWith('live_shopping_scope.dart')) continue;

      final lines = File(file.path).readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final previous = i > 0 ? lines[i - 1] : '';
        if (line.contains('// live-nav-ok') ||
            previous.contains('// live-nav-ok')) {
          continue;
        }
        if (line.trimLeft().startsWith('//')) continue;
        if (line.trimLeft().startsWith('///')) continue;
        if (patterns.any((p) => p.hasMatch(line))) {
          offenders.add('${file.path}:${i + 1}: ${line.trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Замените на liveAware*-хелпер либо пометьте // live-nav-ok:\n'
          '${offenders.join('\n')}',
    );
  });
}

Iterable<File> _dartFiles(List<String> dirs, List<String> files) sync* {
  for (final dir in dirs) {
    final directory = Directory(dir);
    if (!directory.existsSync()) continue;
    for (final entity in directory.listSync(recursive: true)) {
      if (entity is File &&
          entity.path.endsWith('.dart') &&
          !entity.path.endsWith('.g.dart')) {
        yield entity;
      }
    }
  }
  for (final path in files) {
    final file = File(path);
    if (file.existsSync()) yield file;
  }
}
