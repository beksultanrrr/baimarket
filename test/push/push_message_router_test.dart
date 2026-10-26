import 'package:bai_market/core/push/push_message_router.dart';
import 'package:bai_market/core/urls.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String route(Map<String, dynamic> data) =>
      PushMessageRouter.resolveRoute(data);

  group('разбор ссылки из пуша', () {
    test('обычный путь', () {
      expect(route({'deeplink': '/product/42'}), '/product/42');
    });

    test('без ведущего слэша', () {
      expect(route({'deeplink': 'product/42'}), '/product/42');
    });

    test('кастомная схема', () {
      expect(route({'deeplink': 'baimarket://product/42'}), '/product/42');
    });

    test('https-ссылка на сайт', () {
      expect(
        route({'deeplink': 'https://iris-cosmetics.kz/product/42'}),
        '/product/42',
      );
    });

    test('buttonLink как запасной ключ', () {
      expect(route({'buttonLink': '/orders'}), '/orders');
    });

    test('deeplink важнее buttonLink', () {
      expect(
        route({'deeplink': '/cart', 'buttonLink': '/orders'}),
        '/cart',
      );
    });

    test('категория по type', () {
      expect(route({'type': 'promo'}), '/notification/promo');
    });
  });

  group('фолбэк на /notification', () {
    test('пустой payload', () {
      expect(route(const {}), '/notification');
    });

    test('неизвестный маршрут не пропускается', () {
      // GoRouter бросает на неизвестном пути — кривой payload из админки не
      // должен ронять приложение.
      expect(route({'deeplink': '/こんにちは'}), '/notification');
      expect(route({'deeplink': '/admin/secret'}), '/notification');
    });

    test('префикс без идентификатора не считается маршрутом', () {
      expect(route({'deeplink': '/product/'}), '/notification');
    });

    test('мусор вместо строки', () {
      expect(route({'deeplink': 123}), '/notification');
      expect(route({'deeplink': ''}), '/notification');
    });
  });

  group('внешние ссылки', () {
    test('билеты ведут на sz.kz, а не в приложение', () {
      expect(route({'deeplink': '/tickets'}), '/tickets');
      expect(PushMessageRouter.externalUrlFor('/tickets'), sattyJuldyzLoginUrl);
    });

    test('обычные маршруты остаются внутри приложения', () {
      expect(PushMessageRouter.externalUrlFor('/orders'), isNull);
      expect(PushMessageRouter.externalUrlFor('/product/42'), isNull);
    });
  });
}
