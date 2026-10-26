import 'package:bai_market/core/routing/deep_link_parser.dart';
import 'package:bai_market/core/services/share_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeDeepLink', () {
    test('https-ссылка с Hosting отдаёт путь без домена', () {
      expect(
        normalizeDeepLink(Uri.parse('https://hibai-8a160.web.app/product/42')),
        '/product/42',
      );
    });

    test('второй домен Hosting разбирается так же', () {
      expect(
        normalizeDeepLink(
          Uri.parse('https://hibai-8a160.firebaseapp.com/seller/7'),
        ),
        '/seller/7',
      );
    });

    test('кастомная схема: host возвращается в начало пути', () {
      // Ровно тот случай, ради которого функция и написана: Uri.parse кладёт
      // `product` в host, и без склейки путь был бы `/42`.
      expect(
        normalizeDeepLink(Uri.parse('baimarket://product/42')),
        '/product/42',
      );
    });

    test('кастомная схема с пустым authority уже корректна', () {
      expect(
        normalizeDeepLink(Uri.parse('baimarket:///product/42')),
        '/product/42',
      );
    });

    test('query сохраняется', () {
      expect(
        normalizeDeepLink(
          Uri.parse('https://hibai-8a160.web.app/collection/parfum?sort=new'),
        ),
        '/collection/parfum?sort=new',
      );
    });

    test('лишние слэши схлопываются', () {
      expect(
        normalizeDeepLink(Uri.parse('https://hibai-8a160.web.app//product//42/')),
        '/product/42',
      );
    });

    test('корень домена не даёт маршрута', () {
      expect(normalizeDeepLink(Uri.parse('https://hibai-8a160.web.app/')), null);
      expect(normalizeDeepLink(Uri.parse('https://hibai-8a160.web.app')), null);
    });
  });

  group('appSchemeLink', () {
    test('собирает ссылку с пустым authority', () {
      expect(appSchemeLink('/product/42'), 'baimarket:///product/42');
      // Путь без ведущего слэша не должен превращаться в host.
      expect(appSchemeLink('product/42'), 'baimarket:///product/42');
    });

    test('собранная ссылка нормализуется обратно в тот же путь', () {
      expect(
        normalizeDeepLink(Uri.parse(appSchemeLink('/product/42'))),
        '/product/42',
      );
    });
  });

  group('ShareLinks', () {
    test('ссылка на товар ведёт на путь, объявленный в assetlinks/AASA', () {
      expect(ShareLinks.product(42), 'https://hibai-8a160.web.app/product/42');
    });

    test('путь ссылки совпадает с маршрутом приложения', () {
      expect(
        normalizeDeepLink(Uri.parse(ShareLinks.product(42))),
        '/product/42',
      );
      expect(normalizeDeepLink(Uri.parse(ShareLinks.seller(7))), '/seller/7');
      expect(normalizeDeepLink(Uri.parse(ShareLinks.live(3))), '/live/3');
      expect(normalizeDeepLink(Uri.parse(ShareLinks.raffle(9))), '/raffle/9');
      expect(
        normalizeDeepLink(Uri.parse(ShareLinks.collection('all'))),
        '/collection/all',
      );
    });
  });
}
