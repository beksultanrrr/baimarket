import 'package:bai_market/core/firebase_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  bool copy({required bool iOS, required bool block, String? title = 'T', String? body}) =>
      FirebaseMessagingService.needsLocalCopy(
        isIOS: iOS,
        hasNotificationBlock: block,
        title: title,
        body: body,
      );

  group('своя копия пуша на переднем плане', () {
    test('iOS: пуш с notification уже показан системой — копии нет', () {
      expect(copy(iOS: true, block: true), isFalse);
    });

    test('iOS: data-only показываем сами', () {
      expect(copy(iOS: true, block: false), isTrue);
    });

    test('Android: система на переднем плане не показывает — копия всегда', () {
      expect(copy(iOS: false, block: true), isTrue);
      expect(copy(iOS: false, block: false), isTrue);
    });

    test('пуш без заголовка и текста не показываем нигде', () {
      expect(copy(iOS: false, block: false, title: null), isFalse);
      expect(copy(iOS: true, block: false, title: null), isFalse);
    });
  });
}
