import 'package:bai_market/features/live/data/datasources/live_socket_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('liveNamespaceUrl', () {
    test('срезает завершающий слэш базового адреса', () {
      // mainUrl объявлен со слэшем на конце, и наивная склейка даёт `//live`,
      // из которого socket.io выводит namespace `//live` — не тот, что нужен.
      expect(
        liveNamespaceUrl('https://api.iris-cosmetics.kz/'),
        'https://api.iris-cosmetics.kz/live',
      );
    });

    test('работает и без слэша на конце', () {
      expect(
        liveNamespaceUrl('https://api.iris-cosmetics.kz'),
        'https://api.iris-cosmetics.kz/live',
      );
    });

    test('путь URL — ровно /live: именно из него берётся namespace', () {
      expect(Uri.parse(liveNamespaceUrl()).path, '/live');
    });
  });

  group('sendChat — проверки до отправки', () {
    late LiveSocketService service;

    setUp(() => service = LiveSocketService(streamId: 42));
    tearDown(() => service.dispose());

    test('пустое сообщение отклоняется', () {
      expect(service.sendChat('   '), LiveChatSendError.empty);
    });

    test('длиннее 500 символов отклоняется', () {
      final long = 'a' * (LiveSocketService.maxMessageLength + 1);
      expect(service.sendChat(long), LiveChatSendError.tooLong);
    });

    test('ровно 500 символов проходит валидацию длины', () {
      final exact = 'a' * LiveSocketService.maxMessageLength;
      // Сокета нет, поэтому дальше упирается в disconnected — важно, что это
      // уже НЕ tooLong.
      expect(service.sendChat(exact), LiveChatSendError.disconnected);
    });

    test('без соединения сообщение дропается, а не буферизуется', () {
      // socket.io сливает sendBuffer в onconnect ДО события `connect`, то есть
      // до нашего joinStream: буферизованное сообщение ушло бы, пока клиент
      // ещё не в комнате.
      expect(service.sendChat('привет'), LiveChatSendError.disconnected);
    });
  });
}
