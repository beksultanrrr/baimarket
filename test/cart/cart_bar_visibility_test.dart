import 'package:bai_market/core/navigation/app_route_observer.dart';
import 'package:bai_market/features/cart/presentation/widgets/cart_floating_bar_host.dart';
import 'package:bai_market/features/menu/presentation/providers/bottom_nav_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  bool visible({
    String? route,
    bool isModal = false,
    int tab = kMenuTabHome,
    int items = 2,
    bool keyboard = false,
  }) {
    return shouldShowCartBar(
      route: AppRouteInfo(name: route, isModal: isModal),
      menuTabIndex: tab,
      itemsCount: items,
      keyboardOpen: keyboard,
    );
  }

  group('плашка корзины видна', () {
    for (final route in const [
      '/main',
      '/catalog',
      '/profile',
      '/live/:id',
      '/live_host/:id',
      'stories_viewer',
      '/search',
      '/collection/:slug',
      '/raffle/:id',
      '/seller/:id',
      '/favorites',
    ]) {
      test('на $route', () => expect(visible(route: route), isTrue));
    }
  });

  group('плашка корзины скрыта', () {
    test('когда корзина пуста', () {
      expect(visible(route: '/main', items: 0), isFalse);
    });

    test('когда открыта клавиатура', () {
      expect(visible(route: '/search', keyboard: true), isFalse);
    });

    test('когда сверху модальный шит', () {
      // Иначе плашка легла бы поверх шита корзины на эфире и его затемнения.
      expect(visible(route: '/live/:id', isModal: true), isFalse);
    });

    test('на самом табе корзины', () {
      expect(visible(route: '/cart', tab: kMenuTabCart), isFalse);
      expect(visible(route: '/main', tab: kMenuTabCart), isFalse);
    });

    for (final route in const [
      '/product/:id',
      '/make_order',
      '/payment',
      '/payment_webview',
      '/order_success',
      '/auth',
      '/pin',
      '/create-pin',
      '/orders',
      '/notification',
    ]) {
      test('на $route', () => expect(visible(route: route), isFalse));
    }

    test('на неизвестном маршруте (список разрешающий)', () {
      expect(visible(route: '/some/new/screen'), isFalse);
      expect(visible(route: null), isFalse);
    });
  });
}
