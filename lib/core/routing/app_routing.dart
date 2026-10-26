import 'package:bai_market/core/secure_token_storage.dart';
import 'package:bai_market/core/auth/app_lock.dart';
import 'package:bai_market/core/navigation/app_route_observer.dart';
import 'package:bai_market/core/pin_storage.dart';
import 'package:bai_market/core/services/app_logger.dart';
import 'package:bai_market/features/cart/data/models/cart_model.dart';
import 'package:bai_market/features/debug/presentation/pages/push_debug_page.dart';
import 'package:bai_market/features/create_order/presentation/pages/create_order_page.dart';
import 'package:bai_market/features/orders/data/models/order_model.dart';
import 'package:bai_market/features/live/data/models/live_host_args.dart';
import 'package:bai_market/features/live/data/models/live_stream_model.dart';
import 'package:bai_market/features/live/presentation/pages/live_host_page.dart';
import 'package:bai_market/features/live/presentation/pages/live_page.dart';
import 'package:bai_market/features/order_success/data/models/order_success_args.dart';
import 'package:bai_market/features/order_success/presentation/pages/order_success_page.dart';
import 'package:bai_market/features/payment/data/models/payment_args.dart';
import 'package:bai_market/features/payment/presentation/pages/payment_page.dart';
import 'package:bai_market/features/payment/presentation/pages/payment_webview_page.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/auth_page.dart';
import '../../features/auth/presentation/pages/pin_lock_page.dart';
import '../../features/auth/presentation/pages/pin_create_page.dart';
import '../../features/auth/presentation/pages/registration_page.dart';
import '../../features/cards/presentation/pages/my_cards_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/main/data/models/banner_model.dart';
import '../../features/main/presentation/pages/banner_page.dart';
import '../../features/collection/presentation/pages/collection_page.dart';
import '../../features/favorites/presentation/pages/favorites_page.dart';
import '../../features/menu/presentation/pages/menu_page.dart';
import '../../features/my_address/presentation/pages/my_address_page.dart';
import '../../features/my_data/presentation/pages/my_data_page.dart';
import '../../features/notification/presentation/pages/notification_list.dart';
import '../../features/notification/presentation/pages/notification_page.dart';
import '../../features/order/presentation/pages/order_page.dart';
import '../../features/orders/presentation/pages/orders_page.dart';
import '../../features/plus/presentation/pages/plus_history_page.dart';
import '../../features/plus/presentation/pages/plus_page.dart';
import '../../features/prizes/presentation/pages/prizes_page.dart';
// TODO(reviews): нужен только маршруту отзывов — вернуть вместе с ним.
// import '../../features/product/data/models/product_model.dart';
import '../../features/product/presentation/pages/product_page.dart';
// TODO(reviews): отзывы временно отключены целиком.
// import '../../features/product/presentation/pages/product_reviews_page.dart';
import '../../features/raffle/presentation/pages/raffle_detail_page.dart';
import '../../features/seller/presentation/pages/seller_store_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/profile/data/models/profile_model.dart';
import '../../features/tickets/presentation/pages/tickets_page.dart';
import 'deep_link_parser.dart';

/// Шаблон маршрута эфира. Вынесен в константу, потому что go_router кладёт в
/// `RouteSettings.name` именно **шаблон**, и на него завязаны плашка корзины,
/// отступы нижней панели и роутер пушей. Строка, размазанная по пяти файлам,
/// ломается молча.
const String kLiveRouteTemplate = '/live/:id';

/// Экран ведущего. Подчёркивание, а не `/live/host`: иначе `/live/:id` съест
/// его как id='host' — сработает то, что объявлено первым.
const String kLiveHostRouteTemplate = '/live_host/:id';

const _protectedPaths = <String>{
  '/profile',
  '/cart',
  '/make_order',
  '/payment',
  '/payment_webview',
  '/order_success',
  '/orders',
  '/order',
  '/my_data',
  '/my_address',
  '/my_cards',
  '/favorites',
  '/tickets',
  '/plus',
  '/plus/history',
  '/notification',
  '/prizes',
};

bool _isProtected(String path) {
  if (_protectedPaths.contains(path)) return true;
  // Сет проверяется точным совпадением, поэтому параметризованные маршруты
  // эфира сюда не положить: '/live/42' в нём не найдётся.
  return path.startsWith('/notification/') ||
      path.startsWith('/live/') ||
      path.startsWith('/live_host/');
}

/// Куда вернуть пользователя после успешной авторизации.
///
/// Гостя с защищённого маршрута мы уводим на `/auth`, и без этой памяти любой
/// диплинк на эфир или пуш заканчивался тупиком: после логина человек
/// оказывался на главной, а не там, куда шёл.
String? pendingProtectedLocation;

/// Забирает сохранённый маршрут ровно один раз.
String? takePendingProtectedLocation() {
  final location = pendingProtectedLocation;
  pendingProtectedLocation = null;
  return location;
}

/// Даёт виджетам над роутером (плашка корзины в `MaterialApp.builder`) знать
/// текущий маршрут и то, лежит ли сверху модальный шит.
final appRouteObserver = AppRouteObserver();

final router = GoRouter(
  observers: [appRouteObserver],
  initialLocation: '/main',
  // Диплинки приходят снаружи, поэтому «маршрута нет» — рядовая ситуация, а не
  // баг: ссылку могли обрезать в мессенджере, прислать со старым путём или
  // открыть кастомной схемой `baimarket://product/42`, где `product` попадает
  // в host и до path не доезжает. Без обработчика go_router показал бы красный
  // экран ошибки прямо по клику на присланную ссылку.
  onException: (context, state, router) {
    final normalized = normalizeDeepLink(state.uri);
    // Сравниваем с уже опробованным путём: если нормализация ничего не
    // изменила, повторный go() снова упал бы сюда — и так по кругу.
    final target = normalized != null && normalized != state.uri.path
        ? normalized
        : '/main';
    routerLog.nav('unknown location ${state.uri} → $target');
    router.go(target);
  },
  redirect: (context, state) async {
    final loc = state.matchedLocation;
    if (loc == '/') {
      routerLog.nav('/ → /main');
      return '/main';
    }
    final token = await getAuthToken();
    final isOnAuth = loc == '/auth' || loc.startsWith('/auth/');
    final isPinRoute = loc == '/pin' || loc == '/create-pin';
    // Возврат авторизованного пользователя: пока сессия не разблокирована
    // и задан PIN — держим на экране блокировки.
    if (token != null && !AppLock.isUnlocked && !isPinRoute && await hasPin()) {
      routerLog.nav('locked user on $loc → /pin');
      return '/pin';
    }
    if (token != null && isOnAuth) {
      routerLog.nav('authed user on $loc → /main');
      return '/main';
    }
    if (token == null && !isOnAuth && !isPinRoute && _isProtected(loc)) {
      routerLog.nav('guest on protected $loc → /auth');
      // Запоминаем, куда человек шёл: после логина вернём его туда.
      pendingProtectedLocation = state.uri.toString();
      return '/auth';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/auth', builder: (context, state) => AuthPage()),
    GoRoute(path: '/pin', builder: (context, state) => const PinLockPage()),
    GoRoute(path: '/create-pin', builder: (context, state) => const PinCreatePage()),
    GoRoute(path: '/register', builder: (context, state) => const RegistrationPage()),
    GoRoute(
      path: '/auth/otp/:phoneNumber',
      builder:
          (context, state) =>
              OtpPage(
                phoneNumber: Uri.decodeComponent(
                  state.pathParameters['phoneNumber'] ?? '',
                ),
              ),
    ),
    GoRoute(
      path: '/main',
      builder: (context, state) => MenuPage(initialPage: 'catalog'),
    ),
    GoRoute(
      path: '/catalog',
      builder: (context, state) => MenuPage(initialPage: 'catalog'),
    ),

    // Вкладка «Эфиры». Раньше на неё нельзя было попасть по ссылке вообще:
    // отдельного маршрута не было, а menuTabIndexFor не знал слова 'streams'.
    GoRoute(
      path: '/streams',
      builder: (context, state) => MenuPage(initialPage: 'streams'),
    ),
    GoRoute(
      path: '/cart',
      builder: (context, state) => MenuPage(initialPage: 'cart'),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => MenuPage(initialPage: 'profile'),
    ),
    GoRoute(
      path: '/product/:id',
      builder: (context, state) => ProductPage(id: state.pathParameters['id']),
    ),
    // TODO(reviews): отзывы временно отключены целиком.
    // GoRoute(
    //   path: '/product/:id/reviews',
    //   redirect: (context, state) => state.extra is ProductModel
    //       ? null
    //       : '/product/${state.pathParameters['id']}',
    //   builder: (context, state) => ProductReviewsPage(
    //     product: state.extra as ProductModel,
    //   ),
    // ),
    GoRoute(
      path: '/notification',
      builder: (context, state) => NotificationList(),
    ),
    GoRoute(
      path: '/notification/:id',
      builder:
          (context, state) => NotificationPage(id: state.pathParameters['id']),
    ),
    GoRoute(path: '/orders', builder: (context, state) => OrdersPage()),
    GoRoute(
      path: '/order',
      redirect: (context, state) =>
          state.extra is OrderModel ? null : '/orders',
      builder: (context, state) {
        final order = state.extra as OrderModel;
        return OrderPage(orderModel: order);
      },
    ),
    GoRoute(
      path: '/my_data',
      redirect: (context, state) =>
          state.extra is ProfileModel ? null : '/profile',
      builder: (context, state) {
        final profile = state.extra as ProfileModel;
        return MyDataPage(profileModel: profile);
      },
    ),
    GoRoute(path: '/my_address', builder: (context, state) => MyAddressPage()),
    GoRoute(path: '/my_cards', builder: (context, state) => const MyCardsPage()),
    GoRoute(
      path: '/make_order',
      // id > 0 обязателен: `createOrder(cartId:)` не должен получить корзину,
      // которую сервер ещё не подтвердил.
      redirect: (context, state) {
        final extra = state.extra;
        if (extra is CartModel && extra.id > 0) return null;
        return '/cart';
      },
      builder: (context, state) {
        final cart = state.extra as CartModel;
        return CreateOrderPage(cartModel: cart);
      },
    ),
    GoRoute(path: '/favorites', builder: (context, state) => FavoritesPage()),
    GoRoute(
      path: '/banner',
      redirect: (context, state) =>
          state.extra is BannerModel ? null : '/main',
      builder: (context, state) {
        final banner = state.extra as BannerModel;
        return BannerPage(banner: banner);
      },
    ),
    GoRoute(path: '/plus', builder: (context, state) => const PlusPage()),
    GoRoute(
      path: '/plus/history',
      builder: (context, state) => const PlusHistoryPage(),
    ),
    GoRoute(path: '/prizes', builder: (context, state) => PrizesPage()),
    // Легаси-путь: раньше открывал витрину-заглушку на mock-id -1. Витрины
    // магазинов теперь живут на /seller/:id, а сам список — на вкладке
    // «Все магазины». Маршрут оставлен редиректом на случай старых ссылок
    // из пуш-payload или админки.
    GoRoute(path: '/shop', redirect: (context, state) => '/catalog'),
    GoRoute(path: '/tickets', builder: (context, state) => TicketsPage()),
    // Диагностика пушей. Намеренно НЕ в _protectedPaths: проверять надо и в
    // разлогиненном состоянии — именно там ломалась регистрация токена.
    GoRoute(
      path: '/debug/push',
      builder: (context, state) => const PushDebugPage(),
    ),
    // Оплата. Нормальный путь — PaymentArgs целиком: там и суммы (товары
    // отдельно от доставки), и id заказа. Так пушат и чекаут
    // (create_order_page), и повторная оплата из карточки заказа
    // (order_status_card).
    GoRoute(
      path: '/payment',
      redirect: (context, state) {
        final extra = state.extra;
        if (extra is PaymentArgs) return null;
        if (extra is String) return null;
        return '/main';
      },
      builder: (context, state) {
        final extra = state.extra;
        if (extra is PaymentArgs) return PaymentPage(args: extra);
        // Совместимость со старым вызовом: в extra пришла голая строка URL.
        // Сумм в ней нет и взять их неоткуда — экран покажет 0, поэтому новые
        // вызовы должны передавать PaymentArgs.
        return PaymentPage(
          args: PaymentArgs(amount: 0, paymentUrl: extra as String),
        );
      },
    ),
    GoRoute(
      path: '/payment_webview',
      redirect: (context, state) =>
          state.extra is PaymentArgs ? null : '/main',
      builder: (context, state) =>
          PaymentWebViewPage(args: state.extra as PaymentArgs),
    ),
    GoRoute(
      path: '/order_success',
      redirect: (context, state) =>
          state.extra is OrderSuccessArgs ? null : '/main',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        opaque: false,
        barrierDismissible: false,
        fullscreenDialog: true,
        child: OrderSuccessPage(args: state.extra as OrderSuccessArgs),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    ),
    // Эфир всегда открывается по конкретному streamId: список приходит из
    // GET /live, а токен — из POST /live/:id/token. `extra` необязателен и
    // нужен только чтобы шапка отрисовалась до ответа сервера.
    GoRoute(
      path: kLiveRouteTemplate,
      redirect: (context, state) {
        final raw = state.pathParameters['id'];
        return int.tryParse(raw ?? '') == null ? '/main' : null;
      },
      builder: (context, state) => LivePage(
        streamId: int.parse(state.pathParameters['id']!),
        preview: state.extra is LiveStreamModel
            ? state.extra as LiveStreamModel
            : null,
      ),
    ),
    // Экран ведущего. Без LiveHostArgs открыть нельзя: publisher-токен есть
    // только в ответе POST /live/start, и получить его повторно неоткуда.
    GoRoute(
      path: kLiveHostRouteTemplate,
      redirect: (context, state) =>
          state.extra is LiveHostArgs ? null : '/streams',
      builder: (context, state) =>
          LiveHostPage(args: state.extra as LiveHostArgs),
    ),
    GoRoute(path: '/search', builder: (context, state) => const SearchPage()),
    GoRoute(
      path: '/collection/:slug',
      builder: (context, state) {
        // extra: {title: 'Парфюмерия'} прокидывается из плиток каталога,
        // чтобы шапка показывала имя категории, а не дефолт от бэка.
        String? titleOverride;
        final extra = state.extra;
        if (extra is Map && extra['title'] is String) {
          titleOverride = extra['title'] as String;
        }
        return CollectionPage(
          slug: state.pathParameters['slug'],
          titleOverride: titleOverride,
        );
      },
    ),
    GoRoute(
      path: '/raffle/:id',
      redirect: (context, state) {
        final raw = state.pathParameters['id'];
        return int.tryParse(raw ?? '') == null ? '/catalog' : null;
      },
      builder: (context, state) => RaffleDetailPage(
        id: int.parse(state.pathParameters['id']!),
      ),
    ),
    // Витрина магазина. Публичный маршрут: `GET /seller/:id/models` работает и
    // для гостей. Через extra можно передать {title: 'Имя\nФамилия'}, чтобы
    // шапка отрисовалась сразу, без второго запроса за списком продавцов.
    GoRoute(
      path: '/seller/:id',
      redirect: (context, state) {
        final raw = state.pathParameters['id'];
        return int.tryParse(raw ?? '') == null ? '/catalog' : null;
      },
      builder: (context, state) {
        final extra = state.extra;
        String? titleOverride;
        if (extra is Map && extra['title'] is String) {
          titleOverride = extra['title'] as String;
        }
        return SellerStorePage(
          id: int.parse(state.pathParameters['id']!),
          titleOverride: titleOverride,
        );
      },
    ),
  ],
);
